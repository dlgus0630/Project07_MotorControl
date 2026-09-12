// Default: internal test plant, physical motor outputs forced low.
// External mode requires a suitable motor driver + encoder and calibrated constants.
module laplace_basys3_top #(
    parameter integer CLK_HZ=100000000,
    parameter integer EXTERNAL_MOTOR=0,
    parameter integer OPEN_LOOP=0,
    parameter integer ENCODER_COUNTS_FULL_SCALE=200
)(input wire clk,input wire btnC,input wire [4:0] sw,input wire encoder_a,
    output wire motor_pwm,output wire motor_dir,output wire motor_enable,
    output wire [15:0] led);
    wire rst;reset_sync resetter(clk,btnC,rst);
    (* ASYNC_REG="TRUE" *) reg [4:0] sw_meta,sw_sync;
    reg seen_off,armed,fault;reg [2:0] switch_warmup;reg [31:0] tick_count,stall_count;
    reg sample_tick,start;
    wire pid_busy,pid_done,plant_done,encoder_pulse;
    wire [12:0] duty,plant_speed,enc_speed;
    wire [12:0] speed=EXTERNAL_MOTOR?enc_speed:plant_speed;
    wire [12:0] reference={1'b0,sw_sync[3:1],9'd0};
    wire [12:0] load=sw_sync[4]?13'd614:13'd0;
    // Open-loop commissioning uses the target switches directly as PWM duty.
    wire [12:0] drive_duty=(EXTERNAL_MOTOR && OPEN_LOOP)?reference:duty;
    wire signed [31:0] integral;wire signed [17:0] derivative;
    wire controller_reset=rst||!armed||fault||(EXTERNAL_MOTOR && OPEN_LOOP);
    wire enabled=armed&&!fault&&!btnC&&!rst;
    wire pwm_internal;wire [12:0] active_duty;
    pid_fixed controller(clk,controller_reset,start,reference,speed,pid_busy,pid_done,duty,integral,derivative);
    motor_plant plant(clk,controller_reset,pid_done,duty,load,plant_speed,plant_done);
    encoder_speed #(.COUNTS_FULL_SCALE(ENCODER_COUNTS_FULL_SCALE)) encoder(
        clk,rst,sample_tick,encoder_a,enc_speed,encoder_pulse);
    pwm_period #(.PERIOD(CLK_HZ/20000)) pwm_unit(clk,rst,enabled,drive_duty,pwm_internal,active_duty);
    assign motor_pwm=EXTERNAL_MOTOR? pwm_internal:1'b0;
    assign motor_enable=EXTERNAL_MOTOR?enabled:1'b0;
    assign motor_dir=EXTERNAL_MOTOR?enabled:1'b0; // fixed forward direction only
    // In external mode SW4 displays unscaled A-channel rising edges per second.
    // This works before CPR is known. Saturate instead of silently wrapping.
    reg [31:0] pulse_timer;
    reg [15:0] pulse_count,pulse_display;
    wire [16:0] pulse_total={1'b0,pulse_count}+encoder_pulse;
    wire [15:0] pulse_limited=pulse_total[16]?16'hffff:pulse_total[15:0];
    assign led=(EXTERNAL_MOTOR && sw_sync[4])?pulse_display:
        {speed[12:3],EXTERNAL_MOTOR!=0,sw_sync[4],pwm_internal,pid_busy,fault,armed};
    always @(posedge clk)begin
        if(rst)begin pulse_timer<=0;pulse_count<=0;pulse_display<=0;end
        else if(pulse_timer==CLK_HZ-1)begin
            pulse_timer<=0;pulse_display<=pulse_limited;pulse_count<=0;
        end else begin pulse_timer<=pulse_timer+1'b1;pulse_count<=pulse_limited;end
    end
    always @(posedge clk)begin
        sample_tick<=0;start<=0;
        if(rst)begin sw_meta<=0;sw_sync<=0;switch_warmup<=0;seen_off<=0;armed<=0;fault<=0;tick_count<=0;stall_count<=0;end
        else begin
            sw_meta<=sw;sw_sync<=sw_meta;
            // Ignore synchronizer reset zeros until real switch values have propagated.
            if(switch_warmup<4)switch_warmup<=switch_warmup+1'b1;
            else if(!sw_sync[0])begin seen_off<=1;armed<=0;end
            else if(seen_off && !fault)armed<=1;
            if(tick_count==CLK_HZ/100-1)begin tick_count<=0;sample_tick<=1;if(enabled && !pid_busy)start<=1;end
            else tick_count<=tick_count+1'b1;
            if(!EXTERNAL_MOTOR || !enabled || drive_duty<=1024 || encoder_pulse)stall_count<=0;
            else if(stall_count>=CLK_HZ*3/10-1)begin fault<=1;armed<=0;end
            else stall_count<=stall_count+1'b1;
        end
    end
endmodule
