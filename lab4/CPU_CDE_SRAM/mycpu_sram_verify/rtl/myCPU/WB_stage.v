`include "mycpu.h"

module wb_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    output                          ws_allowin    ,
    //from ms
    input                           ms_to_ws_valid,
    input  [`MS_TO_WS_BUS_WD -1:0]  ms_to_ws_bus  ,
    //to rf: for write back
    output [`WS_TO_RF_BUS_WD -1:0]  ws_to_rf_bus  ,
    //trace debug interface
    output [31:0] debug_wb_pc     ,
    output [ 3:0] debug_wb_rf_wen ,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,
    output        wb_flush        ,
    output [31:0] wb_flush_pc ,
    input  [ 5:0] hw_int
);

reg         ws_valid;
wire        ws_ready_go;

reg [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus_r;
wire        ws_badv_we;
wire [31:0] ws_badvaddr;
wire        ws_bd;
wire        ws_ex;
wire [ 4:0] ws_excode;
wire [ 1:0] ws_cp0_op;
wire [ 4:0] ws_cp0_rd;
wire [31:0] ws_rt_value;
wire        ws_gr_we;
wire [ 4:0] ws_dest;
wire [31:0] ws_final_result;
wire [31:0] ws_pc;
assign {ws_badv_we     ,  //148
        ws_badvaddr    ,  //147:116
        ws_bd          ,  //115
        ws_ex          ,  //114
        ws_excode      ,  //113:109
        ws_cp0_op      ,  //108:107
        ws_cp0_rd      ,  //106:102
        ws_rt_value    ,  //101:70
        ws_gr_we       ,  //69
        ws_dest        ,  //68:64
        ws_final_result,  //63:32
        ws_pc             //31:0
       } = ms_to_ws_bus_r;

wire        ws_mtc0 = ws_cp0_op == `CP0_MTC;
wire        ws_eret = ws_valid && ws_cp0_op == `CP0_ERET;
wire        ws_mfc0 = ws_valid && ws_cp0_op == `CP0_MFC;
wire [31:0] cp0_rdata;
wire [31:0] cp0_epc;
wire [31:0] ex_entry;
wire        int_req;
wire        take_ex  = ws_valid && ws_ex;
wire        take_int = ws_valid && !ws_ex && int_req;
wire        do_ex    = take_ex || take_int;
wire [ 4:0] excode   = take_int ? `EXC_INT : ws_excode;

cp0 u_cp0(
    .clk       (clk       ),
    .reset     (reset     ),
    .ws_valid  (ws_valid  ),
    .ws_ex     (do_ex     ),
    .ws_bd     (ws_bd     ),
    .ws_excode (excode    ),
    .ws_pc     (ws_pc     ),
    .ws_eret   (ws_eret   ),
    .ws_mtc0   (ws_valid && ws_mtc0),
    .ws_addr   (ws_cp0_rd ),
    .ws_wdata  (ws_rt_value),
    .ws_badv_we(ws_badv_we),
    .ws_badvaddr(ws_badvaddr),
    .hw_int    (hw_int    ),
    .raddr     (ws_cp0_rd ),
    .rdata     (cp0_rdata ),
    .epc       (cp0_epc   ),
    .int_req   (int_req   ),
    .ex_entry  (ex_entry  )
);

assign wb_flush    = do_ex || ws_eret;
assign wb_flush_pc = ws_eret ? cp0_epc : ex_entry;

wire        rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;
assign ws_to_rf_bus = {rf_we   ,  //37:37
                       rf_waddr,  //36:32
                       rf_wdata   //31:0
                      };

assign ws_ready_go = 1'b1;
assign ws_allowin  = !ws_valid || ws_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
    end
    else if (ws_allowin) begin
        ws_valid <= ms_to_ws_valid;
    end

    if (ms_to_ws_valid && ws_allowin) begin
        ms_to_ws_bus_r <= ms_to_ws_bus;
    end
end

assign rf_we    = ws_gr_we && ws_valid && !take_ex;
assign rf_waddr = ws_dest;
assign rf_wdata = ws_mfc0 ? cp0_rdata : ws_final_result;

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_wen   = {4{rf_we}};
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = rf_wdata;

endmodule
