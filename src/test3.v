//
// Test3.v - Tang Nano video demo
//

module Test3 (
  // 24 MHz clock
  input clk_in,    // 35
    
  // LCD Screen output
  output       lcdClk,          // 11
  output [4:0] lcdR,            // 31, 30, 29, 28, 27
  output [5:0] lcdG,            // 40, 39, 38, 34, 33, 32
  output [4:0] lcdB,            // 45, 44, 43, 42, 41
  output       lcdHSync,        // 10
  output       lcdVSync,        // 46
  output       lcdDE,           // 5

  // tri-color LED - active low
  output ledR,  // 18
  output ledG,  // 16    
  output ledB,  // 17

  // buttons
  input btnA, // iob6b 15
  input btnB, // iob3b 14

  // PS - reused for ADC
  input adc0_in,    // SIO1 - IOB16A - 23
  output adc0_out,  // SIO2 - IOB16B - 24
  input adc1_in,    // SIO0 - IOB14B - 22
  output adc1_out,  // SIO3 - IOB14A - 21
  // output [3:0] sio,   // 21, 24, 23, 22
  output       sclk,  // 20
  output       ps_cen // 19

);

    // 33 MHz clock generator
    wire clk;
    Gowin_rPLL pll1 (
        .clkout(),      //output clkout
        .clkoutd3(clk), //output clkoutd3
        .clkin(clk_in)  //input clkin
    );

    reg [27:0] ctr;
    always @( posedge clk )
        ctr <= ctr + 1'b1;
    assign { ledR, ledG, ledB } = ~ctr[27:25];

  //Coordinates
  reg [3:0] coordcnt;
  wire [35:0] coordout;
  coords_rom your_instance_name(
        .dout(coordout), //output [35:0] dout
        .clk(clk), //input clk
        .oce(1'b1), //input oce
        .ce(1'b1), //input ce
        .reset(1'b0), //input reset
        .ad(coordcnt) //input [3:0] ad
  );
  // Video signal generator
  wire vsync;
  wire hsync;
  wire de;
  wire [7:0] r;
  wire [7:0] g;
  wire [7:0] b;
  wire vblank;

  reg [9:0] test_y;
  reg vblank_d;
  always @( posedge clk ) begin
    vblank_d <= vblank;
    if( vblank & ~vblank_d )
        test_y <= test_y + 1'b1;
  end

  wire [9:0] cursor_x;
  wire [9:0] cursor_y;
  wire [9:0] target_x;
  wire [9:0] target_y;
  wire [63:0] message = {4'hb, 4'hf, coordout[23:16], 4'hf, 4'hc, 4'hf, coordout[35:24], 24'hFFFFFF};
  wire [9:0] tx = {coordout[15:8], 2'b00};
  wire [8:0] ty = {coordout[7:0], 1'b0};

  xvga_test xvga_test_inst (
	.clk   ( clk ),
	.vsync ( vsync ),
	.hsync ( hsync ),
	.de    ( de ),
	.r     ( r ),
	.g     ( g ),
	.b     ( b ),
	.vblank ( vblank ),
	.cursor_x ( cursor_x ),
	.cursor_y ( cursor_y ),
    .target_x ( tx ),
    .target_y ( ty ),
//    .message  ( 64'h0123456789ABCDEF ) // 16 4-bit characters - testing
    .message ( message )

  );
  assign lcdR = r[7:3];
  assign lcdG = g[7:2];
  assign lcdB = b[7:3];
  assign lcdHSync = hsync;
  assign lcdVSync = vsync;
  assign lcdDE = de;

  assign lcdClk = clk;  // TODO: phase   


  // 1-bit ADCs
  reg adc0;
  reg adc1;
  always @( posedge clk ) begin
    adc0 <= adc0_in;
    adc1 <= adc1_in;
  end

  // Sigma-Delta ADC gated by vblank = 45 * 1056 = ~48000 clocks
  reg [15:0] adc_acc_0;
  reg [15:0] adc_acc_1;
  reg vblank_prev;
  
  always @( posedge clk ) begin
	  
	  vblank_prev <= vblank;
	  if( vblank ) begin
		if( ~vblank_prev ) begin
			adc_acc_0 <= 16'hF800; // TBD
			adc_acc_1 <= 16'hE800;
		end else begin
			adc_acc_0 <= adc_acc_0 + adc0;
			adc_acc_1 <= adc_acc_1 + adc1;
        end
	  end
  end
  
  assign cursor_x = adc_acc_0[15:5]; // 0..TBD
  assign cursor_y = adc_acc_1[15:6]; // 0..562

  // random target

  reg next_target;  // update target location once per 4 seconds
  reg [7:0] tctr;
  reg vs;
  always @( posedge clk ) begin 
    vs <= vblank & ~vblank_prev;    // single pulse per frame
    if( vs ) begin 
      next_target <= tctr == 239;
      tctr <= next_target ? 0 : tctr + 1;
    end
  end

  reg [19:0] prbs20 = 20'h55555;    // x^20+x^3+1
  always @( posedge clk ) begin
    if( next_target & vs ) begin
      prbs20 <= { prbs20[18:0], prbs20[19] ^ prbs20[2] };
      coordcnt <= (coordcnt + 1'b1);
    end
  end
  assign { target_x, target_y } = prbs20;

  assign adc0_out = ~adc0;
  assign adc1_out = ~adc1;
  assign sclk = 1'b0;
  assign ps_cen = 1'b1;

endmodule // Test3


// Generate VGA video signal, 25.175 MHz pixel clock, both vsync and hsync are negative
// Horizontal: 16 + 96 + 48 + 640 = 800 pixels (front porch, hsync pulse, back porch, active line
// Vertical: 10 + 2 + 33 + 480 = 525 lines (front porch, vsync pulse, back porch, active area) 
// Also output vblank - vertical blanking using as sigma/delta ADC gate

// TFT 5" display using ILI1622 chip in 800 x 480 mode:
//  Clock frequency: TBD .. 33.3 .. 50 MHz
//  H size = 800; Htotal = 862 .. 1056 .. 1200
//  H pulse 1 .. TBD .. 40,
//  H back porch 46
//  H from porch 16 .. 210 .. 354
//  Vsize = 480; Vtotal = 510 .. 525 .. 650
//  V pulse 1 .. 20
//  V back porch 23; V front porch 7 .. 22 .. 147

// From sample file
//	/*localparam      V_BackPorch = 16'd12; 
//	localparam      V_Pluse 	= 16'd11; 
//	localparam      HightPixel  = 16'd272;
//	localparam      V_FrontPorch= 16'd8; 
//	
//	localparam      H_BackPorch = 16'd50; 
//	localparam      H_Pluse 	= 16'd10; 
//	localparam      WidthPixel  = 16'd480;
//	localparam      H_FrontPorch= 16'd8;    */

//	localparam      V_BackPorch = 16'd0; //6
//	localparam      V_Pluse 	= 16'd5; 
//	localparam      HightPixel  = 16'd480;
//	localparam      V_FrontPorch= 16'd45; //62

//	localparam      H_BackPorch = 16'd182; 	//NOTE: 高像素时钟时，增加这里的延迟，方便K210加入中断
//	localparam      H_Pluse 	= 16'd1; 
//	localparam      WidthPixel  = 16'd800;
//	localparam      H_FrontPorch= 16'd210;


module xvga_test (
	input clk,
	output reg vsync,
	output reg hsync,
	output wire de,
	output reg [7:0] r,
	output reg [7:0] g,
	output reg [7:0] b,
	
	output reg vblank,
	input [9:0] cursor_x,
	input [9:0] cursor_y,
    input [9:0] target_x,
	input [8:0] target_y,
    input [63:0] message // 4-bit characters
);

    localparam HTOT = 11'd1058;
    localparam HACT = 11'd800;
    localparam HFRONT = 11'd116;
    localparam HPULSE = 11'd96;
    localparam HBACK  = 11'd46;
    localparam HBLANK = HFRONT+HPULSE+HBACK;

    localparam LBAT_X = 11'd300;
    localparam RBAT_X = 11'd1000;
    localparam BAT_HEIGHT = 7'd80;
    localparam TARGET_X = 11'd500;
    localparam TARGET_Y = 7'd80;

    localparam VTOT = 10'd525;
    localparam VACT = 10'd480;
    localparam VFRONT = 10'd20;
    localparam VPULSE = 10'd2;
    localparam VBACK  = 10'd23;
    localparam VBLANK = VFRONT+VPULSE+VBACK;
    
	reg [10:0] x; //x values for whole horizontal span
	reg [9:0] y;
	reg xlast;
	reg ylast;
	reg dex;
	reg dey;
	always @( posedge clk ) begin
		xlast <= (x == (HTOT-11'd2));
		x <= xlast ? 0 : x + 1'b1;
		if( x == HFRONT )
			hsync <= 1'b0;
		else if( x == (HFRONT+HPULSE) )
			hsync <= 1'b1;
		if( x == HBLANK ) 
			dex <= 1'b1;
		else if( xlast )
			dex <= 1'b0;
			
		if( xlast ) begin
			ylast <= (y==(VTOT-10'd2));
			y <= ylast ? 0 : y + 1'b1;
			if( y == VFRONT )
				vsync <= 1'b0;
			else if( y == (VFRONT+VPULSE) )
				vsync <= 1'b1;
			if( y == (VBLANK) )
				dey <= 1'b1;
			else if( ylast )
				dey <= 1'b0;
			if( ylast )
				vblank <= 1'b1;
			else if( y == (VBLANK-10'd2) )
				vblank <= 1'b0;
		end
	end
	assign de = dex & dey;

    // active screen area x and y
    reg [9:0] xa;
    reg [8:0] ya;
    reg xbl_last;
    reg ybl_last;
    always @( posedge clk ) begin
      xbl_last <= (x==HBLANK-1);
      xa <= xbl_last ? 0 : xa + 1;
      if( xlast ) begin
          ybl_last <= (y==VBLANK-1);
          ya <= ybl_last ? 0 : ya + 1;
      end
    end

	// color gradient
	reg [7:0] cg;
	always @( posedge clk )
		cg <= dex ? cg + 1'b1 : 0;
	
	reg [23:0] cgrgb;
	always @( posedge clk )
		case( y[8:6] )
			3'b000: cgrgb <= { 8'd0, 8'd0, 8'd0 };
			3'b001: cgrgb <= { cg, 8'd0, 8'd0 };
			3'b010: cgrgb <= { 8'd0, cg, 8'd0 };
			3'b011: cgrgb <= { 8'd0, 8'd0, cg };
			3'b100: cgrgb <= { cg, cg, 8'd0 };
			3'b101: cgrgb <= { cg, 8'd0, cg };
			3'b110: cgrgb <= { 8'd0, cg, cg };
			3'b111: cgrgb <= { cg, cg, cg };
		endcase
	

    // vertical line test
    reg line_xon;
    always @ (posedge clk) begin
        line_xon <= (HBLANK + HACT / 2) == x;
    end

    // horizontal line test
    reg line_yon;
    always @ (posedge clk) begin
        line_yon <= (VBLANK + VACT / 2) == y;
    end

    //cursor
    reg [3:0] cursor_xon;
    reg [3:0] cursor_yon;
    always @ (posedge clk) begin 
        cursor_xon <= { |cursor_xon[2:0], cursor_xon[1:0], cursor_x==x };
        if( xlast )
            cursor_yon <= { |cursor_yon[2:0], cursor_yon[1:0], cursor_y==y };
    end

    //target
    reg [3:0] target_xon;
    reg [3:0] target_yon;
    always @ (posedge clk) begin 
        target_xon <= { |target_xon[2:0], target_xon[1:0], target_x==xa};
        if( xlast )
            target_yon <= { |target_yon[2:0], target_yon[1:0], target_y==ya};
    end

    // text message 
    // 1 string of 16 4-bit characters
    // 8x16 font (8-width in pixels)

    // generate one char at a time for font rom
    wire csr_load;
    wire csr_shift;
    reg [63:0] csr;
    always @( posedge clk ) begin
      if( csr_load )
        csr <= message;
      else if( csr_shift )
        csr <= { csr[59:0], 4'hF }; // pad message with F 
    end

    // font address: 4-bit character, 4-bit Y 
    wire [7:0] faddr = { csr[63:60], ya[3:0] };   // [7:4] - symbol index, [3:0] - Y index 0..31
    wire [7:0] font_out;   

    // font 8x16
    font16_rom font_rom (
        .dout(font_out), //output [7:0] dout
        .clk(clk), //input clk
        .oce(1'b1), //input oce
        .ce(1'b1), //input ce
        .reset(1'b0), //input reset
        .ad(faddr) //input [7:0] ad
    );

    reg [7:0] psr; // char pixels shift register
    reg psr_load;
    always @( posedge clk ) begin
      if( psr_load )
        psr <= font_out;
      else
        psr <= { psr[6:0], 1'b0 };   // shift pixels to the left 
    end 


    // char message controls
    //                      15      14      13                              0
    //                      765432107
    // fsx                 1 
    // csr_load             1
    // csr_shift            1       1       1       1       1       1 ...   1
    // psr_load              1       1       1       1       1       1       1
    // repeat at next 16 lines
    reg fsx;
    reg fsy;
    reg [7:0] strctr;   // count down from FF to 00
    always @( posedge clk ) begin
      fsx <= (xa==126);  // start text output from position 128
      if( xlast )
          fsy <= (ya[8:4]==2);   // place text output in lines 32..47
      if( fsx & fsy )
        strctr <= 8'hFF;
      else if( strctr[7] )
        strctr <= strctr - 1'b1;
       psr_load <= csr_shift;
    end
    assign csr_load = strctr==8'hFF;
    assign csr_shift = strctr[2:0]==3'h7;


	always @* begin
		{ r, g, b } = (line_xon | line_yon | (cursor_xon[3] & cursor_yon[3]) | (target_xon[3] & target_yon[3]) |  psr[7] ) ? 24'hFFFFFF : 0;
	end
		
endmodule // xvga_test
