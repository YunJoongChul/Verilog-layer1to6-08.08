`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/04 14:18:26
// Design Name: 
// Module Name: layer2
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


module layer2(clk, rst, start, dout_layer1, addr_layer1, addr_layer2, dout, done);
input clk, rst, start;
input signed [63:0] dout_layer1;
input [10:0] addr_layer2;
output signed [31:0] dout;
output reg [12:0] addr_layer1;
output reg done;
reg signed [31:0] din_layer2;
reg [10:0] addr_layer2_reg;
reg wea ;
reg [3:0] state;
reg [15:0] cnt_col_stride, cnt_row_stride, cnt_module, cnt_max_ctrl;
layer2_o u0(.clka(clk) ,.wea(wea), .addra(addr_layer2_reg), .dina(din_layer2), .clkb(clk), .addrb(addr_layer2), .doutb(dout));
reg [31:0] max_high, max_low;
localparam IDLE = 3'd0, MAXPOOLING_HIGH = 3'd1, MAXPOOLING_LOW = 3'd2, DONE = 3'd3;


always@(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        case(state)
        IDLE : if(start) state <= MAXPOOLING_HIGH ; else state <= IDLE;
        MAXPOOLING_HIGH : state <= MAXPOOLING_LOW;
        MAXPOOLING_LOW : if(addr_layer2_reg == 1175 && cnt_max_ctrl == 1) state <=  DONE; else state <= MAXPOOLING_HIGH;
        DONE : state <= IDLE;
        default : state <= IDLE;
        endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_col_stride <= 16'd0;
    else
        case(state)
        MAXPOOLING_LOW : if(cnt_col_stride == 13) cnt_col_stride <= 0; else cnt_col_stride <= cnt_col_stride + 1'd1;
        default : cnt_col_stride <= cnt_col_stride;
        endcase
end

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_row_stride <= 16'd0;
    else
        case(state)
        MAXPOOLING_LOW : if(cnt_col_stride == 13) cnt_row_stride <= cnt_row_stride + 6'd28; else cnt_row_stride <= cnt_row_stride;
        default : cnt_row_stride <= cnt_row_stride;
        endcase
end


always@(posedge clk or posedge rst)
begin
    if(rst)
        addr_layer1 <= 13'd0;
    else
        if(addr_layer1 <= 13'd2351)
            case(state)
            MAXPOOLING_HIGH : addr_layer1 <=  cnt_col_stride + cnt_row_stride;
            MAXPOOLING_LOW : addr_layer1 <= 7'd14 + cnt_col_stride + cnt_row_stride;
            default : addr_layer1 <= addr_layer1;
            endcase
       else
           addr_layer1 <= addr_layer1;
end
        

always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_module <= 16'd0;
    else
        case(state)
            IDLE : cnt_module <= 16'd0;
            default cnt_module <= cnt_module + 1'd1;
            endcase
end
    
always@(posedge clk or posedge rst)
begin
    if(rst)
        cnt_max_ctrl <= 16'd0;
    else if(cnt_module < 16'd2)
        cnt_max_ctrl <= 16'd0;
    else
        case(state)
            MAXPOOLING_HIGH : cnt_max_ctrl <= 1;
            MAXPOOLING_LOW :  cnt_max_ctrl <= 2;
            default : cnt_max_ctrl <= 0;           
            endcase
end
    
always@(posedge clk or posedge rst)
begin
    if(rst)
        max_high <= 32'd0;
    else
       case(cnt_max_ctrl)
       1: max_high <= (dout_layer1[63:32] > dout_layer1[31:0] ) ?  dout_layer1[63:32] : dout_layer1[31:0];
       default : max_high <= max_high;
       endcase
end        
        
always@(posedge clk or posedge rst)
begin
    if(rst)
        max_low <= 32'd0;
    else
       case(cnt_max_ctrl)
       2 : max_low <=(dout_layer1[63:32] > dout_layer1[31:0] ) ?  dout_layer1[63:32] : dout_layer1[31:0];
       default : max_low <= max_low;
       endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
        din_layer2 <= 32'd0;
    else
        case(state)
        MAXPOOLING_LOW : din_layer2 <= (max_high > max_low) ? max_high : max_low;
        default : din_layer2 <= din_layer2;
        endcase
end 

always@(posedge clk or posedge rst)
begin
    if(rst)
         addr_layer2_reg <= 0;
    else if(cnt_module < 16'd5)
          addr_layer2_reg <= 16'd0;
    else
        case(state)
            MAXPOOLING_HIGH :if(cnt_max_ctrl == 2) addr_layer2_reg <= addr_layer2_reg + 1; else  addr_layer2_reg <= addr_layer2_reg;
            default : addr_layer2_reg <= addr_layer2_reg;         
            endcase
end

 always@(posedge clk or posedge rst)
begin
    if(rst)
        wea <= 0;
    else if(cnt_module < 16'd4)
             wea <= 0;
     else
        case(state)
        MAXPOOLING_LOW : if(cnt_max_ctrl ==1) wea <= 1; else wea <= 0;
        default : wea <=0;
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
