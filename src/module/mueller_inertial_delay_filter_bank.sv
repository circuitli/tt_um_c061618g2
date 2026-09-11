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

`ifndef MUELLER_INERTIAL_DELAY_FILTER_BANK_SV
`define MUELLER_INERTIAL_DELAY_FILTER_BANK_SV

`include "src/module/mueller_inertial_delay_filter.v"

`default_nettype none

// Variable-width filter bank that instantiates the mueller_inertial_delay_filter module
module mueller_inertial_delay_filter_bank #(
    parameter int WIDTH = 13
)(
    input  wire             rst_n,
    input  wire [WIDTH-1:0] async_in,
    output wire [WIDTH-1:0] async_out
);

    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : gen_filter_bank
            mueller_inertial_delay_filter u_filter (
                .rst_n    (rst_n),
                .async_in (async_in[i]),
                .async_out(async_out[i]) 
            );
        end
    endgenerate

endmodule

`default_nettype wire
`endif