function RUN_MATLAB_CHECKS()
root=fileparts(mfilename('fullpath'));
old=pwd;
cleanup=onCleanup(@()cd(old));
cd(root);
addpath(fullfile(root,'matlab'));
outdir=fullfile(root,'reports');
if ~exist(outdir,'dir'),mkdir(outdir);end
Simulink.fileGenControl('set','CacheFolder',fullfile(outdir,'sim_cache'),...
    'CodeGenFolder',fullfile(outdir,'sim_codegen'),'createDir',true);
source_hash=source_digest(root);
marker=fullfile(outdir,'matlab.pass');
if exist(marker,'file'),delete(marker);end

C=jsondecode(fileread(fullfile(root,'data','pid_config.json')));
T=readmatrix(fullfile(root,'data','pid_reference.csv'));
speed=0;integral=0;derivative=0;previous=0;
for k=1:size(T,1)
    [duty,integral,derivative,previous]=pid_fixed(T(k,2),speed,integral,derivative,previous);
    speed=floor((C.plant_a*speed+(65536-C.plant_a)*max(duty-T(k,3),0))/65536);
    assert(isequal([duty,speed,integral,derivative],T(k,5:8)),...
        'PID Golden mismatch at sample %d',k);
end

s=tf('s');R=2;L=.002;J=.0002;B=.0001;Kt=.05;Ke=.05;
motor=Kt/((J*s+B)*(L*s+R)+Kt*Ke);
motor=motor/dcgain(motor);
tau=J/(B+Kt*Ke/R);
reduced=1/(tau*s+1);
motor_z=c2d(reduced,C.ts,'zoh');

assignin('base','MOTOR_PID',C);
assignin('base','MOTOR_REF',[T(:,1)*C.ts,T(:,2)]);
assignin('base','MOTOR_LOAD',[T(:,1)*C.ts,T(:,3)]);
build_model(outdir);
result=sim('laplace_pid_closed_loop','ReturnWorkspaceOutputs','on');
actual_speed=result.get('sl_speed');
actual_duty=result.get('sl_duty');
assert(isequal(actual_speed(:),T(:,6)) && isequal(actual_duty(:),T(:,5)),...
    'Simulink PID loop mismatch');

SELF_TEST_ANALYSIS(outdir);

save(fullfile(outdir,'matlab_reference.mat'),'C','motor','reduced','motor_z','T');
close_system('laplace_pid_closed_loop',0);
assert(strcmp(source_hash,source_digest(root)),'Source changed during validation; rerun.');
write_marker(marker,source_hash);
result_files={'reports/matlab.pass','reports/matlab_reference.mat',...
    'reports/laplace_pid_closed_loop.slx','reports/analysis_self_test.txt'};
zip(fullfile(outdir,'matlab_results.zip'),result_files,root);
fprintf('Plots skipped; numeric Golden and Simulink results are unchanged.\n');
fprintf('MATLAB/SIMULINK PASS. Download reports/matlab_results.zip.\n');
end

function write_marker(path,value)
file=fopen(path,'w');
assert(file>=0,'Cannot write marker');
cleanup=onCleanup(@()fclose(file));
fprintf(file,'%s\n',value);
end
