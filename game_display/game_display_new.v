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
        uart_baud,
        uart_rx_i,
        uart_tx_o,
        rst_n,
        xplus,
        xminus,
        yplus,
        yminus

    );
    input CLOCK_50;
    input [3:0] uart_baud;
    input uart_rx_i;
    input rst_n;
    input xplus;
    input xminus;
    input yplus;
    input yminus;
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
	
	
   reg disp_player;


   reg [9:0]player_x[7:0][3:0];
   reg [9:0]player_y[7:0][3:0];
	
	
   
    
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
    
	 
    
    always @(posedge CLOCK_50)
    begin
      //disp_arn_bndry_lhs1 <= ((hor_reg + ver_reg ) == (ARN_BNDRY_LHS_CX + ARN_BNDRY_TOP_Y))  & (hor_reg >= ARN_BNDRY_LHS_X) & (ver_reg >= ARN_BNDRY_TOP_Y);
     // disp_arn_bndry_lhs2 <= ((ver_reg - hor_reg ) == (ARN_BNDRY_BOT_Y  - ARN_BNDRY_LHS_CX)) & (hor_reg >= ARN_BNDRY_LHS_X) & (ver_reg <= ARN_BNDRY_BOT_Y);
     // disp_arn_bndry_rhs1 <= ((hor_reg + ver_reg ) == (ARN_BNDRY_RHS_CX + ARN_BNDRY_BOT_Y))  & (hor_reg <= ARN_BNDRY_RHS_X) & (ver_reg <= ARN_BNDRY_BOT_Y);
     // disp_arn_bndry_rhs2 <= ((hor_reg - ver_reg ) == (ARN_BNDRY_RHS_CX - ARN_BNDRY_TOP_Y))  & (hor_reg <= ARN_BNDRY_RHS_X) & (ver_reg >= ARN_BNDRY_TOP_Y);
    end

    always @ (posedge CLOCK_50)
    begin
      disp_arn_kz_lhs    <= (hor_reg ==  ARN_KZ_LHS_X) && (ver_reg >= ARN_BNDRY_TOP_Y) && (ver_reg <= ARN_BNDRY_BOT_Y); 
      disp_arn_kz_rhs    <= (hor_reg ==  ARN_KZ_RHS_X) && (ver_reg >= ARN_BNDRY_TOP_Y) && (ver_reg <= ARN_BNDRY_BOT_Y); 
		//disp_arn_midline   <= (hor_reg ==  ARN_MIDLINE_X) && (ver_reg >= ARN_BNDRY_TOP_Y) && (ver_reg <= ARN_BNDRY_BOT_Y);
		disp_arn_goalbndry_lhs <= (hor_reg ==  ARN_GOALBNDRY_TB_LHS_X) && (ver_reg >= ARN_GOALBNDRY_TOP_Y) && (ver_reg <= ARN_GOALBNDRY_BOT_Y);
		disp_arn_goalbndry_rhs <= (hor_reg ==  ARN_GOALBNDRY_TB_RHS_X) && (ver_reg >= ARN_GOALBNDRY_TOP_Y) && (ver_reg <= ARN_GOALBNDRY_BOT_Y);
		disp_arn_goal_lhs  <= ((hor_reg <=  ARN_GOAL_TB_LHS_MARGIN_X) &&(hor_reg >= ARN_KZ_LHS_X ) ) && (ver_reg >= ARN_GOAL_TOP_MARGIN_Y) && (ver_reg <= ARN_GOAL_BOT_MARGIN_Y);
		disp_arn_goal_rhs  <= ((hor_reg >=  ARN_GOAL_TB_RHS_MARGIN_X) &&(hor_reg <= ARN_KZ_RHS_X ) ) && (ver_reg >= ARN_GOAL_TOP_MARGIN_Y) && (ver_reg <= ARN_GOAL_BOT_MARGIN_Y);

    end

    always @ (posedge CLOCK_50)
    begin
//     // disp_arn_gh_lhs <= (hor_reg ==  ARN_GH_LHS_X) && (((ver_reg >= (ARN_GH_LR_YT - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YT + (ARN_GH_SZ/2))))
//                                                       |((ver_reg >= (ARN_GH_LR_YM - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YM + (ARN_GH_SZ/2))))
//                                                       |((ver_reg >= (ARN_GH_LR_YB - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YB + (ARN_GH_SZ/2)))));
//      //disp_arn_gh_rhs <= (hor_reg ==  ARN_GH_RHS_X) && (((ver_reg >= (ARN_GH_LR_YT - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YT + (ARN_GH_SZ/2))))
//                                                       |((ver_reg >= (ARN_GH_LR_YM - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YM + (ARN_GH_SZ/2))))
//                                                       |((ver_reg >= (ARN_GH_LR_YB - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YB + (ARN_GH_SZ/2)))));
  end
    
    
    assign VGA_RED =    disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2 
                       | disp_arn_kz_lhs | disp_arn_kz_rhs|disp_arn_midline|disp_arn_goalbndry_lhs|disp_arn_goalbndry_rhs|disp_arn_goalbndry_lhs_top
							  |disp_arn_goalbndry_lhs_bot|disp_arn_goalbndry_rhs_top|disp_arn_goalbndry_rhs_bot ;
    assign VGA_GREEN =  disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2
                       | disp_arn_kz_lhs | disp_arn_kz_rhs | disp_player|disp_arn_midline|disp_arn_goalbndry_lhs|disp_arn_goalbndry_rhs|disp_arn_goalbndry_lhs_top
							  |disp_arn_goalbndry_lhs_bot|disp_arn_goalbndry_rhs_top|disp_arn_goalbndry_rhs_bot |disp_arn_goal_lhs |disp_arn_goal_rhs ;
    assign VGA_BLUE =   disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2
                       | disp_arn_kz_lhs | disp_arn_kz_rhs | disp_player | disp_arn_midline|disp_arn_goalbndry_lhs|disp_arn_goalbndry_rhs|disp_arn_goalbndry_lhs_top
							  |disp_arn_goalbndry_lhs_bot|disp_arn_goalbndry_rhs_top|disp_arn_goalbndry_rhs_bot|disp_arn_goal_lhs |disp_arn_goal_rhs ;
    
  // ARENA display ends ------------------
  //
  // Player display ----------------------
  
  reg [15:0] clk50_cntr;
  always @ (posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
      clk50_cntr <= 16'd0;
    else
      clk50_cntr <= #0.5 clk50_cntr + 1'd1;
  end

  always @ (posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
     begin
		player_x[0][0] <= #0.5 ARN_CX;
		player_x[0][1] <= #0.5 ARN_CX+ 2'd1;
		player_x[0][2] <= #0.5 ARN_CX;
		player_x[0][3] <= #0.5 ARN_CX+ 2'd1;
		end
    else if ((xplus) & (clk50_cntr == 16'd1))
      player_x[0][0] <= #0.5 player_x[0][0] + 1'd1;
    else if ((xminus) & (clk50_cntr == 16'd1))
      player_x[0][0] <= #0.5 player_x[0][0] - 1'd1;
  end

  always @ (posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
      begin
		player_y[0][0] <= #0.5 ARN_CY;
		player_y[0][1] <= #0.5 ARN_CY;
		player_y[0][2] <= #0.5 ARN_CY+2'd1;
		player_y[0][3] <= #0.5 ARN_CY+2'd1;
		end
    else if ((yplus) & (clk50_cntr == 16'd1))
      player_y[0][0] <= #0.5 player_y[0][0] + 1'd1;
		
    else if ((yminus) & (clk50_cntr == 16'd1))
      player_y[0][0] <= #0.5 player_y[0][0] - 1'd1;
  end
    

  always @ (posedge CLOCK_50)
  begin
    disp_player = ((hor_reg == player_x[0][0]) & (ver_reg == player_y[0][0]))|
						((hor_reg == player_x[0][1]) & (ver_reg == player_y[0][1]))|
						((hor_reg == player_x[0][2]) & (ver_reg == player_y[0][2]))|
						((hor_reg == player_x[0][3]) & (ver_reg == player_y[0][3]));
  end
  
   
    
  // Player display ends -----------------

  wire [7:0] uart_rx_data;
  wire [7:0] uart_tx_data;
  
  uart u_uart (
    .clk50(CLOCK_50),
    .rst_n(rst_n),
    .uart_baud(uart_baud),
    .rx_in(uart_rx_i),
    .rx_data(uart_rx_data),
    .tx_data(uart_tx_data),
    .tx_out(uart_tx_o),
    .test(LED[7:0])
  );
  
  assign uart_tx_data = uart_rx_data;

endmodule


