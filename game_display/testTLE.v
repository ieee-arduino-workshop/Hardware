module testTLE(
  input        clk50,
  input        rst_n,
  input        rx_in,
  output	[7:0] LEDS
); 


wire [39:0] dataconn ;
wire dataReceived;

wire  [7:0] elementID;
wire  [15:0] x_pos;
wire  [15:0] y_pos;

reg [7:0]ledsreg;

assign LEDS[7:0] = ledsreg[7:0];
assign elementID [7:0] = dataconn[39:32];
assign x_pos [15:0] = dataconn[31:16];
assign y_pos [15:0] = dataconn[15:0];


uarttestTLE uart(
         .clk50(clk50),
         .rst_n(rst_n),
         .rx_in(rx_in),
			.packet(dataconn),
			.dataReceived(dataReceived)
); 


always @ (posedge clk50 or negedge rst_n)
begin
	if(~rst_n)
	begin
		ledsreg[7:0]<=8'd0;
	end
	else if (clk50==1'b1)
	begin
		if(dataReceived==1'b1) //data received triggered
		begin
			if(elementID==1)
			begin
				if(x_pos==16'h2031)
				begin
					ledsreg[7:0] <= 8'b11011101;
				end
				else
				begin
					ledsreg[7:0] <= 8'b11100111;
				end
			end
			else
			begin
				ledsreg[7:0] <= 8'b11100111;
			end
		end
	end

end

endmodule
