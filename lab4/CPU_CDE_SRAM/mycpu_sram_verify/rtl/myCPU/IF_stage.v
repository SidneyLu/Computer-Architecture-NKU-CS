`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    input                          ds_allowin     ,
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    input                          ds_is_bj       ,
    input                          wb_flush       ,
    input  [31:0]                  wb_flush_pc    ,
    input                          ex_cancel      ,
    output                         fs_to_ds_valid ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,
    output                         inst_sram_req  ,
    output                         inst_sram_wr   ,
    output [ 1:0]                  inst_sram_size ,
    output [ 3:0]                  inst_sram_wstrb,
    output [31:0]                  inst_sram_addr ,
    output [31:0]                  inst_sram_wdata,
    input                          inst_sram_addr_ok,
    input                          inst_sram_data_ok,
    input  [31:0]                  inst_sram_rdata
);

localparam S_IDLE = 3'd0;
localparam S_REQ  = 3'd1;
localparam S_WAIT = 3'd2;
localparam S_HAVE = 3'd3;
localparam S_HOLD = 3'd4;

reg  [ 2:0] st;
reg  [31:0] req_pc;
reg  [31:0] acc_pc;
reg  [31:0] fs_pc;
reg  [31:0] fs_inst;
reg         fs_valid;
reg         kill;
reg         pend_flush;
reg  [31:0] pend_pc;

wire        br_taken;
wire [31:0] br_target;
assign {br_taken, br_target} = br_bus;

wire fs_fire = fs_valid && ds_allowin && !wb_flush && !ex_cancel;
assign fs_to_ds_valid = fs_valid && !wb_flush && !ex_cancel;
assign fs_to_ds_bus   = {ds_is_bj, fs_inst, fs_pc};

assign inst_sram_req   = (st == S_REQ);
assign inst_sram_wr    = 1'b0;
assign inst_sram_size  = 2'd2;
assign inst_sram_wstrb = 4'h0;
assign inst_sram_addr  = req_pc;
assign inst_sram_wdata = 32'b0;

always @(posedge clk) begin
    if (reset) begin
        st         <= S_IDLE;
        fs_valid   <= 1'b0;
        fs_pc      <= 32'hbfbf_fffc;
        fs_inst    <= 32'b0;
        req_pc     <= 32'hbfc0_0000;
        acc_pc     <= 32'b0;
        kill       <= 1'b0;
        pend_flush <= 1'b0;
        pend_pc    <= 32'b0;
    end
    else begin
        if (wb_flush) begin
            pend_flush <= 1'b1;
            pend_pc    <= wb_flush_pc;
            fs_valid   <= 1'b0;
        end
        else if (fs_fire) begin
            fs_valid <= 1'b0;
        end

        case (st)
        S_IDLE: begin
            st     <= S_REQ;
            req_pc <= 32'hbfc00000;
            kill   <= 1'b0;
        end
        S_REQ: begin
            if (inst_sram_addr_ok) begin
                st     <= S_WAIT;
                acc_pc <= req_pc;
                kill   <= wb_flush || pend_flush || ex_cancel;
            end
            else if (wb_flush) begin
                req_pc <= wb_flush_pc;
            end
            else if (pend_flush) begin
                req_pc     <= pend_pc;
                pend_flush <= 1'b0;
            end
            else if (ex_cancel) begin
                st <= S_HOLD;
            end
        end
        S_WAIT: begin
            if (inst_sram_data_ok) begin
                kill <= 1'b0;
                if (kill || wb_flush || pend_flush || ex_cancel) begin
                    if (wb_flush) begin
                        st         <= S_REQ;
                        req_pc     <= wb_flush_pc;
                        pend_flush <= 1'b0;
                    end
                    else if (pend_flush) begin
                        st         <= S_REQ;
                        req_pc     <= pend_pc;
                        pend_flush <= 1'b0;
                    end
                    else begin
                        st <= S_HOLD;
                    end
                end
                else begin
                    st       <= S_HAVE;
                    fs_valid <= 1'b1;
                    fs_pc    <= acc_pc;
                    fs_inst  <= inst_sram_rdata;
                end
            end
            else if (wb_flush || pend_flush || ex_cancel) begin
                kill <= 1'b1;
            end
        end
        S_HAVE: begin
            if (wb_flush) begin
                st         <= S_REQ;
                req_pc     <= wb_flush_pc;
                pend_flush <= 1'b0;
                fs_valid   <= 1'b0;
            end
            else if (ex_cancel) begin
                st       <= S_HOLD;
                fs_valid <= 1'b0;
            end
            else if (fs_fire) begin
                st     <= S_REQ;
                req_pc <= br_taken ? br_target : (fs_pc + 32'd4);
            end
        end
        S_HOLD: begin
            if (wb_flush) begin
                st         <= S_REQ;
                req_pc     <= wb_flush_pc;
                pend_flush <= 1'b0;
            end
            else if (pend_flush) begin
                st         <= S_REQ;
                req_pc     <= pend_pc;
                pend_flush <= 1'b0;
            end
        end
        default: st <= S_IDLE;
        endcase
    end
end

endmodule
