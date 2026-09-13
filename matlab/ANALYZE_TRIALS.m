function summary=ANALYZE_TRIALS(pattern,output_path)
% Aggregate repeated step-response metrics into mean and sample deviation.
if nargin<1,pattern=fullfile('data','step_trial_*_metrics.csv');end
files=dir(pattern);assert(numel(files)>=3,'At least three trials are required.');
names={'RiseTime_s','Overshoot_pct','SettlingTime_s','SteadyError_pct',...
    'RawSteadyStd_RPM','FilteredSteadyStd_RPM'};
values=zeros(numel(files),numel(names));
for k=1:numel(files)
    T=readtable(fullfile(files(k).folder,files(k).name));
    assert(height(T)==1,'Each metrics file must contain exactly one result row.');
    for j=1:numel(names),values(k,j)=T.(names{j});end
end
assert(all(isfinite(values),'all'),'Every repeated trial must have finite metrics.');
Metric=names';Mean=mean(values,1)';Std=std(values,0,1)';
Minimum=min(values,[],1)';Maximum=max(values,[],1)';Trials=repmat(numel(files),numel(names),1);
summary=table(Metric,Mean,Std,Minimum,Maximum,Trials);
if nargin<2
    folder=files(1).folder;output_path=fullfile(folder,'step_trials_summary.csv');
end
writetable(summary,output_path);disp(summary);
end
