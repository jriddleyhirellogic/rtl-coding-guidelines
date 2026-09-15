//! GOLDEN FIXTURE - intentionally violates the RTL guidelines. Do not "fix" it.
//! Planted defects: a clock generated inside the block by a divider, that clock
//! then gated with an AND gate, and an inverter placed on the clock path.

module gated_clock_div (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       enable,
  input  wire [7:0] din,
  output reg  [7:0] dout
);

  reg  div_clk;
  wire gated_clk;
  wire inv_clk;

  always @(posedge clk or negedge rst_n)
    if (!rst_n) div_clk <= 1'b0;
    else        div_clk <= ~div_clk;

  assign gated_clk = div_clk & enable;
  assign inv_clk   = ~gated_clk;

  always @(posedge inv_clk or negedge rst_n)
    if (!rst_n) dout <= 8'h00;
    else        dout <= din;

endmodule
