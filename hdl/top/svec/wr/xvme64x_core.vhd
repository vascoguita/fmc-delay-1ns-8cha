library ieee;
use ieee.STD_LOGIC_1164.all;
use WORK.wishbone_pkg.all;

entity xvme64x_core is

  port (
    clk_i   : in std_logic;
    rst_n_i : in std_logic;

    VME_AS_n_i      : in    std_logic;
    VME_RST_n_i     : in    std_logic;
    VME_WRITE_n_i   : in    std_logic;
    VME_AM_i        : in    std_logic_vector(5 downto 0);
    VME_DS_n_i      : in    std_logic_vector(1 downto 0);
    VME_GA_i        : in    std_logic_vector(5 downto 0);
    VME_BERR_o      : out   std_logic;
    VME_DTACK_n_o   : out   std_logic;
    VME_RETRY_n_o   : out   std_logic;
    VME_RETRY_OE_o  : out   std_logic;
    VME_LWORD_n_b   : inout std_logic;
    VME_ADDR_b      : inout std_logic_vector(31 downto 1);
    VME_DATA_b      : inout std_logic_vector(31 downto 0);
    VME_BBSY_n_i    : in    std_logic;
    VME_IRQ_n_o     : out   std_logic_vector(6 downto 0);
    VME_IACK_n_i    : in   std_logic;
    VME_IACKIN_n_i  : in    std_logic;
    VME_IACKOUT_n_o : out   std_logic;
    VME_DTACK_OE_o  : out   std_logic;
    VME_DATA_DIR_o  : out   std_logic;
    VME_DATA_OE_N_o : out   std_logic;
    VME_ADDR_DIR_o  : out   std_logic;
    VME_ADDR_OE_N_o : out   std_logic;

    master_o : out t_wishbone_master_out;
    master_i : in  t_wishbone_master_in;

    irq_i : in std_logic

    );

end xvme64x_core;

architecture wrapper of xvme64x_core is

  component VME64xCore_Top
    port (
      clk_i           : in    std_logic;
      VME_AS_n_i      : in    std_logic;
      VME_RST_n_i     : in    std_logic;
      VME_WRITE_n_i   : in    std_logic;
      VME_AM_i        : in    std_logic_vector(5 downto 0);
      VME_DS_n_i      : in    std_logic_vector(1 downto 0);
      VME_GA_i        : in    std_logic_vector(5 downto 0);
      VME_BERR_o      : out   std_logic;
      VME_DTACK_n_o   : out   std_logic;
      VME_RETRY_n_o   : out   std_logic;
      VME_RETRY_OE_o  : out   std_logic;
      VME_LWORD_n_b   : inout std_logic;
      VME_ADDR_b      : inout std_logic_vector(31 downto 1);
      VME_DATA_b      : inout std_logic_vector(31 downto 0);
      VME_BBSY_n_i    : in    std_logic;
      VME_IRQ_n_o     : out   std_logic_vector(6 downto 0);
      VME_IACK_n_i    : in std_logic;
      VME_IACKIN_n_i  : in    std_logic;
      VME_IACKOUT_n_o : out   std_logic;
      VME_DTACK_OE_o  : out   std_logic;
      VME_DATA_DIR_o  : out   std_logic;
      VME_DATA_OE_N_o : out   std_logic;
      VME_ADDR_DIR_o  : out   std_logic;
      VME_ADDR_OE_N_o : out   std_logic;
      RST_i           : in    std_logic;
      DAT_i           : in    std_logic_vector(63 downto 0);
      DAT_o           : out   std_logic_vector(63 downto 0);
      ADR_o           : out   std_logic_vector(63 downto 0);
      CYC_o           : out   std_logic;
      ERR_i           : in    std_logic;
      LOCK_o          : out   std_logic;
      RTY_i           : in    std_logic;
      SEL_o           : out   std_logic_vector(7 downto 0);
      STB_o           : out   std_logic;
      ACK_i           : in    std_logic;
      WE_o            : out   std_logic;
      STALL_i         : in    std_logic;
      IRQ_i           : in    std_logic);
  end component;

  signal rst                             : std_logic;
  signal dummy_adr, dummy_dat, dummy_sel : std_logic_vector(63 downto 0);
  
begin  -- wrapper

  rst <= not rst_n_i;

  U_Wrapped_VME : VME64xCore_Top
    port map (
      clk_i               => clk_i,
      VME_AS_n_i          => VME_AS_n_i,
      VME_RST_n_i         => VME_RST_n_i,
      VME_WRITE_n_i       => VME_WRITE_n_i,
      VME_AM_i            => VME_AM_i,
      VME_DS_n_i          => VME_DS_n_i,
      VME_GA_i            => VME_GA_i,
      VME_BERR_o          => VME_BERR_o,
      VME_DTACK_n_o       => VME_DTACK_n_o,
      VME_RETRY_n_o       => VME_RETRY_n_o,
      VME_RETRY_OE_o      => VME_RETRY_OE_o,
      VME_LWORD_n_b       => VME_LWORD_n_b,
      VME_ADDR_b          => VME_ADDR_b,
      VME_DATA_b          => VME_DATA_b,
      VME_BBSY_n_i        => VME_BBSY_n_i,
      VME_IRQ_n_o         => VME_IRQ_n_o,
      VME_IACK_n_i        => VME_IACK_n_i,
      VME_IACKIN_n_i      => VME_IACKIN_n_i,
      VME_IACKOUT_n_o     => VME_IACKOUT_n_o,
      VME_DTACK_OE_o      => VME_DTACK_OE_o,
      VME_DATA_DIR_o      => VME_DATA_DIR_o,
      VME_DATA_OE_N_o     => VME_DATA_OE_N_o,
      VME_ADDR_DIR_o      => VME_ADDR_DIR_o,
      VME_ADDR_OE_N_o     => VME_ADDR_OE_N_o,
      RST_i               => rst_n_i,
      DAT_i(31 downto 0)  => master_i.dat,
      DAT_i(63 downto 32) => x"00000000",
      DAT_o(31 downto 0)  => master_o.dat,
      DAT_o(63 downto 32) => dummy_dat(63 downto 32),
      ADR_o(31 downto 0)  => master_o.adr,
      ADR_o(63 downto 32) => dummy_adr(63 downto 32),
      CYC_o               => master_o.cyc,
      ERR_i               => master_i.err,
      LOCK_o              => open,
      RTY_i               => master_i.rty,
      SEL_o(3 downto 0)   => master_o.sel,
      SEL_o(7 downto 4)   => dummy_sel(7 downto 4),
      STB_o               => master_o.stb,
      ACK_i               => master_i.ack,
      WE_o                => master_o.we,
      STALL_i             => master_i.stall,
      IRQ_i               => irq_i);


end wrapper;
