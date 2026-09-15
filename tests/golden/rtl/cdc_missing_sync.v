//! GOLDEN FIXTURE - intentionally violates the RTL guidelines. Do not "fix" it.
//! Planted defect: a control signal crosses from the clk_a domain into the
//! clk_b domain through a single flip-flop instead of a two-stage synchronizer.
//!
//! Lines beginning with //! are fixture annotations. tests/gen-eval-cases.sh
//! strips them before inlining this file into an eval prompt, so they can say
//! whatever a human needs without handing the answer to the model under test.

module cdc_missing_sync (
  input  wire clk_a,
  input  wire clk_b,
  input  wire rst_n,
  input  wire req_a,
  output reg  ack_b
);

  reg req_a_r;

  always @(posedge clk_a or negedge rst_n)
    if (!rst_n) req_a_r <= 1'b0;
    else        req_a_r <= req_a;

  always @(posedge clk_b or negedge rst_n)
    if (!rst_n) ack_b <= 1'b0;
    else        ack_b <= req_a_r;

endmodule
