/*
 * Copyright 2026 circuitli (https://github.com)
 *
 * Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://cern-ohl.web.cern.ch/
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`ifndef ASYNC_GLITCH_FILTER_BANK_SVH
`define ASYNC_GLITCH_FILTER_BANK_SVH
`default_nettype none

`include "src/module/async_glitch_filter.sv"

// Variable-width filter bank that instantiates the async_glitch_filter module
module async_glitch_filter_bank #(
    parameter int WIDTH = 13,
    parameter int STAGES = 3
)(
    input  wire             rst_n,
    input  wire [WIDTH-1:0] async_in,
    output wire [WIDTH-1:0] async_out
);

    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : gen_filter_bank
            async_glitch_filter #(
                .STAGES(STAGES)
            ) u_filter (
                .rst_n    (rst_n),
                .async_in (async_in[i]),
                .async_out(async_out[i]) 
            );
        end
    endgenerate

endmodule

`default_nettype wire
`endif