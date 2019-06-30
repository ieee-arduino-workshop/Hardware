`timescale 1us/1ns
module uarttest(
  input        clk50,
  input        rst_n,
  input        rx_in,
  output [7:0] RxedData,
  output 		rxDone
);


  
  
  //=====================================================
 
 /* reg        rx_d1;
  reg        rx_d2;
  reg        rx_d3;
  reg [15:0] sample_reg; //16 bit sample register
  reg [10:0] rx_reg;
  reg [2:0]  sample_cnt;
  reg [2:0]  sample_cnt_rx;
  reg [2:0]  sample_cnt_tx;
  reg [3:0]  bit_cnt;
  reg        sample_edge;
  reg        rx_on;
  reg        rx_on_d1;
  reg        rx_on_d2;
  wire       rx_on_edge;  
  reg [7:0]  tx_data_d1;
  reg [10:0] tx_data_reg;
  reg        tx_data_written;
  wire       tx_data_parity;
  reg [3:0]  bit_cnt_tx;
  reg        tx_on;*/
  //=====================================================
	 
	  // (1 / Baud Rate )/ (CLK_50_Period)
  
  //parameters below specifies the 
  parameter UART_4800  = 10416;    // Option 3 multiply by 12
  parameter UART_9600  =  5208;    // Option 2 Multiply by 6
  parameter UART_19200 =  2604;    // Option 1 Multiply by 3
  parameter UART_57600 =   108;    // Option 0 Multiply by 1
  parameter UART_115200 =  434; 
  parameter UART_115200_half = 217;
  
  //for simulation
  //parameter UART_115200 =  100; 
  //parameter UART_115200_half =  50; 
  
  //define the states
  parameter IDLE_STATE 		= 3'b000;
  parameter STARTBIT_STATE = 3'b001;
  parameter DATABITS_STATE = 3'b010;
  parameter STOPBITS_STATE = 3'b011;
  parameter FINISHEDRX_STATE = 3'b100;
	
	 
  reg           Rx_Data_Reg = 1'b1;
  reg           Rx_Data   = 1'b1;
  reg [2:0] 	 UART_Rx_State;
  reg [15:0] 	 clk50_cntr; //16 bit counter value
  reg [3:0] 	 bitcount_rx; //to count number of bits received
  reg [7:0]		 rx_data;
  reg sampletrig;
  reg rxfinished;
  //reg [2:0]		 stopbitscount; //to count number of stop bits
  
  
  assign RxedData = rx_data;
  assign rxDone	= rxfinished;
  
  
  //for double-register uart signal
  always @(posedge clk50 or negedge rst_n)
  begin
		if(~rst_n)
		begin
			Rx_Data_Reg<=1;
			Rx_Data<=1;
		end
		else
		begin
			Rx_Data_Reg<=rx_in;
			Rx_Data<=Rx_Data_Reg;
		end
  end  
  
  
 //state machine for uart
  always @(posedge clk50 or negedge rst_n)
  begin 
	if(~rst_n)
	begin
		UART_Rx_State<=IDLE_STATE;
		rxfinished<=0;
	end 
	else
	begin
		case (UART_Rx_State)
			IDLE_STATE://receiver is idle in this state
				begin
					if(Rx_Data==1'b0)   
						begin
							//start bit detected
							clk50_cntr<=0;
							UART_Rx_State<=STARTBIT_STATE;
							sampletrig<=0;
							rxfinished<=0;
						end
					else
						begin
							UART_Rx_State<=IDLE_STATE;
							rxfinished<=0;
						end
				end
			STARTBIT_STATE:
				begin
					if(clk50_cntr == UART_115200_half)
						begin
							//check if the start bit is still low
							if(Rx_Data==1'b1) //if the start bit is not 0
							begin
								clk50_cntr<=0;
								UART_Rx_State<=IDLE_STATE;
								sampletrig<=0;
							end
							else
							begin
								UART_Rx_State<=STARTBIT_STATE;
								clk50_cntr <= clk50_cntr+1'b1;
								sampletrig<=1;
							end
							
						end
					else if(clk50_cntr == UART_115200)
						begin
							bitcount_rx <=0; 
							clk50_cntr <=0;
							UART_Rx_State<=DATABITS_STATE;
							sampletrig<=0;
						end
					else
						begin
							UART_Rx_State<=STARTBIT_STATE;
							clk50_cntr <= clk50_cntr+1'b1;
							sampletrig<=0;
						end
					
				end
			DATABITS_STATE:
				begin
					if(clk50_cntr == UART_115200_half)
						begin
							UART_Rx_State <= DATABITS_STATE;
							rx_data[bitcount_rx] <= Rx_Data;
							clk50_cntr <= clk50_cntr+1'b1;
							sampletrig<=1;
						end
					else if(clk50_cntr == UART_115200)
						begin
							if(bitcount_rx==7)
							begin
								clk50_cntr <=0;
								UART_Rx_State<=STOPBITS_STATE;
							end
							else
							begin
								bitcount_rx = bitcount_rx+1;
								UART_Rx_State<=DATABITS_STATE;
								clk50_cntr <=0;
								sampletrig<=0;
							end
						end
					else
						begin
							UART_Rx_State<=DATABITS_STATE;
							clk50_cntr <= clk50_cntr+1'b1;
							sampletrig<=0;
						end
				end
			STOPBITS_STATE:
				begin
						if(clk50_cntr == UART_115200_half)
						begin
							//check if the stop bit is  low
							if(Rx_Data==1'b0) //if the stop bit is not 1
							begin
								clk50_cntr<=0;
								UART_Rx_State<=IDLE_STATE;
								sampletrig<=0;
							end
							else
							begin
								UART_Rx_State<=STOPBITS_STATE;
								clk50_cntr <= clk50_cntr+1'b1;
								sampletrig<=1;
							end
							
						end
					else if(clk50_cntr == UART_115200)
						begin
							clk50_cntr <=0;
							UART_Rx_State<=FINISHEDRX_STATE;
							sampletrig<=0;
							rxfinished<=1;
						end
					else
						begin
							UART_Rx_State<=STOPBITS_STATE;
							clk50_cntr <= clk50_cntr+1'b1;
							sampletrig<=0;
						end				
				end
			FINISHEDRX_STATE:
				begin
					//if(clk50_cntr==2)
					//begin
						rxfinished<=0;
						UART_Rx_State<=IDLE_STATE;
						clk50_cntr<=0;
					//end
					//else
					/*begin
						rxfinished<=1;
						UART_Rx_State<=FINISHEDRX_STATE;
						clk50_cntr<=clk50_cntr+1'b1;
					end*/
				end
				
		default:
			UART_Rx_State<=IDLE_STATE;
		endcase
	end
  
  end  
  
  endmodule
  