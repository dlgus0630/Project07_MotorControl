function metrics=ANALYZE_TELEMETRY(csv_path,make_plot)
% Analyze one closed-loop reference step captured by capture_telemetry.py.
if nargin<1,csv_path=fullfile('data','telemetry.csv');end
if nargin<2,make_plot=true;end
T=readtable(csv_path);
assert(height(T)>=500,'At least 5 seconds of telemetry are required.');
assert(all(T.fault==0),'Fault occurred during the capture.');

t=T.time_s;
reference=T.target_rpm;
measured=T.measured_rpm;
filtered=movmean(measured,[9 0]); % causal 100 ms average at 100 Hz
step_index=find(abs(diff(reference))>0.5,1,'first')+1;
assert(~isempty(step_index),'No reference step was found.');
assert(step_index>100 && height(T)-step_index>300,...
    'Capture at least 1 s before and 3 s after the step.');

t0=t(step_index);
initial=mean(filtered(step_index-100:step_index-1));
last_index=height(T);
target=median(reference(max(step_index,last_index-199):last_index));
delta=target-initial;
assert(abs(delta)>1,'Reference change is too small.');
progress=(filtered-initial)/delta;
after=(step_index:height(T))';
i10_local=find(progress(after)>=0.10,1,'first');
i90_local=find(progress(after)>=0.90,1,'first');
assert(~isempty(i10_local) && ~isempty(i90_local),...
    'Response did not cross the 10%% and 90%% thresholds.');
i10=after(i10_local);
i90=after(i90_local);
rise_time=t(i90)-t(i10);

direction=sign(delta);
peak_error=max(direction*(filtered(after)-target));
overshoot_percent=max(0,100*peak_error/abs(delta));
band=max(0.02*abs(target),0.25);
outside=after(abs(filtered(after)-target)>band);
if isempty(outside)
    settling_time=0;
elseif outside(end)==height(T)
    settling_time=NaN;
else
    settling_time=t(outside(end)+1)-t0;
end
tail=max(step_index,height(T)-199):height(T);
steady_speed=mean(filtered(tail));
steady_error_percent=100*(steady_speed-target)/target;
raw_steady_std=std(measured(tail));
filtered_steady_std=std(filtered(tail));

metrics=table(initial,target,rise_time,overshoot_percent,settling_time,...
    steady_speed,steady_error_percent,raw_steady_std,filtered_steady_std,band,...
    'VariableNames',{'InitialRPM','TargetRPM','RiseTime_s','Overshoot_pct',...
    'SettlingTime_s','SteadyRPM','SteadyError_pct','RawSteadyStd_RPM',...
    'FilteredSteadyStd_RPM','SettlingBand_RPM'});

[folder,name]=fileparts(csv_path);if isempty(folder),folder='.';end
writetable(metrics,fullfile(folder,[name '_metrics.csv']));
if make_plot,try
    figure('Color','w');
    plot(t,reference,'--','LineWidth',1.4);hold on;
    plot(t,measured,'Color',[0.75 0.82 0.95]);
    plot(t,filtered,'LineWidth',1.5);grid on;
    xline(t0,':','Reference step');
    xlabel('Time (s)');ylabel('Output-shaft speed (RPM)');
    legend('Reference','Raw 10 ms estimate','100 ms moving average','Location','best');
    title(sprintf('PI step: rise %.3f s, overshoot %.2f%%, settling %.3f s',...
        rise_time,overshoot_percent,settling_time));
    exportgraphics(gcf,fullfile(folder,[name '_response.png']),'Resolution',200);
catch plot_error
    warning('Plot skipped: %s',plot_error.message);
end,end
disp(metrics);
end
