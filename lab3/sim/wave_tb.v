`timescale 1ns / 1ps
`include "wave_labels.vh"

// Focused program for syscall, break, overflow, address error, reserved
// instruction, software interrupt, timer interrupt and hw_int[0].
module wave_tb;
reg clk;
reg resetn;
reg [5:0] hw_int;

wire        inst_en;
wire [3:0]  inst_wen;
wire [31:0] inst_addr;
wire [31:0] inst_wdata;
wire [31:0] inst_rdata;
wire        data_en;
wire [3:0]  data_wen;
wire [31:0] data_addr;
wire [31:0] data_wdata;
wire [31:0] data_rdata;
wire [31:0] debug_pc;
wire [3:0]  debug_wen;
wire [4:0]  debug_wnum;
wire [31:0] debug_wdata;

mycpu_top cpu(
    .clk             (clk),
    .resetn          (resetn),
    .hw_int          (hw_int),
    .inst_sram_en    (inst_en),
    .inst_sram_wen   (inst_wen),
    .inst_sram_addr  (inst_addr),
    .inst_sram_wdata (inst_wdata),
    .inst_sram_rdata (inst_rdata),
    .data_sram_en    (data_en),
    .data_sram_wen   (data_wen),
    .data_sram_addr  (data_addr),
    .data_sram_wdata (data_wdata),
    .data_sram_rdata (data_rdata),
    .debug_wb_pc     (debug_pc),
    .debug_wb_rf_wen (debug_wen),
    .debug_wb_rf_wnum(debug_wnum),
    .debug_wb_rf_wdata(debug_wdata)
);

reg [31:0] imem [0:1023];
reg [31:0] dmem [0:255];
reg [31:0] i_rdata;
reg [31:0] d_rdata;
integer i;

initial begin
    for (i = 0; i < 1024; i = i + 1) imem[i] = 32'd0;
    for (i = 0; i < 256; i = i + 1) dmem[i] = 32'd0;
    $readmemh("D:/Architecture/lab3/sim/wave_imem.hex", imem);
end

assign inst_rdata = i_rdata;
assign data_rdata = d_rdata;

always @(posedge clk) begin
    if (inst_en)
        i_rdata <= imem[inst_addr[11:2]];
    if (data_en) begin
        if (data_wen[0]) dmem[data_addr[9:2]][ 7: 0] <= data_wdata[ 7: 0];
        if (data_wen[1]) dmem[data_addr[9:2]][15: 8] <= data_wdata[15: 8];
        if (data_wen[2]) dmem[data_addr[9:2]][23:16] <= data_wdata[23:16];
        if (data_wen[3]) dmem[data_addr[9:2]][31:24] <= data_wdata[31:24];
        d_rdata <= dmem[data_addr[9:2]];
    end
end

wire [31:0] fs_pc    = cpu.if_stage.fs_pc;
wire        wb_valid = cpu.wb_stage.ws_valid;
wire [31:0] wb_pc    = cpu.wb_stage.ws_pc;
wire        wb_flush = cpu.wb_stage.wb_flush;
wire        ex_cancel= cpu.exe_stage.ex_cancel;
wire        ds_valid = cpu.id_stage.ds_valid;
wire [31:0] cause    = cpu.wb_stage.u_cp0.cause_value;
wire [31:0] epc      = cpu.wb_stage.u_cp0.cause_epc;
wire [31:0] status   = cpu.wb_stage.u_cp0.status;
wire        int_req  = cpu.wb_stage.u_cp0.int_req;
wire        cause_ti = cpu.wb_stage.u_cp0.cause_ti;

reg hw_arm;
always @(posedge clk) begin
    if (!resetn)
        hw_arm <= 1'b0;
    else if (wb_valid && wb_pc == `WAVE_SPIN_HW)
        hw_arm <= 1'b1;
end
always @(*) hw_int = hw_arm ? 6'b000001 : 6'b000000;

integer fd;
integer cyc;
initial begin
    fd = $fopen("D:/Architecture/lab3/sim/wave.csv", "w");
    $fwrite(fd, "cyc,fs_pc,wb_valid,wb_pc,wb_flush,ex_cancel,ds_valid,data_wen,data_addr,cause,epc,status,int_req,ti,hw_int\n");
    clk = 0;
    resetn = 0;
    cyc = 0;
    #200;
    resetn = 1;
end
always #5 clk = ~clk;

always @(posedge clk) begin
    if (resetn) begin
        cyc = cyc + 1;
        $fwrite(fd, "%0d,%08x,%0d,%08x,%0d,%0d,%0d,%1x,%08x,%08x,%08x,%08x,%0d,%0d,%0d\n",
            cyc, fs_pc, wb_valid, wb_pc, wb_flush, ex_cancel, ds_valid,
            data_wen, data_addr, cause, epc, status, int_req, cause_ti, hw_int[0]);
        if (dmem[5] == 32'h00000055) begin
            $display("WAVE markers %08x %08x %08x %08x %08x done %08x early %08x",
                dmem[0], dmem[1], dmem[2], dmem[3], dmem[4], dmem[5], dmem[128]);
            $display("WAVE log0 cause %08x epc %08x", dmem[64], dmem[65]);
            $display("WAVE log1 cause %08x epc %08x", dmem[66], dmem[67]);
            $display("WAVE log2 cause %08x epc %08x", dmem[68], dmem[69]);
            $display("WAVE log3 cause %08x epc %08x", dmem[70], dmem[71]);
            $display("WAVE log4 cause %08x epc %08x", dmem[72], dmem[73]);
            $display("WAVE log5 cause %08x epc %08x", dmem[74], dmem[75]);
            $display("WAVE log6 cause %08x epc %08x", dmem[76], dmem[77]);
            $display("WAVE log7 cause %08x epc %08x", dmem[78], dmem[79]);
            if (dmem[0] == 1 && dmem[1] == 2 && dmem[2] == 3 &&
                dmem[3] == 4 && dmem[4] == 5)
                $display("----WAVE PASS!!!----");
            else
                $display("----WAVE FAIL!!!----");
            $fclose(fd);
            #20;
            $finish;
        end
        if (cyc > 20000) begin
            $display("----WAVE TIMEOUT!!!----");
            $display("WAVE markers %08x %08x %08x %08x %08x done %08x",
                dmem[0], dmem[1], dmem[2], dmem[3], dmem[4], dmem[5]);
            $fclose(fd);
            $finish;
        end
    end
end
endmodule
