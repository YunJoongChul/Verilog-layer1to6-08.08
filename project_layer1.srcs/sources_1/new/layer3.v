`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/05 14:35:10
// Design Name: 
// Module Name: layer3
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


module layer3(clk, rst, start, dout_layer2, addr_layer2, addr_layer3, dout, done);
input clk, rst, start;
input signed [31:0] dout_layer2;
input [10:0] addr_layer3;
output reg [10:0] addr_layer2;
output signed [95:0] dout;
output reg done;
wire signed [15:0] dout_w;
reg [3:0] state;
reg [11:0] addr_w;
reg [2:0] cnt_col, cnt_weight_6ch;
reg [15:0] cnt_stride_ctrl, cnt_col_stride, cnt_row_stride, cnt_ch,cnt_ch_ctrl, cnt_weights_ctrl, cnt_weights_stride, cnt_150, cnt_addr_ctrl;
reg [31:0] cnt_entire;
reg [10:0] addr_layer3_reg;
reg signed[47:0] din_layer3;
reg signed[47:0] sum_mul;
wire signed [47:0] dout_mul;
reg [9:0] addrb;
reg [3:0] addr_b;
wire signed [47:0] dout_b;
reg wea;
localparam IDLE = 4'd0, CONV1 = 4'd1, CONV2 = 4'd2, CONV3 = 4'd3, CONV4 = 4'd4, CONV5 = 4'd5,  DONE = 4'd6;

layer3_w u0(.clka(clk), .addra(addr_w), .douta(dout_w));
layer3_b u1(.clka(clk), .addra(addr_b), .douta(dout_b));
mult_32n16_48 u2(.CLK(clk), .A(dout_layer2), .B(dout_w), .P(dout_mul));
layer3_o u3(.clka(clk) ,.wea(wea), .addra(addr_layer3_reg), .dina(din_layer3), .clkb(clk), .addrb(addr_layer3), .doutb(dout));


always@(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        case(state)
             IDLE : if(start) state <= CONV1; else state <= IDLE;
             CONV1 : if(cnt_col == 4 && cnt_ch_ctrl == 5) state <= CONV2; else if(addr_layer3_reg == 13'd1599 && cnt_addr_ctrl == 16'd0) state <= DONE;  else state <= CONV1;
             CONV2 : if(cnt_col == 4 && cnt_ch_ctrl == 5) state <= CONV3; else state <= CONV2;
             CONV3 : if(cnt_col == 4 && cnt_ch_ctrl == 5) state <= CONV4; else state <= CONV3;
             CONV4 : if(cnt_col == 4 && cnt_ch_ctrl == 5) state <= CONV5; else state <= CONV4;
             CONV5 : if(cnt_col == 4 && cnt_ch_ctrl == 5) state <= CONV1;else state <= CONV5;
             //DONE : if(addrb == 799) state <= IDLE; else state <= DONE; //good write?  confirm
             DONE : state <= IDLE;  
             default : state <= IDLE;
             endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_ch_ctrl <= 16'd0;
    else
       case(state)
        IDLE : cnt_ch_ctrl <= 16'd0;
        DONE : cnt_ch_ctrl <= 16'd0;
        default if(cnt_ch_ctrl == 5) cnt_ch_ctrl <= 0; else cnt_ch_ctrl <= cnt_ch_ctrl + 1'd1;
        endcase
end
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_ch <= 16'd0;
    else
        case(state)
            IDLE : cnt_ch <= 16'd0;
            DONE : cnt_ch <= 16'd0;
            default :if(cnt_ch_ctrl == 5) cnt_ch <= 16'd0;  else cnt_ch <= cnt_ch + 16'd196;
            endcase
end
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col <= 16'd0;
    else
        case(state)
            IDLE : cnt_col <= 16'd0;
            DONE : cnt_col <= 16'd0;
        
            default :if(cnt_col == 4&& cnt_ch_ctrl == 5) cnt_col <= 16'd0; else if(cnt_ch_ctrl == 5) cnt_col <= cnt_col + 1'd1; else cnt_col <= cnt_col;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_stride_ctrl <= 16'd0;
    else
        case(state)
            CONV5 : if(cnt_stride_ctrl == 299) cnt_stride_ctrl <= 0; else cnt_stride_ctrl  <= cnt_stride_ctrl  + 1'd1; 
            default : cnt_stride_ctrl <= cnt_stride_ctrl;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col_stride <= 16'd0;
    else if(cnt_weights_ctrl == 14999)
        cnt_col_stride <= 16'd0;
    else
        case(state)
            CONV5 : if(cnt_col == 4 && cnt_ch_ctrl == 5 &&cnt_stride_ctrl != 299) cnt_col_stride <= cnt_col_stride + 1'd1; else if(cnt_col == 4 && cnt_ch_ctrl == 5 &&cnt_stride_ctrl == 299) cnt_col_stride <= 0; else cnt_col_stride <= cnt_col_stride;
            default : cnt_col_stride <= cnt_col_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_row_stride <= 16'd0;
    else if(cnt_weights_ctrl == 14999) 
        cnt_row_stride <= 16'd0;    
    else
        case(state)
            CONV5 : if(cnt_stride_ctrl == 299) cnt_row_stride <= cnt_row_stride + 16'd14; else cnt_row_stride <= cnt_row_stride;
            default : cnt_row_stride <= cnt_row_stride;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_layer2 <= 10'd0;
    else
        if(cnt_entire < 32'd240000)
        case(state)
            IDLE : addr_layer2 <= 10'd0;
            CONV1 : addr_layer2 <= 10'd0 + cnt_col + cnt_col_stride + cnt_row_stride + cnt_ch;
            CONV2 : addr_layer2 <= 10'd14 + cnt_col + cnt_col_stride + cnt_row_stride + cnt_ch;
            CONV3 : addr_layer2 <= 10'd28 + cnt_col + cnt_col_stride + cnt_row_stride + cnt_ch;
            CONV4 : addr_layer2 <= 10'd42 + cnt_col + cnt_col_stride + cnt_row_stride + cnt_ch;
            CONV5 : addr_layer2 <= 10'd56 + cnt_col + cnt_col_stride + cnt_row_stride + cnt_ch;
           default : addr_layer2 <= addr_layer2;
           endcase
        else
            addr_layer2 <= 10'd0;
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_ctrl <= 16'd0;    
    else
        case(state)
            IDLE:  cnt_weights_ctrl<= 16'd0;
            default : if(cnt_weights_ctrl == 14999) cnt_weights_ctrl <= 0; else cnt_weights_ctrl <= cnt_weights_ctrl + 1'd1;
            endcase
end



always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_weights_stride <= 16'd0;
    else
        case(state)
            IDLE : cnt_weights_stride <= 16'd0;
            DONE : cnt_weights_stride <= 16'd0;
            default :if(cnt_weights_ctrl == 14999) cnt_weights_stride <= cnt_weights_stride + 150; else cnt_weights_stride <= cnt_weights_stride;
       
            endcase
end 
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_150 <= 16'd0;
    else
        case(state)
            IDLE : cnt_150 <= 16'd0;
            default : if(cnt_150 == 16'd149) cnt_150 <= 0; else cnt_150 <= cnt_150 + 1'd1;
            endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_w <= 12'd0;
    else
        if(cnt_entire < 32'd240000)
        case(state)
            IDLE : addr_w <= 12'd0;
            default : if(addr_w == cnt_weights_stride + 149) addr_w <= cnt_weights_stride; else  addr_w <= cnt_weights_stride + cnt_150;
            endcase
        else
            addr_w <= 12'd0;
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

//why cnt_ram < 7? read 2, mult 3, sum 1 , delay
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_addr_ctrl <= 16'd0;
    else
        case(state)
            IDLE:  cnt_addr_ctrl <= 16'd0;
            CONV1 : if(cnt_entire < 7) cnt_addr_ctrl <= 0;  
                     else if(cnt_addr_ctrl == 149) cnt_addr_ctrl <= 0;
                     else cnt_addr_ctrl <= cnt_addr_ctrl +1'd1;
            default : cnt_addr_ctrl <= cnt_addr_ctrl + 1'd1;
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
            default :if(cnt_weights_ctrl == 14999 &&  cnt_weights_stride != 2250) addr_b <= addr_b + 1'd1; else addr_b <= addr_b;
            endcase
        end
end 


//why cmt < 6 sum mul zero? read 2, mult 3 delay
always@(posedge clk or posedge rst)
begin
    if(rst)
        sum_mul <= 32'd0;
    else
        case(state)
           IDLE : sum_mul <= 0;
           CONV1 : if(cnt_entire < 6) sum_mul <= 0; else if(cnt_addr_ctrl == 149) sum_mul <= dout_mul; else sum_mul <= sum_mul + dout_mul;
           default : sum_mul <= sum_mul + dout_mul;
           endcase
end
always@(posedge clk or posedge rst)
begin
    if(rst)
        din_layer3 <= 16'd0;
    else
        case(state)
            CONV1 :if(cnt_addr_ctrl == 8'd149) din_layer3 <= (sum_mul+ dout_b > 0) ? sum_mul + dout_b : 0; else din_layer3 <= din_layer3;
            default : din_layer3 <= din_layer3;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
    addr_layer3_reg <= 0;
    else
    case(state)
    CONV1 : if(cnt_addr_ctrl == 16'd0  && cnt_entire > 155 && addr_layer3_reg != 1599) addr_layer3_reg <= addr_layer3_reg + 1'd1; 
            else if(addr_layer3_reg == 11'd1599 && cnt_addr_ctrl == 16'd0) addr_layer3_reg <= 11'd0;  
            else addr_layer3_reg <= addr_layer3_reg;
    default addr_layer3_reg <= addr_layer3_reg;
    endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        wea <= 1'd0;
    else
        case(state)
            CONV1 : if(cnt_addr_ctrl == 149) wea <= 1'd1;  else wea <= 1'd0;
            default : wea <= 1'd0;
            endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        addrb <= 10'd0;
    else
        case(state)
            DONE : addrb <= addrb + 1;
            default : addrb <= 0;
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
