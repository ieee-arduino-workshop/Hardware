
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
        rst_n

    );
    input CLOCK_50;
    input [3:0] uart_baud;
    input uart_rx_i;
    input rst_n;
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
   
   // All Dimensions from US Quidditch 
   localparam ARN_HEIGHT = 36 * _1_YARD;    // Total height is 36 yards
   localparam ARN_WIDTH  = 60 * _1_YARD;    // Total width is 60 yards
   localparam ARN_CX     = SCR_CX;          // X coord centre of Arena
   localparam ARN_CY     = SCR_CY;          // Y coord centre of Arena
   localparam ARN_C2KZL  = 12 * _1_YARD;    // Arena centre to Keeper Zone line
   localparam ARN_E2GHL  = 12 * _1_YARD;    // Arena edge to Goal Hoop line
   localparam ARN_GH_SZ  = 3 * _1_YARD;
   
   localparam ARN_BNDRY_TOP_Y     = ARN_CY - (ARN_HEIGHT/2);  // Top edge of the arena
   localparam ARN_BNDRY_TB_LHS_X  = ARN_CX - (ARN_C2KZL);     // LHS of the central rectangle  
   localparam ARN_BNDRY_TB_RHS_X  = ARN_CX + (ARN_C2KZL);     // RHS of the central rectangle
   localparam ARN_BNDRY_BOT_Y     = ARN_CY + (ARN_HEIGHT/2);  // Bottom edge of the arena
   localparam ARN_BNDRY_LHS_X     = ARN_CX - (ARN_WIDTH/2);   // LHS edge of the arena 
   localparam ARN_BNDRY_RHS_X     = ARN_CX + (ARN_WIDTH/2);   // RHS edge os the arena
   localparam ARN_KZ_LHS_X        = ARN_CX - (ARN_C2KZL);     // X coord of the keeper zone line LHS 
   localparam ARN_KZ_RHS_X        = ARN_CX + (ARN_C2KZL);     // X coord of the keeper zone line RHS 
   localparam ARN_GH_LHS_X        = ARN_BNDRY_LHS_X + ARN_E2GHL;
   localparam ARN_GH_RHS_X        = ARN_BNDRY_RHS_X - ARN_E2GHL;
   localparam ARN_GH_LR_YT        = ARN_CY - (2 * ARN_GH_SZ);
   localparam ARN_GH_LR_YM        = ARN_CY;
   localparam ARN_GH_LR_YB        = ARN_CY + (2 * ARN_GH_SZ);
   
   localparam ARN_BNDRY_LHS_CX    = ARN_CX - (ARN_C2KZL);     // Centre of the LHS Semi-circle X coord
   localparam ARN_BNDRY_LHS_CY    = ARN_CY;                   // Centre of the LHS Semi-circle Y coord
   localparam ARN_BNDRY_RHS_CX    = ARN_CX + (ARN_C2KZL);     // Centre of the RHS Semi-circle X coord
   localparam ARN_BNDRY_RHS_CY    = ARN_CY;                   // Centre of the RHS Semi-circle Y coord
   
   localparam ARN_BNDRY_SC_RADIUS = ARN_WIDTH/2;              // Radius of the Semi circles
   
   
   // Arena boundary
   reg disp_arn_bndry_top;
   reg disp_arn_bndry_bot;
   reg disp_arn_bndry_lhs1;
   reg disp_arn_bndry_lhs2;
   reg disp_arn_bndry_rhs1;
   reg disp_arn_bndry_rhs2;
   reg disp_arn_kz_lhs;
   reg disp_arn_kz_rhs;
   reg disp_arn_gh_lhs;
   reg disp_arn_gh_rhs;


   reg disp_player[6:0][1:0];


   reg [10:0]player_x[1:0][6:0];
   reg [10:0]player_y[1:0][6:0];
   reg       xplus   [1:0][6:0];
   reg       xminus  [1:0][6:0];
   reg       yplus   [1:0][6:0];
   reg       yminus  [1:0][6:0];

   reg [10:0]ball_x[2:0];
   reg [10:0]ball_y[2:0];
   reg       ball_xplus[2:0];
   reg       ball_xminus[2:0];
   reg       ball_yplus[2:0];
   reg       ball_yminus[2:0];
   
    
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
    end
    
    
    always @(posedge CLOCK_50)
    begin
      disp_arn_bndry_lhs1 <= ((hor_reg + ver_reg ) == (ARN_BNDRY_LHS_CX + ARN_BNDRY_TOP_Y))  & (hor_reg >= ARN_BNDRY_LHS_X) & (ver_reg >= ARN_BNDRY_TOP_Y);
      disp_arn_bndry_lhs2 <= ((ver_reg - hor_reg ) == (ARN_BNDRY_BOT_Y  - ARN_BNDRY_LHS_CX)) & (hor_reg >= ARN_BNDRY_LHS_X) & (ver_reg <= ARN_BNDRY_BOT_Y);
      disp_arn_bndry_rhs1 <= ((hor_reg + ver_reg ) == (ARN_BNDRY_RHS_CX + ARN_BNDRY_BOT_Y))  & (hor_reg <= ARN_BNDRY_RHS_X) & (ver_reg <= ARN_BNDRY_BOT_Y);
      disp_arn_bndry_rhs2 <= ((hor_reg - ver_reg ) == (ARN_BNDRY_RHS_CX - ARN_BNDRY_TOP_Y))  & (hor_reg <= ARN_BNDRY_RHS_X) & (ver_reg >= ARN_BNDRY_TOP_Y);
    end

    always @ (posedge CLOCK_50)
    begin
      disp_arn_kz_lhs    <= (hor_reg ==  ARN_KZ_LHS_X) && (ver_reg >= ARN_BNDRY_TOP_Y) && (ver_reg <= ARN_BNDRY_BOT_Y); 
      disp_arn_kz_rhs    <= (hor_reg ==  ARN_KZ_RHS_X) && (ver_reg >= ARN_BNDRY_TOP_Y) && (ver_reg <= ARN_BNDRY_BOT_Y); 
    end

    always @ (posedge CLOCK_50)
    begin
      disp_arn_gh_lhs <= (hor_reg ==  ARN_GH_LHS_X) && (((ver_reg >= (ARN_GH_LR_YT - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YT + (ARN_GH_SZ/2))))
                                                       |((ver_reg >= (ARN_GH_LR_YM - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YM + (ARN_GH_SZ/2))))
                                                       |((ver_reg >= (ARN_GH_LR_YB - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YB + (ARN_GH_SZ/2)))));
      disp_arn_gh_rhs <= (hor_reg ==  ARN_GH_RHS_X) && (((ver_reg >= (ARN_GH_LR_YT - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YT + (ARN_GH_SZ/2))))
                                                       |((ver_reg >= (ARN_GH_LR_YM - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YM + (ARN_GH_SZ/2))))
                                                       |((ver_reg >= (ARN_GH_LR_YB - (ARN_GH_SZ/2))) && (ver_reg <= (ARN_GH_LR_YB + (ARN_GH_SZ/2)))));
    end
    
    
    assign VGA_RED =    disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2 
                       | disp_arn_kz_lhs | disp_arn_kz_rhs | disp_arn_gh_lhs | disp_arn_gh_rhs 
                       | disp_ball[0]
                       | disp_player[0][0] | disp_player[0][1] | disp_player[0][2] | disp_player[0][3]
                       | disp_player[0][4] | disp_player[0][5] | disp_player[0][6];
    assign VGA_GREEN =  disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2
                       | disp_arn_kz_lhs | disp_arn_kz_rhs | disp_arn_gh_lhs | disp_arn_gh_rhs
                       | disp_ball[0];
    assign VGA_BLUE =   disp_arn_bndry_top | disp_arn_bndry_bot | disp_arn_bndry_lhs1 | disp_arn_bndry_lhs2 | disp_arn_bndry_rhs1 | disp_arn_bndry_rhs2
                       | disp_arn_kz_lhs | disp_arn_kz_rhs |  disp_arn_gh_lhs | disp_arn_gh_rhs
                       | disp_ball[0]
                       | disp_player[1][0] | disp_player[1][1] | disp_player[1][2] | disp_player[1][3]
                       | disp_player[1][4] | disp_player[1][5] | disp_player[1][6];
    
  // ARENA display ends ------------------
  //
  // MOVING display ----------------------

  // clk50_cntr controls the refresh rate of all moving objects. This can be increased by reducing the
  // size of the counter if necessary.
  reg [15:0] clk50_cntr;
  always @ (posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
      clk50_cntr <= 16'd0;
    else
      clk50_cntr <= #0.5 clk50_cntr + 1'd1;
  end

  // Players
  generate
    genvar i,j;
    for(i=0;i<=1;i=i+1)
    begin : TEAMS

      for (j=0;j<=7;j=j+1)
      begin : PLAYERS

        always @ (posedge CLOCK_50 or negedge rst_n)
        begin
          if (~rst_n)
            player_x[i][j] <= #0.5 ARN_CX;
          else if ((xplus[i][j]) & (clk50_cntr == 16'd1))
            player_x[i][j] <= #0.5 player_x[i][j] + 1'd1;
          else if ((xminus[i][j]) & (clk50_cntr == 16'd1))
            player_x[i][j] <= #0.5 player_x[i][j] - 1'd1;
        end

        always @ (posedge CLOCK_50 or negedge rst_n)
        begin
          if (~rst_n)
            player_y[i][j] <= #0.5 ARN_CX;
          else if ((yplus[i][j]) & (clk50_cntr == 16'd1))
            player_y[i][j] <= #0.5 player_y[i][j] + 1'd1;
          else if ((yminus[i][j]) & (clk50_cntr == 16'd1))
            player_y[i][j] <= #0.5 player_y[i][j] - 1'd1;
        end
          
        always @ (posedge CLOCK_50)
        begin
          disp_player[i][j] = ((hor_reg[10:1] == player_x[i][j][10:1]) & (ver_reg[10:1] == player_y[i][j][10:1]));
        end

      end
    end
  endgenerate
  
  // Player display ends -----------------


  // Ball display
  always @ (posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
      ball_x[0] <= #0.5 ARN_CX;
    else if ((ball_xplus[0]) & (clk50_cntr == 16'd1))
      ball_x[0] <= #0.5 ball_x[0] + 1'd1;
    else if ((ball_xminus[0]) & (clk50_cntr == 16'd1))
      ball_x[0] <= #0.5 ball_x[0] - 1'd1;
  end

  always @ (posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
      ball_y[0] <= #0.5 ARN_CX;
    else if ((ball_yplus[0]) & (clk50_cntr == 16'd1))
      ball_y[0] <= #0.5 ball_y[0] + 1'd1;
    else if ((ball_yminus[0]) & (clk50_cntr == 16'd1))
      ball_y[0] <= #0.5 ball_y[0] - 1'd1;
  end
    
  always @ (posedge CLOCK_50)
  begin
    disp_ball[0] = ((clk50_cntr[15]==1'd0) & (hor_reg[10:2] == ball_x[0][10:2]) & (ver_reg[10:1] == ball_y[0][10:1]));
  end

  // Ball display ends
  
  // UART Data communication with Arduino
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
 
  always @(posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
      uart_rx_data_d1 <= #0.5 8'd0;
    else 
      uart_rx_data_d1 <= #0.5 uart_rx_data;
  end

  always @(posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
      uart_rx_data_rcvd <= #0.5 1'd0;
    else if (uart_rx_data_d1 != uart_rx_data)
      uart_rx_data_rcvd <= #0.5 ~uart_rx_data_rcvd;
  end

  always @(posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
      uart_rx_data_rcvd_d1 <= #0.5 1'd0;
    else
      uart_rx_data_rcvd_d1 <= #0.5 uart_rx_data_rcvd;
  end

  assign uart_rx_data_rcvd_edge = uart_rx_data_rcvd & ~uart_rx_data_rcvd_d1;

//  // UART data for players
//  generate
//  genvar i,j;
//    for (i=0;i<=1;i=i+1)
//    begin : UART_TEAMS
//
//      for (j=0;j<=6;j=j+1)
//      begin : UART_PLAYERS
//      
//        always @ (posedge CLOCK_50 or negedge rst_n)
//        begin
//          if (~rst_n)
//          begin
//            xplus[i][j]  <= #0.5 1'd0;
//            xminus[i][j] <= #0.5 1'd0;
//            yplus[i][j]  <= #0.5 1'd0;
//            yminus[i][j] <= #0.5 1'd0;
//          end
//          else if (uart_rx_data_rcvd_edge & (uart_rx_data_d1[7] == i) & (uart_rx_data_d1[6:4] == j))
//          begin
//            xplus[i][j]  <= #0.5 uart_rx_data_d1[0];
//            xminus[i][j] <= #0.5 uart_rx_data_d1[1];
//            yplus[i][j]  <= #0.5 uart_rx_data_d1[2];
//            yminus[i][j] <= #0.5 uart_rx_data_d1[3];
//          end
//          else if (clk50_cntr == 16'd1)
//          begin
//            xplus[i][j]  <= #0.5 1'd0;
//            xminus[i][j] <= #0.5 1'd0;
//            yplus[i][j]  <= #0.5 1'd0;
//            yminus[i][j] <= #0.5 1'd0;
//          end
//        end
//
//      end
//    end
//  endgenerate

  // UART data for ball
  always @ (posedge CLOCK_50 or negedge rst_n)
  begin
    if (~rst_n)
    begin
      ball_xplus[0]  <= #0.5 1'd0;
      ball_xminus[0] <= #0.5 1'd0;
      ball_yplus[0]  <= #0.5 1'd0;
      ball_yminus[0] <= #0.5 1'd0;
    end
    else if (uart_rx_data_rcvd_edge & (uart_rx_data_d1[7] == 0) & (uart_rx_data_d1[6:4] == 7))
    begin
      ball_xplus[0]  <= #0.5 uart_rx_data_d1[0];
      ball_xminus[0] <= #0.5 uart_rx_data_d1[1];
      ball_yplus[0]  <= #0.5 uart_rx_data_d1[2];
      ball_yminus[0] <= #0.5 uart_rx_data_d1[3];
    end
    else if (clk50_cntr == 16'd1)
    begin
      ball_xplus[0]  <= #0.5 1'd0;
      ball_xminus[0] <= #0.5 1'd0;
      ball_yplus[0]  <= #0.5 1'd0;
      ball_yminus[0] <= #0.5 1'd0;
    end
  end

endmodule


