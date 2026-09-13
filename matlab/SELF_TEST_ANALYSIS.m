function SELF_TEST_ANALYSIS(outdir)
% Deterministic synthetic-data checks for the experiment analysis scripts.
Ts=0.01;t=(0:Ts:19.99)';n=numel(t);sample=(0:n-1)';
reference=10*ones(n,1);reference(t>=5)=20;
measured=10*ones(n,1);
after=t>=5;measured(after)=20-10*exp(-(t(after)-5)/0.5);
step_path=fullfile(outdir,'self_test_step.csv');
write_capture(step_path,sample,t,reference,measured,50*ones(n,1));
step=ANALYZE_TELEMETRY(step_path,false);
assert(step.RiseTime_s>0.9 && step.RiseTime_s<1.3,'Step rise-time analysis failed.');
assert(step.Overshoot_pct<0.1,'Step overshoot analysis failed.');
assert(step.SettlingTime_s>1.5 && step.SettlingTime_s<1.9,...
    'Step settling-time analysis failed.');
for trial=1:3
    repeated=step;repeated.RiseTime_s=repeated.RiseTime_s+0.01*(trial-2);
    writetable(repeated,fullfile(outdir,sprintf('self_test_trial_%d.csv',trial)));
end
summary=ANALYZE_TRIALS(fullfile(outdir,'self_test_trial_*.csv'),...
    fullfile(outdir,'self_test_trials_summary.csv'));
assert(all(summary.Trials==3) && summary.Std(1)>0,'Repeated-trial analysis failed.');

reference=20*ones(n,1);measured=reference;
during=t>=5 & t<10;measured(during)=15;
after=t>=10;measured(after)=20-5*exp(-(t(after)-10)/0.5);
disturbance_path=fullfile(outdir,'self_test_disturbance.csv');
write_capture(disturbance_path,sample,t,reference,measured,60*ones(n,1));
recovery=ANALYZE_DISTURBANCE(disturbance_path,5,10,false);
assert(abs(recovery.MinimumRPM-15)<0.1,'Disturbance minimum analysis failed.');
assert(recovery.RecoveryTime_s>1.0 && recovery.RecoveryTime_s<1.6,...
    'Disturbance recovery analysis failed.');

t=(0:Ts:29.99)';n=numel(t);sample=(0:n-1)';
u=zeros(n,1);levels=[0.25 0.50 0.75 0.375 0.625 0.25];
for k=1:numel(levels),u(t>=(k-1)*5 & t<k*5)=levels(k);end
a=exp(-Ts/0.4);gain=80;b=(1-a)*gain;y=zeros(n,1);y(1)=gain*u(1);
for k=2:n,y(k)=a*y(k-1)+b*u(k-1);end
identification_path=fullfile(outdir,'self_test_identification.csv');
write_capture(identification_path,sample,t,zeros(n,1),y,100*u);
identified=IDENTIFY_MOTOR(identification_path,false);
assert(identified.PlantGain_RPM_per_dutyPU>70 && ...
    identified.PlantGain_RPM_per_dutyPU<90,'Plant gain identification failed.');
assert(identified.Tau_s>0.3 && identified.Tau_s<0.6,'Plant time constant identification failed.');
assert(identified.TestFit_pct>80,'Plant model fit self-test failed.');

report=fopen(fullfile(outdir,'analysis_self_test.txt'),'w');
assert(report>=0,'Cannot write analysis self-test report.');
cleanup=onCleanup(@()fclose(report));
fprintf(report,'ANALYSIS SELF TEST PASS\n');
fprintf('Telemetry analysis self-test PASS.\n');
end

function write_capture(path,sample,time_s,target_rpm,measured_rpm,duty_percent)
n=numel(time_s);reference_q12=zeros(n,1);measured_q12=zeros(n,1);
duty_q12=zeros(n,1);integral_q12=zeros(n,1);armed=ones(n,1);
fault=zeros(n,1);enabled=ones(n,1);
T=table(sample,time_s,reference_q12,measured_q12,duty_q12,integral_q12,...
    armed,fault,enabled,target_rpm,measured_rpm,duty_percent);
writetable(T,path);
end
