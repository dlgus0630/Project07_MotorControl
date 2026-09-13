function metrics=ANALYZE_DISTURBANCE(csv_path,disturbance_time,restore_time,make_plot)
% Analyze a known disturbance interval and recovery after it is removed.
if nargin<1,csv_path=fullfile('data','disturbance.csv');end
if nargin<2,disturbance_time=5;end
if nargin<3,restore_time=10;end
if nargin<4,make_plot=true;end
T=readtable(csv_path);assert(all(T.fault==0),'Fault occurred during capture.');
t=T.time_s;y=movmean(T.measured_rpm,[9 0]);reference=T.target_rpm;
disturbance_index=find(t>=disturbance_time,1,'first');
restore_index=find(t>=restore_time,1,'first');
assert(~isempty(disturbance_index) && ~isempty(restore_index) && ...
    disturbance_index>100 && restore_index>disturbance_index+100,...
    'Capture at least 1 s before and during the disturbance.');
baseline=mean(y(disturbance_index-100:disturbance_index-1));
target=median(reference(disturbance_index-100:disturbance_index-1));
disturbance_range=disturbance_index:restore_index-1;
minimum=min(y(disturbance_range));maximum=max(y(disturbance_range));
worst_deviation=max(abs(y(disturbance_range)-target));
tail=restore_index:height(T);
band=max(0.02*abs(target),0.25);
outside=tail(abs(y(tail)-target)>band);
if isempty(outside),recovery_time=0;
elseif outside(end)==height(T),recovery_time=NaN;
else,recovery_time=t(outside(end)+1)-t(restore_index);end
steady=mean(y(max(restore_index,height(T)-199):height(T)));
metrics=table(target,baseline,minimum,maximum,worst_deviation,recovery_time,steady,...
    100*(steady-target)/target,band,'VariableNames',...
    {'TargetRPM','PreDisturbanceRPM','MinimumRPM','MaximumRPM','WorstDeviation_RPM','RecoveryTime_s',...
    'FinalRPM','FinalError_pct','RecoveryBand_RPM'});
[folder,name]=fileparts(csv_path);if isempty(folder),folder='.';end
writetable(metrics,fullfile(folder,[name '_metrics.csv']));
if make_plot,try
    figure('Color','w');plot(t,reference,'--','LineWidth',1.3);hold on;
    plot(t,T.measured_rpm,'Color',[0.75 0.82 0.95]);plot(t,y,'LineWidth',1.5);
    xline(disturbance_time,':','Disturbance applied');
    xline(restore_time,':','Disturbance removed');grid on;
    xlabel('Time (s)');ylabel('Speed (RPM)');legend('Reference','Raw','100 ms average');
    exportgraphics(gcf,fullfile(folder,[name '_recovery.png']),'Resolution',200);
catch plot_error
    warning('Plot skipped: %s',plot_error.message);
end,end
disp(metrics);
end
