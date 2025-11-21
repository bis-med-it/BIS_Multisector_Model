function res_dist = golden_search(x_target, x_int,SET_baseline, min_target_value, min_target_name)

SET = SET_baseline;

% Input the new parameter values
%eval(['param_new_names = exercises.', char(exercises_fields(1)), '.names ;']) ;
%eval(['param_new_value = exercises.', char(exercises_fields(1)), '.values ;']) ;
param_new_names = min_target_name;
param_new_value = x_int;
% Change the parameter values
try
    for j_ = 1 : size(param_new_names,1) 
        if eval(['size(SET.param.' char(param_new_names(j_,:)) ',1)']) == 1
            eval(['SET.param.', char(param_new_names(j_,:)), ' = ', num2str(param_new_value(j_,:)), ';']) ;
            warning(['Changed ' char(param_new_names(j_,:)) ' to ' num2str(param_new_value(j_,:))])
        elseif eval(['size(SET.param.' char(param_new_names(j_,:)) ',1)']) > 1
            for k_ = 1 : size(param_new_value,1) 
                eval(['SET.param.', char(param_new_names(j_,:)), '(' num2str(k_) ',1) = ', num2str(param_new_value(k_,j_)), ';']) ;
                warning(['Changed ' char(param_new_names(j_,:)) ' to ' num2str(param_new_value(k_,j_))])
            end
        end
    end
catch
    warning('Nothing changed');
end

% Updated the steady state
disp('Calculating initial steady state')

ss_params_update = calc_ss(SET) ;
ss_update = update_steady_state(SET,ss_params_update) ;
%SET.ss = ss_update ;

eval(strcat("res_dist = (log(ss_update.",strjoin(regexp(x_target, '[a-zA-Z_]+', 'match')),"(",regexp(x_target, '\d+', 'match'),")) - min_target_value)^2;"));
end
