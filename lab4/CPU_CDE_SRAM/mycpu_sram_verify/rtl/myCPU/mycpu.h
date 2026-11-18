`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD       33
    `define FS_TO_DS_BUS_WD 65
    `define DS_TO_ES_BUS_WD 192
    `define ES_TO_MS_BUS_WD 154
    `define MS_TO_WS_BUS_WD 149
    `define WS_TO_RF_BUS_WD 38

    `define CP0_NONE 2'd0
    `define CP0_MFC  2'd1
    `define CP0_MTC  2'd2
    `define CP0_ERET 2'd3

    `define EXC_INT  5'd0
    `define EXC_ADEL 5'd4
    `define EXC_ADES 5'd5
    `define EXC_SYS  5'd8
    `define EXC_BP   5'd9
    `define EXC_RI   5'd10
    `define EXC_OV   5'd12

    `define MEM_NONE 4'd0
    `define MEM_LW   4'd1
    `define MEM_LB   4'd2
    `define MEM_LBU  4'd3
    `define MEM_LH   4'd4
    `define MEM_LHU  4'd5
    `define MEM_LWL  4'd6
    `define MEM_LWR  4'd7
    `define MEM_SW   4'd8
    `define MEM_SB   4'd9
    `define MEM_SH   4'd10
    `define MEM_SWL  4'd11
    `define MEM_SWR  4'd12

    `define MD_NONE  4'd0
    `define MD_MULT  4'd1
    `define MD_MULTU 4'd2
    `define MD_DIV   4'd3
    `define MD_DIVU  4'd4
    `define MD_MFHI  4'd5
    `define MD_MFLO  4'd6
    `define MD_MTHI  4'd7
    `define MD_MTLO  4'd8
`endif
