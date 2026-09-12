function y=plant_sl(u)
C=evalin('base','MOTOR_PID');
y=floor((C.plant_a*u(1)+(65536-C.plant_a)*max(u(2)-u(3),0))/65536);
end
