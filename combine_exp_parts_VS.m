%Vanessa Silbar
%This script is used to select experiment parts and combine the csvs 
clear all 
close all

%select the overaching folder
dir_path = uigetdir(pwd);

ovr_dir = dir(dir_path);   % Get directory of experiment
ovr_dir = ovr_dir([ovr_dir.isdir]);                   % Flag directorys
ovr_dir(ismember( {ovr_dir.name}, {'.', '..'})) = [];  % Removes . and ..

all_exp = cell(length(ovr_dir),1);
exp_combine_list = cell(2,1);
pre_combine = cell(2,1);
count = 1;
flag = 0;

for i = 1:length(ovr_dir)
    all_exp{i} = string(ovr_dir(i).name);
    
    if contains(all_exp{i},("pt1"|"pt2"|"pt3")) == 1 %finds all exp parts
        exp_combine_list{count} = all_exp{i};
        count = count + 1;
    end
end

if count == 1
    error('No experiment parts found');
end

%Select all experiment parts

[exp_idx,tf] = listdlg('PromptString',{'Select experiment parts to combine.'},...
    'ListSize',[300,300],'ListString',exp_combine_list);

if sum(exp_idx) == 0 
   error('No experiment selected');
end

exp_string = exp_combine_list{exp_idx(1)};

for j = 2:length(exp_idx) %combines selected experiment parts
    exp_parts = exp_combine_list{exp_idx(j)};
    exp_string = exp_string + ' & ' + exp_parts;
end

dlg_choice = questdlg({('You have selected ' + exp_string + '.')},...
    'Continue','Correct','Quit','Correct');    %confirm the selected experiments are correct 

if isequal(dlg_choice, 'Quit')
    error('Quit program, begin again');
end

for k = 1:length(exp_idx) %finding csvs from selected experiments
    exp_parts = exp_combine_list{exp_idx(k)};
    opts = detectImportOptions(fullfile(dir_path,exp_parts,exp_parts + '.csv'));
    opts.VariableNamingRule = 'preserve';
    pre_combine{k,1} = readtable(fullfile(dir_path,exp_parts,exp_parts + '.csv'),opts);
    
    %if experiments are different sizes, finds the amount of days
    %14 is the variables not including daily activity and there are 3 types
    %of daily activity variables 
    
    exp_days(k,1) = (width(pre_combine{k,1}) - 14) / 3;
    [num_days,idx] = max(exp_days); 
end

for m = 1:length(exp_days)
    if ~isequal(exp_days(m,1),num_days)
        day_diff = num_days - exp_days(m,1);
        curr_exp = pre_combine{m,1};
        work_var(height(curr_exp),:) = 0;
        
        for n = 1:day_diff
            %adds the difference in days for the daily activity variables
            curr_exp = addvars(curr_exp,work_var,'After',...
                ("daily_activity_combined"+exp_days(m,1)),...
                'NewVariableNames',("daily_activity_combined"+(exp_days(m,1)+n)));
            curr_exp = addvars(curr_exp,work_var,'After',...
                ("daily_activity_unstim"+exp_days(m,1)),...
                'NewVariableNames',("daily_activity_unstim"+(exp_days(m,1)+n)));
            curr_exp = addvars(curr_exp,work_var,'After',...
                ("daily_activity_stim"+exp_days(m,1)),...
                'NewVariableNames',("daily_activity_stim"+(exp_days(m,1)+n))); 
        end
        pre_combine{m,1} = curr_exp; 
    end
end

post_combine = vertcat(pre_combine{:,1}); %vertically combine all csvs

for o = 1:height(post_combine)
    post_combine(o,1) = table(o); %reassigns worm number 1 to total worms in all experiment parts
end

%new path uses the name of the last exp part selected
new_path = extractBefore(exp_parts, ("pt1"|"pt2"|"pt3"));

%if a folder of the same name already exists
if ~~exist(fullfile(dir_path,new_path))
    dlg_choice = questdlg({('Folder ' + new_path + ' already exists. Overwrite?')},...
        'WARNING','Overwrite','Quit','Quit');  %confirm overwrite
    
    if isequal(dlg_choice, 'Quit')
        error('Quit program, begin again');
    else
        writetable(post_combine,fullfile(dir_path,new_path,new_path + '.csv'));
        disp('Making csv for ' + new_path);
    end
else
    mkdir(dir_path,new_path)
    writetable(post_combine,fullfile(dir_path,new_path,new_path + '.csv'));
    disp('Making csv for ' + new_path);
end

% [msg,warnID] = lastwarn; %checks warnings

disp("Done :)")