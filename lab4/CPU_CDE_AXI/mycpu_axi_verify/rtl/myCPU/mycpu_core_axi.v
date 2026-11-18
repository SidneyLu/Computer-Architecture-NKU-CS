module mycpu_core_axi(
    input         clk,
    input         resetn,
    input  [5:0]  hw_int,
    output [ 2:0] i_arid,
    output [31:0] i_araddr,
    output [ 3:0] i_arlen,
    output [ 2:0] i_arsize,
    output [ 1:0] i_arburst,
    output [ 1:0] i_arlock,
    output [ 3:0] i_arcache,
    output [ 2:0] i_arprot,
    output        i_arvalid,
    input         i_arready,
    input  [ 2:0] i_rid,
    input  [31:0] i_rdata,
    input  [ 1:0] i_rresp,
    input         i_rlast,
    input         i_rvalid,
    output        i_rready,
    output [ 2:0] d_arid,
    output [31:0] d_araddr,
    output [ 3:0] d_arlen,
    output [ 2:0] d_arsize,
    output [ 1:0] d_arburst,
    output [ 1:0] d_arlock,
    output [ 3:0] d_arcache,
    output [ 2:0] d_arprot,
    output        d_arvalid,
    input         d_arready,
    input  [ 2:0] d_rid,
    input  [31:0] d_rdata,
    input  [ 1:0] d_rresp,
    input         d_rlast,
    input         d_rvalid,
    output        d_rready,
    output [ 2:0] d_awid,
    output [31:0] d_awaddr,
    output [ 3:0] d_awlen,
    output [ 2:0] d_awsize,
    output [ 1:0] d_awburst,
    output [ 1:0] d_awlock,
    output [ 3:0] d_awcache,
    output [ 2:0] d_awprot,
    output        d_awvalid,
    input         d_awready,
    output [ 2:0] d_wid,
    output [31:0] d_wdata,
    output [ 3:0] d_wstrb,
    output        d_wlast,
    output        d_wvalid,
    input         d_wready,
    input  [ 2:0] d_bid,
    input  [ 1:0] d_bresp,
    input         d_bvalid,
    output        d_bready,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

wire         ds_allowin;
wire         es_allowin;
wire         ms_allowin;
wire         ws_allowin;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0] br_bus;
wire         es_valid;
wire         es_gr_we;
wire [ 4:0]  es_dest;
wire         es_load_op;
wire [31:0]  es_alu_result;
wire         ms_valid;
wire         ms_gr_we;
wire [ 4:0]  ms_dest;
wire [31:0]  ms_final_result;
wire         ds_is_bj;
wire         wb_flush;
wire [31:0]  wb_flush_pc;
wire         ex_cancel;
wire         es_mfc;
wire         ms_mfc;
wire [31:0]  data_rdata;

// IF stage
if_stage_axi if_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ds_allowin     (ds_allowin     ),
    //brbus
    .br_bus         (br_bus         ),
    .ds_is_bj       (ds_is_bj       ),
    .wb_flush       (wb_flush       ),
    .wb_flush_pc    (wb_flush_pc    ),
    .ex_cancel      (ex_cancel      ),
    //outputs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    .arid     (i_arid    ),
    .araddr   (i_araddr  ),
    .arlen    (i_arlen   ),
    .arsize   (i_arsize  ),
    .arburst  (i_arburst ),
    .arlock   (i_arlock  ),
    .arcache  (i_arcache ),
    .arprot   (i_arprot  ),
    .arvalid  (i_arvalid ),
    .arready  (i_arready ),
    .rid      (i_rid     ),
    .rdata    (i_rdata   ),
    .rresp    (i_rresp   ),
    .rlast    (i_rlast   ),
    .rvalid   (i_rvalid  ),
    .rready   (i_rready  )
);
// ID stage
id_stage id_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .es_allowin     (es_allowin     ),
    .ds_allowin     (ds_allowin     ),
    //from fs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //to es
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to fs
    .br_bus         (br_bus         ),
    .ds_is_bj       (ds_is_bj       ),
    .wb_flush       (wb_flush       ),
    .ex_cancel      (ex_cancel      ),
    .es_mfc         (es_mfc         ),
    .ms_mfc         (ms_mfc         ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    .es_valid       (es_valid       ),
    .es_gr_we       (es_gr_we       ),
    .es_dest        (es_dest        ),
    .es_load_op     (es_load_op     ),
    .es_alu_result  (es_alu_result  ),
    .ms_valid       (ms_valid       ),
    .ms_gr_we       (ms_gr_we       ),
    .ms_dest        (ms_dest        ),
    .ms_final_result(ms_final_result)
);
// EXE stage
exe_stage_axi exe_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ms_allowin     (ms_allowin     ),
    .es_allowin     (es_allowin     ),
    //from ds
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    .wb_flush       (wb_flush       ),
    .ex_cancel      (ex_cancel      ),
    .es_mfc         (es_mfc         ),
    //to ms
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    .es_valid       (es_valid       ),
    .es_gr_we       (es_gr_we       ),
    .es_dest        (es_dest        ),
    .es_load_op     (es_load_op     ),
    .es_alu_result  (es_alu_result  ),
    .arid     (d_arid    ),
    .araddr   (d_araddr  ),
    .arlen    (d_arlen   ),
    .arsize   (d_arsize  ),
    .arburst  (d_arburst ),
    .arlock   (d_arlock  ),
    .arcache  (d_arcache ),
    .arprot   (d_arprot  ),
    .arvalid  (d_arvalid ),
    .arready  (d_arready ),
    .rid      (d_rid     ),
    .rdata    (d_rdata   ),
    .rresp    (d_rresp   ),
    .rlast    (d_rlast   ),
    .rvalid   (d_rvalid  ),
    .rready   (d_rready  ),
    .awid     (d_awid    ),
    .awaddr   (d_awaddr  ),
    .awlen    (d_awlen   ),
    .awsize   (d_awsize  ),
    .awburst  (d_awburst ),
    .awlock   (d_awlock  ),
    .awcache  (d_awcache ),
    .awprot   (d_awprot  ),
    .awvalid  (d_awvalid ),
    .awready  (d_awready ),
    .wid      (d_wid     ),
    .wdata    (d_wdata   ),
    .wstrb    (d_wstrb   ),
    .wlast    (d_wlast   ),
    .wvalid   (d_wvalid  ),
    .wready   (d_wready  ),
    .bid      (d_bid     ),
    .bresp    (d_bresp   ),
    .bvalid   (d_bvalid  ),
    .bready   (d_bready  ),
    .data_rdata (data_rdata)
);
// MEM stage
mem_stage mem_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    .ms_allowin     (ms_allowin     ),
    //from es
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    //to ws
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    .ms_valid       (ms_valid       ),
    .ms_gr_we       (ms_gr_we       ),
    .ms_dest        (ms_dest        ),
    .ms_final_result(ms_final_result),
    .ms_mfc         (ms_mfc         ),
    .wb_flush       (wb_flush       ),
    .data_sram_rdata(data_rdata      )
);
// WB stage
wb_stage wb_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    //from ms
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    //trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    .wb_flush         (wb_flush         ),
    .wb_flush_pc      (wb_flush_pc      ),
    .hw_int           (hw_int           )
);

endmodule
