`timescale 1ns/1ps
module tb_uart_telemetry;
    reg clk=0;always #5 clk=~clk;
    reg rst=1,sample=0,armed=1,fault=0,enabled=1;
    reg [12:0] reference=13'h123,measured=13'h456,duty=13'h789;
    reg signed [31:0] integral=32'h89abcdef;
    wire tx,busy;
    reg [7:0] received[0:15];reg [7:0] check;
    integer i,j;
    telemetry_uart #(.CLK_HZ(100),.BAUD(25)) dut(
        clk,rst,sample,reference,measured,duty,integral,armed,fault,enabled,tx,busy);

    task receive_byte;
        output [7:0] value;
        begin
            wait(tx===0);repeat(6)@(posedge clk);
            for(j=0;j<8;j=j+1)begin value[j]=tx;repeat(4)@(posedge clk);end
            if(tx!==1)begin $display("TEST FAIL UART stop bit");$finish;end
            repeat(3)@(posedge clk);
        end
    endtask

    initial begin
        repeat(4)@(negedge clk);rst=0;repeat(2)@(negedge clk);
        sample=1;@(negedge clk);sample=0;
        for(i=0;i<16;i=i+1)receive_byte(received[i]);
        if(received[0]!==8'ha5 || received[1]!==8'h5a ||
            received[2]!==0 || received[3]!==0 ||
            received[4]!==8'h23 || received[5]!==8'h01 ||
            received[6]!==8'h56 || received[7]!==8'h04 ||
            received[8]!==8'h89 || received[9]!==8'h07 ||
            received[10]!==8'hef || received[11]!==8'hcd ||
            received[12]!==8'hab || received[13]!==8'h89 ||
            received[14]!==8'h05)begin
            $display("TEST FAIL telemetry payload");$finish;
        end
        check=0;for(i=0;i<15;i=i+1)check=check^received[i];
        if(received[15]!==check)begin $display("TEST FAIL telemetry checksum");$finish;end
        $display("TEST PASS tb_uart_telemetry");$finish;
    end
    initial begin #200000;$display("TEST FAIL timeout tb_uart_telemetry");$finish;end
endmodule
