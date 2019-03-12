`timescale 1us/1ns
module game_display_tb();


reg clk50;
reg rst_n;
reg uart_rx;

initial
begin
	clk50 = 1;
	rst_n = 1;
	#10 rst_n = 0;
	#10 rst_n = 1;
end

always # 0.01 clk50 = ~clk50;

initial
begin
		    uart_rx = 1;
	#50    uart_rx = 0;
	#17.36 uart_rx = 1;
	#17.36 uart_rx = 0;
	#17.36 uart_rx = 1;
	#17.36 uart_rx = 0;
	#17.36 uart_rx = 1;
	#17.36 uart_rx = 0;
	#17.36 uart_rx = 1;
	#17.36 uart_rx = 0;
	#17.36 uart_rx = 0;
   #17.36 uart_rx = 1;	
	
	#50 $finish;
end

game_display u_game_display
(
        .CLOCK_50(clk50),
        .uart_rx_i(uart_rx),
        .rst_n(rst_n),
);
