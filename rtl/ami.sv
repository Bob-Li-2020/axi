//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: AXI MASTER INTERFACE.
//----------------------Protocol: AXI4. "AMBA AXI and ACE Protocol Specification, 30 July 2019"
//----------------------SUPPORTED FEATURES(A1-26): 
//----------------------                         1) OUTSTANDING AW/AR ADDRESSES( parameter "AMI_OD" );
//----------------------                         2) INDEPENDENT AW CHANNEL / W CHANNEL; 
//----------------------                         3) INDEPENDENT AW CHANNEL / AR CHANNEL; 
//----------------------                         4) WRITE DATA STROBES.
//----------------------BRESP:
//----------------------        2'b00: OKAY;
//----------------------        2'b01: EXOKAY; 
//----------------------        2'b10: SLVERR; 
//----------------------        2'b00: DECERR. 
//----------------------        

module ami //ami: Axi Master Interface
#(
    //--------- AXI PARAMETERS -------
    AXI_DW     = 128                 , // AXI DATA    BUS WIDTH
    AXI_AW     = 32                  , // AXI ADDRESS BUS WIDTH(MUST >= 32)
    AXI_IW     = 8                   , // AXI ID TAG  BITS WIDTH
    AXI_LW     = 8                   , // AXI AWLEN   BITS WIDTH
    AXI_SW     = 3                   , // AXI AWSIZE  BITS WIDTH
    //--------- AMI CONFIGURE --------
    AMI_OD     = 4                   , // AMI OUTSTANDING DEPTH
    AMI_AD     = 8                   , // AMI AW/AR CHANNEL FIFO DEPTH
    AMI_XD     = 16                  , // AMI W/R   CHANNEL FIFO DEPTH
    AMI_BD     = 8                   , // AMI B     CHANNEL FIFO DEPTH
    //-------- DERIVED PARAMETERS ----
    AXI_WSTRBW = AXI_DW/8              // AXI WSTRB BITS WIDTH
)(
    //---- AXI GLOBAL -------------------------------
    input  logic                        ACLK        ,
    input  logic                        ARESETn     ,
    //---- AXI AW -----------------------------------
    output logic [AXI_IW-1         : 0] AWID        ,
    output logic [AXI_AW-1         : 0] AWADDR      ,
    output logic [AXI_LW-1         : 0] AWLEN       ,
    output logic [AXI_SW-1         : 0] AWSIZE      ,
    output logic [1                : 0] AWBURST     ,
    output logic                        AWVALID     ,
    input  logic                        AWREADY     ,
    output logic                        AWLOCK      ,
    output logic [3                : 0] AWCACHE     ,
    output logic [2                : 0] AWPROT      ,
    output logic [3                : 0] AWQOS       ,
    output logic [3                : 0] AWREGION    ,
    //---- AXI W ------------------------------------
    output logic [AXI_DW-1         : 0] WDATA       ,
    output logic [AXI_WSTRBW-1     : 0] WSTRB       ,
    output logic                        WLAST       ,
    output logic                        WVALID      ,
    input  logic                        WREADY      ,
    //---- AXI B ------------------------------------
    input  logic [AXI_IW-1         : 0] BID         ,
    input  logic [1                : 0] BRESP       ,
    input  logic                        BVALID      ,
    output logic                        BREADY      ,
    //---- AXI AR -----------------------------------
    output logic [AXI_IW-1         : 0] ARID        ,
    output logic [AXI_AW-1         : 0] ARADDR      ,
    output logic [AXI_LW-1         : 0] ARLEN       ,
    output logic [AXI_SW-1         : 0] ARSIZE      ,
    output logic [1                : 0] ARBURST     ,
    output logic                        ARVALID     ,
    input  logic                        ARREADY     ,
    output logic                        ARLOCK      ,
    output logic [3                : 0] ARCACHE     ,
    output logic [2                : 0] ARPROT      ,
    output logic [3                : 0] ARQOS       ,
    output logic [3                : 0] ARREGION    ,
    //---- AXI R ------------------------------------
    input  logic [AXI_IW-1         : 0] RID         ,
    input  logic [AXI_DW-1         : 0] RDATA       ,
    input  logic [1                : 0] RRESP       ,
    input  logic                        RLAST       ,
    input  logic                        RVALID      ,
    output logic                        RREADY      ,
    //---- USER GLOBAL ------------------------------
    input  logic                        usr_clk     ,
    input  logic                        usr_reset_n ,
    //---- USER AW ----------------------------------
    input  logic [AXI_IW-1         : 0] usr_awid    ,
    input  logic [AXI_AW-1         : 0] usr_awaddr  ,
    input  logic [AXI_LW-1         : 0] usr_awlen   ,
    input  logic [AXI_SW-1         : 0] usr_awsize  ,
    input  logic [1                : 0] usr_awburst ,
    input  logic                        usr_awvalid ,
    output logic                        usr_awready ,
    //---- USER W  ----------------------------------
    input  logic [AXI_DW-1         : 0] usr_wdata   ,
    input  logic [AXI_WSTRBW-1     : 0] usr_wstrb   ,
    input  logic                        usr_wlast   ,
    input  logic                        usr_wvalid  ,
    output logic                        usr_wready  ,
    output logic                        usr_wnafull , // !almost_full
    input  logic [$clog2(AMI_XD)-1 : 0] usr_ram_ws  , // RAM read wait states
    //---- USER B  ----------------------------------
    output logic [AXI_IW-1         : 0] usr_bid     ,
    output logic [1                : 0] usr_bresp   ,
    output logic                        usr_bvalid  ,
    input  logic                        usr_bready  ,
    //---- USER AR ----------------------------------
    input  logic [AXI_IW-1         : 0] usr_arid    ,
    input  logic [AXI_AW-1         : 0] usr_araddr  ,
    input  logic [AXI_LW-1         : 0] usr_arlen   ,
    input  logic [AXI_SW-1         : 0] usr_arsize  ,
    input  logic [1                : 0] usr_arburst ,
    input  logic                        usr_arvalid ,
    output logic                        usr_arready ,
    //---- USER R  ----------------------------------
    output logic [AXI_IW-1         : 0] usr_rid     ,
    output logic [AXI_DW-1         : 0] usr_rdata   ,
    output logic [1                : 0] usr_rresp   ,
    output logic                        usr_rlast   ,
    output logic                        usr_rvalid  ,
    input  logic                        usr_rready   
);

timeunit 1ns;
timeprecision 1ps;

assign {AWLOCK, AWCACHE, AWPROT, AWQOS, AWREGION} = {1'b0, 4'b0001, 3'b000, 4'b0000}; 
assign {ARLOCK, ARCACHE, ARPROT, ARQOS, ARREGION} = {1'b0, 4'b0001, 3'b000, 4'b0000};

ami_w #(
    //--------- AXI PARAMETERS -------
    .AXI_DW     ( AXI_DW     ),
    .AXI_AW     ( AXI_AW     ),
    .AXI_IW     ( AXI_IW     ),
    .AXI_LW     ( AXI_LW     ),
    .AXI_SW     ( AXI_SW     ),
    //--------- AMI CONFIGURE --------
    .AMI_OD     ( AMI_OD     ),
    .AMI_AD     ( AMI_AD     ),
    .AMI_XD     ( AMI_XD     ),
    .AMI_BD     ( AMI_BD     ),
    //-------- DERIVED PARAMETERS ----
    .AXI_WSTRBW ( AXI_WSTRBW )
) w_inf (
    .*
);

ami_r #(
    //--------- AXI PARAMETERS -------
    .AXI_DW     ( AXI_DW     ),
    .AXI_AW     ( AXI_AW     ),
    .AXI_IW     ( AXI_IW     ),
    .AXI_LW     ( AXI_LW     ),
    .AXI_SW     ( AXI_SW     ),
    //--------- AMI CONFIGURE --------
    .AMI_OD     ( AMI_OD     ),
    .AMI_AD     ( AMI_AD     ),
    .AMI_XD     ( AMI_XD     ),
    .AMI_BD     ( AMI_BD     ),
    //-------- DERIVED PARAMETERS ----
    .AXI_WSTRBW ( AXI_WSTRBW )
) r_inf (
    .*
);

endmodule
