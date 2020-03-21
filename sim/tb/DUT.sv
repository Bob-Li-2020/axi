module DUT #(
)(
    //---- AXI GLOBAL SIGNALS -----------------------
    input  logic                    ACLK            ,
    input  logic                    ARESETn         ,
    //---- USER LOGIC SIGNALS -----------------------
    input  logic                    usr_clk         ,
    input  logic                    usr_reset_n      
);

axi_inf ainf( .* );
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
.AXI_DW     ( AXI_DW     ),
.AXI_AW     ( AXI_AW     ),
.AXI_IW     ( AXI_IW     ),
.AXI_LW     ( AXI_LW     ),
.AXI_SW     ( AXI_SW     ),
.AXI_BURSTW ( AXI_BURSTW ),
.AXI_BRESPW ( AXI_BRESPW ),
.AXI_RRESPW ( AXI_RRESPW ),
.ASI_AD     ( ASI_AD     ),
.ASI_RD     ( ASI_RD     ),
.ASI_WD     ( ASI_WD     ),
.ASI_BD     ( ASI_BD     ),
.ASI_ARB    ( ASI_ARB    ),
.SLV_WS     ( SLV_WS     ),
.AXI_BYTES  ( AXI_BYTES  ),
.AXI_WSTRBW ( AXI_WSTRBW ),
.AXI_BYTESW ( AXI_BYTESW )
) u_asi (
    input  logic                    ACLK            ,
    input  logic                    ARESETn         ,
    input  logic [AXI_IW-1     : 0] AWID            ,
    input  logic [AXI_AW-1     : 0] AWADDR          ,
    input  logic [AXI_LW-1     : 0] AWLEN           ,
    input  logic [AXI_SW-1     : 0] AWSIZE          ,
    input  logic [AXI_BURSTW-1 : 0] AWBURST         ,
    input  logic                    AWVALID         ,
    output logic                    AWREADY         ,
    input  logic                    AWLOCK          , // NO LOADS 
    input  logic [3            : 0] AWCACHE         , // NO LOADS
    input  logic [2            : 0] AWPROT          , // NO LOADS
    input  logic [3            : 0] AWQOS           , // NO LOADS
    input  logic [3            : 0] AWREGION        , // NO LOADS
    input  logic [AXI_DW-1     : 0] WDATA           ,
    input  logic [AXI_WSTRBW-1 : 0] WSTRB           ,
    input  logic                    WLAST           ,
    input  logic                    WVALID          ,
    output logic                    WREADY          ,
    output logic [AXI_IW-1     : 0] BID             ,
    output logic [AXI_BRESPW-1 : 0] BRESP           ,
    output logic                    BVALID          ,
    input  logic                    BREADY          ,
    input  logic [AXI_IW-1     : 0] ARID            ,
    input  logic [AXI_AW-1     : 0] ARADDR          ,
    input  logic [AXI_LW-1     : 0] ARLEN           ,
    input  logic [AXI_SW-1     : 0] ARSIZE          ,
    input  logic [AXI_BURSTW-1 : 0] ARBURST         ,
    input  logic                    ARVALID         ,
    output logic                    ARREADY         ,
    input  logic                    ARLOCK          , // NO LOADS 
    input  logic [3            : 0] ARCACHE         , // NO LOADS 
    input  logic [2            : 0] ARPROT          , // NO LOADS 
    input  logic [3            : 0] ARQOS           , // NO LOADS 
    input  logic [3            : 0] ARREGION        , // NO LOADS
    output logic [AXI_IW-1     : 0] RID             ,
    output logic [AXI_DW-1     : 0] RDATA           ,
    output logic [AXI_RRESPW-1 : 0] RRESP           ,
    output logic                    RLAST           ,
    output logic                    RVALID          ,
    input  logic                    RREADY          ,
    input  logic                    usr_clk         ,
    input  logic                    usr_reset_n     ,
    output logic [AXI_AW-1     : 0] usr_a           , // address
    output logic                    usr_ce          , // clock enable. Active-High
    output logic [AXI_DW-1     : 0] usr_d           , // data
    output logic [AXI_WSTRBW-1 : 0] usr_we          , // write enable. Active-High
    input  logic [AXI_DW-1     : 0] usr_q           , // Q
    //extra signals
    output logic [AXI_SW-1     : 0] usr_wsize       ,
    output logic [AXI_SW-1     : 0] usr_rsize       ,
    input  logic                    usr_wsize_error ,
    input  logic                    usr_rsize_error  

    .*
);

RAMSP #(
    .SZ ( RAM_SZ ), // RAM DEPTH 
    .BW ( RAM_BW ), // BYTE WIDTH
    .BS ( RAM_BS ), // BYTES NUMBER IN A WORD
    .QX ( RAM_QX ), // 
    .WS ( RAM_WS )  // READ WAIT STATES
) slv_ram (
    .CLK ( RAM_CLK ),
    .CEN ( RAM_CEN ),
    .WEN ( RAM_WEN ),
    .A   ( RAM_A   ),
    .D   ( RAM_D   ),
    .Q   ( RAM_Q   )
);


endmodule
