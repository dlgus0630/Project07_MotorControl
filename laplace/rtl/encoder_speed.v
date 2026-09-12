// Rising edges of one encoder channel. CPR means counted rising edges/revolution.
module encoder_speed #(parameter integer COUNTS_FULL_SCALE=200)(
    input wire clk,input wire rst,input wire sample_tick,input wire encoder_a,
    output reg [12:0] speed,output wire pulse);
    (* ASYNC_REG="TRUE" *) reg [1:0] sync;
    reg previous;reg [31:0] count;
    assign pulse=sync[1]&&!previous;
    wire [32:0] total={1'b0,count}+pulse;
    wire [63:0] scaled=(64'd4096*total)/COUNTS_FULL_SCALE;
    always @(posedge clk)begin
        if(rst)begin sync<=0;previous<=0;count<=0;speed<=0;end
        else begin
            sync<={sync[0],encoder_a};previous<=sync[1];
            if(sample_tick)begin count<=0;speed<=(scaled>4096)?13'd4096:scaled[12:0];end
            else if(pulse && count!=32'hffffffff)count<=count+1'b1;
        end
    end
endmodule
