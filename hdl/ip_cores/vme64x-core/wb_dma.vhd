-------------------------------------------------------------------------------
--
-- Title       : WB_bus
-- Design      : VME64xCore
-- Author      : Pablo Alvarez
-- Company     : CERN
--
-------------------------------------------------------------------------------
--
-- File        : wb_dma.vhd
-- Generated   : 25/02/2011
-- From        : interface description file
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use work.common_components.all;

entity wb_dma is
  generic(c_dl     : integer := 64;
          c_al     : integer := 64;
          c_sell   : integer := 8;
          c_psizel : integer := 10);

  port (
    -- Common signals
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    transfer_done_o : out std_logic;

    -- Slave WB with dma support        
    sl_dat_i   : in  std_logic_vector(c_dl -1 downto 0);
    sl_dat_o   : out std_logic_vector(c_dl -1 downto 0);
    sl_adr_i   : in  std_logic_vector(c_al -1 downto 0);
    sl_cyc_i   : in  std_logic;
    sl_err_o   : out std_logic;
    sl_lock_i  : in  std_logic;
    sl_rty_o   : out std_logic;
    sl_sel_i   : in  std_logic_vector(c_sell -1 downto 0);
    sl_stb_i   : in  std_logic;
    sl_ack_o   : out std_logic;
    sl_we_i    : in  std_logic;
    sl_stall_o : out std_logic;

    -- This signals are not WB compatible. Should be connected to 0 if not
    -- used. 
    sl_psize_i : in std_logic_vector(c_psizel -1 downto 0);
--    sl_buff_access_i : in std_logic;

    -- Master WB port to fabric
    m_dat_i   : in  std_logic_vector(c_dl -1 downto 0);
    m_dat_o   : out std_logic_vector(c_dl -1 downto 0);
    m_adr_o   : out std_logic_vector(c_al -1 downto 0);
    m_cyc_o   : out std_logic;
    m_err_i   : in  std_logic;
    m_lock_o  : out std_logic;
    m_rty_i   : in  std_logic;
    m_sel_o   : out std_logic_vector(c_sell -1 downto 0);
    m_stb_o   : out std_logic;
    m_ack_i   : in  std_logic;
    m_we_o    : out std_logic;
    m_stall_i : in  std_logic


    );    
end wb_dma;

architecture RTL of wb_dma is

  signal ack_latched : std_logic;
  
begin

  
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if(sl_cyc_i = '1' and sl_stb_i = '1' and m_ack_i = '1') then
        ack_latched <= '1';
      elsif(sl_cyc_i = '0' or sl_stb_i = '0') then
        ack_latched <= '0';
      end if;
    end if;
  end process;

  sl_stall_o <= m_stall_i;
  m_we_o     <= sl_we_i;
  sl_ack_o   <= m_ack_i;
  m_stb_o    <= sl_stb_i and not ack_latched;
  m_sel_o    <= sl_sel_i;
  sl_rty_o   <= '0';
  sl_err_o   <= '0';
  m_adr_o    <= sl_adr_i;
  m_dat_o    <= sl_dat_i;
  sl_dat_o   <= m_dat_i;
  m_cyc_o    <= sl_cyc_i;
  
end RTL;
