`timescale 1ns/1ps

module tb_sync;

// Parameters matching DUT
parameter DEPTH    = 22;
parameter WIDTH    = 8;
parameter CLK_PERIOD = 10;

// Testbench signals
reg                     clk;
reg                     rst_n;
reg                     wen;
reg  [WIDTH-1:0]        din;
reg                     ren;
wire [WIDTH-1:0]        dout;
wire                    wfull;
wire                    rempty;

// Instantiate the FIFO under test
sync_fifo #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
) dut (
    .clk   (clk),
    .rst_n (rst_n),
    .wen   (wen),
    .din   (din),
    .ren   (ren),
    .dout  (dout),
    .wfull (wfull),
    .rempty(rempty)
);

// Clock generator
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Monitor signals
initial begin
    $display("Time    wen din   wfull | ren dout rempty");
    $monitor("%0t  %b   %02h     %b   | %b   %02h    %b", 
             $time, wen, din, wfull, ren, dout, rempty);
end

// Test sequence
initial begin
    // Reset
    rst_n = 0;
    wen   = 0;
    ren   = 0;
    din   = 0;
    #(CLK_PERIOD*3);
    rst_n = 1;
    #(CLK_PERIOD);

    // Write until full
    $display("\n--- Writing to FIFO ---");
    repeat (DEPTH+2) begin
        @(posedge clk);
        if (!wfull) begin
            wen <= 1;
            din <= $random;
        end else begin
            wen <= 0;
        end
    end
    @(posedge clk) wen <= 0;
    $display("wfull = %b (expected 1)", wfull);

    // Read until empty
    $display("\n--- Reading from FIFO ---");
    repeat (DEPTH+2) begin
        @(posedge clk);
        if (!rempty) begin
            ren <= 1;
        end else begin
            ren <= 0;
        end
    end
    @(posedge clk) ren <= 0;
    $display("rempty = %b (expected 1)", rempty);

    $display("\n*** Test complete ***");

end

endmodule
