`timescale 1ns/1ps
module tb_laplace_motor;
    reg clk=0;always #5 clk=~clk;
    reg reset=1,enc=0;reg [4:0] sw=0;
    wire pwm,in1,in2,uart;wire [15:0] led;
    integer j,n;
    laplace_basys3_top #(.CLK_HZ(320000),.EXTERNAL_MOTOR(1),.OPEN_LOOP(1)) dut(clk,reset,sw,enc,pwm,in1,in2,led,uart);
    initial begin
        repeat(5)@(negedge clk);reset=0;repeat(20)@(negedge clk);
        // 37 known external rising edges; SW4 must display raw count, not Q12 speed.
        for(j=0;j<37;j=j+1)begin
            enc=1;repeat(5)@(negedge clk);enc=0;repeat(5)@(negedge clk);
        end
        sw[4]=1;wait(dut.pulse_display!=0);@(negedge clk);
        if(led!==37)begin $display("TEST FAIL raw encoder count %d",led);$finish;end
        // 50% open-loop must work independently of the PID output and CPR.
        sw=5'b01001;repeat(50)@(negedge clk);
        while(dut.pwm_unit.count!=0)@(negedge clk);
        n=0;for(j=0;j<16;j=j+1)begin if(pwm)n=n+1;@(negedge clk);end
        if(n!=8 || in1!==1 || in2!==0 || dut.enabled!==1 || dut.duty!==0)begin
            $display("TEST FAIL Laplace open-loop duty %d",n);$finish;
        end
        // Even with the PID held reset, missing feedback must trip the stall latch.
        wait(dut.fault);@(negedge clk);
        if(in1!==0 || in2!==0 || pwm!==0 || dut.enabled!==0)begin $display("TEST FAIL open-loop stall cutoff");$finish;end
        sw[0]=0;repeat(12)@(negedge clk);sw[0]=1;repeat(12)@(negedge clk);
        if(dut.enabled!==0)begin $display("TEST FAIL fault reset required");$finish;end
        reset=1;repeat(5)@(negedge clk);reset=0;repeat(20)@(negedge clk);
        if(dut.enabled!==0)begin $display("TEST FAIL open-loop reset rearm");$finish;end
        sw[0]=0;repeat(12)@(negedge clk);sw[0]=1;repeat(50)@(negedge clk);
        wait(pwm);#2;reset=1;#1;
        if(pwm!==0 || in1!==0 || in2!==0 || dut.enabled!==0)begin $display("TEST FAIL open-loop immediate stop");$finish;end
        $display("TEST PASS tb_laplace_motor");$finish;
    end
    initial begin #6000000;$display("TEST FAIL timeout tb_laplace_motor");$finish;end
endmodule
