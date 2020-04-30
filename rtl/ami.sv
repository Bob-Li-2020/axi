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
//----------------------        

// DMA write(OCM->EXTERNAL): 
// step1 - CONFIGURE  : Set values of <dmaw_sa>, <dmaw_len> and assert <dmaw_valid> and wait for handshake with <dmaw_ready> happen
// step2 - DRIVE DATA : Feed write data in by driving <usr_wdata>, <usr_wvalid>, until all write data are accepted(indicated by handshake <usr_wready>)
// step3 - INTERUPT   : DMA write interupt <dmaw_irq> shall be asserted. Clear <dmaw_irq> by driving <dmaw_irq_w1c> high

// DMA READ(EXTERNAL->OCM): 
// step1 - CONFIGURE    : Set values of <dmar_sa>, <dmar_len> and assert <dmar_valid> and wait for handshake with <dmar_ready> happen
// step2 - RECEIVE DATA : Receive <usr_rdata>
// step3 - INTERUPT     : Clear DMA read interrupt <dmar_irq> by driving <dmar_irq_w1c> high

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
    AMI_AD     = 16                  , // AMI AW/AR CHANNEL BUFFER DEPTH
    AMI_RD     = 16                  , // AMI R CHANNEL BUFFER DEPTH
    AMI_WD     = 16                  , // AMI W CHANNEL BUFFER DEPTH
    AMI_BD     = 16                  , // AMI B CHANNEL BUFFER DEPTH
    //-------- DERIVED PARAMETERS ----
    AXI_BYTES  = AXI_DW/8            , // BYTES NUMBER IN <AXI_DW>
    AXI_WSTRBW = AXI_BYTES           , // AXI WSTRB BITS WIDTH
    AXI_BYTESW = $clog2(AXI_BYTES+1) ,
    BL         = 16                  , // default burst length
    L          = $clog2(AXI_BYTES)   ,
    B          = $clog2(BL)+L 
)(
    //---- AXI GLOBAL ----------------------------
    input  logic                    ACLK         ,
    input  logic                    ARESETn      ,
    //---- AXI AW --------------------------------
    output logic [AXI_IW-1     : 0] AWID         ,
    output logic [AXI_AW-1     : 0] AWADDR       ,
    output logic [AXI_LW-1     : 0] AWLEN        ,
    output logic [AXI_SW-1     : 0] AWSIZE       ,
    output logic [AXI_BURSTW-1 : 0] AWBURST      ,
    output logic                    AWVALID      ,
    input  logic                    AWREADY      ,
    output logic                    AWLOCK       ,
    output logic [3            : 0] AWCACHE      ,
    output logic [2            : 0] AWPROT       ,
    output logic [3            : 0] AWQOS        ,
    output logic [3            : 0] AWREGION     ,
    //---- AXI W ---------------------------------
    output logic [AXI_DW-1     : 0] WDATA        ,
    output logic [AXI_WSTRBW-1 : 0] WSTRB        ,
    output logic                    WLAST        ,
    output logic                    WVALID       ,
    input  logic                    WREADY       ,
    //---- AXI B ---------------------------------
    input  logic [AXI_IW-1     : 0] BID          ,
    input  logic [AXI_BRESPW-1 : 0] BRESP        ,
    input  logic                    BVALID       ,
    output logic                    BREADY       ,
    //---- AXI AR --------------------------------
    output logic [AXI_IW-1     : 0] ARID         ,
    output logic [AXI_AW-1     : 0] ARADDR       ,
    output logic [AXI_LW-1     : 0] ARLEN        ,
    output logic [AXI_SW-1     : 0] ARSIZE       ,
    output logic [AXI_BURSTW-1 : 0] ARBURST      ,
    output logic                    ARVALID      ,
    input  logic                    ARREADY      ,
    output logic                    ARLOCK       ,
    output logic [3            : 0] ARCACHE      ,
    output logic [2            : 0] ARPROT       ,
    output logic [3            : 0] ARQOS        ,
    output logic [3            : 0] ARREGION     ,
    //---- AXI R ---------------------------------
    input  logic [AXI_IW-1     : 0] RID          ,
    input  logic [AXI_DW-1     : 0] RDATA        ,
    input  logic [AXI_RRESPW-1 : 0] RRESP        ,
    input  logic                    RLAST        ,
    input  logic                    RVALID       ,
    output logic                    RREADY       ,
    //---- USER GLOBAL ---------------------------
    input  logic                    usr_clk      ,
    input  logic                    usr_reset_n  ,
    //---- CONFIG DMA WRITE ----------------------
    input  logic                    dmaw_valid   ,
    output logic                    dmaw_ready   ,
    input  logic [31           : 0] dmaw_sa      , // dma write start address   
    input  logic [31           : 0] dmaw_len     , // dma write length
    input  logic                    dmaw_irq_w1c , // dmaw interrupt write 1 clear
    output logic                    dmaw_irq     , // dmaw interrupt
    output logic [3            : 0] dmaw_err     , // dmaw error
    //---- CONFIG DMA READ -----------------------
    input  logic                    dmar_valid   ,
    output logic                    dmar_ready   ,
    input  logic [31           : 0] dmar_sa      , // dma read start address   
    input  logic [31           : 0] dmar_len     , // dma read length
    input  logic                    dmar_irq_w1c , // dmar interrupt write 1 clear
    output logic                    dmar_irq     , // dmar interrupt
    output logic [3            : 0] dmar_err     , // dmaw error
    //---- DMA W  --------------------------------
    input  logic [AXI_DW-1     : 0] dma_wdata    ,
    input  logic [AXI_WSTRBW-1 : 0] dma_wstrb    ,
    input  logic                    dma_wlast    ,
    input  logic                    dma_wvalid   ,
    output logic                    dma_wready   ,
    //---- DMA R  --------------------------------
    output logic [AXI_DW-1     : 0] dma_rdata    ,
    output logic                    dma_rlast    ,
    output logic                    dma_rvalid   ,
    input  logic                    dma_rready    
);

timeunit 1ns;
timeprecision 1ps;

//---- USER W  -----------------------
logic [AXI_DW-1     : 0] usr_wdata   ;
logic [AXI_WSTRBW-1 : 0] usr_wstrb   ;
logic                    usr_wlast   ;
logic                    usr_wvalid  ;
logic                    usr_wready  ;
//---- USER R  -----------------------
logic [AXI_DW-1     : 0] usr_rdata   ;
logic                    usr_rlast   ;
logic                    usr_rvalid  ;
logic                    usr_rready  ;
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
//---- USER R ------------------------
logic [AXI_IW-1     : 0] usr_rid     ;
logic [AXI_RRESPW-1 : 0] usr_rresp   ;

// DMA W
assign usr_wdata  = dma_wdata ;
assign usr_wstrb  = dma_wstrb ;
assign usr_wlast  = dma_wlast ;
assign usr_wvalid = dma_wvalid;
assign dma_wready = usr_wready;
// DMA R
assign dma_rdata  = usr_rdata ;
assign dma_rlast  = usr_rlast ;
assign dma_rvalid = usr_rvalid;
assign usr_rready = dma_rready; 

assign {AWLOCK, AWCACHE, AWPROT, AWQOS, AWREGION} = {1'b0, 4'b0001, 3'b000, 4'b0000}; 
assign {ARLOCK, ARCACHE, ARPROT, ARQOS, ARREGION} = {1'b0, 4'b0001, 3'b000, 4'b0000};
assign usr_bready = 1'b1      ; // always ready to receive B channel output

axlen_partition #(
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
    .AXI_BYTESW ( AXI_BYTESW ),
    .BL         ( BL         ),
    .L          ( L          ),
    .B          ( B          )
) arlen_partition (
    .clk         ( usr_clk                ),
    .reset_n     ( usr_reset_n            ),

    .dma_valid   ( dmar_valid             ),
    .dma_ready   ( dmar_ready             ),
    .dma_sa      ( dmar_sa                ),
    .dma_len     ( dmar_len               ),
    .dma_irq_w1c ( dmar_irq_w1c           ),
    .dma_irq     ( dmar_irq               ),
    .dma_err     ( dmar_err               ),

    .axid        ( usr_arid               ),
    .axaddr      ( usr_araddr             ),
    .axlen       ( usr_arlen              ),
    .axsize      ( usr_arsize             ),
    .axburst     ( usr_arburst            ),
    .axvalid     ( usr_arvalid            ),
    .axready     ( usr_arready            ),

    .usr_bid     ( usr_rid                ),
    .usr_bresp   ( usr_rresp              ),     
    .usr_bvalid  ( usr_rvalid & usr_rlast ),
    .usr_bready  ( usr_rready             ) 
);

axlen_partition #(
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
    .AXI_BYTESW ( AXI_BYTESW ),
    .BL         ( BL         ),
    .L          ( L          ),
    .B          ( B          )
) awlen_partition (
    .clk         ( usr_clk      ),
    .reset_n     ( usr_reset_n  ),

    .dma_valid   ( dmaw_valid   ),
    .dma_ready   ( dmaw_ready   ),
    .dma_sa      ( dmaw_sa      ),
    .dma_len     ( dmaw_len     ),
    .dma_irq_w1c ( dmaw_irq_w1c ),
    .dma_irq     ( dmaw_irq     ),
    .dma_err     ( dmaw_err     ),

    .axid        ( usr_awid     ),
    .axaddr      ( usr_awaddr   ),
    .axlen       ( usr_awlen    ),
    .axsize      ( usr_awsize   ),
    .axburst     ( usr_awburst  ),
    .axvalid     ( usr_awvalid  ),
    .axready     ( usr_awready  ), 

    .usr_bid     ( usr_bid      ),
    .usr_bresp   ( usr_bresp    ),     
    .usr_bvalid  ( usr_bvalid   ),
    .usr_bready  ( usr_bready   ) 
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
    .AXI_BYTESW ( AXI_BYTESW ),
    .BL         ( BL         ),
    .L          ( L          ),
    .B          ( B          )
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
    .AXI_BYTESW ( AXI_BYTESW ),
    .BL         ( BL         ),
    .L          ( L          ),
    .B          ( B          )
) r_inf (
    .*
);

// --debug
//always_ff @(posedge usr_clk)
//    if(usr_rvalid & usr_rready)
//        $display("%m: %0t: usr_rdata = %0d", $realtime, usr_rdata);
//initial begin
//while(1) begin
//    while(1'b1!==(usr_rvalid&usr_rready)) @(posedge usr_clk);
//    $display("%m: %0t: usr_rvalid = %b; usr_rready = %b; usr_rdata = %0d", $realtime, usr_rvalid, usr_rready, usr_rdata);
//    @(posedge usr_clk);
//end
//end
endmodule
