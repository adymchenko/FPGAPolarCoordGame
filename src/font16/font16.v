//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.8 Education
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Sun Feb 20 10:04:57 2022

module font16_rom (dout, clk, oce, ce, reset, ad);

output [7:0] dout;
input clk;
input oce;
input ce;
input reset;
input [7:0] ad;

wire [23:0] prom_inst_0_dout_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

pROM prom_inst_0 (
    .DO({prom_inst_0_dout_w[23:0],dout[7:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({gw_gnd,gw_gnd,gw_gnd,ad[7:0],gw_gnd,gw_gnd,gw_gnd})
);

defparam prom_inst_0.READ_MODE = 1'b0;
defparam prom_inst_0.BIT_WIDTH = 8;
defparam prom_inst_0.RESET_MODE = "SYNC";
defparam prom_inst_0.INIT_RAM_00 = 256'h000000007E1818181818587838180000000000007CC6C6E6F6DECEC6C67C0000;
defparam prom_inst_0.INIT_RAM_01 = 256'h000000007CC60606063C0606C67C000000000000FEC66030180C0606C67C0000;
defparam prom_inst_0.INIT_RAM_02 = 256'h000000007CC6060606FCC0C0C6FE0000000000000C0C0CFECCCCCCCCC0C00000;
defparam prom_inst_0.INIT_RAM_03 = 256'h0000000030303030180C0606C6FE0000000000007CC6C6C6C6FCC0C0C67C0000;
defparam prom_inst_0.INIT_RAM_04 = 256'h000000007CC606067EC6C6C6C67C0000000000007CC6C6C6C67CC6C6C67C0000;
defparam prom_inst_0.INIT_RAM_05 = 256'h00000000C6C6C6C6C6FCC6C6C6FC000000000000181800000000000000000000;
defparam prom_inst_0.INIT_RAM_06 = 256'h00000000000000000000000000000000000000007CC6C6C6F6F6C6C6C67C0000;
defparam prom_inst_0.INIT_RAM_07 = 256'h0000000000000000000000000000000000000000000000000000000000000000;

endmodule //font16_rom
