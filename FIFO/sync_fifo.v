module sync_fifo#(
	parameter DEPTH = 16,
	parameter WIDTH = 8
)
(
	input						clk,
	input						rst_n,
	input 						wen,
	input		[WIDTH -1:0] 	din,
	input						ren,
	
	output	reg	[WIDTH -1:0] 	dout,				
	output						wfull,
	output						rempty
);
localparam ADDR_WIDTH = $clog2(DEPTH);

reg [WIDTH- 1:0] mem [0:DEPTH-1];
reg [ADDR_WIDTH :0] data_cnt;
reg [ADDR_WIDTH-1 :0] w_ptr;
reg [ADDR_WIDTH-1 :0] r_ptr;

always@(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		w_ptr <= 'd0;
		r_ptr <= 'd0;
	end
	else begin
		if(wen && !wfull && w_ptr == DEPTH -1)
			w_ptr <= 'd0;
		else if(wen && !wfull)
			w_ptr <= w_ptr + 1;
		if(ren && !rempty && r_ptr == DEPTH -1)	
			r_ptr <= 'd0;
		else if(ren && !rempty)
			r_ptr <= r_ptr + 1;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(rst_n && wen && !wfull)
		mem[w_ptr[ADDR_WIDTH -1:0]] <= din;
end


always@(posedge clk or negedge rst_n) begin
	if(~rst_n)
		dout <= 'd0;
	if(ren && !rempty)
		dout <= mem[r_ptr[ADDR_WIDTH -1:0]];
end

always @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		data_cnt <= 'd0;
	else if(wen && !wfull && ren && !rempty)
		data_cnt <= data_cnt;
	else if(wen && !wfull)
		data_cnt <= data_cnt+1;
	else if(ren && !rempty)
		data_cnt <= data_cnt -1;
end
assign wfull = data_cnt == DEPTH;
assign rempty = data_cnt == 0;
// assign wfull = (w_ptr[ADDR_WIDTH] != r_ptr[ADDR_WIDTH] && w_ptr[ADDR_WIDTH -1:0]==r_ptr[ADDR_WIDTH -1:0]);
// assign rempty = (w_ptr==r_ptr);
// assign data_cnt = w_ptr-r_ptr;
endmodule