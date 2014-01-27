//----------------------------------------------------------------------------
// icap_stream - module
//----------------------------------------------------------------------------
// IMPORTANT:
// DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
//
// SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
//
// TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
// PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
// OF THE USER_LOGIC ENTITY.
//----------------------------------------------------------------------------
//
// ***************************************************************************
// ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
// **                                                                       **
// ** Xilinx, Inc.                                                          **
// ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
// ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
// ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
// ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
// ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
// ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
// ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
// ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
// ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
// ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
// ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
// ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
// ** FOR A PARTICULAR PURPOSE.                                             **
// **                                                                       **
// ***************************************************************************
//
//----------------------------------------------------------------------------
// Filename:          icap_stream
// Version:           1.00.a
// Description:       Example Axi Streaming core (Verilog).
// Date:              Wed Aug 07 11:13:27 2013 (by Create and Import Peripheral Wizard)
// Verilog Standard:  Verilog-2001
//----------------------------------------------------------------------------
// Naming Conventions:
//   active low signals:                    "*_n"
//   clock signals:                         "clk", "clk_div#", "clk_#x"
//   reset signals:                         "rst", "rst_n"
//   generics:                              "C_*"
//   user defined types:                    "*_TYPE"
//   state machine next state:              "*_ns"
//   state machine current state:           "*_cs"
//   combinatorial signals:                 "*_com"
//   pipelined or register delay signals:   "*_d#"
//   counter signals:                       "*cnt*"
//   clock enable signals:                  "*_ce"
//   internal version of output port:       "*_i"
//   device pins:                           "*_pin"
//   ports:                                 "- Names begin with Uppercase"
//   processes:                             "*_PROCESS"
//   component instantiations:              "<ENTITY_>I_<#|FUNC>"
//----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
//
//
// Definition of Ports
// ACLK              : Synchronous clock
// ARESETN           : System reset, active low
// S_AXIS_TREADY  : Ready to accept data in
// S_AXIS_TDATA   :  Data in 
// S_AXIS_TLAST   : Optional data in qualifier
// S_AXIS_TVALID  : Data in is valid
//
////////////////////////////////////////////////////////////////////////////////

//----------------------------------------
// Module Section
//----------------------------------------
module icap_ctrl 
	(
		// ADD USER PORTS BELOW THIS LINE 
		// -- USER ports added here 
		// ADD USER PORTS ABOVE THIS LINE 

		// DO NOT EDIT BELOW THIS LINE ////////////////////
		// Bus protocol ports, do not add or delete. 
		ACLK,
		ARESETN,
		S_AXIS_TREADY,
		S_AXIS_TDATA,
		S_AXIS_TLAST,
		S_AXIS_TVALID
		// DO NOT EDIT ABOVE THIS LINE ////////////////////
	);

// ADD USER PORTS BELOW THIS LINE 
// -- USER ports added here 
// ADD USER PORTS ABOVE THIS LINE 

input                                     ACLK;
input                                     ARESETN;
output                                    S_AXIS_TREADY;
input      [31 : 0]                       S_AXIS_TDATA;
input                                     S_AXIS_TLAST;
input                                     S_AXIS_TVALID;

wire [31:0] icap_data;

assign S_AXIS_TREADY = 1'b1; 
assign icap_data = {S_AXIS_TDATA[24],S_AXIS_TDATA[25],S_AXIS_TDATA[26],S_AXIS_TDATA[27],S_AXIS_TDATA[28],S_AXIS_TDATA[29],S_AXIS_TDATA[30],S_AXIS_TDATA[31],S_AXIS_TDATA[16],S_AXIS_TDATA[17],S_AXIS_TDATA[18],S_AXIS_TDATA[19],S_AXIS_TDATA[20],S_AXIS_TDATA[21],S_AXIS_TDATA[22],S_AXIS_TDATA[23],S_AXIS_TDATA[8],S_AXIS_TDATA[9],S_AXIS_TDATA[10],S_AXIS_TDATA[11],S_AXIS_TDATA[12],S_AXIS_TDATA[13],S_AXIS_TDATA[14],S_AXIS_TDATA[15],S_AXIS_TDATA[0],S_AXIS_TDATA[1],S_AXIS_TDATA[2],S_AXIS_TDATA[3],S_AXIS_TDATA[4],S_AXIS_TDATA[5],S_AXIS_TDATA[6],S_AXIS_TDATA[7]};

   ICAPE2 #(
      .DEVICE_ID('h3651093),     // Specifies the pre-programmed Device ID value to be used for simulation
                                  // purposes.
      .ICAP_WIDTH("X32"),         // Specifies the input and output data width.
      .SIM_CFG_FILE_NAME("None")  // Specifies the Raw Bitstream (RBT) file to be parsed by the simulation
                                  // model.
   )
   ICAPE2_inst (
      .O(),           // 32-bit output: Configuration data output bus
      .CLK(ACLK),    // 1-bit input: Clock Input
      .CSIB(~S_AXIS_TVALID),   // 1-bit input: Active-Low ICAP Enable
      .I(icap_data),         // 32-bit input: Configuration data input bus
      .RDWRB(~S_AXIS_TVALID)  // 1-bit input: Read/Write Select input
   );

endmodule
