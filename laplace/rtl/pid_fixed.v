// Q12 per-unit PI, Ts=10 ms. All negative divisions round toward -infinity.
module pid_fixed(input wire clk,input wire rst,input wire start,
    input wire [12:0] reference,input wire [12:0] measured,
    output reg busy,output reg done,output reg [12:0] duty,
    output reg signed [31:0] integral,output reg signed [17:0] derivative);
    // The controller runs once per 10 ms.  Split the anti-windup arithmetic
    // across clock cycles so every registered path meets the 100 MHz board clock.
    localparam IDLE=0,FILTER=1,PRODUCTS=2,PROPOSE_ADD=3,PROPOSE_SUB=4,
        SELECT=5,OUTPUT_ADD=6,OUTPUT_SUB=7,CLAMP=8,FINISH=9;
    reg [3:0] state;
    reg signed [17:0] error;
    reg [12:0] y_hold,y_previous;
    reg signed [31:0] p_term,d_term,candidate;
    reg signed [31:0] proposed_sum,proposed_value,selected_i;
    reg signed [31:0] output_sum,output_value;
    wire signed [63:0] e64={{46{error[17]}},error};
    wire signed [63:0] df64={{46{derivative[17]}},derivative};
    wire signed [63:0] i64={{32{integral[31]}},integral};
    wire signed [63:0] filter_value=(64'sd3*df64+$signed({1'b0,y_hold})-$signed({1'b0,y_previous}))>>>2;
    wire signed [63:0] i_candidate=i64+((64'sd3932*e64)>>>16);
    wire reject_update=((proposed_value>4096)&&(error>0))||
        ((proposed_value<0)&&(error<0));
    wire signed [31:0] chosen_i=reject_update?integral:candidate;
    always @(posedge clk)begin
        done<=0;
        if(rst)begin state<=IDLE;busy<=0;done<=0;duty<=0;integral<=0;derivative<=0;
            error<=0;y_hold<=0;y_previous<=0;p_term<=0;d_term<=0;candidate<=0;
            proposed_sum<=0;proposed_value<=0;selected_i<=0;
            output_sum<=0;output_value<=0;end
        else case(state)
        IDLE:if(start)begin
            error<=$signed({1'b0,reference})-$signed({1'b0,measured});
            y_hold<=measured;busy<=1;state<=FILTER;
        end
        FILTER:begin derivative<=filter_value[17:0];y_previous<=y_hold;state<=PRODUCTS;end
        PRODUCTS:begin
            p_term<=(64'sd58982*e64)>>>16;d_term<=0;
            if(i_candidate>4096)candidate<=4096;
            else if(i_candidate< -4096)candidate<=-4096;else candidate<=i_candidate;
            state<=PROPOSE_ADD;
        end
        PROPOSE_ADD:begin proposed_sum<=p_term+candidate;state<=PROPOSE_SUB;end
        PROPOSE_SUB:begin proposed_value<=proposed_sum-d_term;state<=SELECT;end
        SELECT:begin
            integral<=chosen_i[31:0];
            selected_i<=chosen_i;state<=OUTPUT_ADD;
        end
        OUTPUT_ADD:begin output_sum<=p_term+selected_i;state<=OUTPUT_SUB;end
        OUTPUT_SUB:begin output_value<=output_sum-d_term;state<=CLAMP;end
        CLAMP:begin
            if(output_value>4096)duty<=4096;
            else if(output_value<0)duty<=0;
            else duty<=output_value[12:0];
            state<=FINISH;
        end
        FINISH:begin busy<=0;done<=1;state<=IDLE;end
        default:begin state<=IDLE;busy<=0;duty<=0;end
        endcase
    end
endmodule
