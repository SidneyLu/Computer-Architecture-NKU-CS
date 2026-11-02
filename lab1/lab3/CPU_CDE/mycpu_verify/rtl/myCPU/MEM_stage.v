`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    // to ds: RAW detect / forwarding
    output reg                     ms_valid      ,
    output                         ms_gr_we      ,
    output [ 4:0]                  ms_dest       ,
    output [31:0]                  ms_final_result,
    //from data-sram
    input  [31                 :0] data_sram_rdata
);

wire        ms_ready_go;

reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire [ 3:0] ms_mem_op;
wire [31:0] ms_rt_value;
wire        ms_res_from_mem;
wire [31:0] ms_alu_result;
wire [31:0] ms_pc;
assign {ms_mem_op      ,  //106:103
        ms_rt_value    ,  //102:71
        ms_res_from_mem,  //70
        ms_gr_we       ,  //69
        ms_dest        ,  //68:64
        ms_alu_result  ,  //63:32
        ms_pc             //31:0
       } = es_to_ms_bus_r;

wire [31:0] mem_result;
wire [1:0]  ea;
wire [31:0] mem_word;
wire [7:0]  mem_byte;
wire [15:0] mem_half;
wire [31:0] load_result;
assign ea       = ms_alu_result[1:0];
assign mem_word = data_sram_rdata;
assign mem_byte = (ea == 2'd0) ? mem_word[7:0] :
                  (ea == 2'd1) ? mem_word[15:8] :
                  (ea == 2'd2) ? mem_word[23:16] :
                                 mem_word[31:24];
assign mem_half = ea[1] ? mem_word[31:16] : mem_word[15:0];
assign load_result =
    (ms_mem_op == `MEM_LB)  ? {{24{mem_byte[7]}}, mem_byte} :
    (ms_mem_op == `MEM_LBU) ? {24'b0, mem_byte} :
    (ms_mem_op == `MEM_LH)  ? {{16{mem_half[15]}}, mem_half} :
    (ms_mem_op == `MEM_LHU) ? {16'b0, mem_half} :
    (ms_mem_op == `MEM_LWL && ea == 2'd0) ? {mem_word[7:0],   ms_rt_value[23:0]} :
    (ms_mem_op == `MEM_LWL && ea == 2'd1) ? {mem_word[15:0],  ms_rt_value[15:0]} :
    (ms_mem_op == `MEM_LWL && ea == 2'd2) ? {mem_word[23:0],  ms_rt_value[7:0]} :
    (ms_mem_op == `MEM_LWR && ea == 2'd1) ? {ms_rt_value[31:24], mem_word[31:8]} :
    (ms_mem_op == `MEM_LWR && ea == 2'd2) ? {ms_rt_value[31:16], mem_word[31:16]} :
    (ms_mem_op == `MEM_LWR && ea == 2'd3) ? {ms_rt_value[31:8],  mem_word[31:24]} :
                                            mem_word;

assign ms_to_ws_bus = {ms_gr_we       ,  //69:69
                       ms_dest        ,  //68:64
                       ms_final_result,  //63:32
                       ms_pc             //31:0
                      };

assign ms_ready_go    = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r <= es_to_ms_bus;
    end
end

assign mem_result = load_result;

assign ms_final_result = ms_res_from_mem ? mem_result
                                         : ms_alu_result;

endmodule
