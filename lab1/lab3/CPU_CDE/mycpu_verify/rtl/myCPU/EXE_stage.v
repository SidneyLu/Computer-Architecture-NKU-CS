`include "mycpu.h"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    input                          wb_flush      ,
    output                         ex_cancel     ,
    output                         es_mfc        ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    // to ds: RAW detect / forwarding
    output reg                     es_valid      ,
    output                         es_gr_we      ,
    output [ 4:0]                  es_dest       ,
    output                         es_load_op    ,
    output [31:0]                  es_alu_result ,
    // data sram interface
    output        data_sram_en   ,
    output [ 3:0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata
);

wire        es_ready_go   ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire        es_src2_is_zimm;
wire [ 3:0] es_mem_op     ;
wire [ 3:0] es_md_op      ;
wire [11:0] es_alu_op     ;
wire        es_src1_is_sa ;
wire        es_src1_is_pc ;
wire        es_src2_is_imm;
wire        es_src2_is_8  ;
wire [15:0] es_imm        ;
wire [31:0] es_rs_value   ;
wire [31:0] es_rt_value   ;
wire [31:0] es_pc         ;
wire        es_bd;
wire        es_ex;
wire [ 4:0] es_excode;
wire [ 1:0] es_cp0_op;
wire [ 4:0] es_cp0_rd;
wire        es_ov_en;
wire        es_badv_we;
wire [31:0] es_badvaddr;
assign {es_ov_en       ,  //191
        es_badv_we     ,  //190
        es_badvaddr    ,  //189:158
        es_bd          ,  //157
        es_ex          ,  //156
        es_excode      ,  //155:151
        es_cp0_op      ,  //150:149
        es_cp0_rd      ,  //148:144
        es_src2_is_zimm,  //143
        es_mem_op      ,  //142:139
        es_md_op       ,  //138:135
        es_alu_op      ,  //134:123
        es_load_op     ,  //122
        es_src1_is_sa  ,  //121
        es_src1_is_pc  ,  //120
        es_src2_is_imm ,  //119
        es_src2_is_8   ,  //118
        es_gr_we       ,  //117
        es_dest        ,  //116:112
        es_imm         ,  //111:96
        es_rs_value    ,  //95 :64
        es_rt_value    ,  //63 :32
        es_pc             //31 :0
       } = ds_to_es_bus_r;

wire [31:0] es_alu_src1;
wire [31:0] es_alu_src2;
wire [31:0] alu_result;
wire [31:0] es_wb_data;
wire        es_res_from_mem;
wire        es_is_mult;
wire        es_is_multu;
wire        es_is_div;
wire        es_is_divu;
wire        es_is_mfhi;
wire        es_is_mflo;
wire        es_is_mthi;
wire        es_is_mtlo;
wire        es_is_mul;
wire        es_is_divop;
wire [63:0] mul_p;
wire [63:0] mulu_p;
wire [63:0] mul_res;
wire [63:0] divs_dout;
wire [63:0] divu_dout;
wire        divs_vout;
wire        divu_vout;
wire        div_vout;
wire [63:0] div_dout;
wire [31:0] hi_rdata;
wire [31:0] lo_rdata;

reg  [31:0] hi;
reg  [31:0] lo;
reg         md_ready;
reg         div_accepted;
reg         mul_seen;

assign es_is_mult  = (es_md_op == `MD_MULT);
assign es_is_multu = (es_md_op == `MD_MULTU);
assign es_is_div   = (es_md_op == `MD_DIV);
assign es_is_divu  = (es_md_op == `MD_DIVU);
assign es_is_mfhi  = (es_md_op == `MD_MFHI);
assign es_is_mflo  = (es_md_op == `MD_MFLO);
assign es_is_mthi  = (es_md_op == `MD_MTHI);
assign es_is_mtlo  = (es_md_op == `MD_MTLO);
assign es_is_mul   = es_is_mult | es_is_multu;
assign es_is_divop = es_is_div | es_is_divu;

assign es_ready_go    = (es_is_mul | es_is_divop) ? md_ready : 1'b1;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
wire        word_unalign = |alu_result[1:0];
wire        half_unalign = alu_result[0];
wire        es_ov = es_ov_en && (es_alu_op[1]
                    ? (es_alu_src1[31] != es_alu_src2[31]) && (alu_result[31] != es_alu_src1[31])
                    : (es_alu_src1[31] == es_alu_src2[31]) && (alu_result[31] != es_alu_src1[31]));
wire        es_adel_m = !es_ex && ((es_mem_op == `MEM_LW  && word_unalign) ||
                                   ((es_mem_op == `MEM_LH || es_mem_op == `MEM_LHU) && half_unalign));
wire        es_ades_m = !es_ex && ((es_mem_op == `MEM_SW  && word_unalign) ||
                                   (es_mem_op == `MEM_SH && half_unalign));
wire        es_ex_f = es_ex || es_ov || es_adel_m || es_ades_m;
wire [ 4:0] es_excode_f = es_ex     ? es_excode :
                          es_ov     ? `EXC_OV   :
                          es_adel_m ? `EXC_ADEL :
                          es_ades_m ? `EXC_ADES : 5'd0;
wire        es_badv_we_f = es_badv_we || es_adel_m || es_ades_m;
wire [31:0] es_badv_f = (es_adel_m || es_ades_m) ? alu_result : es_badvaddr;
assign es_to_ms_valid =  es_valid && es_ready_go && !wb_flush;
assign ex_cancel      =  es_valid && (es_ex_f || es_cp0_op == `CP0_ERET);
assign es_mfc         =  es_valid && es_cp0_op == `CP0_MFC;
always @(posedge clk) begin
    if (reset || wb_flush) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

assign es_alu_src1 = es_src1_is_sa  ? {27'b0, es_imm[10:6]} :
                     es_src1_is_pc  ? es_pc[31:0] :
                                      es_rs_value;
assign es_alu_src2 = es_src2_is_zimm ? {16'b0, es_imm[15:0]} :
                     es_src2_is_imm  ? {{16{es_imm[15]}}, es_imm[15:0]} :
                     es_src2_is_8    ? 32'd8 :
                                       es_rt_value;

alu u_alu(
    .alu_op     (es_alu_op    ),
    .alu_src1   (es_alu_src1  ),
    .alu_src2   (es_alu_src2  ),
    .alu_result (alu_result   )
    );

mult_gen_signed_0 u_mult_s (
    .CLK (clk),
    .A   (es_rs_value),
    .B   (es_rt_value),
    .P   (mul_p)
);
mult_gen_unsigned_0 u_mult_u (
    .CLK (clk),
    .A   (es_rs_value),
    .B   (es_rt_value),
    .P   (mulu_p)
);
assign mul_res = es_is_multu ? mulu_p : mul_p;

div_gen_signed_0 u_div_s (
    .aclk                   (clk),
    .s_axis_divisor_tvalid  (es_valid && es_is_div && !div_accepted),
    .s_axis_divisor_tdata   (es_rt_value),
    .s_axis_dividend_tvalid (es_valid && es_is_div && !div_accepted),
    .s_axis_dividend_tdata  (es_rs_value),
    .m_axis_dout_tvalid     (divs_vout),
    .m_axis_dout_tdata      (divs_dout)
);
div_gen_unsigned_0 u_div_u (
    .aclk                   (clk),
    .s_axis_divisor_tvalid  (es_valid && es_is_divu && !div_accepted),
    .s_axis_divisor_tdata   (es_rt_value),
    .s_axis_dividend_tvalid (es_valid && es_is_divu && !div_accepted),
    .s_axis_dividend_tdata  (es_rs_value),
    .m_axis_dout_tvalid     (divu_vout),
    .m_axis_dout_tdata      (divu_dout)
);
assign div_vout = es_is_div ? divs_vout : divu_vout;
assign div_dout = es_is_div ? divs_dout : divu_dout;

always @(posedge clk) begin
    if (reset) begin
        hi           <= 32'b0;
        lo           <= 32'b0;
        md_ready     <= 1'b0;
        div_accepted <= 1'b0;
        mul_seen     <= 1'b0;
    end
    else if (wb_flush) begin
        md_ready     <= 1'b0;
        div_accepted <= 1'b0;
        mul_seen     <= 1'b0;
    end
    else begin
        if (ds_to_es_valid && es_allowin) begin
            md_ready     <= 1'b0;
            div_accepted <= 1'b0;
            mul_seen     <= 1'b0;
        end
        if (es_valid && es_is_divop && !div_accepted && !(ds_to_es_valid && es_allowin))
            div_accepted <= 1'b1;
        if (es_valid && es_is_divop && div_accepted && div_vout && !md_ready) begin
            lo       <= div_dout[63:32];
            hi       <= div_dout[31:0];
            md_ready <= 1'b1;
        end
        if (es_valid && es_is_mul && !md_ready && !(ds_to_es_valid && es_allowin)) begin
            if (!mul_seen)
                mul_seen <= 1'b1;
            else begin
                hi       <= mul_res[63:32];
                lo       <= mul_res[31:0];
                md_ready <= 1'b1;
            end
        end
        if (es_valid && es_is_mthi && es_ready_go && ms_allowin)
            hi <= es_rs_value;
        if (es_valid && es_is_mtlo && es_ready_go && ms_allowin)
            lo <= es_rs_value;
    end
end

assign hi_rdata = hi;
assign lo_rdata = lo;
assign es_wb_data = es_is_mfhi ? hi_rdata :
                    es_is_mflo ? lo_rdata :
                                 alu_result;
assign es_alu_result   = es_wb_data;
assign es_res_from_mem = es_load_op;
assign es_to_ms_bus = {es_badv_we_f   ,  //153
                       es_badv_f      ,  //152:121
                       es_bd          ,  //120
                       es_ex_f        ,  //119
                       es_excode_f    ,  //118:114
                       es_cp0_op      ,  //113:112
                       es_cp0_rd      ,  //111:107
                       es_mem_op      ,  //106:103
                       es_rt_value     ,  //102:71
                       es_res_from_mem ,  //70
                       es_gr_we        ,  //69
                       es_dest         ,  //68:64
                       es_wb_data      ,  //63:32
                       es_pc              //31:0
                      };

wire [1:0]  ea;
wire [31:0] st_data;
wire [3:0]  st_wen;
assign ea = alu_result[1:0];
assign st_wen =
    (es_mem_op == `MEM_SW)  ? 4'b1111 :
    (es_mem_op == `MEM_SB)  ? (4'b0001 << ea) :
    (es_mem_op == `MEM_SH)  ? (ea[1] ? 4'b1100 : 4'b0011) :
    (es_mem_op == `MEM_SWL) ? (ea == 2'd0 ? 4'b0001 :
                               ea == 2'd1 ? 4'b0011 :
                               ea == 2'd2 ? 4'b0111 : 4'b1111) :
    (es_mem_op == `MEM_SWR) ? (ea == 2'd0 ? 4'b1111 :
                               ea == 2'd1 ? 4'b1110 :
                               ea == 2'd2 ? 4'b1100 : 4'b1000) :
                              4'b0000;
assign st_data =
    (es_mem_op == `MEM_SB)  ? {4{es_rt_value[7:0]}} :
    (es_mem_op == `MEM_SH)  ? {2{es_rt_value[15:0]}} :
    (es_mem_op == `MEM_SWL && ea == 2'd0) ? {24'b0, es_rt_value[31:24]} :
    (es_mem_op == `MEM_SWL && ea == 2'd1) ? {16'b0, es_rt_value[31:16]} :
    (es_mem_op == `MEM_SWL && ea == 2'd2) ? {8'b0,  es_rt_value[31:8]} :
    (es_mem_op == `MEM_SWR && ea == 2'd1) ? {es_rt_value[23:0], 8'b0} :
    (es_mem_op == `MEM_SWR && ea == 2'd2) ? {es_rt_value[15:0], 16'b0} :
    (es_mem_op == `MEM_SWR && ea == 2'd3) ? {es_rt_value[7:0],  24'b0} :
                                            es_rt_value;

assign data_sram_en    = 1'b1;
assign data_sram_wen   = (es_valid && !wb_flush && !es_ex_f) ? st_wen : 4'h0;
assign data_sram_addr  = alu_result;
assign data_sram_wdata = st_data;

endmodule
