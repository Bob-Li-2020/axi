//-- AUTHOR: LIBING
//-- DATE: 2019.12
//-- DESCRIPTION: AXI SLAVE INTERFACE WITH A SINGLE-PORT RAM.
//----------------------PROTOCOL: AXI4. "AMBA AXI and ACE Protocol Specification, 30 July 2019"
//----------------------SUPPORTED FEATURES: 
//----------------------                         1) INDEPENDENT AW CHANNEL / W CHANNEL;
//----------------------                         2) INDEPENDENT AW CHANNEL / AR CHANNEL; 
//----------------------                         3) NARROW/UNALIGNED TRANSFERS; 
//----------------------                         4) WRITE BYTE STROBES;
//----------------------                         *) SPRAM READ/WRITE ARBITER.
//----------------------NOT SUPPORTED FEATURES: 
//----------------------                         1) READ DATA RE-ORDERING;
//----------------------                         2) INTERLEAVED WRITE TRANSFERS.
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
    AXI_BYTESW = $clog2(AXI_BYTES+1)   
)(
    //---- AXI GLOBAL --------------------------
    input  logic                    ACLK       ,
    input  logic                    ARESETn    ,
    //---- AXI ADDRESS WRITE -------------------
    input  logic [AXI_IW-1     : 0] AWID       ,
    input  logic [AXI_AW-1     : 0] AWADDR     ,
    input  logic [AXI_LW-1     : 0] AWLEN      ,
    input  logic [AXI_SW-1     : 0] AWSIZE     ,
    input  logic [AXI_BURSTW-1 : 0] AWBURST    ,
    input  logic                    AWVALID    ,
    output logic                    AWREADY    ,
    input  logic                    AWLOCK     , // NO LOADS 
    input  logic [3            : 0] AWCACHE    , // NO LOADS
    input  logic [2            : 0] AWPROT     , // NO LOADS
    input  logic [3            : 0] AWQOS      , // NO LOADS
    input  logic [3            : 0] AWREGION   , // NO LOADS
    //---- AXI DATA WRITE ----------------------
    input  logic [AXI_DW-1     : 0] WDATA      ,
    input  logic [AXI_WSTRBW-1 : 0] WSTRB      ,
    input  logic                    WLAST      ,
    input  logic                    WVALID     ,
    output logic                    WREADY     ,
    //---- AXI WRITE RESPONSE ------------------
    output logic [AXI_IW-1     : 0] BID        ,
    output logic [AXI_BRESPW-1 : 0] BRESP      ,
    output logic                    BVALID     ,
    input  logic                    BREADY     ,
    //---- AXI ADDRESS READ --------------------
    input  logic [AXI_IW-1     : 0] ARID       ,
    input  logic [AXI_AW-1     : 0] ARADDR     ,
    input  logic [AXI_LW-1     : 0] ARLEN      ,
    input  logic [AXI_SW-1     : 0] ARSIZE     ,
    input  logic [AXI_BURSTW-1 : 0] ARBURST    ,
    input  logic                    ARVALID    ,
    output logic                    ARREADY    ,
    input  logic                    ARLOCK     , // NO LOADS 
    input  logic [3            : 0] ARCACHE    , // NO LOADS 
    input  logic [2            : 0] ARPROT     , // NO LOADS 
    input  logic [3            : 0] ARQOS      , // NO LOADS 
    input  logic [3            : 0] ARREGION   , // NO LOADS
    //---- AXI READ DATA -----------------------
    output logic [AXI_IW-1     : 0] RID        ,
    output logic [AXI_DW-1     : 0] RDATA      ,
    output logic [AXI_RRESPW-1 : 0] RRESP      ,
    output logic                    RLAST      ,
    output logic                    RVALID     ,
    input  logic                    RREADY     ,
    //---- RAM INTERFACE -----------------------
    input  logic                    RAM_CLK    ,
    input  logic                    RAM_RESETn ,
    output logic [AXI_AW-1     : 0] RAM_A      , // RAM Address
    output logic                    RAM_CEN    , // RAM Clock Enable. Active-Low
    output logic [AXI_DW-1     : 0] RAM_D      , // RAM D
    output logic [AXI_WSTRBW-1 : 0] RAM_WEN    , // RAM Write Enable. Active-Low
    input  logic [AXI_DW-1     : 0] RAM_Q        // RAM Q
);

timeunit 1ns;
timeprecision 1ps;

typedef enum logic [1:0] { ARB_IDLE=2'b00, ARB_READ, ARB_WRITE } TYPE_ARB;
typedef enum logic { RGNT=1'b0, WGNT } TYPE_GNT;

//--------------------------------------
//------ r_inf/w_inf SIGNALS -----------
//--------------------------------------
logic [AXI_AW-1     : 0] m_addr        ;
logic [AXI_DW-1     : 0] m_wdata       ;
logic [AXI_WSTRBW-1 : 0] m_wstrb       ;
logic                    m_we          ;
logic [AXI_DW-1     : 0] m_rdata       ;
logic                    m_re          ; // asi read request("m_raddr" valid)
//--------------------------------------
//------ EASY SIGNALS ------------------
//--------------------------------------
logic                    rlast         ;
logic                    wlast         ;
logic                    arff_v        ;
logic                    awff_v        ;
//--------------------------------------
//------ asi SIGNALS -------------------
//--------------------------------------
//ARBITER SIGNALS
logic                    m_arff_rvalid ; // (AR FIFO NOT EMPTY) && (BP_st_cur==BP_FIRST)
logic                    m_awff_rvalid ; // (AW FIFO NOT EMPTY) && (BP_st_cur==BP_FIRST)
logic                    m_rgranted    ;
logic                    m_wgranted    ;
//ERROR FLAGS
logic                    m_wsize_error ; // unsupported transfer size
logic                    m_rsize_error ; // unsupported transfer size
//AW CHANNEL
logic [AXI_IW-1     : 0] m_wid         ;
logic [AXI_LW-1     : 0] m_wlen        ;
logic [AXI_SW-1     : 0] m_wsize       ;
logic [AXI_BURSTW-1 : 0] m_wburst      ;
//W CHANNEL
logic                    m_wlast       ;
//AR CHANNEL
logic [AXI_IW-1     : 0] m_rid         ;
logic [AXI_LW-1     : 0] m_rlen        ;
logic [AXI_SW-1     : 0] m_rsize       ;
logic [AXI_BURSTW-1 : 0] m_rburst      ;
//R CHANNEL
logic                    m_rlast       ; // asi read request last cycle
//ADDRESSES
logic [AXI_AW-1     : 0] m_waddr       ;
logic [AXI_AW-1     : 0] m_raddr       ;
//--------------------------------------
//------ ARBITER STATE MACHINE ---------
//--------------------------------------
TYPE_ARB st_cur;
TYPE_ARB st_nxt;
//------------------------------------
//---- TOP PORTS ASSIGN --------------
//------------------------------------
assign RAM_A         = m_addr           ; // address
assign RAM_CEN       = ~(m_we | m_re)   ; // clock enable
assign RAM_D         = m_wdata          ; // data
assign RAM_WEN       = ~(m_wstrb & {AXI_WSTRBW{m_we}}); // write enable
assign m_rdata       = RAM_Q            ; // Q

assign m_wsize_error = 1'b0             ;
assign m_rsize_error = 1'b0             ;
//------------------------------------
//------ EASY SIGNALS ASSIGN ---------
//------------------------------------
assign rlast         = m_rlast          ;
assign wlast         = m_wlast          ;
assign arff_v        = m_arff_rvalid    ;
assign awff_v        = m_awff_rvalid    ;
//------------------------------------
//------ ARBITER STATE MACHINE -------
//------------------------------------
assign m_addr        = m_we ? m_waddr : m_raddr;
assign m_rgranted    = st_cur==ARB_READ ; 
assign m_wgranted    = st_cur==ARB_WRITE;

always_ff @(posedge RAM_CLK or negedge RAM_RESETn) begin
    if(!RAM_RESETn) begin
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
            if(arff_v & (!awff_v | ASI_ARB))
                st_nxt = ARB_READ;
            if(awff_v & (!arff_v | !ASI_ARB))
                st_nxt = ARB_WRITE;
        end
        ARB_READ: st_nxt = rlast ? (awff_v ? ARB_WRITE : ARB_IDLE) : st_cur;
        ARB_WRITE: st_nxt = wlast ? (arff_v ? ARB_READ : ARB_IDLE) : st_cur;
        default: st_nxt = ARB_IDLE;
    endcase
end

//------------------------------------
//------ asi_w/r INSTANCES -----------
//------------------------------------
asi_w #(
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
) r_inf ( 
    .*
);

endmodule


