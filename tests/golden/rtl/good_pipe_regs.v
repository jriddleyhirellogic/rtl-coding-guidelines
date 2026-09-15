//! GOLDEN FIXTURE - intentionally CLEAN. This is the false-positive control:
//! a review of this module should not report the rules listed in its .expect
//! file. Keep it conformant if you edit it.
//!
//! The first behavioral pass found two real defects here that made the control
//! unfair: no `default_nettype none (ML_IMPLICIT), and internal pipeline
//! registers named with the _r suffix that NTL_NAM07 reserves for registered
//! output ports. Both are fixed below. If a review starts reporting something
//! new on this file, check the file before blaming the skill.

`default_nettype none

module good_pipe_regs #(
  parameter WIDTH = 8
) (
  input  wire             clk,
  input  wire             rst_n,
  input  wire             valid_in,
  input  wire [WIDTH-1:0] data_in,
  output reg              valid_out_r,
  output reg  [WIDTH-1:0] data_out_r
);

  reg             valid_d1;
  reg [WIDTH-1:0] data_d1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_d1    <= 1'b0;
      data_d1     <= {WIDTH{1'b0}};
      valid_out_r <= 1'b0;
      data_out_r  <= {WIDTH{1'b0}};
    end else begin
      valid_d1    <= valid_in;
      data_d1     <= data_in;
      valid_out_r <= valid_d1;
      data_out_r  <= data_d1;
    end
  end

endmodule

`default_nettype wire
