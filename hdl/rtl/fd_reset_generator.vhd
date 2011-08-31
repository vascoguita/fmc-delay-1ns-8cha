library ieee;
use ieee.std_logic_1164.all;

use work.fd_wbgen2_pkg.all;

entity fd_reset_generator is
  
  port (
    clk_sys_i : in std_logic;
    clk_ref_i : in std_logic;

    rst_n_i : in std_logic;

    rst_n_sys_o : out std_logic;
    rst_n_ref_o : out std_logic;
    regs_b      : inout t_fd_registers);

end fd_reset_generator;

architecture behavioral of fd_reset_generator is

  constant c_RSTR_TRIGGER_VALUE : std_logic_vector(31 downto 0) := x"deadbeef";

  signal rstn_host_sysclk : std_logic;
  signal rstn_host_refclk : std_logic;
  signal rstn_host_d0     : std_logic;
  signal rstn_host_d1     : std_logic;

begin  -- behavioral


  regs_b <= c_fd_registers_init_value;
  
  p_soft_reset : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if(rst_n_i = '0') then
        rstn_host_sysclk <= '0';
      else
        if(regs_b.rstr_wr_o = '1' and regs_b.rstr_o = c_RSTR_TRIGGER_VALUE) then
          rstn_host_sysclk <= '0';
        else
          rstn_host_sysclk <= '1';
        end if;
      end if;
    end if;
  end process;



  p_sync_reset_refclk : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      rstn_host_refclk <= rst_n_i and rstn_host_sysclk;
      rstn_host_d0     <= rstn_host_sysclk;
      rstn_host_d1     <= rstn_host_d0;
      rstn_host_refclk <= rstn_host_d1;
    end if;
  end process;

  rst_n_ref_o <= rstn_host_sysclk;
  rst_n_sys_o <= rstn_host_refclk;

end behavioral;
