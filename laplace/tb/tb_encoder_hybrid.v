`timescale 1ns/1ps
module tb_encoder_hybrid;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,tick=0,enc=0;wire [12:0] speed;wire pulse;
    reg [12:0] prev_speed;
    integer j,k,glitch;
    encoder_speed_hybrid #(.CLK_HZ(100000),.COUNTS_FULL_SCALE(10),
        .HIGH_COUNT_THRESHOLD(8),.LOW_COUNT_THRESHOLD(5),.TIMEOUT_MS(100)) dut(
        clk,rst,tick,enc,speed,pulse);
    initial begin
        repeat(5)@(negedge clk);rst=0;
        repeat(4500)@(negedge clk);
        if(speed<2000 || speed>2100)begin
            $display("TEST FAIL hybrid reciprocal speed %d",speed);$finish;
        end
        wait(j==40);repeat(12000)@(negedge clk);
        if(speed!==0)begin $display("TEST FAIL hybrid timeout %d",speed);$finish;end
        rst=1;repeat(5)@(negedge clk);rst=0;
        glitch=0;prev_speed=13'bx;
        for(k=0;k<20;k=k+1)begin
            @(posedge tick);
            if(k>1 && prev_speed!==13'bx)begin
                if((speed>prev_speed && speed-prev_speed>400) ||
                   (prev_speed>speed && prev_speed-speed>400))glitch=glitch+1;
            end
            prev_speed=speed;
        end
        if(glitch>0)begin
            $display("TEST FAIL hybrid hysteresis glitch count=%d",glitch);$finish;
        end
        if(dut.high_speed_mode!==1'b0)begin
            $display("TEST FAIL hybrid stayed in high_speed_mode at nominal count");$finish;
        end
        $display("TEST PASS tb_encoder_hybrid reciprocal low-speed, timeout, and hysteresis margin");$finish;
    end
    initial begin
        wait(!rst);
        for(j=0;j<40;j=j+1)begin
            repeat(199)@(negedge clk);enc=1;@(negedge clk);enc=0;
        end
    end
    initial begin
        wait(!rst);
        forever begin repeat(999)@(negedge clk);tick=1;@(negedge clk);tick=0;end
    end
    initial begin
        repeat(2)@(negedge rst);
        forever begin
            repeat(195)@(negedge clk);enc=1;@(negedge clk);enc=0;
        end
    end
    initial begin #600000;$display("TEST FAIL timeout tb_encoder_hybrid");$finish;end
endmodule
