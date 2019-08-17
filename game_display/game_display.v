// Code your design here
`timescale 1us/1ns

module game_display
    (
        CLOCK_50,
        VGA_RED,
        VGA_GREEN,
        VGA_BLUE,
        VGA_HS,
        VGA_VS,
        LED,
        //uart_baud,
        uart_rx_i,
		  uart_rx_dump,
        uart_tx_o,
        rst_n/*,
        xplus,
        xminus,
        yplus,
        yminus*/

    );
    input CLOCK_50;
    //input [3:0] uart_baud;
    input uart_rx_i;
    input rst_n;
	 output uart_rx_dump;
//    input xplus;
//    input xminus;
//    input yplus;
//    input yminus;
    output VGA_RED;
    output VGA_GREEN;
    output VGA_BLUE;
    output VGA_HS;
    output VGA_VS;
    output [7:0] LED;
    output  uart_tx_o;

//============================================================================== 
    /* Internal registers for horizontal signal timing */
    reg [10:0] hor_reg;
    reg hor_sync;
    wire hor_max = (hor_reg == 1039);
    /* Internal registers for vertical signal timing */
    reg [9:0] ver_reg;
    reg ver_sync;
    wire ver_max = (ver_reg == 665);

   // All Dimensions based on a 800 x 600 display.
   localparam _1_YARD    = 12;   // Number of pixels per yard. To be used in Arena Scaling
   localparam SCR_EDGE_L = 20;
   localparam SCR_EDGE_R = 780;
   localparam SCR_EDGE_T = 40;
   localparam SCR_EDGE_B = 560;
   localparam SCR_CX     = (SCR_EDGE_R - SCR_EDGE_L)/2 + SCR_EDGE_L;
   localparam SCR_CY     = (SCR_EDGE_B - SCR_EDGE_T)/2 + SCR_EDGE_T;
   
   // All Dimensions of the soccer field 
   localparam ARN_HEIGHT = 40 * _1_YARD;    // Total height is 40 yards
   localparam ARN_WIDTH  = 60 * _1_YARD;    // Total width is 60 yards
   localparam ARN_CX     = SCR_CX;          // X coord centre of Arena
   localparam ARN_CY     = SCR_CY;          // Y coord centre of Arena
   localparam ARN_C2KZL  = 25 * _1_YARD;    // Arena centre to Keeper Zone line
	localparam ARN_GOALBNDRY_LEN = 10 * _1_YARD;  //goal boundry length (x axis)
	localparam ARN_GOALBNDRY_HEIGHT = 30 * _1_YARD; //goal boundry height (y axis)
	localparam ARN_GOAL_LEN			  = 1 * _1_YARD; //goal length (x axis)
	localparam ARN_GOAL_HEIGHT		  = 8 * _1_YARD; //goal height (y axis)
   
   localparam ARN_BNDRY_TOP_Y     = ARN_CY - (ARN_HEIGHT/2);  // Top edge of the arena
   localparam ARN_BNDRY_TB_LHS_X  = ARN_CX - (ARN_C2KZL);     // LHS of the central rectangle  
   localparam ARN_BNDRY_TB_RHS_X  = ARN_CX + (ARN_C2KZL);     // RHS of the central rectangle
   localparam ARN_BNDRY_BOT_Y     = ARN_CY + (ARN_HEIGHT/2);  // Bottom edge of the arena
   localparam ARN_KZ_LHS_X        = ARN_CX - (ARN_C2KZL);     // X coord of the keeper zone line LHS 
   localparam ARN_KZ_RHS_X        = ARN_CX + (ARN_C2KZL);     // X coord of the keeper zone line RHS 
	
	
	
	localparam ARN_MIDLINE_X	 		 = ARN_CX;
	localparam ARN_GOALBNDRY_TB_LHS_X = ARN_CX - ARN_C2KZL+ARN_GOALBNDRY_LEN;
	localparam ARN_GOALBNDRY_TB_RHS_X = ARN_CX + ARN_C2KZL-ARN_GOALBNDRY_LEN;
	localparam ARN_GOALBNDRY_TOP_Y	 = ARN_CY - (ARN_GOALBNDRY_HEIGHT/2);
	localparam ARN_GOALBNDRY_BOT_Y	 =	ARN_CY + (ARN_GOALBNDRY_HEIGHT/2);
	localparam ARN_GOAL_TOP_MARGIN_Y			 = ARN_CY - (ARN_GOAL_HEIGHT/2);
	localparam ARN_GOAL_BOT_MARGIN_Y			 = ARN_CY + (ARN_GOAL_HEIGHT/2);
	localparam ARN_GOAL_TB_LHS_MARGIN_X = ARN_CX - ARN_C2KZL+ARN_GOAL_LEN;
	localparam ARN_GOAL_TB_RHS_MARGIN_X = ARN_CX + ARN_C2KZL-ARN_GOAL_LEN;

   
   // Arena boundary
   reg disp_arn_bndry_top;
   reg disp_arn_bndry_bot;
   reg disp_arn_bndry_lhs1;
   reg disp_arn_bndry_lhs2; 
   reg disp_arn_bndry_rhs1;
   reg disp_arn_bndry_rhs2;
   reg disp_arn_kz_lhs;
   reg disp_arn_kz_rhs;
	
	reg disp_arn_midline;
	reg disp_arn_goalbndry_lhs;
	reg disp_arn_goalbndry_rhs;
	reg disp_arn_goalbndry_lhs_top;
	reg disp_arn_goalbndry_lhs_bot;
	reg disp_arn_goalbndry_rhs_top;
	reg disp_arn_goalbndry_rhs_bot;
	
	reg disp_arn_goal_lhs;
	reg disp_arn_goal_rhs;
	reg disp_arn_goal_lhs_top;
	reg disp_arn_goal_lhs_bot;
	reg disp_arn_goal_rhs_top;
	reg disp_arn_goal_rhs_bot;
	
	
   reg disp_player[9:0]; //display of 10 players
	reg disp_ball;


   reg [9:0]player_x[9:0][15:0];
   reg [9:0]player_y[9:0][15:0];
	
	reg [9:0]ball_x[15:0];
	reg [9:0]ball_y[15:0];
	
	
	//------------------uart comms--------------
	wire [39:0] dataconn ;
	wire dataReceived;

	wire  [7:0] elementID;
	wire  [15:0] x_pos;
	wire  [15:0] y_pos;

	reg [7:0]ledsreg;

	assign LED[7:0] = ledsreg[7:0];
	assign elementID [7:0] = dataconn[39:32];
	assign x_pos [15:0] = dataconn[31:16];
	assign y_pos [15:0] = dataconn[15:0];

	assign uart_rx_dump = uart_rx_i;

uarttestTLE uart(
         .clk50(CLOCK_50),
         .rst_n(rst_n),
         .rx_in(uart_rx_i),
			.packet(dataconn),
			.dataReceived(dataReceived)
); 

	
	
	//end uart comms
	
	
   
    
   // Code
   
  // RASTER ----------------------------
  /* Running through line */
  
 
   always @ (posedge CLOCK_50) begin
    if (hor_max) begin
        hor_reg <= 0;
        /* Running through frame */
        if (ver_max)
            ver_reg <= 0;
        else
        ver_reg <= ver_reg + 1;
    end else
        hor_reg <= hor_reg + 1;
   end
   
   always @ (posedge CLOCK_50) begin
    /* Generating the horizontal sync signal */
    if (hor_reg == 856)
        hor_sync <= 1;
    else if (hor_reg == 976)
        hor_sync <= 0;
    /* Generating the vertical sync signal */
    if (ver_reg == 637)
        ver_sync <= 1;
    else if (ver_reg == 643)
        ver_sync <= 0;
   end
  
   assign VGA_HS = ~hor_sync;
   assign VGA_VS = ~ver_sync;
  // RASTER ends -------------------------

  // ARENA display -----------------------
    always @(posedge CLOCK_50)
    begin
      disp_arn_bndry_top <= (ver_reg == ARN_BNDRY_TOP_Y) && (hor_reg >= ARN_BNDRY_TB_LHS_X) && (hor_reg <= ARN_BNDRY_TB_RHS_X);
      disp_arn_bndry_bot <= (ver_reg == ARN_BNDRY_BOT_Y) && (hor_reg >= ARN_BNDRY_TB_LHS_X) && (hor_reg <= ARN_BNDRY_TB_RHS_X);
		disp_arn_goalbndry_lhs_top <= (ver_reg == ARN_GOALBNDRY_TOP_Y) && (hor_reg >= ARN_KZ_LHS_X) && (hor_reg <= ARN_GOALBNDRY_TB_LHS_X);
		disp_arn_goalbndry_lhs_bot <= (ver_reg == ARN_GOALBNDRY_BOT_Y) && (hor_reg >= ARN_KZ_LHS_X) && (hor_reg <= ARN_GOALBNDRY_TB_LHS_X);
		disp_arn_goalbndry_rhs_top <= (ver_reg == ARN_GOALBNDRY_TOP_Y) && (hor_reg >= ARN_GOALBNDRY_TB_RHS_X) && (hor_reg <= ARN_KZ_RHS_X);
		disp_arn_goalbndry_rhs_bot <= (ver_reg == ARN_GOALBNDRY_BOT_Y) && (hor_reg >= ARN_GOALBNDRY_TB_RHS_X) && (hor_reg <= ARN_KZ_RHS_X);
    end
    
	 
    
   /* always @(posedge CLOCK_50)
    begin
      //disp_arn_bndry_lhs1 <= ((hor_reg + ver_reg ) == (ARN_BNDRY_LHS_CX + ARN_BNDRY_TOP_Y))  & (hor_reg >= ARN_BNDRY_LHS_X) & (ver_reg >= ARN_BNDRY_TOP_Y);
     // disp_arn_bndry_lhs2 <= ((ver_reg - hor_reg ) == (ARN_BNDRY_BOT_Y  - ARN_BNDRY_LHS_CX)) & (hor_reg >= ARN_BNDRY_LHS_X) & (ver_reg <= ARN_BNDRY_BOT_Y);
     // disp_arn_bndry_rhs1 <= ((hor_reg + ver_reg ) == (ARN_BNDRY_RHS_CX + ARN_BNDRY_BOT_Y))  & (hor_reg <= ARN_BNDRY_RHS_X) & (ver_reg <= ARN_BNDRY_BOT_Y);
     // disp_arn_bndry_rhs2 <= ((hor_reg - ver_reg ) == (ARN_BNDRY_RHS_CX - ARN_BNDRY_TOP_Y))  & (hor_reg <= ARN_BNDRY_RHS_X) & (ver_reg >= ARN_BNDRY_TOP_Y);
    end*/

    always @ (posedge CLOCK_50)
    begin
      disp_arn_kz_lhs    <= (hor_reg ==  ARN_KZ_LHS_X) && (ver_reg >= ARN_BNDRY_TOP_Y) && (ver_reg <= ARN_BNDRY_BOT_Y); 
      disp_arn_kz_rhs    <= (hor_reg ==  ARN_KZ_RHS_X) && (ver_reg >= ARN_BNDRY_TOP_Y) && (ver_reg <= ARN_BNDRY_BOT_Y); 
		disp_arn_midline   <= (hor_reg ==  ARN_MIDLINE_X) && (ver_reg >= ARN_BNDRY_TOP_Y) && (ver_reg <= ARN_BNDRY_BOT_Y);
		disp_arn_goalbndry_lhs <= (hor_reg ==  ARN_GOALBNDRY_TB_LHS_X) && (ver_reg >= ARN_GOALBNDRY_TOP_Y) && (ver_reg <= ARN_GOALBNDRY_BOT_Y);
		disp_arn_goalbndry_rhs <= (hor_reg ==  ARN_GOALBNDRY_TB_RHS_X) && (ver_reg >= ARN_GOALBNDRY_TOP_Y) && (ver_reg <= ARN_GOALBNDRY_BOT_Y);
		disp_arn_goal_lhs  <= ((hor_reg <=  ARN_GOAL_TB_LHS_MARGIN_X) &&(hor_reg >= ARN_KZ_LHS_X ) ) && (ver_reg >= ARN_GOAL_TOP_MARGIN_Y) && (ver_reg <= ARN_GOAL_BOT_MARGIN_Y);
		disp_arn_goal_rhs  <= ((hor_reg >=  ARN_GOAL_TB_RHS_MARGIN_X) &&(hor_reg <= ARN_KZ_RHS_X ) ) && (ver_reg >= ARN_GOAL_TOP_MARGIN_Y) && (ver_reg <= ARN_GOAL_BOT_MARGIN_Y);

    end

/*    always @ (posedge CLOCK_50)
    begin
//     // disp_arn_gh_lhs <= (hor_reg ==  ARN_GH_LHS_X) && (((ver_reg >= (ARN_GH_LR_YT - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YT + (ARN_GH_SZ/2))))
//                                                       |((ver_reg >= (ARN_GH_LR_YM - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YM + (ARN_GH_SZ/2))))
//                                                       |((ver_reg >= (ARN_GH_LR_YB - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YB + (ARN_GH_SZ/2)))));
//      //disp_arn_gh_rhs <= (hor_reg ==  ARN_GH_RHS_X) && (((ver_reg >= (ARN_GH_LR_YT - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YT + (ARN_GH_SZ/2))))
//                                                       |((ver_reg >= (ARN_GH_LR_YM - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YM + (ARN_GH_SZ/2))))
//                                                       |((ver_reg >= (ARN_GH_LR_YB - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YB + (ARN_GH_SZ/2)))));
  end
  */
    
    
    assign VGA_RED =    disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2 
                       | disp_arn_kz_lhs | disp_arn_kz_rhs|disp_arn_midline|disp_arn_goalbndry_lhs|disp_arn_goalbndry_rhs|disp_arn_goalbndry_lhs_top
							  |disp_arn_goalbndry_lhs_bot|disp_arn_goalbndry_rhs_top|disp_arn_goalbndry_rhs_bot |disp_player[1]|disp_player[3]|disp_player[5]|disp_player[7]|disp_player[9]|disp_ball;
							  
							  
    assign VGA_GREEN =  disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2
                       | disp_arn_kz_lhs | disp_arn_kz_rhs | disp_arn_midline|disp_arn_goalbndry_lhs|disp_arn_goalbndry_rhs|disp_arn_goalbndry_lhs_top
							  |disp_arn_goalbndry_lhs_bot|disp_arn_goalbndry_rhs_top|disp_arn_goalbndry_rhs_bot |disp_arn_goal_lhs |disp_arn_goal_rhs |disp_player[0]|disp_player[2]|disp_player[4]|disp_player[6]|disp_player[8]|disp_ball ;
							  
							  
    assign VGA_BLUE =   disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2
                       | disp_arn_kz_lhs | disp_arn_kz_rhs |disp_arn_midline|disp_arn_goalbndry_lhs|disp_arn_goalbndry_rhs|disp_arn_goalbndry_lhs_top
							  |disp_arn_goalbndry_lhs_bot|disp_arn_goalbndry_rhs_top|disp_arn_goalbndry_rhs_bot|disp_arn_goal_lhs |disp_arn_goal_rhs |disp_player[1]|disp_player[3]|disp_player[5]|disp_player[7]|disp_player[9]|disp_ball;
    
  // ARENA display ends ------------------
  //
  // Player display ----------------------
  
//  reg [15:0] clk50_cntr;
//  always @ (posedge CLOCK_50 or negedge rst_n)
//  begin
//    if (~rst_n)
//      clk50_cntr <= 16'd0;
//    else
//      clk50_cntr <= #0.5 clk50_cntr + 1'd1;
//  end
//
//  //x aixs locations of the players and ball
//  always @ (posedge CLOCK_50 or negedge rst_n)
//  begin
//    if (~rst_n)
//     begin
//		player_x[0][0] <=  ARN_CX+2*_1_YARD;
//		player_x[0][1] <=  ARN_CX+2*_1_YARD+ 2'd1;
//		player_x[0][2] <=  ARN_CX+2*_1_YARD;
//		player_x[0][3] <=  ARN_CX+2*_1_YARD+2'd1;
//		
//		
//		player_x[1][0] <= #0.5 ARN_CX+4'd5;
//		player_x[1][1] <= #0.5 ARN_CX+4'd6;
//		player_x[1][2] <= #0.5 ARN_CX+4'd5;
//		player_x[1][3] <= #0.5 ARN_CX+4'd6;
//		
//		
//		
//		end
//    else if ((xplus) & (clk50_cntr == 16'd1))
//      player_x[0][0] <= #0.5 player_x[0][0] + 1'd1;
//    else if ((xminus) & (clk50_cntr == 16'd1))
//      player_x[0][0] <= #0.5 player_x[0][0] - 1'd1;
//  end
//
//  //y-axis locations of the players and ball
//  always @ (posedge CLOCK_50 or negedge rst_n)
//  begin
//    if (~rst_n)
//      begin
//		player_y[0][0] <= #0.5 ARN_CY;
//		player_y[0][1] <= #0.5 ARN_CY;
//		player_y[0][2] <= #0.5 ARN_CY+2'd1;
//		player_y[0][3] <= #0.5 ARN_CY+2'd1;
//		
//	   player_y[1][0] <= #0.5 ARN_CY;
//		player_y[1][1] <= #0.5 ARN_CY;
//		player_y[1][2] <= #0.5 ARN_CY+2'd1;
//		player_y[1][3] <= #0.5 ARN_CY+2'd1;
//		
//		
//		end
//    else if ((yplus) & (clk50_cntr == 16'd1))
//      player_y[0][0] <= #0.5 player_y[0][0] + 1'd1;
//		
//    else if ((yminus) & (clk50_cntr == 16'd1))
//      player_y[0][0] <= #0.5 player_y[0][0] - 1'd1;
//  end
//    
//
//	//display the player
//
//	
//
//  always @ (posedge CLOCK_50)
//  begin
//    disp_player[0] = ((hor_reg == player_x[0][0]) & (ver_reg == player_y[0][0]))|
//						((hor_reg == player_x[0][1]) & (ver_reg == player_y[0][1]))|
//						((hor_reg == player_x[0][2]) & (ver_reg == player_y[0][2]))|
//						((hor_reg == player_x[0][3]) & (ver_reg == player_y[0][3]));
//  end
//  
   
    
  // Player display ends -----------------

//  wire [7:0] uart_rx_data;
//  wire [7:0] uart_tx_data;
//  
//  uart u_uart (
//    .clk50(CLOCK_50),
//    .rst_n(rst_n),
//    .uart_baud(uart_baud),
//    .rx_in(uart_rx_i),
//    .rx_data(uart_rx_data),
//    .tx_data(uart_tx_data),
//    .tx_out(uart_tx_o),
//    .test(LED[7:0])
//  );
  
  //assign uart_tx_data = uart_rx_data;

  
 //---players and ball display---
  
generate
	genvar i,j;
	for (i=0;i<=9;i=i+1)
	begin : PLAYERS
	
	for (j=0;j<=0;j=j+1)
	begin : PIXELS
	
		always @ (posedge CLOCK_50 or negedge rst_n)
			begin
				if (~rst_n)
					begin	
					
						//x pixels
						//row 1
						player_x[i][j]   <=  ARN_CX+2*_1_YARD+(8*i);
						player_x[i][j+1] <=  ARN_CX+2*_1_YARD+1+(8*i);
						player_x[i][j+2] <=  ARN_CX+2*_1_YARD+2+(8*i);
						player_x[i][j+3] <=  ARN_CX+2*_1_YARD+3+(8*i);
						
						//row 2
						player_x[i][j+4]   <=  ARN_CX+2*_1_YARD+(8*i);
						player_x[i][j+5] <=  ARN_CX+2*_1_YARD+1+(8*i);
						player_x[i][j+6] <=  ARN_CX+2*_1_YARD+2+(8*i);
						player_x[i][j+7] <=  ARN_CX+2*_1_YARD+3+(8*i);

						//row 3
						player_x[i][j+8]   <=  ARN_CX+2*_1_YARD+(8*i);
						player_x[i][j+9] <=  ARN_CX+2*_1_YARD+1+(8*i);
						player_x[i][j+10] <=  ARN_CX+2*_1_YARD+2+(8*i);
						player_x[i][j+11] <=  ARN_CX+2*_1_YARD+3+(8*i);
						
						//row 4
						player_x[i][j+12]   <=  ARN_CX+2*_1_YARD+(8*i);
						player_x[i][j+13] <=  ARN_CX+2*_1_YARD+1+(8*i);
						player_x[i][j+14] <=  ARN_CX+2*_1_YARD+2+(8*i);
						player_x[i][j+15] <=  ARN_CX+2*_1_YARD+3+(8*i);					
						//end of x pixels
						
						
						
						//y pixels
						//row 1
						player_y[i][j]   <= #0.5 ARN_CY-2;
						player_y[i][j+1] <= #0.5 ARN_CY-2;
						player_y[i][j+2] <= #0.5 ARN_CY-2;
						player_y[i][j+3] <= #0.5 ARN_CY-2;
						
						//row 2
						player_y[i][j+4]   <= #0.5 ARN_CY-1;
						player_y[i][j+5] <= #0.5 ARN_CY-1;
						player_y[i][j+6] <= #0.5 ARN_CY-1;
						player_y[i][j+7] <= #0.5 ARN_CY-1;
						
						//row 3
						player_y[i][j+8]   <= #0.5  ARN_CY;
						player_y[i][j+9] <= #0.5  ARN_CY;
						player_y[i][j+10] <= #0.5  ARN_CY;
						player_y[i][j+11] <= #0.5  ARN_CY;
						
						//row 4
						player_y[i][j+12]   <= #0.5 ARN_CY+1;
						player_y[i][j+13] <= #0.5 ARN_CY+1;
						player_y[i][j+14] <= #0.5 ARN_CY+1;
						player_y[i][j+15] <= #0.5 ARN_CY+1;
						//end of y pixels
						
					end
					else if(CLOCK_50==1'b1)
					begin
						if(dataReceived == 1) //the ball is addresses
						begin
							if((elementID>0) && (elementID<11))
							begin
								if(i==(elementID-1))
								begin
									//x pixels
									//row 1
									player_x[i][0]   <= x_pos-2 ;
									player_x[i][1] <=  x_pos-1;
									player_x[i][2] <=  x_pos;
									player_x[i][3] <=  x_pos+1;
									
									//row 2
									player_x[i][4]   <= x_pos-2 ;
									player_x[i][5] <=  x_pos-1;
									player_x[i][6] <=  x_pos;
									player_x[i][7] <=  x_pos+1;

									//row 3
									player_x[i][8]   <= x_pos-2 ;
									player_x[i][9] <=  x_pos-1;
									player_x[i][10] <=  x_pos;
									player_x[i][11] <=  x_pos+1;
									
									//row 4
									player_x[i][12]   <= x_pos-2 ;
									player_x[i][13] <=  x_pos-1;
									player_x[i][14] <=  x_pos;
									player_x[i][15] <=  x_pos+1;				
									//end of x pixels
									
									
									
									//y pixels
									//row 1
									player_y[i][0]   <= #0.5 y_pos-2;
									player_y[i][1] <= #0.5 y_pos-2;
									player_y[i][2] <= #0.5 y_pos-2;
									player_y[i][3] <= #0.5 y_pos-2;
									
									//row 2
									player_y[i][4]   <= #0.5 y_pos-1;
									player_y[i][5] <= #0.5 y_pos-1;
									player_y[i][6] <= #0.5 y_pos-1;
									player_y[i][7] <= #0.5 y_pos-1;
									
									//row 3
									player_y[i][8]   <= #0.5  y_pos;
									player_y[i][9] <= #0.5  y_pos;
									player_y[i][10] <= #0.5  y_pos;
									player_y[i][11] <= #0.5  y_pos;
									
									//row 4
									player_y[i][12]   <= #0.5 y_pos+1;
									player_y[i][13] <= #0.5 y_pos+1;
									player_y[i][14] <= #0.5 y_pos+1;
									player_y[i][15] <= #0.5 y_pos+1;
									//end of y pixels
								end
							end
						end
					end
		
			end
			
		
			
	end //end of j for loop
	always @ (posedge CLOCK_50)
		begin
			disp_player[i] <= ((hor_reg == player_x[i][0]) & (ver_reg == player_y[i][0]))|
									((hor_reg == player_x[i][1]) & (ver_reg == player_y[i][1]))|
									((hor_reg == player_x[i][2]) & (ver_reg == player_y[i][2]))|
									((hor_reg == player_x[i][3]) & (ver_reg == player_y[i][3]))|
									
									((hor_reg == player_x[i][4]) & (ver_reg == player_y[i][4]))|
									((hor_reg == player_x[i][5]) & (ver_reg == player_y[i][5]))|
									((hor_reg == player_x[i][6]) & (ver_reg == player_y[i][6]))|
									((hor_reg == player_x[i][7]) & (ver_reg == player_y[i][7]))|
									
									((hor_reg == player_x[i][8]) & (ver_reg == player_y[i][8]))|
									((hor_reg == player_x[i][9]) & (ver_reg == player_y[i][9]))|
									((hor_reg == player_x[i][10]) & (ver_reg == player_y[i][10]))|
									((hor_reg == player_x[i][11]) & (ver_reg == player_y[i][11]))|
									
									((hor_reg == player_x[i][12]) & (ver_reg == player_y[i][12]))|
									((hor_reg == player_x[i][13]) & (ver_reg == player_y[i][13]))|
									((hor_reg == player_x[i][14]) & (ver_reg == player_y[i][14]))|
									((hor_reg == player_x[i][15]) & (ver_reg == player_y[i][15]));
		end
	
	end//end of i for loop
 
 endgenerate
  
  
 //always block to define the ball location 
always @ (posedge CLOCK_50 or negedge rst_n)
begin
	if (~rst_n)
		begin
		//define the initial position of the ball	
				//x pixels
						//row 1
						ball_x[0]   <=  ARN_CX-2;
						ball_x[1] <=  ARN_CX-1;
						ball_x[2] <=  ARN_CX;
						ball_x[3] <=  ARN_CX+1;
						
						//row 2
						ball_x[4]   <=  ARN_CX-2;
						ball_x[5] <=  ARN_CX-1;
						ball_x[6] <=  ARN_CX;
						ball_x[7] <=  ARN_CX+1;

						//row 3
						ball_x[8]   <=  ARN_CX-2;
						ball_x[9] <=  ARN_CX-1;
						ball_x[10] <=  ARN_CX;
						ball_x[11] <=  ARN_CX+1;
						
						//row 4
						ball_x[12]   <=  ARN_CX-2;
						ball_x[13] <=  ARN_CX-1;
						ball_x[14] <=  ARN_CX;
						ball_x[15] <=  ARN_CX+1;				
						//end of x pixels
						
						
						
						//y pixels
						//row 1
						ball_y[0]   <= #0.5 ARN_CY-2;
						ball_y[1] <= #0.5 ARN_CY-2;
						ball_y[2] <= #0.5 ARN_CY-2;
						ball_y[3] <= #0.5 ARN_CY-2;
						
						//row 2
						ball_y[4]   <= #0.5 ARN_CY-1;
						ball_y[5] <= #0.5 ARN_CY-1;
						ball_y[6] <= #0.5 ARN_CY-1;
						ball_y[7] <= #0.5 ARN_CY-1;
						
						//row 3
						ball_y[8]   <= #0.5  ARN_CY;
						ball_y[9] <= #0.5  ARN_CY;
						ball_y[10] <= #0.5  ARN_CY;
						ball_y[11] <= #0.5  ARN_CY;
						
						//row 4
						ball_y[12]   <= #0.5 ARN_CY+1;
						ball_y[13] <= #0.5 ARN_CY+1;
						ball_y[14] <= #0.5 ARN_CY+1;
						ball_y[15] <= #0.5 ARN_CY+1;
						//end of y pixels
		end
		else if (CLOCK_50==1'b1)
		begin
				
				if(dataReceived == 1) //the ball is addresses
				begin
					if(elementID==8'h88)
					begin
						//define the position of the ball	
						//x pixels
						//row 1
						ball_x[0]   <=  x_pos-2;
						ball_x[1] <=  x_pos-1;
						ball_x[2] <=  x_pos;
						ball_x[3] <=  x_pos+1;
						
						//row 2
						ball_x[4]   <=  x_pos-2;
						ball_x[5] <=  x_pos-1;
						ball_x[6] <=  x_pos;
						ball_x[7] <=  x_pos+1;

						//row 3
						ball_x[8]   <=  x_pos-2;
						ball_x[9] <=  x_pos-1;
						ball_x[10] <=  x_pos;
						ball_x[11] <=  x_pos+1;
						
						//row 4
						ball_x[12]   <=  x_pos-2;
						ball_x[13] <=  x_pos-1;
						ball_x[14] <=  x_pos;
						ball_x[15] <=  x_pos+1;				
						//end of x pixels
						
						
						
						//y pixels
						//row 1
						ball_y[0]   <= #0.5 y_pos-2;
						ball_y[1] <= #0.5 y_pos-2;
						ball_y[2] <= #0.5 y_pos-2;
						ball_y[3] <= #0.5 y_pos-2;
						
						//row 2
						ball_y[4]   <= #0.5 y_pos-1;
						ball_y[5] <= #0.5 y_pos-1;
						ball_y[6] <= #0.5 y_pos-1;
						ball_y[7] <= #0.5 y_pos-1;
						
						//row 3
						ball_y[8]   <= #0.5  y_pos;
						ball_y[9] <= #0.5  y_pos;
						ball_y[10] <= #0.5  y_pos;
						ball_y[11] <= #0.5  y_pos;
						
						//row 4
						ball_y[12]   <= #0.5 y_pos+1;
						ball_y[13] <= #0.5 y_pos+1;
						ball_y[14] <= #0.5 y_pos+1;
						ball_y[15] <= #0.5 y_pos+1;
						//end of y pixels
						
						
						ledsreg[7:0]<=8'b01110111;
					end
					else
					begin
							ledsreg[7:0]<=elementID;
					end
				end
		end

end

always @ (posedge CLOCK_50)
begin
				disp_ball <=   ((hor_reg == ball_x[0]) & (ver_reg == ball_y[0]))|
									((hor_reg == ball_x[1]) & (ver_reg == ball_y[1]))|
									((hor_reg == ball_x[2]) & (ver_reg == ball_y[2]))|
									((hor_reg == ball_x[3]) & (ver_reg == ball_y[3]))|
									
									((hor_reg == ball_x[4]) & (ver_reg == ball_y[4]))|
									((hor_reg == ball_x[5]) & (ver_reg == ball_y[5]))|
									((hor_reg == ball_x[6]) & (ver_reg == ball_y[6]))|
									((hor_reg == ball_x[7]) & (ver_reg == ball_y[7]))|
									
									((hor_reg == ball_x[8]) & (ver_reg == ball_y[8]))|
									((hor_reg == ball_x[9]) & (ver_reg == ball_y[9]))|
									((hor_reg == ball_x[10]) & (ver_reg == ball_y[10]))|
									((hor_reg == ball_x[11]) & (ver_reg == ball_y[11]))|
									
									((hor_reg == ball_x[12]) & (ver_reg == ball_y[12]))|
									((hor_reg == ball_x[13]) & (ver_reg == ball_y[13]))|
									((hor_reg == ball_x[14]) & (ver_reg == ball_y[14]))|
									((hor_reg == ball_x[15]) & (ver_reg == ball_y[15]));
end
  
  
 //--players and ball display ends
 
 
// always @ (posedge CLOCK_50 or negedge rst_n)
//begin
//	if(~rst_n)
//	begin
//		ledsreg[7:0]<=8'd0;
//	end
//	else if (CLOCK_50==1'b1)
//	begin
//		if(dataReceived==1'b1) //data received triggered
//		begin
//			if(elementID==1)
//			begin
//				if(x_pos==16'h2031)
//				begin
//					ledsreg[7:0] <= 8'b11011101;
//				end
//				else
//				begin
//					ledsreg[7:0] <= 8'b11100111;
//				end
//			end
//			else
//			begin
//				ledsreg[7:0] <= 8'b11100111;
//			end
//		end
//	end
//
//end
// 

 
  
endmodule


