package test_pkg;
    //-- RAM
    localparam
    RAM_SZ = 512 , // RAM DEPTH 
    RAM_BW = 8 , // BYTE WIDTH
    RAM_BS = AXI_BYTES , // BYTES NUMBER IN A WORD
    RAM_QX = 1 , // 
    RAM_WS = 1 , // READ WAIT STATES
    //--- derived parameters
    RAM_AW = $clog2(RAM_SZ) , 
    RAM_DW = RAM_BW*RAM_BS ,
    //--------- ASI CONFIGURE --------
    ASI_AD     = 4                   , // ASI AW/AR CHANNEL BUFFER DEPTH
    ASI_RD     = 64                  , // ASI R CHANNEL BUFFER DEPTH
    ASI_WD     = 64                  , // ASI W CHANNEL BUFFER DEPTH
    ASI_BD     = 4                   , // ASI B CHANNEL BUFFER DEPTH
    ASI_ARB    = 0                   , // 1-GRANT READ WITH HIGHER PRIORITY; 0-GRANT WRITE WITH HIGHER PRIORITY
    //--------- SLAVE ATTRIBUTES -----
    SLV_WS     = 1                   , // SLAVE MODEL READ WAIT STATES CYCLE
    //--------- AMI CONFIGURE --------
    AMI_OD     = 4                   , // AMI OUTSTANDING DEPTH
    AMI_AD     = 4                   , // AMI AW/AR CHANNEL BUFFER DEPTH
    AMI_RD     = 64                  , // AMI R CHANNEL BUFFER DEPTH
    AMI_WD     = 64                  , // AMI W CHANNEL BUFFER DEPTH
    AMI_BD     = 4                   ; // AMI B CHANNEL BUFFER DEPTH
endpackage: test_pkg
