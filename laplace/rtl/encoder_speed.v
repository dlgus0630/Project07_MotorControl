// Rising edges of one encoder channel. CPR means counted rising edges/revolution.
module encoder_speed #(parameter integer COUNTS_FULL_SCALE=200)(
    input wire clk,input wire rst,input wire sample_tick,input wire encoder_a,
    output reg [12:0] speed,output wire pulse);
    (* ASYNC_REG="TRUE" *) reg [1:0] sync;
    reg previous;reg [31:0] count;
    assign pulse=sync[1]&&!previous;
    wire [32:0] total={1'b0,count}+pulse;
    // A direct division by a non-power-of-two calibration constant creates a
    // long combinational path.  Use a Q12 reciprocal fixed at elaboration.
    localparam integer RECIP_Q12=(16777216+(COUNTS_FULL_SCALE/2))/COUNTS_FULL_SCALE;
    wire [12:0] bounded_count=(total>=COUNTS_FULL_SCALE)?COUNTS_FULL_SCALE:total[12:0];
    wire [33:0] scaled_product=bounded_count*RECIP_Q12;
    wire [21:0] scaled=scaled_product>>12;
    always @(posedge clk)begin
        if(rst)begin sync<=0;previous<=0;count<=0;speed<=0;end
        else begin
            sync<={sync[0],encoder_a};previous<=sync[1];
            if(sample_tick)begin count<=0;speed<=(total>=COUNTS_FULL_SCALE)?13'd4096:scaled[12:0];end
            else if(pulse && count!=32'hffffffff)count<=count+1'b1;
        end
    end
endmodule
