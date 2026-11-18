`include "mycpu.h"

// Execute stage that drives an AXI3 read or write directly.
module exe_stage_axi(
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
    output [ 2:0]                  arid           ,
    output [31:0]                  araddr         ,
    output [ 3:0]                  arlen          ,
    output [ 2:0]                  arsize         ,
    output [ 1:0]                  arburst        ,
    output [ 1:0]                  arlock         ,
    output [ 3:0]                  arcache        ,
    output [ 2:0]                  arprot         ,
    output                         arvalid        ,
    input                          arready        ,
    input  [ 2:0]                  rid            ,
    input  [31:0]                  rdata          ,
    input  [ 1:0]                  rresp          ,
    input                          rlast          ,
    input                          rvalid         ,
    output                         rready         ,
    output [ 2:0]                  awid           ,
    output [31:0]                  awaddr         ,
    output [ 3:0]                  awlen          ,
    output [ 2:0]                  awsize         ,
    output [ 1:0]                  awburst        ,
    output [ 1:0]                  awlock         ,
    output [ 3:0]                  awcache        ,
    output [ 2:0]                  awprot         ,
    output                         awvalid        ,
    input                          awready        ,
    output [ 2:0]                  wid            ,
    output [31:0]                  wdata          ,
    output [ 3:0]                  wstrb          ,
    output                         wlast          ,
    output                         wvalid         ,
    input                          wready         ,
    input  [ 2:0]                  bid            ,
    input  [ 1:0]                  bresp          ,
    input                          bvalid         ,
    output                         bready         ,
    output [31:0]                  data_rdata
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
localparam D_IDLE   = 3'd0;
localparam D_AR     = 3'd1;
localparam D_R      = 3'd2;
localparam D_WR     = 3'd3;
localparam D_B      = 3'd4;
localparam D_DONE   = 3'd5;
localparam D_DROP_R = 3'd6;
localparam D_DROP_B = 3'd7;
reg  [ 2:0] dst;
reg  [31:0] load_buf;
reg         aw_done;
reg         w_done;
reg  [31:0] axi_addr;
reg  [31:0] axi_wdata;
reg  [ 3:0] axi_wstrb;
reg  [ 2:0] axi_size;
reg         axi_drop;
wire        es_mem_go = es_valid && !es_ex_f && (es_mem_op != `MEM_NONE);
wire        mem_wait  = es_mem_go && (dst != D_DONE);
assign es_ready_go = mem_wait ? 1'b0 : ((es_is_mul | es_is_divop) ? md_ready : 1'b1);
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

wire [1:0] data_size =
    (es_mem_op == `MEM_LB || es_mem_op == `MEM_LBU || es_mem_op == `MEM_SB) ? 2'd0 :
    (es_mem_op == `MEM_LH || es_mem_op == `MEM_LHU || es_mem_op == `MEM_SH) ? 2'd1 :
                                                                              2'd2;
wire is_store = |st_wen;
wire aw_fire  = awvalid && awready;
wire w_fire   = wvalid  && wready;
wire r_fire   = rvalid && rready && rlast;
wire b_fire   = bvalid && bready;

assign arid    = 3'd0;
assign araddr  = axi_addr;
assign arlen   = 4'd0;
assign arsize  = axi_size;
assign arburst = 2'b01;
assign arlock  = 2'b00;
assign arcache = 4'b0000;
assign arprot  = 3'b000;
assign arvalid = (dst == D_AR);
assign rready  = (dst == D_R) || (dst == D_DROP_R);

assign awid    = 3'd0;
assign awaddr  = axi_addr;
assign awlen   = 4'd0;
assign awsize  = axi_size;
assign awburst = 2'b01;
assign awlock  = 2'b00;
assign awcache = 4'b0000;
assign awprot  = 3'b000;
assign awvalid = (dst == D_WR) && !aw_done;
assign wid     = 3'd0;
assign wdata   = axi_wdata;
assign wstrb   = axi_wstrb;
assign wlast   = 1'b1;
assign wvalid  = (dst == D_WR) && !w_done;
assign bready  = (dst == D_B) || (dst == D_DROP_B);
assign data_rdata = load_buf;

always @(posedge clk) begin
    if (reset) begin
        dst       <= D_IDLE;
        load_buf  <= 32'b0;
        aw_done   <= 1'b0;
        w_done    <= 1'b0;
        axi_addr  <= 32'b0;
        axi_wdata <= 32'b0;
        axi_wstrb <= 4'b0;
        axi_size  <= 3'd2;
        axi_drop  <= 1'b0;
    end
    else if (wb_flush && (dst == D_IDLE || dst == D_DONE)) begin
        dst <= D_IDLE;
    end
    else begin
        case (dst)
        D_IDLE: begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
            if (es_mem_go) begin
                axi_addr  <= alu_result;
                axi_wdata <= st_data;
                axi_wstrb <= st_wen;
                axi_size  <= {1'b0, data_size};
                axi_drop  <= 1'b0;
                dst       <= is_store ? D_WR : D_AR;
            end
        end
        D_AR: begin
            if (arvalid && arready)
                dst <= (wb_flush || axi_drop) ? D_DROP_R : D_R;
            else if (wb_flush)
                axi_drop <= 1'b1;
        end
        D_R: begin
            if (r_fire) begin
                load_buf <= rdata;
                dst      <= D_DONE;
            end
            else if (wb_flush)
                dst <= D_DROP_R;
        end
        D_DROP_R: if (r_fire) dst <= D_IDLE;
        D_WR: begin
            if (aw_fire) aw_done <= 1'b1;
            if (w_fire)  w_done  <= 1'b1;
            if (wb_flush) axi_drop <= 1'b1;
            if ((aw_done || aw_fire) && (w_done || w_fire)) begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
                dst     <= (wb_flush || axi_drop) ? D_DROP_B : D_B;
            end
        end
        D_B:      if (b_fire) dst <= D_DONE;
        D_DROP_B: if (b_fire) dst <= D_IDLE;
        D_DONE:   if (es_to_ms_valid && ms_allowin) dst <= D_IDLE;
        default:  dst <= D_IDLE;
        endcase
    end
end

wire _unused = |{rid, rresp, bid, bresp};
endmodule
