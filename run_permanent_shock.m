%% run_permanent_shock.m
% This script runs the simulations for a permanent shock/structural change
close all; clear; clc; tic; 
fprintf('-------------------\n\n');
fprintf('Script execution has started. Estimated runtime: approximately 5700 seconds.\n');
fprintf('Tested on: CPU - 13th Gen Intel(R) Core(TM) i7-1370P (1.90 GHz), RAM - 64.0 GB, OS - Windows 11 Enterprise.\n');
fprintf('Performance may vary depending on your system configuration.\n\n');
fprintf('-------------------\n');
pause(5);

% Folder settings
[folder_path, ~, ~] = fileparts(matlab.desktop.editor.getActiveFilename());
cd(folder_path); addpath(genpath(folder_path));
allPaths = strsplit(path, pathsep);
isDynarePath = false(1, numel(allPaths));
for f = 1:numel(allPaths)
    isDynarePath(f) = exist(fullfile(allPaths{f}, 'dynare.m'), 'file') == 2 && exist(fullfile(allPaths{f}, 'dynare_version.m'), 'file') == 2;
end
d_path = allPaths(isDynarePath);
if ~isempty(d_path) % Check if Dynare path is already added
    fprintf('-------------------\n\n');
    disp(d_path');
    fprintf("The path(s) listed above containing 'Dynare' have been found in the MATLAB search path. Proceeding to the next step...\n");
    pause(5);
else % if not, ask user
    d_path = input( ...
        "-------------------\n\n" + ...
        "\nThe model requires Dynare 5.5 to run. Please ensure it is installed before proceeding.\n" + ...
        "Enter the full Dynare path on your local drive (eg, C:\\Program Files\\Dynare\\5.5\\matlab) and press `Enter`.\n > ", 's');
    d_path = strrep(strrep(d_path, '''', ''), '"', '');
    if exist(d_path, "dir") && ischar(d_path)
        addpath(d_path); fprintf("The following path was successfully added to the MATLAB search path:\n%s\n\n", d_path);
    else
        error("Error: The specified Dynare path does not exist or is invalid. Check the path and try again. Execution has been stopped.");
    end
end

% Select the country and source
[iso2, source] = f_select_country_source(); % function saved under `input\progs'
% `iso2' and `source` must be entered by the user when prompted. Available
% options and instructions are provided in the prompts.
source = ['_' source];

% Option to use the algorithm by Callum Jones
bypass_Callum = 0; % bypass the dyn_to_str algorithm by Callum Jones; not with permanent shocks

% Set the horizon of the IRFs and the number of shocks
horizon = 100;
% If numshk is larger than 1, selected_shock and selected_target must be of
% the same size as the number of shocks
numshk = 1;

% Select the shocks
selected_shocks = {'eps_mm'}; % Shock to the TFP in the commodity sector
for selected_shock = 1:length(selected_shocks)
    eval(strcat('exovars',num2str(selected_shock), "    = '", ...
        selected_shocks{selected_shock},"';")); 
end

% Select the target
selected_targets = {'gam_2'}; % Commodity price is target
for selected_target = 1:length(selected_targets)
    eval(strcat('targetvar',num2str(selected_target), "  = '", ...
        selected_targets{selected_target},"';")); 
end

% Specify the size of the change in the target variable
% 1 stands for doubling the steady state value
target_change_size = .25;

% Specify the Taylor rule
% n_ait_parameter = 1 >>> IT
% n_ait_parameter > 1 >>> AIT
n_ait_parameter = 8;

i = 1;

% Run model
model_run;
out_baseline = out;
dyn_in_baseline = dyn_in;
M__baseline = M_;
SET_baseline = SET;

%% Find the country-specific shock parameter value to pass
min_target_name = {'tau_c_(2)'};
min_target_value = 0.25;
fun = @(x)golden_search(selected_targets{1},x,SET_baseline, min_target_value, min_target_name);
x_end = fminbnd(fun,0.0000001,2.0);
res_dist = golden_search(selected_targets{1},x_end,SET_baseline, min_target_value, min_target_name);
permanent_shock_value = x_end;


%%

% Specify the exercises that you want to run
exercises = struct();
exercises.id_2 = struct();
exercises.id_2.id = 2; % Must be at least 2 because baseline exercise is 1
% Set the names of the parameters to change
exercises.id_2.names =        {'c';'phi_pie'};
exercises.id_2.names_legend = {'\c';'\phi_{\pi}'}; % LaTeX format
% Set the new values of the parameters to change
exercises.id_2.values = [0.1;1.5];
% Specify if perfect foresight or non-perfect foresight
exercises.id_2.foresight = 'pf'; % Perfect foresight = pf; ...
% non perfect foresight = abrupt; stepwise = step; staggered expectations = stag

% Choose the parameter
exercises.id_2.permanent_shock = 'tau_c_';
% Choose the parameter value to pass
exercises.id_2.permanent_shock_value = permanent_shock_value;
% Set the target variable
exercises.id_2.name_save = '_tau_c_01_it';

% Exercise 3
exercises.id_3 = struct();
exercises.id_3.id = 3;
exercises.id_3.names =        {'c';'phi_pie';'phi_pie_core'};
exercises.id_3.names_legend = {'\c';'\phi_{\pi}';'\phi_{core}'}; % LaTeX format
exercises.id_3.values = [0.1;0;1.5];
exercises.id_3.foresight = 'pf';
exercises.id_3.permanent_shock = 'tau_c_';
exercises.id_3.permanent_shock_value =  permanent_shock_value;
exercises.id_3.name_save = '_tau_c_01_core';

% Exercise 4
exercises.id_4 = struct();
exercises.id_4.id = 4;
exercises.id_4.names =        {'c';'phi_pie';'phi_pie_bar'};
exercises.id_4.names_legend = {'\c';'\phi_{\pi}';'\phi_{\bar{\pi}}'}; % LaTeX format
exercises.id_4.values = [0.1;0;1.5];
exercises.id_4.foresight = 'pf';
exercises.id_4.permanent_shock = 'tau_c_';
exercises.id_4.permanent_shock_value = permanent_shock_value;
exercises.id_4.name_save = '_tau_c_01_ait';

exercises_fields = fieldnames(exercises);

for exercise_ = 1:length(exercises_fields)
    out = out_baseline;
    dyn_in = dyn_in_baseline;
    M_ = M__baseline;
    SET = SET_baseline;
    i = str2double(extractAfter(char(exercises_fields(exercise_)),'id_'));

    % Consider structural change scenario:
    y_0         = [log(out.mats.y_bar); 1];
    Q_init      = out.mats.Q;
    G_init      = out.mats.G;

    A0_init = out.mats.A0;
    A1_init = out.mats.A1;
    B0_init = out.mats.B0;
    D0_init = out.mats.D0;

    A_init = A0_init \ A1_init; B_init = A0_init \ B0_init;
    D_init = A0_init \ D0_init;

    out_init = out;

    % Change parameter
    params_orig = M_.params;

    param = SET.param;
    %param.a_ss_(2) = param.a_ss_(2) / 2;   % Halve TFP in sector 2
    % a_ss_2_initialvalue = param.a_ss_(2);
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_initialvalue = param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(2);"));
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_finalvalue = param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(2)+", num2str(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock_value"))),";"));  % Final value in line with a 15% in relative prices in long run.

    c_para = eval(strcat("exercises.",char(exercises_fields(exercise_)),".values(1)"));
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_initialvalue = param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(5);"));
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_finalvalue = param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(5)+ (",num2str(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock_value"))),"*c_para);"));  % Set to c_para to 0 in case of no spillovers

    % MP rule
    % eval(strcat("param.", eval(strcat("exercises.",char(exercises_fields(exercise_)),".names{2}")), "= exercises.",char(exercises_fields(exercise_)),".values(2);"));
    % eval(strcat("param.", eval(strcat("exercises.",char(exercises_fields(exercise_)),".names{3}")), "= exercises.",char(exercises_fields(exercise_)),".values(3);"));
    for it_ = 2:length(eval(strcat("exercises.",char(exercises_fields(exercise_)),".names")))
        eval(strcat("param.", eval(strcat("exercises.",char(exercises_fields(exercise_)),".names{",num2str(it_),"}")), "= exercises.",char(exercises_fields(exercise_)),".values(",num2str(it_),");"));
    end

    eval(strcat("param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(2) =  ",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_finalvalue;"));   % Adjust TFP in sector 2
    eval(strcat("param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(5) =  ",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_finalvalue;"));   % Adjust TFP in sector 5
    transition_matrices_calculation  % File calculates the new matrices

    B_temp = B_new;
    A_temp = A_new;
    D_temp = D_new;

    horizon = 100;

    % Construct time varying matrices using Kulish-Pagan
    init_para = 9; % Initialization period of old regime - needs to be larger than 1
    horizon_para = 40;
    if strcmp(eval(strcat("exercises.",char(exercises_fields(exercise_)),".foresight")),'stag')
        extra_inertia = 40;
        T_b = horizon_para + extra_inertia + init_para; % Period of finished structural break.  
        T_a = 1 + init_para; % Period of transition structural break
    elseif strcmp(eval(strcat("exercises.",char(exercises_fields(exercise_)),".foresight")),'abrupt')
        extra_inertia = 0;
        T_b = 2 + extra_inertia + init_para; % Period of finished structural break.  
        T_a = 1 + init_para; % Period of transition structural break
    else
        extra_inertia = 0;
        T_b = horizon_para + extra_inertia + init_para; % Period of finished structural break.  
        T_a = 1 + init_para; % Period of transition structural break
    end
    T_c = T_b - extra_inertia;
    n_bp = M_.endo_nbr + 1;
    l_   = M_.exo_nbr;


    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_transitionvec = linspace(",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_finalvalue,",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_initialvalue,T_b-T_a+2);"));
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_transitionvec = linspace(",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_finalvalue,",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_initialvalue,T_b-T_a+2);"));
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_transitionvec2 = linspace(",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_finalvalue,",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_initialvalue,T_c-T_a+2);"));
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_transitionvec2 = linspace(",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_finalvalue,",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_initialvalue,T_c-T_a+2);"));
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_transitionvec2 = [repmat(",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_finalvalue, 1, extra_inertia), ",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_transitionvec2];"));
    eval(strcat(eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_transitionvec2 = [repmat(",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_finalvalue, 1, extra_inertia), ",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_transitionvec2];"));


    Q_tv = zeros(n_bp, n_bp, horizon);
    G_tv = zeros(n_bp, l_, horizon);

    % After the structural change
    Q_tv(:,:,T_b : horizon) = repmat(Q_new,1,1,horizon - T_b + 1);
    G_tv(:,:,T_b : horizon) = repmat(G_new,1,1,horizon - T_b + 1);

    % During the transition period
    iii = 2;
    for t_ = T_b - 1 : -1 : T_a


        eval(strcat("param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(2) =  ",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_transitionvec(iii);"));   % Adjust TFP in sector 2
        eval(strcat("param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(5) =  ",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_transitionvec(iii);"));   % Adjust TFP in sector 2
        transition_matrices_calculation  % File calculates the new matrices

        B_temp = B_new;
        A_temp = A_new;
        D_temp = D_new;
        Q_temp = Q_new;

        if extra_inertia > 1
            eval(strcat("param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(2) =  ",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"2_transitionvec2(iii);"));   % Adjust TFP in sector 2
            eval(strcat("param.",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"(5) =  ",eval(strcat("exercises.",char(exercises_fields(exercise_)),".permanent_shock")),"5_transitionvec2(iii);"));   % Adjust TFP in sector 2
            transition_matrices_calculation  % File calculates the new matrices
            B_temp = B_new;
            A_temp = A_new;
            D_temp = D_new;
        end

        %Q_tv(:,:,t_) = Q_new;
        %G_tv(:,:,t_) = G_new;

        if strcmp(eval(strcat("exercises.",char(exercises_fields(exercise_)),".foresight")),'pf')
            % Perfect Foresight
            Q_tv(:,:,t_) = (eye(n_bp) - B_temp * Q_tv(:,:,t_+1)) \ A_temp;
            G_tv(:,:,t_) = (eye(n_bp) - B_temp * Q_tv(:,:,t_+1)) \ D_temp;
        elseif strcmp(eval(strcat("exercises.",char(exercises_fields(exercise_)),".foresight")),'nopf')
            % Surprise Each Period
            Q_tv(:,:,t_) = (eye(n_bp) - B_temp * Q_init) \ A_temp;
            G_tv(:,:,t_) = (eye(n_bp) - B_temp * Q_init) \ D_temp;
        elseif strcmp(eval(strcat("exercises.",char(exercises_fields(exercise_)),".foresight")),'step')
            % Stepwise
            Q_tv(:,:,t_) = Q_new;
            G_tv(:,:,t_) = G_new;
        elseif strcmp(eval(strcat("exercises.",char(exercises_fields(exercise_)),".foresight")),'stag')
            % Staggered expectations
            Q_tv(:,:,t_) = (eye(n_bp) - B_temp * Q_temp) \ A_temp;
            G_tv(:,:,t_) = (eye(n_bp) - B_temp * Q_temp) \ D_temp;
        elseif strcmp(eval(strcat("exercises.",char(exercises_fields(exercise_)),".foresight")),'abrupt')
            % Abrupt with perfect foresight
            Q_tv(:,:,t_) = (eye(n_bp) - B_temp * Q_tv(:,:,t_+1)) \ A_temp;
            G_tv(:,:,t_) = (eye(n_bp) - B_temp * Q_tv(:,:,t_+1)) \ D_temp;
        end

        iii = iii+1;
    end

    % Before the transition
    Q_tv(:,:,1:T_a-1) = repmat(Q_init,1,1,T_a-1);
    G_tv(:,:,1:T_a-1) = repmat(G_init,1,1,T_a-1);

    % Create error matrix
    e_ = zeros(l_, horizon);
    if eval(strcat("isfield(exercises.",char(exercises_fields(exercise_)),", 'temp_shock')"))
        eval(strcat("e_(find(strcmp(M_.exo_names, exercises.",char(exercises_fields(exercise_)),".temp_shock)),exercises.",char(exercises_fields(exercise_)),".temp_shock_horizon_start:exercises.",char(exercises_fields(exercise_)),".temp_shock_horizon_end) = exercises.",char(exercises_fields(exercise_)),".temp_shock_horizon_value;"))
    end

    for t_ = 2 : horizon

        y_0(:,t_) = Q_tv(:,:,t_) * y_0(:,t_-1) + G_tv(:,:,t_) * e_(:,t_);

    end

    dyn_in = dyn_in.oo_.var_list;

    if ~exist(strcat("output\permanent_shock\",iso2), 'dir')
        mkdir(strcat("output\permanent_shock\",iso2)); % Create the folder
    end

    eval(strcat("save output\permanent_shock\",iso2,"\", char(exercises_fields(exercise_)), eval(strcat("exercises.",char(exercises_fields(exercise_)),".name_save")),"_",eval(strcat("exercises.",char(exercises_fields(exercise_)),".foresight")),  " dyn_in y_0"));

end

close all;

toc


%% Variable to plot IRFs for
vcell = {'pie','gam_2','r','y_va','c','rr'}; % b
annualisation_cell = {'400','100','400','100','100','400'};
titlecell = {'Inflation','Relative price, energy','Policy rate','Real output',...
    'Real consumption','Real interest rate'};
obs_units = {'pp','pp','pp','%','%','pp'};
lin_style = {'-','--',':'};
fontSize = 15;
fontName = 'Times New Roman';

%% Plot the IRFs comparing the different parameters assigned under each
% exercise and the same monetary policy rule

% Check if the relevant folder exists
if ~exist(strcat("graphs\permanent_shock\",iso2), 'dir')
    mkdir(strcat("graphs\permanent_shock\",iso2)); % Create the folder
end

% Import the results
clearvars -except exercises exercises_fields source iso2 n_ait_parameter vcell annualisation_cell titlecell selected_shocks folder_path fontSize fontName obs_units horizon lin_style
for i = 1:length(exercises_fields)
    load(['output\permanent_shock\' iso2 '\' exercises_fields{i} eval(strcat("exercises.",exercises_fields{i},".name_save")) '_' eval(strcat("exercises.",exercises_fields{i},".foresight")) '.mat'])
    eval(strcat("dyn_in_",exercises_fields{i},"_", iso2,"= dyn_in;"));
    eval(strcat("y_0_",exercises_fields{i},"_", iso2,"= y_0;"));
end

% Figure
figure_name = strcat(folder_path,'\graphs\permanent_shock\',iso2,'\',iso2,'_struct_shock_',exercises.id_2.foresight);
fprintf('Generating figures:\n %s.jpg\n %s.eps\n', figure_name, figure_name);
close all;
jj=0;figure;
set(gcf, 'Position', [100, 100, 1400, 1400]);  % [left, bottom, width, height]
set(gcf, 'PaperPositionMode', 'auto');
set(gca, 'FontSize', fontSize);
set(gca, 'FontName', fontName);
for n = 1:numel(vcell)
    v = vcell{n};
    annualisation = annualisation_cell{n};
    jj = jj +1;
    subplot(2,3,jj)
    grid on; grid minor; box on; hold on;

    eval(['plot([zeros(1) (y_0_id_2_',iso2,'(find(ismember(dyn_in_id_2_',iso2,',''', v,''')),11:',num2str(horizon),')- y_0_id_2_',iso2,'(find(ismember(dyn_in_id_2_',iso2,',''', v,''')),1)   )*', annualisation, '], ''LineWidth'', 1.5, ''LineStyle'',''' lin_style{1} '''); hold on;']);
    for i = 2:length(exercises_fields)
        eval(['plot([zeros(1) (y_0_',exercises_fields{i},'_',iso2,'(find(ismember(dyn_in_',exercises_fields{i},'_',iso2,',''', v,''')),11:',num2str(horizon),')- y_0_',exercises_fields{i},'_',iso2,'(find(ismember(dyn_in_',exercises_fields{i},'_',iso2,',''', v,''')),1)   )*', annualisation, '], ''LineWidth'', 1.5, ''LineStyle'',''' lin_style{i} ''');']);
    end
    title([iso2  ' ' lower(titlecell{n})], 'FontSize', fontSize, 'FontName', fontName);
    yline(0, '-black', 'LineWidth', 1.5);
    xline(0, '-black', 'LineWidth', 1.5);
    ylabel([obs_units{n}], 'FontSize', fontSize, 'FontName', fontName);
    xlabel('Quarters', 'FontSize', fontSize, 'FontName', fontName)
    ax = gca;
    ax.XAxis.FontSize = fontSize-2;
    ax.YAxis.FontSize = fontSize-2;

end
legend_handle = legend(['Headline inflation targeting'], ...
    ['Core inflation targeting'], ...
    ['Average inflation targeting'], ...
    'Location', 'northeast','FontSize',fontSize-3,'Orientation','Horizontal', 'Interpreter', 'latex');
set(legend_handle,'Position',[0.39, 0.01, 0.25, 0.04],'Units','normalized')
print(figure_name,'-djpeg','-r600')
print(figure_name,'-depsc','-r300')
fprintf('Script execution completed successfully.\n');

toc
