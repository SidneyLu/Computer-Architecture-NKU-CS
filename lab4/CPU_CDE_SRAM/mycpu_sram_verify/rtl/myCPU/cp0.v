`include "mycpu.h"

// Status/Cause layout follows the gettrace GS132, only the fields func_lab8/9 read or write.
module cp0(
    input         clk,
    input         reset,
    input         ws_valid,
    input         ws_ex,
    input         ws_bd,
    input  [ 4:0] ws_excode,
    input  [31:0] ws_pc,
    input         ws_eret,
    input         ws_mtc0,
    input  [ 4:0] ws_addr,
    input  [31:0] ws_wdata,
    input         ws_badv_we,
    input  [31:0] ws_badvaddr,
    input  [ 5:0] hw_int,
    input  [ 4:0] raddr,
    output [31:0] rdata,
    output [31:0] epc,
    output        int_req,
    output [31:0] ex_entry
);

reg  [31:0] status;
reg         cause_bd;
reg         cause_ti;
reg         cause_ip1;
reg         cause_ip0;
reg  [ 4:0] cause_excode;
reg  [31:0] cause_epc;
reg  [31:0] count;
reg  [31:0] compare;
reg  [31:0] badvaddr;
reg         count_add_en;
reg  [ 5:0] cause_hwip;

wire        status_ie  = status[0];
wire        status_exl = status[1];
wire        status_erl = status[2];
wire        status_bev = status[22];
wire        count_eq   = (count == compare);
// IP7:IP2 follow TI and hw_int by one cycle, matching GS132 int_pending.
wire [7:0]  ip         = {cause_hwip, cause_ip1, cause_ip0};
wire [31:0] cause_value;

assign cause_value = {cause_bd, cause_ti, 2'b0, 1'b0, 1'b0, 2'b0,
                      1'b0, 1'b0, 1'b0, 3'b0, 2'b0,
                      ip, 1'b0, cause_excode, 2'b00};
assign epc      = cause_epc;
assign ex_entry = status_bev ? 32'hbfc00380 : 32'h80000180;
assign int_req  = status_ie && !status_exl && !status_erl &&
                  (|(status[15:8] & ip));

assign rdata = (raddr == 5'd8)  ? badvaddr :
               (raddr == 5'd9)  ? count :
               (raddr == 5'd11) ? compare :
               (raddr == 5'd12) ? status :
               (raddr == 5'd13) ? cause_value :
               (raddr == 5'd14) ? cause_epc :
                                  32'b0;

always @(posedge clk) begin
    if (reset) begin
        status       <= 32'h10400004;
        cause_bd     <= 1'b0;
        cause_ti     <= 1'b0;
        cause_ip1    <= 1'b0;
        cause_ip0    <= 1'b0;
        cause_excode <= 5'h1f;
        cause_epc    <= 32'b0;
        count        <= 32'b0;
        compare      <= 32'b0;
        badvaddr     <= 32'b0;
        count_add_en <= 1'b0;
        cause_hwip   <= 6'b0;
    end
    else begin
        count_add_en <= ~count_add_en;
        cause_hwip   <= {hw_int[5] | cause_ti, hw_int[4:0]};
        if (ws_valid && ws_mtc0 && ws_addr == 5'd9)
            count <= ws_wdata;
        else if (count_add_en)
            count <= count + 32'd1;

        if (ws_valid && ws_mtc0 && ws_addr == 5'd11)
            cause_ti <= 1'b0;
        else if (count_eq)
            cause_ti <= 1'b1;

        if (ws_valid && ws_ex)
            cause_excode <= ws_excode;
        if (ws_valid && ws_ex && !status_exl)
            cause_bd <= ws_bd;

        if (ws_valid && ws_mtc0 && ws_addr == 5'd13) begin
            cause_ip1 <= ws_wdata[9];
            cause_ip0 <= ws_wdata[8];
        end

        if (ws_valid && ws_ex && !status_exl)
            cause_epc <= ws_bd ? (ws_pc - 32'd4) : ws_pc;
        else if (ws_valid && ws_mtc0 && ws_addr == 5'd14)
            cause_epc <= ws_wdata;

        if (ws_valid && ws_ex && ws_badv_we)
            badvaddr <= ws_badvaddr;
        else if (ws_valid && ws_mtc0 && ws_addr == 5'd8)
            badvaddr <= ws_wdata;
        if (ws_valid && ws_mtc0 && ws_addr == 5'd11)
            compare <= ws_wdata;

        if (ws_valid && ws_ex)
            status[1] <= 1'b1;
        else if (ws_valid && ws_eret)
            status[1] <= status_erl ? status[1] : 1'b0;
        else if (ws_valid && ws_mtc0 && ws_addr == 5'd12)
            status[1] <= ws_wdata[1];

        if (ws_valid && ws_eret)
            status[2] <= 1'b0;
        else if (ws_valid && ws_mtc0 && ws_addr == 5'd12)
            status[2] <= ws_wdata[2];

        if (ws_valid && ws_mtc0 && ws_addr == 5'd12) begin
            status[28]    <= ws_wdata[28];
            status[22]    <= ws_wdata[22];
            status[19]    <= ws_wdata[19];
            status[15:8]  <= ws_wdata[15:8];
            status[4:3]   <= ws_wdata[4:3];
            status[0]     <= ws_wdata[0];
        end
    end
end

endmodule
