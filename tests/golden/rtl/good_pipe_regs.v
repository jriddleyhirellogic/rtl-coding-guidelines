//! GOLDEN FIXTURE - intentionally CLEAN. This is the false-positive control:
//! a review of this module should not report the rules listed in its .expect
//! file. Keep it conformant if you edit it.

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

  reg             valid_d1_r;
  reg [WIDTH-1:0] data_d1_r;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_d1_r  <= 1'b0;
      data_d1_r   <= {WIDTH{1'b0}};
      valid_out_r <= 1'b0;
      data_out_r  <= {WIDTH{1'b0}};
    end else begin
      valid_d1_r  <= valid_in;
      data_d1_r   <= data_in;
      valid_out_r <= valid_d1_r;
      data_out_r  <= data_d1_r;
    end
  end

endmodule
