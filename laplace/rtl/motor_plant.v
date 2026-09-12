// Synthesizable normalized first-order ZOH test plant. One update per PID result.
module motor_plant(input wire clk,input wire rst,input wire step,
    input wire [12:0] duty,input wire [12:0] load,
    output reg [12:0] speed,output reg done);
    wire [12:0] drive=(duty>load)?duty-load:13'd0;
    wire [63:0] next_value=(64'd61258*speed+64'd4278*drive)>>16;
    always @(posedge clk)begin
        done<=0;
        if(rst)begin speed<=0;done<=0;end
        else if(step)begin speed<=next_value[12:0];done<=1;end
    end
endmodule
