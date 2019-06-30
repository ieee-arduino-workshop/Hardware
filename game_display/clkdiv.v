
module clkdiv(
	input clk50,
	input rst_n,
	output dividedclk
);

parameter DIVIDEFACTOR = 25;

reg dividedout;
reg [5:0] counter;


assign dividedclk = dividedout;

always @ (posedge clk50 or negedge rst_n)
begin
	if(~rst_n)
	begin
		dividedout<=0; 
		counter<=0;
	end
	else if (counter==DIVIDEFACTOR)
	begin
		dividedout<=~dividedout;
		counter<=0;
	end
	else
	begin
		dividedout<=dividedout;
		counter<=counter+1'd1;
	end
	
end

endmodule
