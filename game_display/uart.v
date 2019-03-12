`timescale 1us/1ns
module uart(
  input        clk50,
  input        rst_n,
  input  [3:0] uart_baud,
  input        rx_in,
  output [7:0] rx_data,
  output       rx_empty,
  input  [7:0] tx_data,
  output reg   tx_out,  
  output [7:0] test
);

  // (1 / Baud Rate )/ (CLK_50_Period)
  parameter UART_4800  = 10416;    // Option 3 multiply by 12
  parameter UART_9600  =  5208;    // Option 2 Multiply by 6
  parameter UART_19200 =  2604;    // Option 1 Multiply by 3
  parameter UART_57600 =   108;    // Option 0 Multiply by 1
  parameter UART_115200 =  54; 
  
  reg [15:0] clk50_cntr;
  reg        rx_d1;
  reg        rx_d2;
  reg        rx_d3;
  reg [15:0] sample_reg;
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
  reg        tx_on;
    
  
  wire start_bit,stop_bit;
  //====================================================
  // clocks and sampling edges for UART communication  
  //====================================================
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
    begin
      clk50_cntr <= 16'd0;
      sample_edge <= 1'd0;
    end
    else if (clk50_cntr == (UART_115200-1))
    begin
      clk50_cntr <=  16'd0;
      sample_edge <= 1'd1;
    end
    else
    begin
      clk50_cntr <= clk50_cntr + 1'd1;
      sample_edge <= 1'd0;
    end
  end

  always @(posedge clk50 or negedge rst_n)
    begin
      if(~rst_n)
        sample_cnt <= 3'd0;
      else if (sample_edge)
        sample_cnt <= sample_cnt + 1'd1;
      else
        sample_cnt <= sample_cnt;
    end
  
  //====================================================
  // UART RX
  //====================================================
  // Synchronizing the incoming signal to the 50M clock
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
    begin
      rx_d1 <= 1'd0;
      rx_d2 <= 1'd0;
      rx_d3 <= 1'd0;
    end
    else
    begin
      rx_d1 <= rx_in;
      rx_d2 <= rx_d1;
      rx_d3 <= rx_d2;
    end
  end
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if (~rst_n)
    begin
      sample_reg[15:0] <= 8'b0;
    end
    else if (sample_edge)
    begin
      sample_reg[15:0] <= {sample_reg[14:0],rx_d3};    
    end
  end
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      rx_on <= 1'd0;
    else if((bit_cnt == 0) & (sample_reg[11:4] == 8'b11110000))
      rx_on <= 1'd1;
    else if ((bit_cnt == 'd11) & (sample_reg[11:4] == 8'b00001111))
      rx_on <= 1'd0;
    else
      rx_on <= rx_on;
  end
    
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      rx_on_d1 <= 1'd0;
    else
      rx_on_d1 <= rx_on;
  end
  
  assign rx_on_edge = rx_on  & ~rx_on_d1;
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if (~rst_n)
      sample_cnt_rx <= 3'd0;
    else if(rx_on_edge)
      sample_cnt_rx <= sample_cnt;
    else
      sample_cnt_rx <= sample_cnt_rx;
  end  
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      bit_cnt <= 4'd0;
    else if (~rx_on)
      bit_cnt = 4'd0;
    else if (sample_edge & rx_on & (sample_cnt == sample_cnt_rx) && (bit_cnt <= 10))
      bit_cnt <= bit_cnt + 1'd1;
    else
      bit_cnt <= bit_cnt;
  end
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      rx_reg <= 11'd0;
    else if((bit_cnt <= 10) & (sample_cnt == sample_cnt_rx) & sample_edge & rx_on)
      rx_reg[10:0] = {sample_reg[3],rx_reg[10:1]};
    else
      rx_reg[10:0] = rx_reg[10:0];
  end

  assign rx_data[7:0] = ((bit_cnt =='d10) & (rx_reg[10] == 1)) ? rx_reg[8:1] : rx_data[7:0];

  //====================================================
  // UART TX
  //====================================================

  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)	
      tx_data_d1 <= 8'd0;
    else
      tx_data_d1 <= tx_data;
  end
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      tx_data_written <= 1'd0;
    else if (tx_data_d1 != tx_data)
      tx_data_written <= 1'd1;
    else
      tx_data_written <= 1'd0;
  end
  
  assign tx_data_parity = ^tx_data[7:0];
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      tx_data_reg[10:0] <= 11'd0;
    else if (tx_data_written)
      tx_data_reg[10:0] <= {1'b1,tx_data_parity,tx_data[7:0],1'd0};
    else
      tx_data_reg <= tx_data_reg;
  end
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      tx_on <= 1'b0;
    else if (tx_data_written)
      tx_on <= 1'b1;
    else if (bit_cnt_tx == 'd11)
      tx_on <= 1'b0;
  end
     
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      sample_cnt_tx <= 3'd0;
    else if(tx_data_written)
      sample_cnt_tx <= sample_cnt;
    else
      sample_cnt_tx <= sample_cnt_tx;
  end
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      tx_out <= 1'b0;
    else if (tx_on & sample_edge & (sample_cnt == sample_cnt_tx))
      tx_out <= tx_data_reg[bit_cnt_tx];
    else
      tx_out <= tx_out;
  end
  
  always @(posedge clk50 or negedge rst_n)
  begin
    if(~rst_n)
      bit_cnt_tx <= 4'd0;
    else if (~tx_on)
      bit_cnt_tx <= 4'd0;
    else if (tx_on & sample_edge & (sample_cnt == sample_cnt_tx))
      bit_cnt_tx <= bit_cnt_tx + 1'd1;
  end
             
endmodule

