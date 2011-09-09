library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.genram_pkg.all;
use work.fd_wbgen2_pkg.all;


entity fd_ring_buffer is
  
  generic (
    g_size_log2 : integer := 8;
    g_frac_bits : integer := 12);

  port (

    rst_n_sys_i : in std_logic;
    rst_n_ref_i : in std_logic;

    clk_ref_i : in std_logic;
    clk_sys_i : in std_logic;

    tag_valid_i  : in std_logic;
    tag_utc_i    : in std_logic_vector(31 downto 0);
    tag_coarse_i : in std_logic_vector(27 downto 0);
    tag_frac_i   : in std_logic_vector(g_frac_bits-1 downto 0);

    advance_rbuf_i : in  std_logic;
    buf_irq_o      : out std_logic;

    regs_i : in  t_fd_out_registers;
    regs_o : out t_fd_in_registers
    );


end fd_ring_buffer;

architecture behavioral of fd_ring_buffer is

  constant c_PACKED_TS_SIZE : integer := 32 + 28 + g_frac_bits + 16;
  constant c_FIFO_SIZE      : integer := 64;

  type t_internal_timestamp is record
    utc    : std_logic_vector(31 downto 0);
    coarse : std_logic_vector(27 downto 0);
    frac   : std_logic_vector(g_frac_bits-1 downto 0);
    seq_id : std_logic_vector(15 downto 0);
  end record;

  function f_pack_timestamp(ts : t_internal_timestamp) return std_logic_vector is
    variable tmp : std_logic_vector(c_PACKED_TS_SIZE-1 downto 0);
  begin
    tmp(31 downto 0)                                               := ts.utc;
    tmp(32 + 27 downto 32)                                         := ts.coarse;
    tmp(32 + 28 + g_frac_bits-1 downto 32 + 28)                    := ts.frac;
    tmp(32 + 28 + g_frac_bits + 16-1 downto 32 + 28 + g_frac_bits) := ts.seq_id;
    return tmp;
  end f_pack_timestamp;

  function f_unpack_timestamp(ts : std_logic_vector)return t_internal_timestamp is
    variable tmp : t_internal_timestamp;
  begin
    tmp.utc    := ts(31 downto 0);
    tmp.coarse := ts(32 + 27 downto 32);
    tmp.frac   := ts(32+ 28 + g_frac_bits-1 downto 32+28);
    tmp.seq_id := ts(32 + 28 + g_frac_bits + 16 -1 downto 32 + 28 + g_frac_bits);
    return tmp;
  end f_unpack_timestamp;

  signal fifo_in, fifo_out     : std_logic_vector(c_PACKED_TS_SIZE-1 downto 0);
  signal fifo_write, fifo_read : std_logic;
  signal fifo_empty, fifo_full : std_logic;

  signal ts_fifo_in : t_internal_timestamp;
  signal cur_seq_id : unsigned(15 downto 0);

  signal buf_wr_ptr : unsigned(g_size_log2-1 downto 0);
  signal buf_rd_ptr : unsigned(g_size_log2-1 downto 0);
  signal buf_full   : std_logic;
  signal buf_empty  : std_logic;

  signal buf_wr_data : std_logic_vector(c_PACKED_TS_SIZE-1 downto 0);
  signal buf_rd_data : std_logic_vector(c_PACKED_TS_SIZE-1 downto 0);
  signal buf_write   : std_logic;

  signal buf_ram_out : t_internal_timestamp;

  signal fifo_read_d0 : std_logic;
  signal update_regs  : std_logic;
  
begin  -- behavioral


  p_count_seq_id : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_ref_i = '0' or regs_i.tsbcr_rst_seq_o = '1' then
        cur_seq_id <= (others => '0');
      elsif(tag_valid_i = '1') then
        cur_seq_id <= cur_seq_id + 1;
      end if;
    end if;
  end process;

  fifo_in <= f_pack_timestamp(ts_fifo_in);

  ts_fifo_in.utc    <= tag_utc_i;
  ts_fifo_in.coarse <= tag_coarse_i;
  ts_fifo_in.frac   <= tag_frac_i;
  ts_fifo_in.seq_id <= std_logic_vector(cur_seq_id);

  fifo_write <= not fifo_full and tag_valid_i;

  U_Clock_Adjustment_Fifo : generic_async_fifo
    generic map (
      g_data_width => fifo_in'length,
      g_size       => c_FIFO_SIZE)
    port map (
      rst_n_i    => rst_n_sys_i,
      clk_wr_i   => clk_ref_i,
      d_i        => fifo_in,
      we_i       => fifo_write,
      wr_full_o  => fifo_full,
      clk_rd_i   => clk_sys_i,
      q_o        => fifo_out,
      rd_i       => fifo_read,
      rd_empty_o => fifo_empty);

  buf_wr_data <= fifo_out;

  U_Buffer_RAM : generic_dpram
    generic map (
      g_data_width => c_PACKED_TS_SIZE,
      g_size       => 2**g_size_log2,
      g_dual_clock => false)
    port map (
      rst_n_i => rst_n_sys_i,
      clka_i  => clk_ref_i,
      bwea_i  => (others => '1'),
      wea_i   => buf_write,
      aa_i    => std_logic_vector(buf_wr_ptr),
      da_i    => buf_wr_data,
      qa_o    => open,
      clkb_i  => clk_sys_i,
      bweb_i  => (others => '0'),
      web_i   => '0',
      ab_i    => std_logic_vector(buf_rd_ptr),
      db_i    => (others => '0'),
      qb_o    => buf_rd_data);


  fifo_read <= not fifo_empty;

  buf_full    <= '1' when (buf_wr_ptr + 1 = buf_rd_ptr) else '0';
  buf_empty   <= '1' when (buf_wr_ptr = buf_rd_ptr)     else '0';
  buf_write   <= regs_i.tsbcr_enable_o and fifo_read_d0;
  buf_ram_out <= f_unpack_timestamp(buf_rd_data);

  buf_irq_o <= not buf_empty;

  -- drive WB registers
  regs_o.tsbcr_empty_i <= buf_empty;
  regs_o.tsbcr_full_i  <= buf_full;

  p_buffer_control : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sys_i = '0' or regs_i.tsbcr_purge_o = '1' then
        buf_rd_ptr   <= (others => '0');
        buf_wr_ptr   <= (others => '0');
        fifo_read_d0 <= '0';
      else

        fifo_read_d0 <= fifo_read;

        --update_regs <= advance_rbuf_i and not (buf_write and buf_full);

        if(buf_write = '1') then
          buf_wr_ptr <= buf_wr_ptr + 1;
        end if;

        if((advance_rbuf_i = '1' or (buf_write = '1' and buf_full = '1')) and buf_empty = '0') then
          buf_rd_ptr <= buf_rd_ptr + 1;
        end if;

        ----if(update_regs = '1') then

        ----end if;
        
      end if;
    end if;
  end process;

  regs_o.tsbr_u_i         <= buf_ram_out.utc;
  regs_o.tsbr_c_i         <= buf_ram_out.coarse;
  regs_o.tsbr_fid_fine_i  <= buf_ram_out.frac;
  regs_o.tsbr_fid_seqid_i <= buf_ram_out.seq_id;

end behavioral;
