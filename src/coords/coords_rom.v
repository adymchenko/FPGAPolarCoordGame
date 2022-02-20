//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.8 Education
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Sun Feb 20 10:23:56 2022

module coords_rom (dout, clk, oce, ce, reset, ad);

output [35:0] dout;
input clk;
input oce;
input ce;
input reset;
input [3:0] ad;

wire gw_gnd;

assign gw_gnd = 1'b0;

pROMX9 promx9_inst_0 (
    .DO(dout[35:0]),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,ad[3:0],gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam promx9_inst_0.READ_MODE = 1'b0;
defparam promx9_inst_0.BIT_WIDTH = 36;
defparam promx9_inst_0.RESET_MODE = "SYNC";
defparam promx9_inst_0.INIT_RAM_00 = 288'h00891C05000792B06000693A07000594808000495B0B000396A0A0002989090001998080;
defparam promx9_inst_0.INIT_RAM_01 = 288'h0000000001175550500164460600153370700142280800131160C00127570B0011808080;

endmodule //coords_rom
