module async_fifo#
(
	parameter WIDTH = 8,
	parameter DEPTH = 13,
	parameter CELL_DEPTH = 16
)(
	input						wclk	,
	input						rclk	,
	input						rst_n 	,
	input						wr_en	,
	input		[WIDTH -1:0]	din		,
	input						rd_en	,
	
	output	reg [WIDTH -1:0] 	dout	,
	output 						wfull	,
	output						rempty
);

localparam	AW = $clog2(DEPTH);
reg [WIDTH -1:0] mem[0: DEPTH -1];
reg [AW :0] w_ptr_bin;
reg [AW :0] r_ptr_bin;

wire [AW :0] w_ptr_map; // 映射，最高bit位指示第0圈还是第1圈，减少格雷码翻转bit次数
wire [AW :0] r_ptr_map;

wire [AW :0] w_ptr_gray;
wire [AW :0] r_ptr_gray;
reg [AW :0] w_ptr_gray_local; // 本地打拍
reg [AW :0] r_ptr_gray_local;


reg [AW :0] w_ptr_g2r; // cdc
reg [AW :0] w_ptr_g2r_d0; 
reg [AW :0] w_ptr_g2r_d1; 
reg [AW :0] r_ptr_g2w;
reg [AW :0] r_ptr_g2w_d0;
reg [AW :0] r_ptr_g2w_d1; 

wire [AW :0] r2w_g2b_map; //格雷码转二进制
wire [AW :0] w2r_g2b_map; 
wire [AW :0] r2w_g2b; 	//格雷码转二进制后进行反映射
wire [AW :0] w2r_g2b; 





always@(posedge wclk or negedge rst_n) begin
	if(~rst_n)
		w_ptr_bin <= 'd0;
	else if(wr_en && !wfull) begin
		if(w_ptr_bin[AW-1:0] == DEPTH -1)
			w_ptr_bin <= {(!w_ptr_bin[AW]),{(AW){1'b0}}};
		else
			w_ptr_bin <= w_ptr_bin + 1;
	end
end

always@(posedge rclk or negedge rst_n) begin
	if(~rst_n)
		r_ptr_bin <= 'd0;
	else if(rd_en && !rempty) begin
		if(r_ptr_bin[AW-1:0] == DEPTH -1)
			r_ptr_bin <= {!(r_ptr_bin[AW]),{(AW){1'b0}}};
		else
			r_ptr_bin <= r_ptr_bin + 1;
	end
end

always@(posedge wclk) begin
	if(wr_en && !wfull)
		mem[w_ptr_bin[AW-1:0]] <= din;
end
always@(posedge rclk) begin
	if(rd_en && !rempty)
		dout <= mem[r_ptr_bin[AW-1:0]];
end
//============================ 格雷码跨时钟域空满判断 ============================//
/*******************************************************************************
if depth is 6, cell depth should be 8, so "cell - depth = 8-6 = 2"
		bin		map		map oprated gray							   oringal gray
		0000	0010 		0011											0000
		0001	0011		0010                                        	0001
		0010	0100 		0110                                        	0011
		0011	0101		0111                                        	0010
first	0100	0110		0101                                        	0110
depth:	0101	0111 —————	0100                                        	0111 -----
		----	----     |------- ————> only singel bit flip in gray √  	----     |-- three bits flip × incorrect
		1000 	1000 <———|	1100                                        	1100 <---|
		1001    1001		1101                                        	1101
		1010    1010		1111                                        	1111
		1011    1011		1110                                        	1110
second	1100    1100		1010                                        	1010
depth:	1101    1101		1011                                        	1011
		^		^			^
*********************************************************************************/

assign w_ptr_map = (w_ptr_bin[AW])? w_ptr_bin : w_ptr_bin + CELL_DEPTH - DEPTH ; // 映射，翻转位为1代表写满了一圈，已经是第二圈了，第二圈就用原指针
assign r_ptr_map = (r_ptr_bin[AW])? r_ptr_bin : r_ptr_bin + CELL_DEPTH - DEPTH ;

assign w_ptr_gray = w_ptr_map ^ (w_ptr_map >> 1);
assign r_ptr_gray = r_ptr_map ^ (r_ptr_map >> 1);
always@(posedge wclk) begin
	if(~rst_n)
		w_ptr_gray_local <= 'd0;
	else
		w_ptr_gray_local <= w_ptr_gray;
end
always@(posedge rclk) begin
	if(~rst_n)
		r_ptr_gray_local <= 'd0;
	else
		r_ptr_gray_local <= r_ptr_gray;
end
always@(posedge wclk or negedge rst_n) begin
	if(~rst_n) begin
		r_ptr_g2w		<= 'd0 ;
		r_ptr_g2w_d0	<= 'd0 ;
		r_ptr_g2w_d1	<= 'd0 ;
	end
	else begin
		r_ptr_g2w		<= r_ptr_gray_local ;
	    r_ptr_g2w_d0	<= r_ptr_g2w ;
	    r_ptr_g2w_d1	<= r_ptr_g2w_d0;
	end	
end
always@(posedge rclk or negedge rst_n) begin
	if(~rst_n) begin
		w_ptr_g2r		<= 'd0 ;
		w_ptr_g2r_d0	<= 'd0 ;
		w_ptr_g2r_d1	<= 'd0 ;
	end
	else begin
		w_ptr_g2r		<= w_ptr_gray_local ;
	    w_ptr_g2r_d0	<= w_ptr_g2r ;
	    w_ptr_g2r_d1	<= w_ptr_g2r_d0;
	end	
end
// gray to bin
assign r2w_g2b_map = g2b(r_ptr_g2w_d1);

assign w2r_g2b_map = g2b(w_ptr_g2r_d1);

// 反映射
assign r2w_g2b = (r2w_g2b_map[AW])? r2w_g2b_map : r2w_g2b_map-(CELL_DEPTH-DEPTH);
assign w2r_g2b = (w2r_g2b_map[AW])? w2r_g2b_map : w2r_g2b_map-(CELL_DEPTH-DEPTH);

assign wfull = r2w_g2b == {~w_ptr_bin[AW], w_ptr_bin[AW -1:0]};
assign rempty = w2r_g2b == r_ptr_bin;


  // 写时钟域：本地写指针 w_ptr_bin 与跨域同步回来的读指针 r2w_g2b 的差值，
  // 模 2^(AW+1) 运算后，就是 FIFO 里目前的有效数据量
  wire [AW:0] w_fifo_cnt = (w_ptr_bin  - r2w_g2b) 
                          & ((1<<(AW+1)) - 1);

  // 读时钟域：本地读指针 r_ptr_bin 与跨域同步回来的写指针 w2r_g2b 的差值，
  // 模 2^(AW+1) 运算后，就是 FIFO 里待读的数据量
  wire [AW:0] r_fifo_cnt = (w2r_g2b - r_ptr_bin) 
                          & ((1<<(AW+1)) - 1);
						  

function [AW:0] g2b(input [AW:0] gray);
	integer i;
	begin
		g2b[AW] = gray[AW];
		for(i=AW-1;i>=0;i=i-1)
			g2b[i] = g2b[i+1]^gray[i];
	end
endfunction

endmodule
 