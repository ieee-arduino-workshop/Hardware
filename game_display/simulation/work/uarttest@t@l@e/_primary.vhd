library verilog;
use verilog.vl_types.all;
entity uarttestTLE is
    port(
        clk50           : in     vl_logic;
        rst_n           : in     vl_logic;
        rx_in           : in     vl_logic;
        LEDS            : out    vl_logic_vector(7 downto 0);
        dataReceived    : out    vl_logic
    );
end uarttestTLE;
