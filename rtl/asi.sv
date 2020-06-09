//-- AUTHOR: LIBING
//-- DATE: 2019.12
//-- DESCRIPTION: AXI SLAVE INTERFACE WITH A SINGLE-PORT RAM.
//----------------------PROTOCOL: AXI4. "AMBA AXI and ACE Protocol Specification, 30 July 2019"
//----------------------SUPPORTED FEATURES: 
//----------------------                         1) INDEPENDENT AW CHANNEL / W CHANNEL;
//----------------------                         2) INDEPENDENT AW CHANNEL / AR CHANNEL; 
//----------------------                         3) NARROW/UNALIGNED TRANSFERS; 
//----------------------                         4) WRITE BYTE STROBES;
//----------------------                         5) 4KB boundary error response;
//----------------------                         *) SPRAM READ/WRITE ARBITER.
//----------------------NOT SUPPORTED FEATURES: 
//----------------------                         1) READ DATA RE-ORDERING;
//----------------------BRESP:
//----------------------        2'b00: OKAY;
//----------------------        2'b01: EXOKAY. NOT supported;
//----------------------        2'b10: SLVERR; 
//----------------------        2'b00: DECERR. NOT supported.
//----------------------AxBURST:
//----------------------        2'b00: FIX;      NOT supported;
//----------------------        2'b01: INCR;   
//----------------------        2'b10: WRAP;     NOT supported;
//----------------------        2'b00: RESERVED. NOT supported;

// asi: Axi Slave Interface
module asi
#(
    //--------- AXI PARAMETERS -------
    AXI_DW     = 128                 , // AXI DATA    BUS WIDTH
    AXI_AW     = 32                  , // AXI ADDRESS BUS WIDTH
    AXI_IW     = 8                   , // AXI ID TAG  BITS WIDTH
    AXI_LW     = 8                   , // AXI AWLEN   BITS WIDTH
    AXI_SW     = 3                   , // AXI AWSIZE  BITS WIDTH
    //--------- ASI CONFIGURE --------
    ASI_AD     = 8                  , // ASI AW/AR CHANNEL BUFFER DEPTH
    ASI_RD     = 16                  , // ASI R CHANNEL BUFFER DEPTH
    ASI_WD     = 16                  , // ASI W CHANNEL BUFFER DEPTH
    ASI_BD     = 8                  , // ASI B CHANNEL BUFFER DEPTH
    ASI_ARB    = 0                   , // 0-GRANT WRITE WITH HIGHER PRIORITY; otherwise-GRANT READ WITH HIGHER PRIORITY
    //--------- SLAVE ATTRIBUTES -----
    SLV_WS     = 1                   , // SLAVE MODEL READ WAIT STATES CYCLE
    //-------- DERIVED PARAMETERS ----
    AXI_BYTES  = AXI_DW/8            , // BYTES NUMBER IN <AXI_DW>
    AXI_WSTRBW = AXI_BYTES           , // AXI WSTRB BITS WIDTH
    AXI_BYTESW = $clog2(AXI_BYTES+1)   
)(
    //---- AXI GLOBAL ---------------------------
    input  logic                    ACLK        ,
    input  logic                    ARESETn     ,
    //---- AXI ADDRESS WRITE --------------------
    input  logic [AXI_IW-1     : 0] AWID        ,
    input  logic [AXI_AW-1     : 0] AWADDR      ,
    input  logic [AXI_LW-1     : 0] AWLEN       ,
    input  logic [AXI_SW-1     : 0] AWSIZE      ,
    input  logic [1 : 0] AWBURST     ,
    input  logic                    AWVALID     ,
    output logic                    AWREADY     ,
    input  logic                    AWLOCK      , // NO LOADS 
    input  logic [3            : 0] AWCACHE     , // NO LOADS
    input  logic [2            : 0] AWPROT      , // NO LOADS
    input  logic [3            : 0] AWQOS       , // NO LOADS
    input  logic [3            : 0] AWREGION    , // NO LOADS
    //---- AXI DATA WRITE -----------------------
    input  logic [AXI_DW-1     : 0] WDATA       ,
    input  logic [AXI_WSTRBW-1 : 0] WSTRB       ,
    input  logic                    WLAST       ,
    input  logic                    WVALID      ,
    output logic                    WREADY      ,
    //---- AXI WRITE RESPONSE -------------------
    output logic [AXI_IW-1     : 0] BID         ,
    output logic [1 : 0] BRESP       ,
    output logic                    BVALID      ,
    input  logic                    BREADY      ,
    //---- AXI ADDRESS READ ---------------------
    input  logic [AXI_IW-1     : 0] ARID        ,
    input  logic [AXI_AW-1     : 0] ARADDR      ,
    input  logic [AXI_LW-1     : 0] ARLEN       ,
    input  logic [AXI_SW-1     : 0] ARSIZE      ,
    input  logic [1 : 0] ARBURST     ,
    input  logic                    ARVALID     ,
    output logic                    ARREADY     ,
    input  logic                    ARLOCK      , // NO LOADS 
    input  logic [3            : 0] ARCACHE     , // NO LOADS 
    input  logic [2            : 0] ARPROT      , // NO LOADS 
    input  logic [3            : 0] ARQOS       , // NO LOADS 
    input  logic [3            : 0] ARREGION    , // NO LOADS
    //---- AXI READ DATA ------------------------
    output logic [AXI_IW-1     : 0] RID         ,
    output logic [AXI_DW-1     : 0] RDATA       ,
    output logic [1 : 0] RRESP       ,
    output logic                    RLAST       ,
    output logic                    RVALID      ,
    input  logic                    RREADY      ,
    //---- RAM INTERFACE ------------------------
    input  logic                    usr_clk     ,
    input  logic                    usr_reset_n ,
    output logic                    RAM_CEN     , // RAM Clock Enable. Active-Low
    output logic [AXI_WSTRBW-1 : 0] RAM_WEN     , // RAM Write Enable. Active-Low
    output logic [AXI_AW-1     : 0] RAM_A       , // RAM Address
    output logic [AXI_DW-1     : 0] RAM_D       , // RAM D
    input  logic [AXI_DW-1     : 0] RAM_Q         // RAM Q
);

timeunit 1ns;
timeprecision 1ps;

enum logic [1:0] { ARB_IDLE=2'b00, ARB_READ, ARB_WRITE } st_cur, st_nxt; // arbiter state machine

//AW CHANNEL
logic [AXI_IW-1     : 0] usr_wid         ; // output 
logic [AXI_LW-1     : 0] usr_wlen        ; // output 
logic [AXI_SW-1     : 0] usr_wsize       ; // output 
logic [1 : 0] usr_wburst      ; // output 
//W CHANNEL
logic [AXI_AW-1     : 0] usr_waddr       ; // output 
logic [AXI_DW-1     : 0] usr_wdata       ; // output 
logic [AXI_WSTRBW-1 : 0] usr_wstrb       ; // output 
logic                    usr_wlast       ; // output 
logic                    usr_we          ; // output 
//ARBITER SIGNALS
logic                    usr_wrequest    ; // output. arbiter write request
logic                    usr_wgrant      ; // input.  arbiter write grant
//ERROR FLAGS
logic                    usr_wsize_error ; // input. unsupported transfer size
//AR CHANNEL
logic [AXI_IW-1     : 0] usr_rid         ; // output  
logic [AXI_LW-1     : 0] usr_rlen        ; // output 
logic [AXI_SW-1     : 0] usr_rsize       ; // output 
logic [1 : 0] usr_rburst      ; // output 
//R CHANNEL
logic [AXI_AW-1     : 0] usr_raddr       ; // output  
logic                    usr_re          ; // output 
logic                    usr_rlast       ; // output 
logic [AXI_DW-1     : 0] usr_rdata       ; // input  
//ARBITER SIGNALS
logic                    usr_rrequest    ; // output. arbiter read request
logic                    usr_rgrant      ; // input.  arbiter read grant
//ERROR FLAGS
logic                    usr_rsize_error ; // input. unsupported transfer size

//---- TOP PORTS ASSIGN ------------------
assign RAM_A           = usr_we ? usr_waddr : usr_raddr; // address
assign RAM_CEN         = ~(usr_we | usr_re); // clock enable
assign RAM_D           = usr_wdata         ; // write data
assign RAM_WEN         = ~(usr_wstrb & {AXI_WSTRBW{usr_we}}); // write enable

assign usr_wgrant      = st_cur==ARB_WRITE ;
assign usr_wsize_error = 1'b0              ;
assign usr_rdata       = RAM_Q             ;
assign usr_rgrant      = st_cur==ARB_READ  ; 
assign usr_rsize_error = 1'b0              ;

always_ff @(posedge usr_clk or negedge usr_reset_n) begin
    if(!usr_reset_n) begin
        st_cur <= ARB_IDLE;
    end
    else begin
        st_cur <= st_nxt;
    end
end

always_comb begin
    case(st_cur)
        ARB_IDLE: begin
            st_nxt = st_cur;
            if(usr_rrequest & (!usr_wrequest || ASI_ARB!=0))
                st_nxt = ARB_READ;
            if(usr_wrequest & (!usr_rrequest || ASI_ARB==0))
                st_nxt = ARB_WRITE;
        end
        ARB_READ : st_nxt = usr_rlast & (usr_wrequest | ~usr_rrequest) ? (usr_wrequest ? ARB_WRITE : ARB_IDLE) : st_cur;
        ARB_WRITE: st_nxt = usr_wlast & (usr_rrequest | ~usr_wrequest) ? (usr_rrequest ? ARB_READ  : ARB_IDLE) : st_cur;
        default: st_nxt = ARB_IDLE;
    endcase
end

asi_w #(
//--------- AXI PARAMETERS -------
.AXI_DW     ( AXI_DW     ),
.AXI_AW     ( AXI_AW     ),
.AXI_IW     ( AXI_IW     ),
.AXI_LW     ( AXI_LW     ),
.AXI_SW     ( AXI_SW     ),
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
) w_inf ( 
    .*
);

asi_r #(
//--------- AXI PARAMETERS -------
.AXI_DW     ( AXI_DW     ),
.AXI_AW     ( AXI_AW     ),
.AXI_IW     ( AXI_IW     ),
.AXI_LW     ( AXI_LW     ),
.AXI_SW     ( AXI_SW     ),
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
) r_inf ( 
    .*
);

endmodule


