`timescale 1ns / 1ps

// Plays one round of memory_game against the real SoC.
// Button rows follow the confreg column scan. The LED echo in
// detectKeyPresses is the handshake that a key was sampled.
module game_tb;
reg resetn;
reg clk;

wire [15:0] led;
wire [1:0]  led_rg0;
wire [1:0]  led_rg1;
wire [7:0]  num_csn;
wire [6:0]  num_a_g;
wire [7:0]  switch;
wire [3:0]  btn_key_col;
reg  [3:0]  btn_key_row;
wire [1:0]  btn_step;

assign switch   = 8'hff;
assign btn_step = 2'd3;

initial begin
    clk = 1'b0;
    resetn = 1'b0;
    #2000;
    resetn = 1'b1;
end
always #5 clk = ~clk;

soc_lite_top #(.SIMULATION(1'b1)) soc_lite (
    .resetn      (resetn),
    .clk         (clk),
    .num_csn     (num_csn),
    .num_a_g     (num_a_g),
    .led         (led),
    .led_rg0     (led_rg0),
    .led_rg1     (led_rg1),
    .switch      (switch),
    .btn_key_col (btn_key_col),
    .btn_key_row (btn_key_row),
    .btn_step    (btn_step)
);

wire [2:0]  kstate   = soc_lite.confreg.state;
wire [31:0] num_data = soc_lite.confreg.num_data;

localparam P_WAIT  = 0;
localparam P_HOLD  = 1;
localparam P_REC   = 2;
localparam P_PLAY  = 3;
localparam P_REL   = 4;
localparam P_SCORE = 5;

reg [2:0]  phase;
reg        pressing;
reg [2:0]  target;
reg [31:0] hold;
reg [3:0]  pat0, pat1, pat2, pat3, pat4, pat5, pat6, pat7;
reg [3:0]  npat;
reg [2:0]  nplay;
reg [3:0]  expect;
reg [15:0] led_d;
reg [31:0] cyc;
reg        saw_pattern;

function [2:0] col_of;
    input [3:0] p;
    begin
        case (p)
            4'd8: col_of = 3'b001;
            4'd4: col_of = 3'b010;
            4'd2: col_of = 3'b011;
            4'd1: col_of = 3'b100;
            default: col_of = 3'b001;
        endcase
    end
endfunction

function [3:0] pat_at;
    input [2:0] n;
    begin
        case (n)
            3'd0: pat_at = pat0;
            3'd1: pat_at = pat1;
            3'd2: pat_at = pat2;
            3'd3: pat_at = pat3;
            3'd4: pat_at = pat4;
            3'd5: pat_at = pat5;
            3'd6: pat_at = pat6;
            3'd7: pat_at = pat7;
            default: pat_at = 4'd0;
        endcase
    end
endfunction

wire is_pat = (led == 16'hfffe) || (led == 16'hfffd) ||
              (led == 16'hfffb) || (led == 16'hfff7);
wire [3:0] seen = (~led) & 4'hf;

function [15:0] echo_of;
    input [3:0] p;
    begin
        case (p)
            4'd1: echo_of = 16'hfffe;
            4'd2: echo_of = 16'hfffd;
            4'd4: echo_of = 16'hfffb;
            4'd8: echo_of = 16'hfff7;
            default: echo_of = 16'h0000;
        endcase
    end
endfunction

always @(*) begin
    if (!pressing)
        btn_key_row = 4'b1111;
    else if (kstate == 3'b000 || kstate == 3'b111 || kstate == target)
        btn_key_row = 4'b0111;
    else
        btn_key_row = 4'b1111;
end

task remember;
    input [3:0] p;
    begin
        case (npat)
            3'd0: pat0 = p;
            3'd1: pat1 = p;
            3'd2: pat2 = p;
            3'd3: pat3 = p;
            3'd4: pat4 = p;
            3'd5: pat5 = p;
            3'd6: pat6 = p;
            3'd7: pat7 = p;
        endcase
        $display("GAME pattern[%0d]=%0d led=%04x at %0d", npat, p, led, cyc);
        npat = npat + 1;
    end
endtask

always @(posedge clk) begin
    if (!resetn) begin
        phase <= P_WAIT;
        pressing <= 1'b0;
        target <= 3'b001;
        hold <= 0;
        npat <= 0;
        nplay <= 0;
        expect <= 0;
        led_d <= 16'h0;
        cyc <= 0;
        saw_pattern <= 1'b0;
        pat0 <= 0; pat1 <= 0; pat2 <= 0; pat3 <= 0;
        pat4 <= 0; pat5 <= 0; pat6 <= 0; pat7 <= 0;
    end else begin
        cyc <= cyc + 1;
        led_d <= led;
        case (phase)
            P_WAIT: begin
                if (led == 16'hffff) begin
                    pressing <= 1'b1;
                    target <= 3'b001;
                    hold <= 0;
                    phase <= P_HOLD;
                    $display("GAME start-key at %0d", cyc);
                end
            end
            P_HOLD: begin
                hold <= hold + 1;
                if (hold == 32'd8000) begin
                    pressing <= 1'b0;
                    phase <= P_REC;
                    $display("GAME start released at %0d", cyc);
                end
            end
            P_REC: begin
                if (is_pat && led != led_d && npat < 4'd8) begin
                    saw_pattern <= 1'b1;
                    remember(seen);
                end
                if (npat == 4'd0 && cyc > 32'd800000) begin
                    $display("----GAME FAIL!!! no pattern----");
                    $finish;
                end
                if (npat == 4'd8 && led == 16'hffff && led_d != 16'hffff) begin
                    pressing <= 1'b1;
                    nplay <= 0;
                    expect <= pat_at(0);
                    target <= col_of(pat_at(0));
                    phase <= P_PLAY;
                    $display("GAME play 0 target pat %0d at %0d", pat_at(0), cyc);
                end
            end
            P_PLAY: begin
                if (is_pat && led == echo_of(expect)) begin
                    pressing <= 1'b0;
                    phase <= P_REL;
                    $display("GAME echo %0d led=%04x expect=%04x at %0d",
                             nplay, led, echo_of(expect), cyc);
                end
            end
            P_REL: begin
                if (led == 16'hffff) begin
                    if (nplay == 3'd7) begin
                        phase <= P_SCORE;
                        $display("GAME waiting score at %0d", cyc);
                    end else begin
                        nplay <= nplay + 1;
                        expect <= pat_at(nplay + 1);
                        pressing <= 1'b1;
                        target <= col_of(pat_at(nplay + 1));
                        phase <= P_PLAY;
                        $display("GAME play %0d target pat %0d at %0d",
                                 nplay + 1, pat_at(nplay + 1), cyc);
                    end
                end
            end
            P_SCORE: begin
                if (led_rg1 != 2'b00) begin
                    $display("GAME num=%08x rg0=%0d rg1=%0d", num_data, led_rg0, led_rg1);
                    $display("GAME seq %0d %0d %0d %0d %0d %0d %0d %0d",
                        pat0, pat1, pat2, pat3, pat4, pat5, pat6, pat7);
                    if (num_data[7:0] == 8'd8 && led_rg1 == 2'b01)
                        $display("----GAME PASS!!!----");
                    else
                        $display("----GAME FAIL!!!----");
                    $finish;
                end
            end
        endcase
        if (cyc > 32'd2500000) begin
            $display("----GAME TIMEOUT!!! phase %0d npat %0d nplay %0d led %04x----",
                     phase, npat, nplay, led);
            $finish;
        end
    end
end
endmodule
