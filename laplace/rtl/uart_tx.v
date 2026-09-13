// 8-N-1 UART transmitter. start is accepted for one cycle only while busy is low.
module uart_tx #(
    parameter integer CLK_HZ=100000000,
    parameter integer BAUD=115200
)(input wire clk,input wire rst,input wire start,input wire [7:0] data,
    output wire tx,output reg busy);
    localparam integer CLKS_PER_BIT=(CLK_HZ+(BAUD/2))/BAUD;
    reg [31:0] baud_count;
    reg [3:0] bit_index;
    reg [7:0] shift;

    assign tx=!busy?1'b1:
        (bit_index==0)?1'b0:
        (bit_index<=8)?shift[bit_index-1]:1'b1;

    always @(posedge clk)begin
        if(rst)begin busy<=0;baud_count<=0;bit_index<=0;shift<=0;end
        else if(!busy)begin
            baud_count<=0;bit_index<=0;
            if(start)begin busy<=1;shift<=data;end
        end else if(baud_count==CLKS_PER_BIT-1)begin
            baud_count<=0;
            if(bit_index==9)begin busy<=0;bit_index<=0;end
            else bit_index<=bit_index+1'b1;
        end else baud_count<=baud_count+1'b1;
    end
endmodule
