`timescale 1ns/1ps
module tb_pwm_encoder;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,en=0;reg [12:0] duty=0;wire pwm;wire [12:0] active;
    reg enc=0,tick=0;wire [12:0] speed;wire pulse;
    integer j,n;
    pwm_period #(.PERIOD(16)) p(clk,rst,en,duty,pwm,active);
    encoder_speed #(.COUNTS_FULL_SCALE(8)) e(clk,rst,tick,enc,speed,pulse);
    task frame;
        input [12:0] value;input integer expected;
        begin
            @(negedge clk);duty=value;wait(active===value);wait(p.count==0);
            n=0;for(j=0;j<16;j=j+1)begin @(negedge clk);if(pwm)n=n+1;end
            if(n!=expected)begin $display("TEST FAIL PWM %d %d",value,n);$finish;end
        end
    endtask
    initial begin
        repeat(4)@(negedge clk);rst=0;en=1;
        frame(2048,8);frame(4096,16);frame(0,0);
        frame(4096,16);#2 en=0;#1;if(pwm!==0)begin $display("TEST FAIL asynchronous disable");$finish;end
        for(j=0;j<4;j=j+1)begin @(negedge clk);enc=1;repeat(4)@(negedge clk);enc=0;repeat(4)@(negedge clk);end
        tick=1;@(negedge clk);tick=0;
        if(speed!==2048)begin $display("TEST FAIL encoder normalization %d",speed);$finish;end
        $display("TEST PASS tb_pwm_encoder");$finish;
    end
    initial begin #100000;$display("TEST FAIL timeout tb_pwm_encoder");$finish;end
endmodule
