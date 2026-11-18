`include "mycpu.h"

// Instruction fetch that drives an AXI3 read directly. One fetch is outstanding.
module if_stage_axi(
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
    output                         rready
);

localparam S_IDLE = 3'd0;
localparam S_AR   = 3'd1;
localparam S_R    = 3'd2;
localparam S_HAVE = 3'd3;
localparam S_HOLD = 3'd4;
localparam S_GAP  = 3'd5;

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

wire r_fire = (st == S_R) && rvalid && rready && rlast;

assign arid    = 3'd0;
assign araddr  = req_pc;
assign arlen   = 4'd0;
assign arsize  = 3'd2;
assign arburst = 2'b01;
assign arlock  = 2'b00;
assign arcache = 4'b0000;
assign arprot  = 3'b000;
assign arvalid = (st == S_AR);
assign rready  = (st == S_R);

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
            st     <= S_AR;
            req_pc <= 32'hbfc00000;
            kill   <= 1'b0;
        end
        // ARVALID stays high until ARREADY. A flush only marks the beat to be dropped.
        S_AR: begin
            if (arvalid && arready) begin
                st     <= S_R;
                acc_pc <= req_pc;
                kill   <= kill || wb_flush || pend_flush || ex_cancel;
            end
            else if (wb_flush || pend_flush || ex_cancel) begin
                kill <= 1'b1;
            end
        end
        S_GAP: begin
            st <= S_AR;
        end
        S_R: begin
            if (r_fire) begin
                kill <= 1'b0;
                if (kill || wb_flush || pend_flush || ex_cancel) begin
                    if (wb_flush) begin
                        st         <= S_AR;
                        req_pc     <= wb_flush_pc;
                        pend_flush <= 1'b0;
                    end
                    else if (pend_flush) begin
                        st         <= S_AR;
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
                    fs_inst  <= rdata;
                end
            end
            else if (wb_flush || pend_flush || ex_cancel) begin
                kill <= 1'b1;
            end
        end
        S_HAVE: begin
            if (wb_flush) begin
                st         <= S_AR;
                req_pc     <= wb_flush_pc;
                pend_flush <= 1'b0;
                fs_valid   <= 1'b0;
            end
            else if (ex_cancel) begin
                st       <= S_HOLD;
                fs_valid <= 1'b0;
            end
            else if (fs_fire) begin
                st     <= S_AR;
                req_pc <= br_taken ? br_target : (fs_pc + 32'd4);
            end
        end
        S_HOLD: begin
            if (wb_flush) begin
                st         <= S_AR;
                req_pc     <= wb_flush_pc;
                pend_flush <= 1'b0;
            end
            else if (pend_flush) begin
                st         <= S_AR;
                req_pc     <= pend_pc;
                pend_flush <= 1'b0;
            end
        end
        default: st <= S_IDLE;
        endcase
    end
end

wire _unused = |{rid, rresp};
endmodule
