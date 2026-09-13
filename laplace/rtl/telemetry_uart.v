// Fixed 16-byte binary telemetry frame, emitted once for every accepted sample.
module telemetry_uart #(
    parameter integer CLK_HZ=100000000,
    parameter integer BAUD=115200
)(input wire clk,input wire rst,input wire sample,
    input wire [12:0] reference,input wire [12:0] measured,input wire [12:0] duty,
    input wire signed [31:0] integral,input wire armed,input wire fault,input wire enabled,
    output wire tx,output wire busy);
    reg [15:0] sequence;
    reg [12:0] reference_hold,measured_hold,duty_hold;
    reg signed [31:0] integral_hold;
    reg [7:0] flags_hold,checksum_hold,tx_data;
    reg [3:0] byte_index;
    reg sending,waiting_for_busy,tx_start;
    wire tx_busy;

    assign busy=sending;
    uart_tx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) serial(
        clk,rst,tx_start,tx_data,tx,tx_busy);

    function [7:0] frame_byte;
        input [3:0] index;
        begin case(index)
            0:frame_byte=8'ha5;
            1:frame_byte=8'h5a;
            2:frame_byte=sequence[7:0];
            3:frame_byte=sequence[15:8];
            4:frame_byte=reference_hold[7:0];
            5:frame_byte={3'b0,reference_hold[12:8]};
            6:frame_byte=measured_hold[7:0];
            7:frame_byte={3'b0,measured_hold[12:8]};
            8:frame_byte=duty_hold[7:0];
            9:frame_byte={3'b0,duty_hold[12:8]};
            10:frame_byte=integral_hold[7:0];
            11:frame_byte=integral_hold[15:8];
            12:frame_byte=integral_hold[23:16];
            13:frame_byte=integral_hold[31:24];
            14:frame_byte=flags_hold;
            default:frame_byte=checksum_hold;
        endcase end
    endfunction

    wire [7:0] live_flags={5'b0,enabled,fault,armed};
    wire [7:0] live_checksum=8'ha5^8'h5a^sequence[7:0]^sequence[15:8]^
        reference[7:0]^{3'b0,reference[12:8]}^measured[7:0]^{3'b0,measured[12:8]}^
        duty[7:0]^{3'b0,duty[12:8]}^integral[7:0]^integral[15:8]^
        integral[23:16]^integral[31:24]^live_flags;

    always @(posedge clk)begin
        tx_start<=0;
        if(rst)begin
            sequence<=0;reference_hold<=0;measured_hold<=0;duty_hold<=0;
            integral_hold<=0;flags_hold<=0;checksum_hold<=0;tx_data<=0;
            byte_index<=0;sending<=0;waiting_for_busy<=0;tx_start<=0;
        end else begin
            if(sample && !sending)begin
                reference_hold<=reference;measured_hold<=measured;duty_hold<=duty;
                integral_hold<=integral;flags_hold<=live_flags;checksum_hold<=live_checksum;
                byte_index<=0;sending<=1;waiting_for_busy<=0;
            end
            if(sending)begin
                if(!tx_busy && !waiting_for_busy)begin
                    tx_data<=frame_byte(byte_index);tx_start<=1;waiting_for_busy<=1;
                end else if(tx_busy && waiting_for_busy)begin
                    waiting_for_busy<=0;
                    if(byte_index==15)begin sending<=0;sequence<=sequence+1'b1;end
                    else byte_index<=byte_index+1'b1;
                end
            end
        end
    end
endmodule
