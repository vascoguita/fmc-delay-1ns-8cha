library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fd_spi_master is
  generic(
    g_div_ratio_log2 : integer := 2);
  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    start_i    : in  std_logic;
    cpol_i     : in  std_logic;
    data_i     : in  std_logic_vector(23 downto 0);
    sel_dac_i  : in  std_logic;
    sel_pll_i  : in  std_logic;
    sel_gpio_i : in  std_logic;
    ready_o    : out std_logic;
    data_o     : out std_logic_vector(23 downto 0);


    -- chip select for VCTCXO DAC
    spi_cs_dac_n_o : out std_logic;

    -- chip select for AD9516 PLL
    spi_cs_pll_n_o : out std_logic;

    -- chip select for MCP23S17 GPIO
    spi_cs_gpio_n_o : out std_logic;

    -- these are obvious
    spi_sclk_o : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic
    );

end fd_spi_master;

architecture behavioral of fd_spi_master is

  signal busy : std_logic;

  signal divider        : unsigned(11 downto 0);
  signal dataSh         : std_logic_vector(23 downto 0);
  signal bitCounter     : std_logic_vector(25 downto 0);
  signal endSendingData : std_logic;
  signal sendingData    : std_logic;
  signal iDacClk        : std_logic;
  signal iValidValue    : std_logic;

  signal divider_muxed : std_logic;

  signal cs_sel_dac  : std_logic;
  signal cs_sel_gpio : std_logic;
  signal cs_sel_pll  : std_logic;

--  signal data_in_reg  : std_logic_vector(23 downto 0);
  signal data_out_reg : std_logic_vector(23 downto 0);
  
  
begin  -- rtl

  
  divider_muxed <= divider(g_div_ratio_log2);  -- sclk = clk_i/64

  iValidValue <= start_i;

  process(clk_sys_i, rst_n_i)
  begin

    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        sendingData <= '0';
      else
        if iValidValue = '1' and sendingData = '0' then
          sendingData <= '1';
        elsif endSendingData = '1' then
          sendingData <= '0';
        end if;
      end if;
    end if;
  end process;

  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if iValidValue = '1' then
        divider <= (others => '0');
      elsif sendingData = '1' then
        if(divider_muxed = '1') then
          divider <= (others => '0');
        else
          divider <= divider + 1;
        end if;
      elsif endSendingData = '1' then
        divider <= (others => '0');
      end if;
    end if;
  end process;


  process(clk_sys_i, rst_n_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        iDacClk <= '1';                 -- 0
      else
        if iValidValue = '1' then
          iDacClk <= '1';               -- 0
        elsif divider_muxed = '1' then
          iDacClk <= not(iDacClk);
        elsif endSendingData = '1' then
          iDacClk <= '1';               -- 0
        end if;
      end if;
    end if;
  end process;

  process(clk_sys_i, rst_n_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        dataSh <= (others => '0');
      else
        if iValidValue = '1' and sendingData = '0' then

          cs_sel_dac  <= sel_dac_i;
          cs_sel_gpio <= sel_gpio_i;
          cs_sel_pll  <= sel_pll_i;

          dataSh <= data_i;                            --data_in_reg;
        elsif sendingData = '1' and divider_muxed = '1' and iDacClk = '0' then
          dataSh(0)                    <= spi_miso_i;  --dataSh(dataSh'left);
          dataSh(dataSh'left downto 1) <= dataSh(dataSh'left - 1 downto 0);


        end if;
      end if;
    end if;
  end process;

  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if iValidValue = '1' and sendingData = '0' then
        bitCounter(0)                        <= '1';
        bitCounter(bitCounter'left downto 1) <= (others => '0');
      elsif sendingData = '1' and to_integer(divider) = 0 and iDacClk = '1' then
        bitCounter(0)                        <= '0';
        bitCounter(bitCounter'left downto 1) <= bitCounter(bitCounter'left - 1 downto 0);
      end if;
    end if;
  end process;

  endSendingData <= bitCounter(bitCounter'left);

  ready_o <= not SendingData;
  data_o  <= dataSh;

  spi_mosi_o <= dataSh(dataSh'left);

  spi_cs_pll_n_o  <= not(sendingData) or (not cs_sel_pll);
  spi_cs_dac_n_o  <= not(sendingData) or (not cs_sel_dac);
  spi_cs_gpio_n_o <= not(sendingData) or (not cs_sel_gpio);

  p_drive_sclk : process(iDacClk, cpol_i)
  begin
    if(cpol_i = '0') then
      spi_sclk_o <= (iDacClk);
    else
      spi_sclk_o <= not (iDacClk);
    end if;
  end process;

end behavioral;

