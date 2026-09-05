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

`ifndef SIGNAL_DIVIDER_BY_4_SV
`define SIGNAL_DIVIDER_BY_4_SV
`default_nettype none

(* keep_hierarchy = 1 *)
module signal_divider_by_4 (
    input  wire clk,              // Master reference clock
    input  wire rst_n,            // Active-low global system reset
    input  wire signal_in,        // Raw data input stream
    output wire signal_out        // Sampled, stable data output (Held for 4 cycles)
);

    // 2-bit counter tracks 4 distinct cycles safely
    (* keep = 1, dont_touch = 1 *) wire [1:0] sample_cnt;
    (* keep = 1, dont_touch = 1 *) wire       data_out_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt   <= 2'd0;
            data_out_reg <= 1'b0;
        end else begin
            if (sample_cnt == 2'd3) begin
                sample_cnt   <= 2'd0;
                data_out_reg <= signal_in; 
            end else begin
                sample_cnt   <= sample_cnt + 1'b1;
                // Structural register hold condition: no toggling, no dropouts
            end
        end
    end

    assign signal_out = data_out_reg;

endmodule

`default_nettype wire
`endif