//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: AXI MASTER INTERFACE.WRITE. 
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


module ami //ami: Axi Master Interface
#(
    //--------- AXI PARAMETERS -------
    AXI_DW     = 128                 , // AXI DATA    BUS WIDTH
    AXI_AW     = 32                  , // AXI ADDRESS BUS WIDTH(MUST <= 32)
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
    //---- AXI GLOBAL ------------------------------
    input  logic                    ACLK           ,
    input  logic                    ARESETn        ,
    //---- AXI AW ----------------------------------
    output logic [AXI_IW-1     : 0] AWID           ,
    output logic [AXI_AW-1     : 0] AWADDR         ,
    output logic [AXI_LW-1     : 0] AWLEN          ,
    output logic [AXI_SW-1     : 0] AWSIZE         ,
    output logic [AXI_BURSTW-1 : 0] AWBURST        ,
    output logic                    AWVALID        ,
    input  logic                    AWREADY        ,
    output logic                    AWLOCK         ,
    output logic [3            : 0] AWCACHE        ,
    output logic [2            : 0] AWPROT         ,
    output logic [3            : 0] AWQOS          ,
    output logic [3            : 0] AWREGION       ,
    //---- AXI W -----------------------------------
    output logic [AXI_DW-1     : 0] WDATA          ,
    output logic [AXI_WSTRBW-1 : 0] WSTRB          ,
    output logic                    WLAST          ,
    output logic                    WVALID         ,
    input  logic                    WREADY         ,
    //---- AXI B -----------------------------------
    input  logic [AXI_IW-1     : 0] BID            ,
    input  logic [AXI_BRESPW-1 : 0] BRESP          ,
    input  logic                    BVALID         ,
    output logic                    BREADY         ,
    //---- AXI AR ----------------------------------
    output logic [AXI_IW-1     : 0] ARID           ,
    output logic [AXI_AW-1     : 0] ARADDR         ,
    output logic [AXI_LW-1     : 0] ARLEN          ,
    output logic [AXI_SW-1     : 0] ARSIZE         ,
    output logic [AXI_BURSTW-1 : 0] ARBURST        ,
    output logic                    ARVALID        ,
    input  logic                    ARREADY        ,
    output logic                    ARLOCK         ,
    output logic [3            : 0] ARCACHE        ,
    output logic [2            : 0] ARPROT         ,
    output logic [3            : 0] ARQOS          ,
    output logic [3            : 0] ARREGION       ,
    //---- AXI R -----------------------------------
    input  logic [AXI_IW-1     : 0] RID            ,
    input  logic [AXI_DW-1     : 0] RDATA          ,
    input  logic [AXI_RRESPW-1 : 0] RRESP          ,
    input  logic                    RLAST          ,
    input  logic                    RVALID         ,
    output logic                    RREADY         ,
    //---- USER GLOBAL -----------------------------
    input  logic                    usr_clk        ,
    input  logic                    usr_reset_n    ,
    //---- CONFIG DMA WRITE ------------------------
    input  logic                    cfg_dmaw_valid ,
    output logic                    cfg_dmaw_ready ,
    input  logic [31           : 0] cfg_dmaw_sa    , // dma write start address   
    input  logic [31           : 0] cfg_dmaw_len   , // dma write length in bytes
    //---- CONFIG DMA READ -------------------------
    input  logic                    cfg_dmar_valid ,
    output logic                    cfg_dmar_ready ,
    input  logic [31           : 0] cfg_dmar_sa    , // dma read start address   
    input  logic [31           : 0] cfg_dmar_len   , // dma read length in bytes
    //---- USER W  ---------------------------------
    input  logic [AXI_DW-1     : 0] usr_wdata      ,
    input  logic [AXI_WSTRBW-1 : 0] usr_wstrb      ,
    input  logic                    usr_wlast      ,
    input  logic                    usr_wvalid     ,
    output logic                    usr_wready      
);

timeunit 1ns;
timeprecision 1ps;

//---- USER AW -----------------------
logic [AXI_IW-1     : 0] usr_awid    ;
logic [AXI_AW-1     : 0] usr_awaddr  ;
logic [AXI_LW-1     : 0] usr_awlen   ;
logic [AXI_SW-1     : 0] usr_awsize  ;
logic [AXI_BURSTW-1 : 0] usr_awburst ;
logic                    usr_awvalid ;
logic                    usr_awready ;
//---- USER B  -----------------------
logic [AXI_IW-1     : 0] usr_bid     ;
logic [AXI_BRESPW-1 : 0] usr_bresp   ;
logic                    usr_bvalid  ;
logic                    usr_bready  ;
//---- USER AR -----------------------
logic [AXI_IW-1     : 0] usr_arid    ;
logic [AXI_AW-1     : 0] usr_araddr  ;
logic [AXI_LW-1     : 0] usr_arlen   ;
logic [AXI_SW-1     : 0] usr_arsize  ;
logic [AXI_BURSTW-1 : 0] usr_arburst ;
logic                    usr_arvalid ;
logic                    usr_arready ;
//---- USER R  -----------------------
logic [AXI_IW-1     : 0] usr_rid     ;
logic [AXI_DW-1     : 0] usr_rdata   ;
logic [AXI_RRESPW-1 : 0] usr_rresp   ;
logic                    usr_rlast   ;
logic                    usr_rvalid  ;
logic                    usr_rready  ;

assign {AWLOCK, AWCACHE, AWPROT, AWQOS, AWREGION} = {1'b0, 4'b0001, 3'b000, 4'b0000}; 
assign {ARLOCK, ARCACHE, ARPROT, ARQOS, ARREGION} = {1'b0, 4'b0001, 3'b000, 4'b0000};

wlen_partition #(
    //--------- AXI PARAMETERS -------
    .AXI_DW     ( AXI_DW     ),
    .AXI_AW     ( AXI_AW     ),
    .AXI_IW     ( AXI_IW     ),
    .AXI_LW     ( AXI_LW     ),
    .AXI_SW     ( AXI_SW     ),
    .AXI_BURSTW ( AXI_BURSTW ),
    .AXI_BRESPW ( AXI_BRESPW ),
    .AXI_RRESPW ( AXI_RRESPW ),
    //--------- AMI CONFIGURE --------
    .AMI_OD     ( AMI_OD     ),
    .AMI_AD     ( AMI_AD     ),
    .AMI_RD     ( AMI_RD     ),
    .AMI_WD     ( AMI_WD     ),
    .AMI_BD     ( AMI_BD     ),
    //-------- DERIVED PARAMETERS ----
    .AXI_BYTES  ( AXI_BYTES  ),
    .AXI_WSTRBW ( AXI_WSTRBW ),
    .AXI_BYTESW ( AXI_BYTESW )
) awlen_partition (
    .clk            ( usr_clk        ),
    .reset_n        ( usr_reset_n    ),
    .cfg_dmaw_valid ( cfg_dmaw_valid ),
    .cfg_dmaw_ready ( cfg_dmaw_ready ),
    .cfg_dmaw_sa    ( cfg_dmaw_sa    ),
    .cfg_dmaw_len   ( cfg_dmaw_len   ),
    .awid           ( usr_awid       ),
    .awaddr         ( usr_awaddr     ),
    .awlen          ( usr_awlen      ),
    .awsize         ( usr_awsize     ),
    .awburst        ( usr_awburst    ),
    .awvalid        ( usr_awvalid    ),
    .awready        ( usr_awready    ) 
);

ami_w #(
//--------- AXI PARAMETERS -------
.AXI_DW     ( AXI_DW     ),
.AXI_AW     ( AXI_AW     ),
.AXI_IW     ( AXI_IW     ),
.AXI_LW     ( AXI_LW     ),
.AXI_SW     ( AXI_SW     ),
.AXI_BURSTW ( AXI_BURSTW ),
.AXI_BRESPW ( AXI_BRESPW ),
.AXI_RRESPW ( AXI_RRESPW ),
//--------- AMI CONFIGURE --------
.AMI_OD     ( AMI_OD     ),
.AMI_AD     ( AMI_AD     ),
.AMI_RD     ( AMI_RD     ),
.AMI_WD     ( AMI_WD     ),
.AMI_BD     ( AMI_BD     ),
//-------- DERIVED PARAMETERS ----
.AXI_BYTES  ( AXI_BYTES  ),
.AXI_WSTRBW ( AXI_WSTRBW ),
.AXI_BYTESW ( AXI_BYTESW )
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
.AXI_BURSTW ( AXI_BURSTW ),
.AXI_BRESPW ( AXI_BRESPW ),
.AXI_RRESPW ( AXI_RRESPW ),
//--------- AMI CONFIGURE --------
.AMI_OD     ( AMI_OD     ),
.AMI_AD     ( AMI_AD     ),
.AMI_RD     ( AMI_RD     ),
.AMI_WD     ( AMI_WD     ),
.AMI_BD     ( AMI_BD     ),
//-------- DERIVED PARAMETERS ----
.AXI_BYTES  ( AXI_BYTES  ),
.AXI_WSTRBW ( AXI_WSTRBW ),
.AXI_BYTESW ( AXI_BYTESW )
) r_inf (
    .*
);
endmodule
