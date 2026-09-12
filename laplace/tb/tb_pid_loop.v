`timescale 1ns/1ps
module tb_pid_loop;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,start=0;reg [12:0] reference=0,load=0;
    wire busy,done,pdone;wire [12:0] duty,y;
    wire signed [31:0] integ;wire signed [17:0] df;
    reg [31:0] refs[0:1199],loads[0:1199],duties[0:1199],ys[0:1199],ii[0:1199],dd[0:1199];
    integer k;
    pid_fixed dut(clk,rst,start,reference,y,busy,done,duty,integ,df);
    motor_plant plant(clk,rst,done,duty,load,y,pdone);
    initial begin
        $readmemh("pid_ref.mem",refs);$readmemh("pid_load.mem",loads);$readmemh("pid_duty.mem",duties);
        $readmemh("pid_y1.mem",ys);$readmemh("pid_integral.mem",ii);$readmemh("pid_derivative.mem",dd);
        for(k=0;k<1200;k=k+1)if((^{refs[k],loads[k],duties[k],ys[k],ii[k],dd[k]})===1'bx)begin $display("TEST FAIL missing/unknown PID vector");$finish;end
        repeat(4)@(negedge clk);rst=0;
        for(k=0;k<1200;k=k+1)begin
            @(negedge clk);reference=refs[k];load=loads[k];start=1;
            @(negedge clk);start=0;wait(done);@(negedge clk);
            if(duty!==duties[k][12:0] || integ!==ii[k] || df!==dd[k][17:0])begin $display("TEST FAIL PID sample %d",k);$finish;end
            wait(pdone);@(negedge clk);
            if(y!==ys[k][12:0])begin $display("TEST FAIL PLANT sample %d",k);$finish;end
        end
        rst=1;repeat(2)@(negedge clk);
        if(duty!==0 || y!==0 || integ!==0)begin $display("TEST FAIL reset");$finish;end
        $display("TEST PASS tb_pid_loop 1200 samples, disturbance, reversal, reset");$finish;
    end
    initial begin #2000000;$display("TEST FAIL timeout tb_pid_loop");$finish;end
endmodule
