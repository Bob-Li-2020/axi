//-- AUTHOR: LIBING
//-- DATE: 2020.3
//-- DESCRIPTION: 
//-------------- AXI SLAVE INTERFACE WITH A SINGLE-PORT RAM.
//-------------- AXI SLAVE INTERFACE + SPRAM

module axi_slave_model
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
    //--------- ASI CONFIGURE --------
    ASI_AD     = 4                   , // ASI AW/AR CHANNEL BUFFER DEPTH
    ASI_RD     = 64                  , // ASI R CHANNEL BUFFER DEPTH
    ASI_WD     = 64                  , // ASI W CHANNEL BUFFER DEPTH
    ASI_BD     = 4                   , // ASI B CHANNEL BUFFER DEPTH
    ASI_ARB    = 0                   , // 1-GRANT READ WITH HIGHER PRIORITY; 0-GRANT WRITE WITH HIGHER PRIORITY
    //--------- SLAVE ATTRIBUTES -----
    SLV_WS     = 1                   , // SLAVE MODEL READ WAIT STATES CYCLE
    //-------- DERIVED PARAMETERS ----
    AXI_BYTES  = AXI_DW/8            , // BYTES NUMBER IN <AXI_DW>
    AXI_WSTRBW = AXI_BYTES           , // AXI WSTRB BITS WIDTH
    AXI_BYTESW = $clog2(AXI_BYTES+1) ,
    //--------- RAM PARAMETERS -------
    RAM_SZ = 512 , // RAM DEPTH 
    RAM_BW = 8 , // BYTE WIDTH
    RAM_BS = AXI_BYTES , // BYTES NUMBER IN A WORD
    RAM_QX = 1 , // 
    RAM_WS = 1 , // READ WAIT STATES
    //--- derived parameters
    RAM_AW = $clog2(RAM_SZ) , 
    RAM_DW = RAM_BW*RAM_BS  
)(
    //---- AXI GLOBAL SIGNALS -------------------
    input  logic                    ACLK        ,
    input  logic                    ARESETn     ,
    //---- AXI ADDRESS WRITE SIGNALS ------------
    input  logic [AXI_IW-1     : 0] AWID        ,
    input  logic [AXI_AW-1     : 0] AWADDR      ,
    input  logic [AXI_LW-1     : 0] AWLEN       ,
    input  logic [AXI_SW-1     : 0] AWSIZE      ,
    input  logic [AXI_BURSTW-1 : 0] AWBURST     ,
    input  logic                    AWVALID     ,
    output logic                    AWREADY     ,
    input  logic                    AWLOCK      , // NO LOADS 
    input  logic [3            : 0] AWCACHE     , // NO LOADS
    input  logic [2            : 0] AWPROT      , // NO LOADS
    input  logic [3            : 0] AWQOS       , // NO LOADS
    input  logic [3            : 0] AWREGION    , // NO LOADS
    //---- AXI DATA WRITE SIGNALS ---------------
    input  logic [AXI_DW-1     : 0] WDATA       ,
    input  logic [AXI_WSTRBW-1 : 0] WSTRB       ,
    input  logic                    WLAST       ,
    input  logic                    WVALID      ,
    output logic                    WREADY      ,
    //---- AXI WRITE RESPONSE SIGNALS -----------
    output logic [AXI_IW-1     : 0] BID         ,
    output logic [AXI_BRESPW-1 : 0] BRESP       ,
    output logic                    BVALID      ,
    input  logic                    BREADY      ,
    //---- READ ADDRESS CHANNEL -----------------
    input  logic [AXI_IW-1     : 0] ARID        ,
    input  logic [AXI_AW-1     : 0] ARADDR      ,
    input  logic [AXI_LW-1     : 0] ARLEN       ,
    input  logic [AXI_SW-1     : 0] ARSIZE      ,
    input  logic [AXI_BURSTW-1 : 0] ARBURST     ,
    input  logic                    ARVALID     ,
    output logic                    ARREADY     ,
    input  logic                    ARLOCK      , // NO LOADS 
    input  logic [3            : 0] ARCACHE     , // NO LOADS 
    input  logic [2            : 0] ARPROT      , // NO LOADS 
    input  logic [3            : 0] ARQOS       , // NO LOADS 
    input  logic [3            : 0] ARREGION    , // NO LOADS
    //---- READ DATA CHANNEL --------------------
    output logic [AXI_IW-1     : 0] RID         ,
    output logic [AXI_DW-1     : 0] RDATA       ,
    output logic [AXI_RRESPW-1 : 0] RRESP       ,
    output logic                    RLAST       ,
    output logic                    RVALID      ,
    input  logic                    RREADY      ,
    input  logic                    usr_clk     ,
    input  logic                    usr_reset_n  
);

//---- asi user ports --------------------
logic [AXI_AW-1     : 0] usr_a           ; // address
logic                    usr_ce          ; // clock enable. Active-High
logic [AXI_DW-1     : 0] usr_d           ; // data
logic [AXI_WSTRBW-1 : 0] usr_we          ; // write enable. Active-High
logic [AXI_DW-1     : 0] usr_q           ; // Q
logic [AXI_SW-1     : 0] usr_wsize       ;
logic [AXI_SW-1     : 0] usr_rsize       ;
logic                    usr_wsize_error ;
logic                    usr_rsize_error ;

//-- RAM
logic                    RAM_CLK         ;
logic                    RAM_CEN         ;
logic [RAM_BS-1     : 0] RAM_WEN         ;
logic [RAM_AW-1     : 0] RAM_A           ;
logic [RAM_DW-1     : 0] RAM_D           ;
logic [RAM_DW-1     : 0] RAM_Q           ;

assign RAM_CLK = usr_clk;
assign RAM_CEN = ~usr_ce;
assign RAM_WEN = ~usr_we;
assign RAM_A   = usr_a[$clog2(RAM_BS) +: RAM_AW];
assign RAM_D   = usr_d  ;
assign usr_q   = RAM_Q  ;

asi #(
//--------- AXI PARAMETERS -------
.AXI_DW     ( AXI_DW     ),
.AXI_AW     ( AXI_AW     ),
.AXI_IW     ( AXI_IW     ),
.AXI_LW     ( AXI_LW     ),
.AXI_SW     ( AXI_SW     ),
.AXI_BURSTW ( AXI_BURSTW ),
.AXI_BRESPW ( AXI_BRESPW ),
.AXI_RRESPW ( AXI_RRESPW ),
//--------- ASI CONFIGURE --------
.ASI_AD     ( ASI_AD     ),
.ASI_RD     ( ASI_RD     ),
.ASI_WD     ( ASI_WD     ),
.ASI_BD     ( ASI_BD     ),
.ASI_ARB    ( ASI_ARB    ),
//--------- SLAVE ATTRIBUTES -----
.SLV_WS     ( SLV_WS     ),
//-------- DERIVED PARAMETERS ----
.AXI_BYTES  ( AXI_BYTES  ),
.AXI_WSTRBW ( AXI_WSTRBW ),
.AXI_BYTESW ( AXI_BYTESW )
) u_asi (
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
