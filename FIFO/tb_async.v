`timescale 1ns/1ps

module async_fifo_tb;

  // Parameters
  parameter WIDTH      = 8;
  parameter DEPTH      = 13;
  parameter CELL_DEPTH = 16;
  parameter WR_CLK_PERIOD = 10;
  parameter RD_CLK_PERIOD = 15;

  // Testbench Signals
  reg                     wr_clk;
  reg                     rd_clk;
  reg                     rst_n;
  reg                     wr_en;
  reg  [WIDTH-1:0]        din;
  reg                     rd_en;
  wire [WIDTH-1:0]        dout;
  wire                    wfull;
  wire                    rempty;

  // Instantiate DUT
  async_fifo #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH),
    .CELL_DEPTH(CELL_DEPTH)
  ) dut (
    .wclk(wr_clk),
    .rclk(rd_clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .din(din),
    .rd_en(rd_en),
    .dout(dout),
    .wfull(wfull),
    .rempty(rempty)
  );

  // Clock Generation
  initial begin
    wr_clk = 0;
    forever #(WR_CLK_PERIOD/2) wr_clk = ~wr_clk;
  end
  initial begin
    rd_clk = 0;
    forever #(RD_CLK_PERIOD/2) rd_clk = ~rd_clk;
  end

  // Stimulus
  integer i;
  reg [WIDTH-1:0] write_data [0:31];
  initial begin
    // Prepare write segments
    for (i = 0; i < 32; i = i + 1) write_data[i] = i;

    // Reset
    rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    din   = 0;
    #(WR_CLK_PERIOD*4);
    rst_n = 1;
    #(WR_CLK_PERIOD*2);

    // First write segment: write 8 words
    $display("--- First write segment ---");
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge wr_clk);
      if (!wfull) begin
        wr_en <= 1;
        din   <= write_data[i];
      end else begin
        wr_en <= 0;
      end
    end
    @(posedge wr_clk) wr_en <= 0;

    // Delay, then read segment
    #(RD_CLK_PERIOD*4);
    $display("--- First read segment ---");
    for (i = 0; i < 8; i = i + 1) begin
      @(posedge rd_clk);
      if (!rempty) begin
        rd_en <= 1;
      end else begin
        rd_en <= 0;
      end
      @(posedge rd_clk);
      if (rd_en) $display("Read %0d: dout = %0d", i, dout);
    end
    @(posedge rd_clk) rd_en <= 0;

    // Second write segment: write 12 words
    #(WR_CLK_PERIOD*4);
    $display("--- Second write segment ---");
    for (i = 8; i < 20; i = i + 1) begin
      @(posedge wr_clk);
      if (!wfull) begin
        wr_en <= 1;
        din   <= write_data[i];
      end else begin
        wr_en <= 0;
      end
    end
    @(posedge wr_clk) wr_en <= 0;

    // Delay, then read second segment
    #(RD_CLK_PERIOD*4);
    $display("--- Second read segment ---");
    for (i = 8; i < 20; i = i + 1) begin
      @(posedge rd_clk);
      if (!rempty) begin
        rd_en <= 1;
      end else begin
        rd_en <= 0;
      end
      @(posedge rd_clk);
      if (rd_en) $display("Read %0d: dout = %0d", i, dout);
    end
    @(posedge rd_clk) rd_en <= 0;

    $display("*** Test Complete ***");
  end

endmodule