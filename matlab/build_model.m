function build_model(outdir)
C=evalin('base','MOTOR_PID');
mdl='laplace_pid_closed_loop';
if bdIsLoaded(mdl),close_system(mdl,0);end
new_system(mdl);
set_param(mdl,'Solver','FixedStepDiscrete','FixedStep','0.01','StopTime','11.99');
add_block('simulink/Sources/From Workspace',[mdl '/Reference'],...
    'VariableName','MOTOR_REF','Interpolate','off','OutputAfterFinalValue','Holding final value',...
    'Position',[20 30 105 60]);
add_block('simulink/Sources/From Workspace',[mdl '/Load'],...
    'VariableName','MOTOR_LOAD','Interpolate','off','OutputAfterFinalValue','Holding final value',...
    'Position',[20 280 105 310]);
add_block('simulink/Signal Routing/Mux',[mdl '/PID_inputs'],'Inputs','3','Position',[180 40 185 160]);
add_block('simulink/Discrete/Unit Delay',[mdl '/PID_state'],'InitialCondition','[0;0;0;0]',...
    'SampleTime','0.01','Position',[290 180 370 220]);
add_matlab_function(mdl,'Fixed_PID',sprintf('function v=fcn(u)\nv=pid_sl(u);\nend'),[230 60 345 110]);
add_block('simulink/Signal Routing/Demux',[mdl '/PID_outputs'],'Outputs','4','Position',[395 55 400 155]);
add_block('simulink/Signal Routing/Mux',[mdl '/Plant_inputs'],'Inputs','3','Position',[455 60 460 170]);
plant_script=sprintf(['function y=fcn(u)\na=%d;\n' ...
    'y=floor((a*u(1)+(65536-a)*max(u(2)-u(3),0))/65536);\nend'],double(C.plant_a));
add_matlab_function(mdl,'ZOH_motor',plant_script,[495 65 595 115]);
add_block('simulink/Discrete/Unit Delay',[mdl '/Speed_state'],'InitialCondition','0',...
    'SampleTime','0.01','Position',[510 225 595 265]);
add_block('simulink/Sinks/To Workspace',[mdl '/Speed_log'],'VariableName','sl_speed',...
    'SaveFormat','Array','Position',[655 65 745 100]);
add_block('simulink/Sinks/To Workspace',[mdl '/Duty_log'],'VariableName','sl_duty',...
    'SaveFormat','Array','Position',[410 330 500 365]);
links={'Reference/1','PID_inputs/1';'Speed_state/1','PID_inputs/2';'PID_state/1','PID_inputs/3';...
    'PID_inputs/1','Fixed_PID/1';'Fixed_PID/1','PID_state/1';'Fixed_PID/1','PID_outputs/1';...
    'Speed_state/1','Plant_inputs/1';'PID_outputs/1','Plant_inputs/2';'Load/1','Plant_inputs/3';...
    'Plant_inputs/1','ZOH_motor/1';'ZOH_motor/1','Speed_state/1';'ZOH_motor/1','Speed_log/1';...
    'PID_outputs/1','Duty_log/1'};
for k=1:size(links,1)
    add_line(mdl,links{k,1},links{k,2},'autorouting','on');
end
for k=2:4
    name=['StateTap' num2str(k)];
    add_block('simulink/Sinks/Terminator',[mdl '/' name],'Position',[420 180+25*k 440 195+25*k]);
    add_line(mdl,['PID_outputs/' num2str(k)],[name '/1']);
end
save_system(mdl,fullfile(outdir,[mdl '.slx']));
end

function add_matlab_function(model,name,script,position)
path=[model '/' name];
add_block('simulink/User-Defined Functions/MATLAB Function',path,'Position',position);
chart=find(sfroot,'-isa','Stateflow.EMChart','Path',path);
assert(isscalar(chart),'Could not configure MATLAB Function block: %s',path);
chart.Script=script;
end

