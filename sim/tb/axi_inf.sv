interface axi_inf import axi_pkg::*;
    (
        //---- AXI GLOBAL SIGNALS ---------
        input logic                    ACLK    ,
        input logic                    ARESETn   
    );
    //---- AXI ADDRESS WRITE SIGNALS --
    logic [AXI_IW-1     : 0] AWID     ;
    logic [AXI_AW-1     : 0] AWADDR   ;
    logic [AXI_LW-1     : 0] AWLEN    ;
    logic [AXI_SW-1     : 0] AWSIZE   ;
    logic [AXI_BURSTW-1 : 0] AWBURST  ;
    logic                    AWVALID  ;
    logic                    AWREADY  ;
    logic                    AWLOCK   ;  
    logic [3            : 0] AWCACHE  ; 
    logic [2            : 0] AWPROT   ; 
    logic [3            : 0] AWQOS    ; 
    logic [3            : 0] AWREGION ; 
    //---- AXI DATA WRITE SIGNALS -----
    logic [AXI_DW-1     : 0] WDATA    ;
    logic [AXI_WSTRBW-1 : 0] WSTRB    ;
    logic                    WLAST    ;
    logic                    WVALID   ;
    logic                    WREADY   ;
    //---- AXI WRITE RESPONSE SIGNALS -
    logic [AXI_IW-1     : 0] BID      ;
    logic [AXI_BRESPW-1 : 0] BRESP    ;
    logic                    BVALID   ;
    logic                    BREADY   ;
    //---- READ ADDRESS CHANNEL -------
    logic [AXI_IW-1     : 0] ARID     ;
    logic [AXI_AW-1     : 0] ARADDR   ;
    logic [AXI_LW-1     : 0] ARLEN    ;
    logic [AXI_SW-1     : 0] ARSIZE   ;
    logic [AXI_BURSTW-1 : 0] ARBURST  ;
    logic                    ARVALID  ;
    logic                    ARREADY  ;
    logic                    ARLOCK   ;  
    logic [3            : 0] ARCACHE  ;  
    logic [2            : 0] ARPROT   ;  
    logic [3            : 0] ARQOS    ;  
    logic [3            : 0] ARREGION ; 
    //---- READ DATA CHANNEL ----------
    logic [AXI_IW-1     : 0] RID      ;
    logic [AXI_DW-1     : 0] RDATA    ;
    logic [AXI_RRESPW-1 : 0] RRESP    ;
    logic                    RLAST    ;
    logic                    RVALID   ;
    logic                    RREADY   ;    

    modport master (
        input  ACLK,ARESETn,AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID,AWLOCK,AWCACHE,AWPROT,AWQOS,AWREGION,WDATA,WSTRB,WLAST,WVALID,BREADY,ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID,ARLOCK,ARCACHE,ARPROT,ARQOS,ARREGION,RREADY,
        output AWREADY,WREADY,BID,BRESP,BVALID,ARREADY,RID,RDATA,RRESP,RLAST,RVALID    
    );
    modport slave (
        input  ACLK,ARESETn,AWREADY,WREADY,BID,BRESP,BVALID,ARREADY,RID,RDATA,RRESP,RLAST,RVALID    
        output AWID,AWADDR,AWLEN,AWSIZE,AWBURST,AWVALID,AWLOCK,AWCACHE,AWPROT,AWQOS,AWREGION,WDATA,WSTRB,WLAST,WVALID,BREADY,ARID,ARADDR,ARLEN,ARSIZE,ARBURST,ARVALID,ARLOCK,ARCACHE,ARPROT,ARQOS,ARREGION,RREADY,
    );

endinterface: axi_inf
