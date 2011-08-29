library ieee;
use ieee.std_logic_1164.all;

use work.fd_wbgen2_pkg.all;

entity fd_gpio is
  
  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    -- chip select for VCTCXO DAC
    spi_cs_dac_n_o : out std_logic;

    -- chip select for AD9516 PLL
    spi_cs_pll_n_o : out std_logic;

    -- chip select for MCP23S17 GPIO
    spi_cs_gpio_n_o : out std_logic;

    -- these are obvious
    spi_sclk_o : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic;

    regs_b : inout t_fd_registers
    );

end fd_gpio;

architecture rtl of fd_gpio is

  
begin  -- rtl

  p_gpio_loads : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if (rst_n_i = '0') then
        spi_cs_dac_n_o  <= '1';
        spi_cs_pll_n_o  <= '1';
        spi_cs_gpio_n_o <= '1';
        spi_sclk_o      <= '0';
        spi_mosi_o      <= '0';

        regs.gprr_miso_i <= '0';
      else

        if(regs.gpsr_cs_pll_wr_o = '1' and regs.gpsr_cs_pll_o = '1') then
          spi_cs_pll_n_o <= '1';
        elsif (regs.gpcr_cs_pll_wr_o = '1' and regs.gpcr_cs_pll_o = '1') then
          spi_cs_pll_n_o <= '0';
        end if;

        if(regs.gpsr_cs_gpio_wr_o = '1' and regs.gpsr_cs_gpio_o = '1') then
          spi_cs_gpio_n_o <= '1';
        elsif (regs.gpcr_cs_gpio_wr_o = '1' and regs.gpcr_cs_gpio_o = '1') then
          spi_cs_gpio_n_o <= '0';
        end if;

        if(regs.gpsr_mosi_wr_o = '1' and regs.gpsr_mosi_o = '1') then
          spi_mosi_o <= '1';
        elsif (regs.gpcr_mosi_wr_o = '1' and regs.gpcr_mosi_o = '1') then
          spi_mosi_o <= '0';
        end if;

        if(regs.gpsr_sclk_wr_o = '1' and regs.gpsr_sclk_o = '1') then
          spi_sclk_o <= '1';
        elsif (regs.gpcr_sclk_wr_o = '1' and regs.gpcr_sclk_o = '1') then
          spi_sclk_o <= '0';
        end if;

        regs.gprr_miso_i <= spi_miso_i;
      end if;
    end if;
  end process;


end rtl;
