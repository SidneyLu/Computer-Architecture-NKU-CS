module mycpu_top(
    input  [ 5:0] int,
    input         aclk,
    input         aresetn,

    output [ 3:0] arid,
    output [31:0] araddr,
    output [ 7:0] arlen,
    output [ 2:0] arsize,
    output [ 1:0] arburst,
    output [ 1:0] arlock,
    output [ 3:0] arcache,
    output [ 2:0] arprot,
    output        arvalid,
    input         arready,

    input  [ 3:0] rid,
    input  [31:0] rdata,
    input  [ 1:0] rresp,
    input         rlast,
    input         rvalid,
    output        rready,

    output [ 3:0] awid,
    output [31:0] awaddr,
    output [ 7:0] awlen,
    output [ 2:0] awsize,
    output [ 1:0] awburst,
    output [ 1:0] awlock,
    output [ 3:0] awcache,
    output [ 2:0] awprot,
    output        awvalid,
    input         awready,

    output [ 3:0] wid,
    output [31:0] wdata,
    output [ 3:0] wstrb,
    output        wlast,
    output        wvalid,
    input         wready,

    input  [ 3:0] bid,
    input  [ 1:0] bresp,
    input         bvalid,
    output        bready,

    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

wire        inst_req;
wire        inst_wr;
wire [ 1:0] inst_size;
wire [ 3:0] inst_wstrb;
wire [31:0] inst_addr;
wire [31:0] inst_wdata;
wire        inst_addr_ok;
wire        inst_data_ok;
wire [31:0] inst_rdata;
wire        data_req;
wire        data_wr;
wire [ 1:0] data_size;
wire [ 3:0] data_wstrb;
wire [31:0] data_addr;
wire [31:0] data_wdata;
wire        data_addr_ok;
wire        data_data_ok;
wire [31:0] data_rdata;

wire [ 2:0] i_arid,    d_arid;
wire [31:0] i_araddr,  d_araddr;
wire [ 3:0] i_arlen,   d_arlen;
wire [ 2:0] i_arsize,  d_arsize;
wire [ 1:0] i_arburst, d_arburst;
wire [ 1:0] i_arlock,  d_arlock;
wire [ 3:0] i_arcache, d_arcache;
wire [ 2:0] i_arprot,  d_arprot;
wire        i_arvalid, d_arvalid;
wire        i_arready, d_arready;
wire [ 3:0] i_rid_w,   d_rid_w;
wire [ 2:0] i_rid,     d_rid;
wire [31:0] i_rdata,   d_rdata;
wire [ 1:0] i_rresp,   d_rresp;
wire        i_rlast,   d_rlast;
wire        i_rvalid,  d_rvalid;
wire        i_rready,  d_rready;
wire [ 2:0] i_awid,    d_awid;
wire [31:0] i_awaddr,  d_awaddr;
wire [ 3:0] i_awlen,   d_awlen;
wire [ 2:0] i_awsize,  d_awsize;
wire [ 1:0] i_awburst, d_awburst;
wire [ 1:0] i_awlock,  d_awlock;
wire [ 3:0] i_awcache, d_awcache;
wire [ 2:0] i_awprot,  d_awprot;
wire        i_awvalid, d_awvalid;
wire        i_awready, d_awready;
wire [ 2:0] i_wid,     d_wid;
wire [31:0] i_wdata,   d_wdata;
wire [ 3:0] i_wstrb,   d_wstrb;
wire        i_wlast,   d_wlast;
wire        i_wvalid,  d_wvalid;
wire        i_wready,  d_wready;
wire [ 3:0] i_bid_w,   d_bid_w;
wire [ 2:0] i_bid,     d_bid;
wire [ 1:0] i_bresp,   d_bresp;
wire        i_bvalid,  d_bvalid;
wire        i_bready,  d_bready;

wire [ 3:0] m_arlen;
wire [ 3:0] m_awlen;

`ifdef NATIVE_AXI
mycpu_core_axi core(
    .clk        (aclk    ),
    .resetn     (aresetn ),
    .hw_int     (int     ),
    .i_arid     (i_arid    ),
    .i_araddr   (i_araddr  ),
    .i_arlen    (i_arlen   ),
    .i_arsize   (i_arsize  ),
    .i_arburst  (i_arburst ),
    .i_arlock   (i_arlock  ),
    .i_arcache  (i_arcache ),
    .i_arprot   (i_arprot  ),
    .i_arvalid  (i_arvalid ),
    .i_arready  (i_arready ),
    .i_rid      (i_rid     ),
    .i_rdata    (i_rdata   ),
    .i_rresp    (i_rresp   ),
    .i_rlast    (i_rlast   ),
    .i_rvalid   (i_rvalid  ),
    .i_rready   (i_rready  ),
    .d_arid     (d_arid    ),
    .d_araddr   (d_araddr  ),
    .d_arlen    (d_arlen   ),
    .d_arsize   (d_arsize  ),
    .d_arburst  (d_arburst ),
    .d_arlock   (d_arlock  ),
    .d_arcache  (d_arcache ),
    .d_arprot   (d_arprot  ),
    .d_arvalid  (d_arvalid ),
    .d_arready  (d_arready ),
    .d_rid      (d_rid     ),
    .d_rdata    (d_rdata   ),
    .d_rresp    (d_rresp   ),
    .d_rlast    (d_rlast   ),
    .d_rvalid   (d_rvalid  ),
    .d_rready   (d_rready  ),
    .d_awid     (d_awid    ),
    .d_awaddr   (d_awaddr  ),
    .d_awlen    (d_awlen   ),
    .d_awsize   (d_awsize  ),
    .d_awburst  (d_awburst ),
    .d_awlock   (d_awlock  ),
    .d_awcache  (d_awcache ),
    .d_awprot   (d_awprot  ),
    .d_awvalid  (d_awvalid ),
    .d_awready  (d_awready ),
    .d_wid      (d_wid     ),
    .d_wdata    (d_wdata   ),
    .d_wstrb    (d_wstrb   ),
    .d_wlast    (d_wlast   ),
    .d_wvalid   (d_wvalid  ),
    .d_wready   (d_wready  ),
    .d_bid      (d_bid     ),
    .d_bresp    (d_bresp   ),
    .d_bvalid   (d_bvalid  ),
    .d_bready   (d_bready  ),
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);
assign i_awid    = 3'd0;
assign i_awaddr  = 32'd0;
assign i_awlen   = 4'd0;
assign i_awsize  = 3'd0;
assign i_awburst = 2'b01;
assign i_awlock  = 2'd0;
assign i_awcache = 4'd0;
assign i_awprot  = 3'd0;
assign i_awvalid = 1'b0;
assign i_wid     = 3'd0;
assign i_wdata   = 32'd0;
assign i_wstrb   = 4'd0;
assign i_wlast   = 1'b1;
assign i_wvalid  = 1'b0;
assign i_bready  = 1'b0;
`else
mycpu_core core(
    .clk              (aclk         ),
    .resetn           (aresetn      ),
    .hw_int           (int          ),
    .inst_sram_req    (inst_req     ),
    .inst_sram_wr     (inst_wr      ),
    .inst_sram_size   (inst_size    ),
    .inst_sram_wstrb  (inst_wstrb   ),
    .inst_sram_addr   (inst_addr    ),
    .inst_sram_wdata  (inst_wdata   ),
    .inst_sram_addr_ok(inst_addr_ok ),
    .inst_sram_data_ok(inst_data_ok ),
    .inst_sram_rdata  (inst_rdata   ),
    .data_sram_req    (data_req     ),
    .data_sram_wr     (data_wr      ),
    .data_sram_size   (data_size    ),
    .data_sram_wstrb  (data_wstrb   ),
    .data_sram_addr   (data_addr    ),
    .data_sram_wdata  (data_wdata   ),
    .data_sram_addr_ok(data_addr_ok ),
    .data_sram_data_ok(data_data_ok ),
    .data_sram_rdata  (data_rdata   ),
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

// S00 is the instruction port. S01 is the data port and has the higher
// arbitration priority, so a load or store is not stuck behind fetches.
sram2axi inst_axi(
    .clk      (aclk        ),
    .resetn   (aresetn     ),
    .req      (inst_req    ),
    .wr       (inst_wr     ),
    .size     (inst_size   ),
    .wstrb    (inst_wstrb  ),
    .addr     (inst_addr   ),
    .wdata    (inst_wdata  ),
    .addr_ok  (inst_addr_ok),
    .data_ok  (inst_data_ok),
    .rdata    (inst_rdata  ),
    .arid     (i_arid      ),
    .araddr   (i_araddr    ),
    .arlen    (i_arlen     ),
    .arsize   (i_arsize    ),
    .arburst  (i_arburst   ),
    .arlock   (i_arlock    ),
    .arcache  (i_arcache   ),
    .arprot   (i_arprot    ),
    .arvalid  (i_arvalid   ),
    .arready  (i_arready   ),
    .rid      (i_rid       ),
    .axi_rdata(i_rdata     ),
    .rresp    (i_rresp     ),
    .rlast    (i_rlast     ),
    .rvalid   (i_rvalid    ),
    .rready   (i_rready    ),
    .awid     (i_awid      ),
    .awaddr   (i_awaddr    ),
    .awlen    (i_awlen     ),
    .awsize   (i_awsize    ),
    .awburst  (i_awburst   ),
    .awlock   (i_awlock    ),
    .awcache  (i_awcache   ),
    .awprot   (i_awprot    ),
    .awvalid  (i_awvalid   ),
    .awready  (i_awready   ),
    .wid      (i_wid       ),
    .axi_wdata(i_wdata     ),
    .axi_wstrb(i_wstrb     ),
    .wlast    (i_wlast     ),
    .wvalid   (i_wvalid    ),
    .wready   (i_wready    ),
    .bid      (i_bid       ),
    .bresp    (i_bresp     ),
    .bvalid   (i_bvalid    ),
    .bready   (i_bready    )
);

sram2axi data_axi(
    .clk      (aclk        ),
    .resetn   (aresetn     ),
    .req      (data_req    ),
    .wr       (data_wr     ),
    .size     (data_size   ),
    .wstrb    (data_wstrb  ),
    .addr     (data_addr   ),
    .wdata    (data_wdata  ),
    .addr_ok  (data_addr_ok),
    .data_ok  (data_data_ok),
    .rdata    (data_rdata  ),
    .arid     (d_arid      ),
    .araddr   (d_araddr    ),
    .arlen    (d_arlen     ),
    .arsize   (d_arsize    ),
    .arburst  (d_arburst   ),
    .arlock   (d_arlock    ),
    .arcache  (d_arcache   ),
    .arprot   (d_arprot    ),
    .arvalid  (d_arvalid   ),
    .arready  (d_arready   ),
    .rid      (d_rid       ),
    .axi_rdata(d_rdata     ),
    .rresp    (d_rresp     ),
    .rlast    (d_rlast     ),
    .rvalid   (d_rvalid    ),
    .rready   (d_rready    ),
    .awid     (d_awid      ),
    .awaddr   (d_awaddr    ),
    .awlen    (d_awlen     ),
    .awsize   (d_awsize    ),
    .awburst  (d_awburst   ),
    .awlock   (d_awlock    ),
    .awcache  (d_awcache   ),
    .awprot   (d_awprot    ),
    .awvalid  (d_awvalid   ),
    .awready  (d_awready   ),
    .wid      (d_wid       ),
    .axi_wdata(d_wdata     ),
    .axi_wstrb(d_wstrb     ),
    .wlast    (d_wlast     ),
    .wvalid   (d_wvalid    ),
    .wready   (d_wready    ),
    .bid      (d_bid       ),
    .bresp    (d_bresp     ),
    .bvalid   (d_bvalid    ),
    .bready   (d_bready    )
);
`endif

// Each slave slot on the crossbar is ID_WIDTH bits. Only the low
// THREAD_ID_WIDTH bits carry the thread ID; the extra bit stays 0.
axi_crossbar_2x1 u_axi_crossbar_2x1(
    .aclk          (aclk   ),
    .aresetn       (aresetn),

    .s_axi_arid    ({1'b0, d_arid,    1'b0, i_arid   }),
    .s_axi_araddr  ({d_araddr,  i_araddr }),
    .s_axi_arlen   ({d_arlen,   i_arlen  }),
    .s_axi_arsize  ({d_arsize,  i_arsize }),
    .s_axi_arburst ({d_arburst, i_arburst}),
    .s_axi_arlock  ({d_arlock,  i_arlock }),
    .s_axi_arcache ({d_arcache, i_arcache}),
    .s_axi_arprot  ({d_arprot,  i_arprot }),
    .s_axi_arqos   (8'd0),
    .s_axi_arvalid ({d_arvalid, i_arvalid}),
    .s_axi_arready ({d_arready, i_arready}),
    .s_axi_rid     ({d_rid_w,   i_rid_w  }),
    .s_axi_rdata   ({d_rdata,   i_rdata  }),
    .s_axi_rresp   ({d_rresp,   i_rresp  }),
    .s_axi_rlast   ({d_rlast,   i_rlast  }),
    .s_axi_rvalid  ({d_rvalid,  i_rvalid }),
    .s_axi_rready  ({d_rready,  i_rready }),

    .s_axi_awid    ({1'b0, d_awid,    1'b0, i_awid   }),
    .s_axi_awaddr  ({d_awaddr,  i_awaddr }),
    .s_axi_awlen   ({d_awlen,   i_awlen  }),
    .s_axi_awsize  ({d_awsize,  i_awsize }),
    .s_axi_awburst ({d_awburst, i_awburst}),
    .s_axi_awlock  ({d_awlock,  i_awlock }),
    .s_axi_awcache ({d_awcache, i_awcache}),
    .s_axi_awprot  ({d_awprot,  i_awprot }),
    .s_axi_awqos   (8'd0),
    .s_axi_awvalid ({d_awvalid, i_awvalid}),
    .s_axi_awready ({d_awready, i_awready}),
    .s_axi_wid     ({1'b0, d_wid,     1'b0, i_wid    }),
    .s_axi_wdata   ({d_wdata,   i_wdata  }),
    .s_axi_wstrb   ({d_wstrb,   i_wstrb  }),
    .s_axi_wlast   ({d_wlast,   i_wlast  }),
    .s_axi_wvalid  ({d_wvalid,  i_wvalid }),
    .s_axi_wready  ({d_wready,  i_wready }),
    .s_axi_bid     ({d_bid_w,   i_bid_w  }),
    .s_axi_bresp   ({d_bresp,   i_bresp  }),
    .s_axi_bvalid  ({d_bvalid,  i_bvalid }),
    .s_axi_bready  ({d_bready,  i_bready }),

    .m_axi_arid    (arid   ),
    .m_axi_araddr  (araddr ),
    .m_axi_arlen   (m_arlen),
    .m_axi_arsize  (arsize ),
    .m_axi_arburst (arburst),
    .m_axi_arlock  (arlock ),
    .m_axi_arcache (arcache),
    .m_axi_arprot  (arprot ),
    .m_axi_arqos   (       ),
    .m_axi_arvalid (arvalid),
    .m_axi_arready (arready),
    .m_axi_rid     (rid    ),
    .m_axi_rdata   (rdata  ),
    .m_axi_rresp   (rresp  ),
    .m_axi_rlast   (rlast  ),
    .m_axi_rvalid  (rvalid ),
    .m_axi_rready  (rready ),

    .m_axi_awid    (awid   ),
    .m_axi_awaddr  (awaddr ),
    .m_axi_awlen   (m_awlen),
    .m_axi_awsize  (awsize ),
    .m_axi_awburst (awburst),
    .m_axi_awlock  (awlock ),
    .m_axi_awcache (awcache),
    .m_axi_awprot  (awprot ),
    .m_axi_awqos   (       ),
    .m_axi_awvalid (awvalid),
    .m_axi_awready (awready),
    .m_axi_wid     (wid    ),
    .m_axi_wdata   (wdata  ),
    .m_axi_wstrb   (wstrb  ),
    .m_axi_wlast   (wlast  ),
    .m_axi_wvalid  (wvalid ),
    .m_axi_wready  (wready ),
    .m_axi_bid     (bid    ),
    .m_axi_bresp   (bresp  ),
    .m_axi_bvalid  (bvalid ),
    .m_axi_bready  (bready )
);

assign arlen = {4'b0, m_arlen};
assign awlen = {4'b0, m_awlen};
assign i_rid = i_rid_w[2:0];
assign d_rid = d_rid_w[2:0];
assign i_bid = i_bid_w[2:0];
assign d_bid = d_bid_w[2:0];

endmodule
