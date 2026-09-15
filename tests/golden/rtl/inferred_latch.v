//! GOLDEN FIXTURE - intentionally violates the RTL guidelines. Do not "fix" it.
//! Planted defects: an incomplete case statement with no default inside a
//! combinational always block (inferred latch), a clock port not named clk*,
//! and an active-low reset port named neither rst* nor with an _n/_x suffix.

module inferred_latch (
  input  wire       CLOCK,
  input  wire       RESET_L,
  input  wire [1:0] sel,
  input  wire [7:0] a,
  input  wire [7:0] b,
  output reg  [7:0] result
);

  reg [7:0] mux_out;

  always @(*)
    case (sel)
      2'b00: mux_out = a;
      2'b01: mux_out = b;
      2'b10: mux_out = a ^ b;
    endcase

  always @(posedge CLOCK or negedge RESET_L)
    if (!RESET_L) result <= 8'h00;
    else          result <= mux_out;

endmodule
