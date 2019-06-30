module uarttestTLE(
  input        clk50,
  input        rst_n,
  input        rx_in,
  output		  [39:0] packet,
  output 		dataReceived
); 


 wire [7:0] RxedData;
 wire 		rxDone;

 reg [39:0] smallMem;
 reg [3:0] rxbytescounter;
 reg datarxedtrig;
 
 assign packet = smallMem;
 assign dataReceived = datarxedtrig;
 
 uarttest uart1(
    .clk50(clk50),
    .rst_n(rst_n),
    .rx_in(rx_in),
    .RxedData(RxedData),
    .rxDone(rxDone)
);

always @ (posedge clk50 or negedge rst_n)
begin
	if(~rst_n)
	begin
		rxbytescounter<=0;
		datarxedtrig<=0;
	end
	else if(clk50==1'b1)
	begin
		if(rxDone==1'b1)
		begin
			smallMem<={smallMem[31:0],RxedData[7:0]};
			if(rxbytescounter==4)
			begin 
				datarxedtrig<=1;
				rxbytescounter<=0;
			end
			else
			begin
				datarxedtrig<=0;
				rxbytescounter<=rxbytescounter+1'b1;
			end
		end
		else
		begin
			rxbytescounter<=rxbytescounter;
			datarxedtrig<=0;
		end
	end
	
end



 endmodule
