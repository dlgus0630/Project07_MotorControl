`timescale 1ns/1ps
module tb_laplace_top;
    reg clk=0;always #5 clk=~clk;
    reg reset=1;reg [4:0] sw=5'b01111;
    wire pwm,dir,en,ipwm,idir,ien,uart,iuart;wire [15:0] led,iled;
    laplace_basys3_top #(.CLK_HZ(200000),.EXTERNAL_MOTOR(1)) external_dut(clk,reset,sw,1'b0,pwm,dir,en,led,uart);
    laplace_basys3_top #(.CLK_HZ(200000)) internal_dut(clk,reset,sw,1'b0,ipwm,idir,ien,iled,iuart);
    always @(negedge clk)if(ipwm!==0 || idir!==0 || ien!==0)begin $display("TEST FAIL internal mode motor pin");$finish;end
    initial begin
        repeat(4)@(negedge clk);reset=0;repeat(20)@(negedge clk);
        if(external_dut.enabled!==0 || pwm!==0 || dir!==0 || en!==0)begin $display("TEST FAIL boot with arm high");$finish;end
        sw[0]=0;repeat(20)@(negedge clk);sw[0]=1;repeat(20)@(negedge clk);
        if(external_dut.enabled!==1 || dir!==1 || en!==0)begin $display("TEST FAIL explicit arm");$finish;end
        wait(external_dut.fault);#1;if(external_dut.enabled!==0 || dir!==0 || en!==0 || pwm!==0)begin $display("TEST FAIL stall cutoff");$finish;end
        reset=1;repeat(4)@(negedge clk);reset=0;repeat(20)@(negedge clk);
        if(external_dut.enabled!==0 || dir!==0 || en!==0 || external_dut.fault!==0)begin $display("TEST FAIL reset rearm");$finish;end
        sw[0]=0;repeat(10)@(negedge clk);sw[0]=1;repeat(10)@(negedge clk);
        #2;reset=1;#1;if(external_dut.enabled!==0 || dir!==0 || en!==0 || pwm!==0)begin $display("TEST FAIL immediate reset cutoff");$finish;end
        $display("TEST PASS tb_laplace_top test-plant isolation, explicit arm, stall fault, reset");$finish;
    end
    initial begin #2000000;$display("TEST FAIL timeout tb_laplace_top");$finish;end
endmodule
