//Copyright (C)2014-2021 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8 Education
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Sun Feb 20 10:54:21 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    coords_rom your_instance_name(
        .dout(dout_o), //output [35:0] dout
        .clk(clk_i), //input clk
        .oce(oce_i), //input oce
        .ce(ce_i), //input ce
        .reset(reset_i), //input reset
        .ad(ad_i) //input [3:0] ad
    );

//--------Copy end-------------------
