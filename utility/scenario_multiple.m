function scenario_path = scenario_multiple(oo_,M_,out,horizon,exonum,exo_nbr,...
                            targetpath,targetnum, bypass_Callum)
%% scenario_multiple
%
% This function runs a scenario for the multisector DSGE model.
% The scenario consists of an unanticipated sequence of shocks to shocks in exonum to
% hit a sequence of outcomes (targetpath) for variables targetnum.

% Check sizes
numvars = size(targetpath,1);
numshks = numel(exonum);
mats    = out.mats ;

% Compute IRF to the desired shock
e1            = zeros(exo_nbr,1,numshks);
for jj = 1 : numshks
e1(exonum(jj),1,jj) = 1; % Select the exogenous shock
y(:,:,jj)           = irf_func(oo_, mats, e1(:,:,jj), horizon, bypass_Callum);       % Compute IRF
scalefac(:,jj)      = y(targetnum,1,jj);                       % Scale shock to get one unit change in target variable
end

scenario_path = y(:,:,1);

for t = 1 : horizon

    if length(targetpath) >= t
        targetmiss      = targetpath(:,t) - scenario_path(targetnum,t);
        scaleshock(:,t) = inv(scalefac) * targetmiss;   
        for jj = 1 : numshks
            scenario_path(:,t) = scenario_path(:,t) + scaleshock(jj,t)*y(:,1,jj);
        end
    else
        scaleshock(:,t) = 0*scaleshock(:,t-1);
    end
    if t < horizon
        for jj = 1 : t
            for kk = 1 : numshks
                scenario_path(:,t+1) = scenario_path(:,t+1) + scaleshock(kk,jj)*y(:,t - jj + 2,kk);
            end
        end
    end
    
end

