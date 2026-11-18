// One SRAM-like master to one AXI3 master. One transfer is outstanding.
module sram2axi(
    input         clk,
    input         resetn,

    input         req,
    input         wr,
    input  [ 1:0] size,
    input  [ 3:0] wstrb,
    input  [31:0] addr,
    input  [31:0] wdata,
    output        addr_ok,
    output        data_ok,
    output [31:0] rdata,

    output [ 2:0] arid,
    output [31:0] araddr,
    output [ 3:0] arlen,
    output [ 2:0] arsize,
    output [ 1:0] arburst,
    output [ 1:0] arlock,
    output [ 3:0] arcache,
    output [ 2:0] arprot,
    output        arvalid,
    input         arready,

    input  [ 2:0] rid,
    input  [31:0] axi_rdata,
    input  [ 1:0] rresp,
    input         rlast,
    input         rvalid,
    output        rready,

    output [ 2:0] awid,
    output [31:0] awaddr,
    output [ 3:0] awlen,
    output [ 2:0] awsize,
    output [ 1:0] awburst,
    output [ 1:0] awlock,
    output [ 3:0] awcache,
    output [ 2:0] awprot,
    output        awvalid,
    input         awready,

    output [ 2:0] wid,
    output [31:0] axi_wdata,
    output [ 3:0] axi_wstrb,
    output        wlast,
    output        wvalid,
    input         wready,

    input  [ 2:0] bid,
    input  [ 1:0] bresp,
    input         bvalid,
    output        bready
);

localparam A_IDLE  = 3'd0;
localparam A_AR    = 3'd1;
localparam A_R     = 3'd2;
localparam A_WRITE = 3'd3;
localparam A_WRESP = 3'd4;

reg [ 2:0] st;
reg [ 1:0] size_r;
reg [ 3:0] wstrb_r;
reg [31:0] addr_r;
reg [31:0] wdata_r;
reg        aw_done;
reg        w_done;

wire read_fire = (st == A_R) && rvalid && rready && rlast;
wire b_fire    = (st == A_WRESP) && bvalid && bready;

assign addr_ok = (st == A_IDLE) && req;
assign data_ok = read_fire || b_fire;
assign rdata   = axi_rdata;

assign arid    = 3'd0;
assign araddr  = addr_r;
assign arlen   = 4'd0;
assign arsize  = {1'b0, size_r};
assign arburst = 2'b01;
assign arlock  = 2'b00;
assign arcache = 4'b0000;
assign arprot  = 3'b000;
assign arvalid = (st == A_AR);
assign rready  = (st == A_R);

assign awid    = 3'd0;
assign awaddr  = addr_r;
assign awlen   = 4'd0;
assign awsize  = {1'b0, size_r};
assign awburst = 2'b01;
assign awlock  = 2'b00;
assign awcache = 4'b0000;
assign awprot  = 3'b000;
assign awvalid = (st == A_WRITE) && !aw_done;

assign wid       = 3'd0;
assign axi_wdata = wdata_r;
assign axi_wstrb = wstrb_r;
assign wlast     = 1'b1;
assign wvalid    = (st == A_WRITE) && !w_done;
assign bready    = (st == A_WRESP);

always @(posedge clk) begin
    if (!resetn) begin
        st      <= A_IDLE;
        size_r  <= 2'b0;
        wstrb_r <= 4'b0;
        addr_r  <= 32'b0;
        wdata_r <= 32'b0;
        aw_done <= 1'b0;
        w_done  <= 1'b0;
    end
    else begin
        case (st)
        A_IDLE: begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
            if (req) begin
                size_r  <= size;
                wstrb_r <= wstrb;
                addr_r  <= addr;
                wdata_r <= wdata;
                st      <= wr ? A_WRITE : A_AR;
            end
        end
        A_AR: begin
            if (arvalid && arready)
                st <= A_R;
        end
        A_R: begin
            if (read_fire)
                st <= A_IDLE;
        end
        A_WRITE: begin
            if (awvalid && awready)
                aw_done <= 1'b1;
            if (wvalid && wready)
                w_done <= 1'b1;
            if ((aw_done || (awvalid && awready)) && (w_done || (wvalid && wready)))
                st <= A_WRESP;
        end
        A_WRESP: begin
            if (b_fire)
                st <= A_IDLE;
        end
        default: st <= A_IDLE;
        endcase
    end
end

wire _unused = |{rid, rresp, bid, bresp};

endmodule
