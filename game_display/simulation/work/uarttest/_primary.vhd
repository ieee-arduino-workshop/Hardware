library verilog;
use verilog.vl_types.all;
entity uarttest is
    generic(
        UART_4800       : integer := 10416;
        UART_9600       : integer := 5208;
        UART_19200      : integer := 2604;
        UART_57600      : integer := 108;
        UART_115200     : integer := 100;
        UART_115200_half: integer := 50;
        IDLE_STATE      : vl_logic_vector(0 to 2) := (Hi0, Hi0, Hi0);
        STARTBIT_STATE  : vl_logic_vector(0 to 2) := (Hi0, Hi0, Hi1);
        DATABITS_STATE  : vl_logic_vector(0 to 2) := (Hi0, Hi1, Hi0);
        STOPBITS_STATE  : vl_logic_vector(0 to 2) := (Hi0, Hi1, Hi1);
        FINISHEDRX_STATE: vl_logic_vector(0 to 2) := (Hi1, Hi0, Hi0)
    );
    port(
        clk50           : in     vl_logic;
        rst_n           : in     vl_logic;
        rx_in           : in     vl_logic;
        RxedData        : out    vl_logic_vector(7 downto 0);
        rxDone          : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of UART_4800 : constant is 1;
    attribute mti_svvh_generic_type of UART_9600 : constant is 1;
    attribute mti_svvh_generic_type of UART_19200 : constant is 1;
    attribute mti_svvh_generic_type of UART_57600 : constant is 1;
    attribute mti_svvh_generic_type of UART_115200 : constant is 1;
    attribute mti_svvh_generic_type of UART_115200_half : constant is 1;
    attribute mti_svvh_generic_type of IDLE_STATE : constant is 1;
    attribute mti_svvh_generic_type of STARTBIT_STATE : constant is 1;
    attribute mti_svvh_generic_type of DATABITS_STATE : constant is 1;
    attribute mti_svvh_generic_type of STOPBITS_STATE : constant is 1;
    attribute mti_svvh_generic_type of FINISHEDRX_STATE : constant is 1;
end uarttest;
