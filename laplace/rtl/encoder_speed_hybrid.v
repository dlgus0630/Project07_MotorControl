// Hybrid encoder estimator: reciprocal pulse period at low speed and window count at high speed.
module encoder_speed_hybrid #(
    parameter integer CLK_HZ=100000000,
    parameter integer SAMPLE_HZ=100,
    parameter integer COUNTS_FULL_SCALE=18,
    parameter integer HIGH_COUNT_THRESHOLD=14,
    parameter integer LOW_COUNT_THRESHOLD=10,
    parameter integer TIMEOUT_MS=100
)(input wire clk,input wire rst,input wire sample_tick,input wire encoder_a,
    output reg [12:0] speed,output wire pulse);
    (* ASYNC_REG="TRUE" *) reg [1:0] sync;
    reg previous,have_edge,period_valid,high_speed_mode;
    reg [31:0] window_count,period_count,period_divisor;
    reg [12:0] period_speed;
    reg divider_start;
    wire divider_busy,divider_done;
    wire [31:0] divider_quotient;

    assign pulse=sync[1]&&!previous;
    wire [32:0] window_total={1'b0,window_count}+pulse;
    localparam integer RECIP_Q12=(16777216+(COUNTS_FULL_SCALE/2))/COUNTS_FULL_SCALE;
    wire [12:0] bounded_count=(window_total>=COUNTS_FULL_SCALE)?
        COUNTS_FULL_SCALE:window_total[12:0];
    wire [33:0] window_product=bounded_count*RECIP_Q12;
    wire [12:0] window_speed=(window_total>=COUNTS_FULL_SCALE)?
        13'd4096:window_product[24:12];

    localparam [63:0] SPEED_NUMERATOR_64=
        (64'd4096*CLK_HZ)/(COUNTS_FULL_SCALE*SAMPLE_HZ);
    localparam [31:0] SPEED_NUMERATOR=SPEED_NUMERATOR_64[31:0];
    localparam integer TIMEOUT_CLOCKS=(CLK_HZ/1000)*TIMEOUT_MS;
    wire [31:0] measured_period=period_count+1'b1;
    wire [12:0] reciprocal_speed=(divider_quotient>=4096)?
        13'd4096:divider_quotient[12:0];

    unsigned_divider divider(clk,rst,divider_start,SPEED_NUMERATOR,period_divisor,
        divider_busy,divider_done,divider_quotient);

    always @(posedge clk)begin
        divider_start<=0;
        if(rst)begin
            sync<=0;previous<=0;have_edge<=0;period_valid<=0;high_speed_mode<=0;
            window_count<=0;period_count<=0;period_divisor<=1;period_speed<=0;speed<=0;
            divider_start<=0;
        end else begin
            sync<={sync[0],encoder_a};previous<=sync[1];
            if(have_edge && period_count!=32'hffffffff)period_count<=period_count+1'b1;
            if(pulse)begin
                if(have_edge && !divider_busy)begin
                    period_divisor<=measured_period;divider_start<=1;
                end
                period_count<=0;have_edge<=1;
                if(window_count!=32'hffffffff)window_count<=window_count+1'b1;
            end
            if(divider_done)begin
                if(!period_valid)period_speed<=reciprocal_speed;
                else if(reciprocal_speed>=period_speed)
                    period_speed<=period_speed+((reciprocal_speed-period_speed+2)>>2);
                else period_speed<=period_speed-((period_speed-reciprocal_speed+2)>>2);
                period_valid<=1;
            end
            if(have_edge && period_count>=TIMEOUT_CLOCKS-1)begin
                period_valid<=0;period_speed<=0;
            end
            if(sample_tick)begin
                window_count<=0;
                if(!period_valid || period_count>=TIMEOUT_CLOCKS-1)begin
                    speed<=0;high_speed_mode<=0;
                end else if(window_total>=HIGH_COUNT_THRESHOLD)begin
                    speed<=window_speed;high_speed_mode<=1;
                end else if(window_total<=LOW_COUNT_THRESHOLD)begin
                    speed<=period_speed;high_speed_mode<=0;
                end else if(high_speed_mode)begin
                    speed<=window_speed;
                end else begin
                    speed<=period_speed;
                end
            end
        end
    end
endmodule
