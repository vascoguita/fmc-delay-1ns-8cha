library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fd_rearm_generator is
  port (
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;

    tag_valid_i : in std_logic;

    rearm_i      : in std_logic_vector(3 downto 0);
    dcr_enable_i : in std_logic_vector(3 downto 0);
    dcr_mode_i   : in std_logic_vector(3 downto 0);

    rearm_p1_o : out std_logic
    );

end fd_rearm_generator;

architecture behavioral of fd_rearm_generator is
  signal rearm_ch : std_logic_vector(3 downto 0);
begin  -- behavioral

  p_rearm : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        rearm_ch   <= (others => '0');
        rearm_p1_o <= '0';
      else

        if(rearm_ch = "1111") then
          rearm_ch   <= (others => '0');
          rearm_p1_o <= '1';
        elsif(tag_valid_i = '1')then
          for i in 0 to 3 loop
            rearm_ch(i) <= (not dcr_enable_i(i)) or dcr_mode_i(i);
          end loop;  -- i
          rearm_p1_o <= '0';
        else
          rearm_p1_o <= '0';
          for i in 0 to 3 loop
            if((dcr_enable_i(i) = '1' and rearm_i(i) = '1') or dcr_enable_i(i) = '0') then
              rearm_ch(i) <= '1';
            end if;
          end loop;  -- i 
        end if;
      end if;
    end if;
  end process;


end behavioral;

