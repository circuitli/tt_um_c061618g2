/*
 * Copyright 2026 circuitli (https://github.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://apache.org
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
 `default_nettype none

module tt_anti_glitch_filter_formal (
    input wire data_in,
    input wire data_out
);

    always_comb begin
        // Without an active clock tree, a combinational logic cell must preserve state integrity
        assert(data_out == data_in);
    end

endmodule