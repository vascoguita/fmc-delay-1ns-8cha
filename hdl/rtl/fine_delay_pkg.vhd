library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fine_delay_pkg is

  constant c_fd_num_outputs : integer := 4;
  constant c_fd_refclk_freq : integer := 125000000;
  
  
  type t_fd_timestamp is record
    secs   : unsigned(31 downto 0);
    cycles : unsigned(27 downto 0);
    fine   : unsigned(11 downto 0);
  end record;

  type t_fd_timestamp_array is array (0 to c_fd_num_outputs-1) of t_fd_timestamp;

end fine_delay_pkg;
