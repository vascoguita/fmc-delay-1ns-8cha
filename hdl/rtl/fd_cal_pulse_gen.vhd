library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fd_cal_pulse_gen is

  port(
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    pulse_o : out std_logic;

    pgcr_enable_i : in std_logic;
    pgcr_period_i : in std_logic_vector(30 downto 0)
    );


end fd_cal_pulse_gen;

architecture behavioral of fd_cal_pulse_gen is

  signal counter : unsigned(30 downto 0);
  signal pulse_int : std_logic;
  
begin  -- behavioral

  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' or pgcr_enable_i = '0' then
        pulse_int <= '0';
        counter <= to_unsigned(1, counter'length);
      else
        if(counter = unsigned(pgcr_period_i)) then
          counter <= to_unsigned(1, counter'length);
          pulse_int <= not pulse_int;
        else
          counter <= counter + 1;
        end if;

        pulse_o <= pulse_int;
      end if;
    end if;
  end process;

end behavioral;
