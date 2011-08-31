library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fd_wbgen2_pkg.all;


entity fd_acam_timestamp_postprocessor is
  generic(
    g_frac_bits : integer := 12);
  port(
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;

    -- Timestamp input, from the ACAM FSM
    raw_valid_i        : in std_logic;
    raw_utc_i          : in std_logic_vector(31 downto 0);
    raw_coarse_i       : in std_logic_vector(23 downto 0);
    raw_frac_i         : in std_logic_vector(22 downto 0);
    raw_start_offset_i : in std_logic_vector(3 downto 0);

    -- Offset between the actual timescale and the ACAM start signal generated
    -- by the AD9516 PLL
    acam_subcycle_offset_i : in std_logic_vector(4 downto 0);

    -- Post-processed timestamp. WARNING! DE-NORMALIZED!
    tag_valid_o  : out std_logic;
    tag_utc_o    : out std_logic_vector(31 downto 0);
    tag_coarse_o : out std_logic_vector(27 downto 0);
    tag_frac_o   : out std_logic_vector(g_frac_bits-1 downto 0);

    regs_b : t_fd_registers
    );

end fd_acam_timestamp_postprocessor;

architecture behavioral of fd_acam_timestamp_postprocessor is

  constant c_SCALER_SHIFT : integer := 12;

  signal pp_pipe : std_logic_vector(3 downto 0);

  signal post_tag_coarse      : unsigned(27 downto 0);
  signal post_tag_frac        : unsigned(g_frac_bits-1 downto 0);
  signal post_tag_utc         : unsigned(31 downto 0);
  signal post_frac_multiplied : signed(c_SCALER_SHIFT + g_frac_bits + 8 downto 0);
  signal post_frac_start_adj  : signed(22 downto 0);

begin  -- behavioral


  p_postprocess_tags : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        tag_valid_o  <= '0';
        tag_coarse_o <= (others => '0');
        tag_utc_o    <= (others => '0');
        tag_frac_o   <= (others => '0');
      else

-- pipeline stage 1:
-- - subtract the start offset from the fractional value got from the ACAM,

        pp_pipe(0) <= raw_valid_i;

        post_frac_start_adj         <= signed(raw_frac_i) - signed(regs_b.asor_offset_o);
        post_tag_coarse(3 downto 0) <= (others => '0');
        post_tag_utc                <= unsigned(raw_utc_i);

-- pipeline stage 2:
-- - check for the "wraparound" condition and adjust the coarse start counter

        pp_pipe(1) <= pp_pipe(0);

        if (unsigned(raw_start_offset_i) <= unsigned(regs_b.atmcr_c_thr_o)) and (post_frac_start_adj > signed(regs_b.atmcr_f_thr_o)) then
          post_tag_coarse(post_tag_coarse'left downto 4) <= unsigned(raw_coarse_i) - 1;
        else
          post_tag_coarse(post_tag_coarse'left downto 4) <= unsigned(raw_coarse_i);
        end if;

-- pipeline stage 3:
-- rescale the fractional part to our internal time base

        pp_pipe(2)           <= pp_pipe(1);
        post_frac_multiplied <= resize(signed(post_frac_start_adj) * signed(regs_b.adsfr_o), post_frac_multiplied'length);

-- pipeline stage 4:
-- - split the rescaled fractional part into the (mod 4096) tag_frac_o and add
-- the rest to the coarse part, along with the start-to-timescale offset

        pp_pipe(3) <= pp_pipe(2);

        tag_utc_o <= std_logic_vector(post_tag_utc);
        tag_coarse_o <= std_logic_vector(
          signed(post_tag_coarse)       -- index of start pulse (mod 16 = 0)
          + signed(acam_subcycle_offset_i)             -- start-to-timescale offset
          + signed(post_frac_multiplied(post_frac_multiplied'left downto c_SCALER_SHIFT + g_frac_bits))); 
        -- extra coarse counts from ACAM's frac part after rescaling

        tag_frac_o <= std_logic_vector(post_frac_multiplied(c_SCALER_SHIFT + g_frac_bits-1 downto c_SCALER_SHIFT));

        tag_valid_o <= pp_pipe(3);

      end if;
    end if;
  end process;

end behavioral;
