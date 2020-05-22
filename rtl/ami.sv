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
    //---- CONFIG GLOBAL -------------------------
    input  logic                    bm           , // dma batch mode. 1~configure with "dmaw_*" and "dmar_*" ports; 0~configure with "usr_*" ports
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
    //---- USR AW --------------------------------
    input  logic [AXI_AW-1     : 0] usr_awaddr   ,
    input  logic [AXI_LW-1     : 0] usr_awlen    ,
    input  logic                    usr_awvalid  ,
    output logic                    usr_awready  ,
    //---- USR W  --------------------------------
    input  logic [AXI_DW-1     : 0] usr_wdata    ,
    input  logic [AXI_WSTRBW-1 : 0] usr_wstrb    ,
    input  logic                    usr_wlast    ,
    input  logic                    usr_wvalid   ,
    output logic                    usr_wready   ,
    //---- USER B  -------------------------------
    output logic [AXI_IW-1     : 0] usr_bid      ,
    output logic [AXI_BRESPW-1 : 0] usr_bresp    ,
    output logic                    usr_bvalid   ,
    input  logic                    usr_bready   ,
    //---- DIRECT CONFIG DMA READ ----------------
    input  logic [AXI_AW-1     : 0] usr_araddr   ,
    input  logic [AXI_LW-1     : 0] usr_arlen    ,
    input  logic                    usr_arvalid  ,
    output logic                    usr_arready  ,
    //---- USR R  --------------------------------
    output logic [AXI_IW-1     : 0] usr_rid      ,
    output logic [AXI_DW-1     : 0] usr_rdata    ,
    output logic [AXI_RRESPW-1 : 0] usr_rresp    ,
    output logic                    usr_rlast    ,
    output logic                    usr_rvalid   ,
    input  logic                    usr_rready    
);

timeunit 1ns;
timeprecision 1ps;

localparam AXID = 1;

//---- ami_w -------------------------
logic [AXI_IW-1     : 0] ami_awid    ;
logic [AXI_AW-1     : 0] ami_awaddr  ;
logic [AXI_LW-1     : 0] ami_awlen   ;
logic [AXI_SW-1     : 0] ami_awsize  ;
logic [AXI_BURSTW-1 : 0] ami_awburst ;
logic                    ami_awvalid ;
logic                    ami_awready ;
//---- ami_r -------------------------
logic [AXI_IW-1     : 0] ami_arid    ;
logic [AXI_AW-1     : 0] ami_araddr  ;
logic [AXI_LW-1     : 0] ami_arlen   ;
logic [AXI_SW-1     : 0] ami_arsize  ;
logic [AXI_BURSTW-1 : 0] ami_arburst ;
logic                    ami_arvalid ;
logic                    ami_arready ;

//---- partion config ----------------
logic                    parw_ready  ;
logic                    parr_ready  ;
//---- partion AR --------------------
logic [AXI_IW-1     : 0] par_arid    ;
logic [AXI_AW-1     : 0] par_araddr  ;
logic [AXI_LW-1     : 0] par_arlen   ;
logic [AXI_SW-1     : 0] par_arsize  ;
logic [AXI_BURSTW-1 : 0] par_arburst ;
logic                    par_arvalid ;
logic                    par_arready ;
//---- partion AW --------------------
logic [AXI_IW-1     : 0] par_awid    ;
logic [AXI_AW-1     : 0] par_awaddr  ;
logic [AXI_LW-1     : 0] par_awlen   ;
logic [AXI_SW-1     : 0] par_awsize  ;
logic [AXI_BURSTW-1 : 0] par_awburst ;
logic                    par_awvalid ;
logic                    par_awready ;

// dma config
assign dmaw_ready  = bm ? parw_ready : 1'b0;
assign dmar_ready  = bm ? parr_ready : 1'b0;

// ami_w
assign ami_awid    = bm ? par_awid    : AXID;
assign ami_awaddr  = bm ? par_awaddr  : usr_awaddr;
assign ami_awlen   = bm ? par_awlen   : usr_awlen;
assign ami_awsize  = bm ? par_awsize  : $clog2(AXI_BYTES);
assign ami_awburst = bm ? par_awburst : 1;
assign ami_awvalid = bm ? par_awvalid : usr_awvalid;
assign par_awready = bm ? ami_awready : 1'b0;
assign usr_awready = bm ? 1'b0 : ami_awready;

// ami_r
assign ami_arid    = bm ? par_arid    : AXID;
assign ami_araddr  = bm ? par_araddr  : usr_araddr;
assign ami_arlen   = bm ? par_arlen   : usr_arlen;
assign ami_arsize  = bm ? par_arsize  : $clog2(AXI_BYTES);
assign ami_arburst = bm ? par_arburst : 1;
assign ami_arvalid = bm ? par_arvalid : usr_arvalid;
assign par_arready = bm ? ami_arready : 1'b0;
assign usr_arready = bm ? 1'b0 : ami_arready;

assign {AWLOCK, AWCACHE, AWPROT, AWQOS, AWREGION} = {1'b0, 4'b0001, 3'b000, 4'b0000}; 
assign {ARLOCK, ARCACHE, ARPROT, ARQOS, ARREGION} = {1'b0, 4'b0001, 3'b000, 4'b0000};

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
    .B          ( B          ),
    .AXID       ( AXID       )
) arlen_partition (
    .clk         ( usr_clk                     ),
    .reset_n     ( usr_reset_n & bm            ),

    .dma_valid   ( dmar_valid & bm             ),
    .dma_ready   ( parr_ready                  ),
    .dma_sa      ( dmar_sa                     ),
    .dma_len     ( dmar_len                    ),
    .dma_irq_w1c ( dmar_irq_w1c                ),
    .dma_irq     ( dmar_irq                    ),
    .dma_err     ( dmar_err                    ),

    .axid        ( par_arid                    ),
    .axaddr      ( par_araddr                  ),
    .axlen       ( par_arlen                   ),
    .axsize      ( par_arsize                  ),
    .axburst     ( par_arburst                 ),
    .axvalid     ( par_arvalid                 ),
    .axready     ( par_arready                 ),

    .usr_bid     ( usr_rid                     ),
    .usr_bresp   ( usr_rresp                   ),     
    .usr_bvalid  ( usr_rvalid & usr_rlast & bm ),
    .usr_bready  ( usr_rready                  ) 
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
    .B          ( B          ),
    .AXID       ( AXID       )
) awlen_partition (
    .clk         ( usr_clk          ),
    .reset_n     ( usr_reset_n & bm ),

    .dma_valid   ( dmaw_valid & bm  ),
    .dma_ready   ( parw_ready       ),
    .dma_sa      ( dmaw_sa          ),
    .dma_len     ( dmaw_len         ),
    .dma_irq_w1c ( dmaw_irq_w1c     ),
    .dma_irq     ( dmaw_irq         ),
    .dma_err     ( dmaw_err         ),

    .axid        ( par_awid         ),
    .axaddr      ( par_awaddr       ),
    .axlen       ( par_awlen        ),
    .axsize      ( par_awsize       ),
    .axburst     ( par_awburst      ),
    .axvalid     ( par_awvalid      ),
    .axready     ( par_awready      ), 

    .usr_bid     ( usr_bid          ),
    .usr_bresp   ( usr_bresp        ),     
    .usr_bvalid  ( usr_bvalid & bm  ),
    .usr_bready  ( usr_bready       ) 
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
    .*,

    .usr_awid    ( ami_awid    ),
    .usr_awaddr  ( ami_awaddr  ),
    .usr_awlen   ( ami_awlen   ),
    .usr_awsize  ( ami_awsize  ),
    .usr_awburst ( ami_awburst ),
    .usr_awvalid ( ami_awvalid ),
    .usr_awready ( ami_awready ),

    .usr_wdata   ( usr_wdata   ),
    .usr_wstrb   ( usr_wstrb   ),
    .usr_wlast   ( usr_wlast   ),
    .usr_wvalid  ( usr_wvalid  ),
    .usr_wready  ( usr_wready  ),

    .usr_bid     ( usr_bid     ),
    .usr_bresp   ( usr_bresp   ),
    .usr_bvalid  ( usr_bvalid  ),
    .usr_bready  ( usr_bready  ) 
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
    .*,

    .usr_arid    ( ami_arid    ),
    .usr_araddr  ( ami_araddr  ),
    .usr_arlen   ( ami_arlen   ),
    .usr_arsize  ( ami_arsize  ),
    .usr_arburst ( ami_arburst ),
    .usr_arvalid ( ami_arvalid ),
    .usr_arready ( ami_arready ),

    .usr_rid     ( usr_rid     ),
    .usr_rdata   ( usr_rdata   ),
    .usr_rresp   ( usr_rresp   ),
    .usr_rlast   ( usr_rlast   ),
    .usr_rvalid  ( usr_rvalid  ),
    .usr_rready  ( usr_rready  ) 
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
