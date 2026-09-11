`ifndef OAI211_1_V
`define OAI211_1_V
`default_nettype none

module oai211_1 (
    input  wire A1,
    input  wire A2,
    input  wire B1,
    input  wire C1,
    output wire Y
);

`ifdef IHP_SG13G2
    // IHP SG13G2 Open-Source 130nm OAI211 Compound Cell Implementation
    wire oa_combined_net;
    wire or_bracket_net;

    // 1. First-stage structural OR gate (A1 | A2)
    sg13g2_or2_1 u_ihp_or (
        .A(A1),
        .B(A2),
        .X(or_bracket_net)
    );

    // 2. Second-stage AND gate multiplying the OR term and your B1 rail
    sg13g2_and2_1 u_ihp_and (
        .A(or_bracket_net),
        .B(B1),
        .X(oa_combined_net)
    );

    // 3. Final structural inverter driven by your C1 mask rail to form the complete OAI stack
    // Note: If C1 acts as an active-high reset, it masks the output node here
    sg13g2_inv_1 u_ihp_output_inv (
        .A(oa_combined_net | C1),
        .Y(Y)
    );

`elsif SKY130
    // SkyWater Sky130 Native High-Density OAI211 Cell Footprint
    sky130_fd_sc_hd__oai211_1 u_sky_oai (
        .A1(A1),
        .A2(A2),
        .B1(B1),
        .C1(C1),
        .Y(Y)
    );

`elsif GF180MCU
    // GlobalFoundries Native 7-track 5V OAI211 Footprint
    gf180mcu_fd_sc_mcu7t5v0__oai211_1 u_gf_oai (
        .I0(A1),
        .I1(A2),
        .I2(B1),
        .I3(C1),
        .Z(Y)
    );

`else
    // Pure behavioral fallback for local verification (Verilator / SBY)
    assign Y = !((A1 || A2) && B1 && C1);
`endif

endmodule

`default_nettype wire
`endif
