`timescale 1ns / 1ps

// 适配 mul_tb：有符号、无符号各一个 mult_gen，流水 1 级。
// 选择信号打一拍，与 IP 的输出寄存器对齐。复位期间结果保持 0。
module mul (
    input  wire               mul_clk,
    input  wire               resetn,
    input  wire               mul_signed,
    input  wire [31:0]        x,
    input  wire [31:0]        y,
    output wire signed [63:0] result
);

    wire [63:0] p_signed;
    wire [63:0] p_unsigned;
    reg         signed_r;
    reg         en;

    mult_gen_signed_0 u_signed (
        .CLK (mul_clk),
        .A   (x),
        .B   (y),
        .P   (p_signed)
    );

    mult_gen_unsigned_0 u_unsigned (
        .CLK (mul_clk),
        .A   (x),
        .B   (y),
        .P   (p_unsigned)
    );

    always @(posedge mul_clk) begin
        if (!resetn) begin
            en       <= 1'b0;
            signed_r <= 1'b0;
        end
        else begin
            en       <= 1'b1;
            signed_r <= mul_signed;
        end
    end

    assign result = (!en)        ? 64'd0 :
                    signed_r     ? p_signed :
                                   p_unsigned;

endmodule
