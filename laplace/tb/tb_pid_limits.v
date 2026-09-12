`timescale 1ns/1ps
module tb_pid_limits;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,start=0;reg [12:0] reference=1000,measured=0;
    wire busy,done;wire [12:0] duty;wire signed [31:0] integral;wire signed [17:0] derivative;
    integer k;
    pid_fixed dut(clk,rst,start,reference,measured,busy,done,duty,integral,derivative);
    task step;
        begin @(negedge clk);start=1;@(negedge clk);start=0;wait(done);@(negedge clk);end
    endtask
    initial begin
        repeat(4)@(negedge clk);rst=0;
        // 1000 constant error: P=899, I increment=59. Saturating integral update is rejected.
        for(k=0;k<100;k=k+1)step;
        if(integral!==3186 || duty!==4085)begin $display("TEST FAIL antiwindup %d %d",integral,duty);$finish;end
        reference=4096;step;
        if(duty!==4096 || integral!==3186)begin $display("TEST FAIL upper saturation");$finish;end
        reference=0;measured=4096;step;
        if(duty!==0 || integral!==3186 || derivative!==1024)begin $display("TEST FAIL lower saturation/filter");$finish;end
        rst=1;repeat(2)@(negedge clk);rst=0;reference=4096;measured=0;
        for(k=0;k<10;k=k+1)step;
        if(integral!==245 || duty!==3931)begin $display("TEST FAIL frozen feedback antiwindup");$finish;end
        $display("TEST PASS tb_pid_limits positive/negative saturation and integral rejection");$finish;
    end
    initial begin #100000;$display("TEST FAIL timeout tb_pid_limits");$finish;end
endmodule
