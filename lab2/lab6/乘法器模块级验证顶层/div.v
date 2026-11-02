`timescale 1ns / 1ps

// 适配 div_tb：div 拉高后只给对应 div_gen 一个时钟的 tvalid。
// 商在 tdata[63:32]，余数在 tdata[31:0]。dout 的 tvalid 作为 complete。
module div (
    input  wire        div_clk,
    input  wire        resetn,
    input  wire        div,
    input  wire        div_signed,
    input  wire [31:0] x,
    input  wire [31:0] y,
    output wire [31:0] s,
    output wire [31:0] r,
    output wire        complete
);

    reg         accepted;
    reg         signed_hold;
    wire        fire;
    wire        vout_s;
    wire        vout_u;
    wire [63:0] dout_s;
    wire [63:0] dout_u;
    wire [63:0] dout;

    assign fire = resetn && div && !accepted;

    div_gen_signed_0 u_signed (
        .aclk                   (div_clk),
        .s_axis_divisor_tvalid  (fire && div_signed),
        .s_axis_divisor_tdata   (y),
        .s_axis_dividend_tvalid (fire && div_signed),
        .s_axis_dividend_tdata  (x),
        .m_axis_dout_tvalid     (vout_s),
        .m_axis_dout_tdata      (dout_s)
    );

    div_gen_unsigned_0 u_unsigned (
        .aclk                   (div_clk),
        .s_axis_divisor_tvalid  (fire && !div_signed),
        .s_axis_divisor_tdata   (y),
        .s_axis_dividend_tvalid (fire && !div_signed),
        .s_axis_dividend_tdata  (x),
        .m_axis_dout_tvalid     (vout_u),
        .m_axis_dout_tdata      (dout_u)
    );

    assign dout     = signed_hold ? dout_s : dout_u;
    assign s        = dout[63:32];
    assign r        = dout[31:0];
    assign complete = signed_hold ? vout_s : vout_u;

    always @(posedge div_clk) begin
        if (!resetn) begin
            accepted    <= 1'b0;
            signed_hold <= 1'b0;
        end
        else if (!div) begin
            accepted <= 1'b0;
        end
        else if (!accepted) begin
            accepted    <= 1'b1;
            signed_hold <= div_signed;
        end
    end

endmodule
