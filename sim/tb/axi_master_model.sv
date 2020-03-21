//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: 
//-------------- AXI MASTER INTERFACE WITH A SINGLE-PORT RAM.
//-------------- AXI MASTER INTERFACE + SPRAM

module axi_master_model import test_pkg::*;
#(    
    //--------- AXI PARAMETERS -------
    AXI_DW     = 128                 , // AXI DATA    BUS WIDTH
    AXI_AW     = 40                  , // AXI ADDRESS BUS WIDTH
    AXI_IW     = 8                   , // AXI ID TAG  BITS WIDTH
    AXI_LW     = 8                   , // AXI AWLEN   BITS WIDTH
    AXI_SW     = 3                   , // AXI AWSIZE  BITS WIDTH
    AXI_BURSTW = 2                   , // AXI AWBURST BITS WIDTH
    AXI_BRESPW = 2                   , // AXI BRESP   BITS WIDTH
    AXI_RRESPW = 2                   , // AXI RRESP   BITS WIDTH
    //--------- AMI CONFIGURE --------
    AMI_OD     = 4                   , // AMI OUTSTANDING DEPTH
    AMI_AD     = 4                   , // AMI AW/AR CHANNEL BUFFER DEPTH
    AMI_RD     = 64                  , // AMI R CHANNEL BUFFER DEPTH
    AMI_WD     = 64                  , // AMI W CHANNEL BUFFER DEPTH
    AMI_BD     = 4                   , // AMI B CHANNEL BUFFER DEPTH
    //-------- DERIVED PARAMETERS ----
    AXI_BYTES  = AXI_DW/8            , // BYTES NUMBER IN <AXI_DW>
    AXI_WSTRBW = AXI_BYTES           , // AXI WSTRB BITS WIDTH
    AXI_BYTESW = $clog2(AXI_BYTES+1)   
)(    
    //---- AXI GLOBAL ---------------------------
    input  logic                    ACLK        ,
    input  logic                    ARESETn     ,
    //---- AXI AW -------------------------------
    output logic [AXI_IW-1     : 0] AWID        ,
    output logic [AXI_AW-1     : 0] AWADDR      ,
    output logic [AXI_LW-1     : 0] AWLEN       ,
    output logic [AXI_SW-1     : 0] AWSIZE      ,
    output logic [AXI_BURSTW-1 : 0] AWBURST     ,
    output logic                    AWVALID     ,
    input  logic                    AWREADY     ,
    output logic                    AWLOCK      ,
    output logic [3            : 0] AWCACHE     ,
    output logic [2            : 0] AWPROT      ,
    output logic [3            : 0] AWQOS       ,
    output logic [3            : 0] AWREGION    ,
    //---- AXI W --------------------------------
    output logic [AXI_DW-1     : 0] WDATA       ,
    output logic [AXI_WSTRBW-1 : 0] WSTRB       ,
    output logic                    WLAST       ,
    output logic                    WVALID      ,
    input  logic                    WREADY      ,
    //---- AXI B --------------------------------
    input  logic [AXI_IW-1     : 0] BID         ,
    input  logic [AXI_BRESPW-1 : 0] BRESP       ,
    input  logic                    BVALID      ,
    output logic                    BREADY      ,
    //---- AXI AR -------------------------------
    output logic [AXI_IW-1     : 0] ARID        ,
    output logic [AXI_AW-1     : 0] ARADDR      ,
    output logic [AXI_LW-1     : 0] ARLEN       ,
    output logic [AXI_SW-1     : 0] ARSIZE      ,
    output logic [AXI_BURSTW-1 : 0] ARBURST     ,
    output logic                    ARVALID     ,
    input  logic                    ARREADY     ,
    output logic                    ARLOCK      ,
    output logic [3            : 0] ARCACHE     ,
    output logic [2            : 0] ARPROT      ,
    output logic [3            : 0] ARQOS       ,
    output logic [3            : 0] ARREGION    ,
    //---- AXI R --------------------------------
    input  logic [AXI_IW-1     : 0] RID         ,
    input  logic [AXI_DW-1     : 0] RDATA       ,
    input  logic [AXI_RRESPW-1 : 0] RRESP       ,
    input  logic                    RLAST       ,
    input  logic                    RVALID      ,
    output logic                    RREADY      ,
    //---- USER GLOBAL --------------------------
    input  logic                    usr_clk     ,
    input  logic                    usr_reset_n ,
    //---- USER RAM INTERFACE -------------------
    input  logic              test_w, // 1-write; 0-read
    input  logic [RAM_AW-1:0] test_a, // ram address
    input  logic [AXI_LW-1:0] test_l, // axi burst length
    input  logic              test_e  // enable

);

//-- RAM
logic                    RAM_CLK ;
logic                    RAM_CEN ;
logic [RAM_BS-1     : 0] RAM_WEN ;
logic [RAM_AW-1     : 0] RAM_A   ;
logic [RAM_DW-1     : 0] RAM_D   ;
logic [RAM_DW-1     : 0] RAM_Q   ;

//--- ami user ports -----------------
logic [AXI_IW-1     : 0] usr_awid    ;
logic [AXI_AW-1     : 0] usr_awaddr  ;
logic [AXI_LW-1     : 0] usr_awlen   ;
logic [AXI_SW-1     : 0] usr_awsize  ;
logic [AXI_BURSTW-1 : 0] usr_awburst ;
logic                    usr_awvalid ;
logic                    usr_awready ;
logic [AXI_DW-1     : 0] usr_wdata   ;
logic [AXI_WSTRBW-1 : 0] usr_wstrb   ;
logic                    usr_wlast   ;
logic                    usr_wvalid  ;
logic                    usr_wready  ;
logic [AXI_IW-1     : 0] usr_bid     ;
logic [AXI_BRESPW-1 : 0] usr_bresp   ;
logic                    usr_bvalid  ;
logic                    usr_bready  ;
logic [AXI_IW-1     : 0] usr_arid    ;
logic [AXI_AW-1     : 0] usr_araddr  ;
logic [AXI_LW-1     : 0] usr_arlen   ;
logic [AXI_SW-1     : 0] usr_arsize  ;
logic [AXI_BURSTW-1 : 0] usr_arburst ;
logic                    usr_arvalid ;
logic                    usr_arready ;
logic [AXI_IW-1     : 0] usr_rid     ;
logic [AXI_DW-1     : 0] usr_rdata   ;
logic [AXI_RRESPW-1 : 0] usr_rresp   ;
logic                    usr_rlast   ;
logic                    usr_rvalid  ;
logic                    usr_rready  ;

ami #(
//--------- AXI PARAMETERS -------
.AXI_DW(AXI_DW),
.AXI_AW(AXI_AW),
.AXI_IW(AXI_IW),
.AXI_LW(AXI_LW),
.AXI_SW(AXI_SW),
.AXI_BURSTW(AXI_BURSTW),
.AXI_BRESPW(AXI_BRESPW),
.AXI_RRESPW(AXI_RRESPW),
//--------- AMI CONFIGURE --------
.AMI_OD(AMI_OD),
.AMI_AD(AMI_AD),
.AMI_RD(AMI_RD),
.AMI_WD(AMI_WD),
.AMI_BD(AMI_BD),
//-------- DERIVED PARAMETERS ----
.AXI_BYTES(AXI_BYTES),
.AXI_WSTRBW(AXI_WSTRBW),
.AXI_BYTESW(AXI_BYTESW)
) u_ami (
    .*
);

RAMSP #(
    .SZ ( RAM_SZ ), // RAM DEPTH 
    .BW ( RAM_BW ), // BYTE WIDTH
    .BS ( RAM_BS ), // BYTES NUMBER IN A WORD
    .QX ( RAM_QX ), // 
    .WS ( RAM_WS )  // READ WAIT STATES
) U_RAM (
    .CLK ( RAM_CLK ),
    .CEN ( RAM_CEN ),
    .WEN ( RAM_WEN ),
    .A   ( RAM_A   ),
    .D   ( RAM_D   ),
    .Q   ( RAM_Q   )
);

endmodule

