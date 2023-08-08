`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/03 13:24:09
// Design Name: 
// Module Name: layer1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module layer1(clk, rst, start, addr_layer1, dout, done);

input clk, rst, start;
input [11:0] addr_layer1;
output signed [63:0] dout;
output reg done;
wire signed [15:0] dout_in, dout_w;
wire signed [31:0] dout_mul;
reg [12:0] addr_layer1_reg;
reg wea; 
reg signed [31:0] din_layer1;
wire signed [31:0] dout_b;
reg [9:0] addr_in;
reg [7:0] addr_w;
reg [2:0] addr_b;
reg [3:0] state;
reg [2:0] cnt_col;
reg [15:0] cnt_stride_ctrl, cnt_col_stride, cnt_row_stride, cnt_weights_ctrl, cnt_weights_stride, cnt_24,  cnt_addr_ctrl;
reg [31:0] cnt_entire;
reg signed [31:0] sum_mul;

layer1_in u0(.clka(clk), .addra(addr_in), .douta(dout_in));
layer1_w u1(.clka(clk), .addra(addr_w), .douta(dout_w));
layer1_b u2(.clka(clk), .addra(addr_b), .douta(dout_b));
mult u3(.CLK(clk), .A(dout_in), .B(dout_w), .P(dout_mul));
layer1_o u4(.clka(clk) ,.wea(wea), .addra(addr_layer1_reg), .dina(din_layer1), .clkb(clk), .addrb(addr_layer1), .doutb(dout));

localparam IDLE = 4'd0, CONV1 = 4'd1, CONV2 = 4'd2, CONV3 = 4'd3, CONV4 = 4'd4, CONV5 = 4'd5,  DONE = 4'd6;
localparam F_SIZE = 3'd5, NUM_1F_PARAM = 15'd19600, NUM_FULL_PARAM = 17'd117600, NUM_COL_SLIDE = 8'd140, NUM_F_SIZE = 6'd25, OUT_SIZE = 16'd4704;
//                                      (28*28*5*5)                  (28*28*5*5*6)              (5*28)                (5*5)             (28*28*6)
always@(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        case(state)
             IDLE : if(start) state <= CONV1; else state <= IDLE;
             CONV1 : if(cnt_col == F_SIZE - 1'd1) state <= CONV2; else state <= CONV1;
             CONV2 : if(cnt_col == F_SIZE - 1'd1) state <= CONV3;
                     else if(addr_layer1_reg == OUT_SIZE - 1'd1 && cnt_addr_ctrl == 16'd0) state <= DONE;  //WHY CONV2 -> DONE ? TOTAL 7 DELAY
                     else state <= CONV2;       
             CONV3 : if(cnt_col == F_SIZE - 1'd1) state <= CONV4; else state <= CONV3;
             CONV4 : if(cnt_col == F_SIZE - 1'd1) state <= CONV5; else state <= CONV4;
             CONV5 : if(cnt_col == F_SIZE - 1'd1) state <= CONV1;else state <= CONV5;
            // DONE : if(addr_layer1_reg == 2351) state <= IDLE; else state <= DONE; //good write?  confirm
             DONE : state <= IDLE;  
             default : state <= IDLE;
             endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col <= 16'd0;
    else
        case(state)
            CONV1 : if(cnt_col == F_SIZE - 1'd1) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            CONV2 : if(cnt_col == F_SIZE - 1'd1) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            CONV3 : if(cnt_col == F_SIZE - 1'd1) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            CONV4 : if(cnt_col == F_SIZE - 1'd1) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            CONV5 : if(cnt_col == F_SIZE - 1'd1) cnt_col <= 16'd0; else cnt_col <= cnt_col + 1'd1;
            default : cnt_col <= 16'd0;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_stride_ctrl <= 16'd0;
    else
        case(state)
            CONV5 : if(cnt_stride_ctrl == NUM_COL_SLIDE - 1'd1) cnt_stride_ctrl <= 16'd0; else cnt_stride_ctrl <= cnt_stride_ctrl  + 1'd1; 
            default : cnt_stride_ctrl <= cnt_stride_ctrl;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_ctrl <= 16'd0;    
    else
        case(state)
            IDLE:  cnt_weights_ctrl<= 16'd0;
            default : if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1) cnt_weights_ctrl <= 16'd0; else cnt_weights_ctrl <= cnt_weights_ctrl + 1'd1;
            endcase
end


always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col_stride <= 16'd0;
    else if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1)
        cnt_col_stride <= 16'd0;
    else
        case(state)
            CONV5 :  if(cnt_col == F_SIZE - 1'd1 && cnt_stride_ctrl != NUM_COL_SLIDE - 1'd1) cnt_col_stride <= cnt_col_stride + 1'd1;
                     else if(cnt_col == F_SIZE - 1'd1 && cnt_stride_ctrl == NUM_COL_SLIDE - 1'd1) cnt_col_stride <= 0; 
                     else cnt_col_stride <= cnt_col_stride;
            default : cnt_col_stride <= cnt_col_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_row_stride <= 16'd0;
    else if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1) 
        cnt_row_stride <= 16'd0;    
    else
        case(state)
            CONV5 : if(cnt_stride_ctrl == NUM_COL_SLIDE - 1'd1) cnt_row_stride <= cnt_row_stride + 16'd32; else cnt_row_stride <= cnt_row_stride;
            default : cnt_row_stride <= cnt_row_stride;
            endcase
end 


always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_in <= 10'd0;
    else
        if(cnt_entire < NUM_FULL_PARAM)
        case(state)
            IDLE : addr_in <= 10'd0;
            CONV1 : addr_in <= 10'd0 + cnt_col + cnt_col_stride + cnt_row_stride;
            CONV2 : addr_in <= 10'd32 + cnt_col + cnt_col_stride + cnt_row_stride;
            CONV3 : addr_in <= 10'd64 + cnt_col + cnt_col_stride + cnt_row_stride;
            CONV4 : addr_in <= 10'd96 + cnt_col + cnt_col_stride + cnt_row_stride;
            CONV5 : addr_in <= 10'd128 + cnt_col + cnt_col_stride + cnt_row_stride;
           default : addr_in <= addr_in;
           endcase
         else
            addr_in <= 0;
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_stride <= 16'd0;
    else
        case(state)
            IDLE : cnt_weights_stride <= 16'd0;
            DONE : cnt_weights_stride <= 16'd0;
            default :if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1) cnt_weights_stride <= cnt_weights_stride + 6'd25; 
                     else cnt_weights_stride <= cnt_weights_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_24 <= 16'd0;
    else
        case(state)
            IDLE : cnt_24 <= 16'd0;
            default : if(cnt_24 == 16'd24) cnt_24 <= 0; else cnt_24 <= cnt_24 + 1'd1;
            endcase
end 
always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_w <= 5'd0;
    else
        if(cnt_entire < NUM_FULL_PARAM)
        case(state)
            IDLE : addr_w <= 5'd0;
            default : if(addr_w == cnt_weights_stride + NUM_F_SIZE - 1'd1) addr_w <= cnt_weights_stride; 
                      else addr_w <= cnt_weights_stride + cnt_24;
            endcase
        else
            addr_w <= 5'd0;
end      

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_entire <= 32'd0;
    else
        case(state)
            IDLE:  cnt_entire <= 32'd0;
            DONE:  cnt_entire <= 32'd0;
            default : cnt_entire <= cnt_entire + 1'd1;
            endcase
end

//why cnt_entire < 7? read 2, mult 3, sum 1 , delay
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_addr_ctrl <= 16'd0;
    else
        case(state)
            IDLE:  cnt_addr_ctrl <= 16'd0;
            CONV1 : if(cnt_entire < 6) cnt_addr_ctrl <= 16'd0;  else cnt_addr_ctrl <= cnt_addr_ctrl +1'd1;
            CONV2 : if(cnt_entire < 7) cnt_addr_ctrl <= 16'd0; 
                    else if(cnt_addr_ctrl == NUM_F_SIZE - 1'd1) cnt_addr_ctrl <= 16'd0;
                    else cnt_addr_ctrl <= cnt_addr_ctrl +1'd1;
            default : cnt_addr_ctrl <= cnt_addr_ctrl + 1'd1;
            endcase
end
//why cnt < 6 sum_mul zero? read 2, mult 3 delay
always@(posedge clk or posedge rst)
begin
    if(rst)
        sum_mul <= 32'd0;
    else
        case(state)
           IDLE : sum_mul <= 32'd0;
           CONV1 : if(cnt_entire < 6) sum_mul <= 0; else sum_mul <= sum_mul + dout_mul;
           CONV2 : if(cnt_entire < 6) sum_mul <= 0; 
                   else if(cnt_addr_ctrl == NUM_F_SIZE - 1'd1) sum_mul <= dout_mul; 
                   else sum_mul <= sum_mul + dout_mul;
           default : sum_mul <= sum_mul + dout_mul;
           endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_b <= 3'd0;
    else
        begin
        case(state)
            IDLE : addr_b <= 3'd0;
            DONE : addr_b <= 3'd0;
            default :if(cnt_weights_ctrl == NUM_1F_PARAM - 1'd1 && cnt_weights_stride != 7'd125) addr_b <= addr_b + 1'd1; 
                     else addr_b <= addr_b;
            endcase
        end
end 



always@(posedge clk or posedge rst)
begin
    if(rst)
        din_layer1 <= 16'd0;
    else
        case(state)
            CONV2 :if(cnt_addr_ctrl == NUM_F_SIZE - 1'd1) din_layer1 <= (sum_mul+ dout_b > 0) ? sum_mul + dout_b : 0; else din_layer1 <= din_layer1;
            default : din_layer1 <= din_layer1;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
    addr_layer1_reg <= 0;
    else
    case(state)
    CONV2 : if(cnt_addr_ctrl == 16'd0  && cnt_entire > 32'd30 && addr_layer1_reg != OUT_SIZE - 1'd1) addr_layer1_reg <= addr_layer1_reg + 1'd1; 
            else if(addr_layer1_reg == OUT_SIZE - 1'd1 && cnt_addr_ctrl == 16'd0) addr_layer1_reg <= 0;
            else addr_layer1_reg <= addr_layer1_reg;
    default addr_layer1_reg <= addr_layer1_reg;
    endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        wea <= 1'd0;
    else
        case(state)
            CONV2 : if(cnt_addr_ctrl == 24) wea <= 1'd1;  else wea <= 1'd0;
            default : wea <= 1'd0;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        done <= 1'd0;
    else
        case(state)
        DONE : done <= 1'd1;
        default : done <= 1'd0;
        endcase
end


endmodule
