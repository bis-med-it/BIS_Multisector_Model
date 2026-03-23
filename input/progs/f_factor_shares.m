function t_factors = f_factor_shares(folder_path,mapping_file,source,industry_names,t_io_final)

% -------------------------------------------------------------------------
% This function decomposes total value added (from ADB MRIO and OECD ICIO)
% into labor and capital components using industry-specific ratios from
% the US, based on data from the US BEA IO table.
% -------------------------------------------------------------------------

    % 1.1 Load data on factor inputs from the US BEA IO table
    filename_us_factors = fullfile(folder_path, 'input', 'data', 'US_Input_Output_Detail_2019.xlsx');
    t_us_factors = readtable(filename_us_factors);
    factors = {'Compensation of employees','Gross operating surplus'}; % Labour, capital
    t_us_factors = t_us_factors(ismember(t_us_factors.Commodities_Industries,factors),:);
    t_us_factors = rows2vars(t_us_factors);
    t_us_factors.Properties.VariableNames = table2array(t_us_factors(2,:));
    t_us_factors.Code = t_us_factors.Commodities_Industries;

    % 1.2 Map sectors into broader industries
    var_codes_us_factors = readtable(mapping_file, 'Sheet', 'IO_VariableCodes_BEA');
    t_us_factors = innerjoin(t_us_factors,var_codes_us_factors,'Keys','Code');

    if ismember(source,{'oecd','oecd2025e'}) 
        t_us_factors.Code_std_20(strcmp(t_us_factors.Code_std_20,'Wholesale')) = {'WholesaleAndRetail'};
        t_us_factors.Code_std_20(strcmp(t_us_factors.Code_std_20,'Retail')) = {'WholesaleAndRetail'};
    end

    t_us_factors = t_us_factors(ismember(t_us_factors.Code_std_20,industry_names),:);
    
    t_us_factors = t_us_factors(:,["Code_std_20","Compensation of employees","Gross operating surplus"]);
    t_us_factors.("Compensation of employees") = cell2mat(t_us_factors.("Compensation of employees"));
    t_us_factors.("Gross operating surplus") = cell2mat(t_us_factors.("Gross operating surplus"));
    t_us_factors = groupsummary(t_us_factors,"Code_std_20","sum");

    % 1.3 Sort
    [~, order] = ismember(t_us_factors.Code_std_20, industry_names);
    [~, sortIdx] = sort(order);
    t_us_factors = t_us_factors(sortIdx, :);
    t_us_factors.Properties.VariableNames = replace(t_us_factors.Properties.VariableNames,"sum_","");
    t_us_factors.Properties.RowNames = t_us_factors.Code_std_20;
    t_us_factors(:,{'GroupCount','Code_std_20'}) = [];

    % 1.4 Join with value added in the IO table for the selected economy
    t_va = rows2vars(t_io_final("ValueAdd",:));
    t_va = t_va(ismember(t_va.OriginalVariableNames,industry_names),:);
    t_va.Properties.RowNames = t_va.OriginalVariableNames;
    t_va.OriginalVariableNames = [];
    t_factors = [t_us_factors t_va];

    % 1.5 Take the ratio of labour/capital to total value added for the US
    % data and multiply these ratios by the value added for the selected economy
    t_factors.VA_Labour = t_factors.ValueAdd ...
        .* (t_factors.("Compensation of employees") ...
        ./ (t_factors.("Compensation of employees") + t_factors.("Gross operating surplus")));
    t_factors.VA_Capital = t_factors.ValueAdd ...
        .* (t_factors.("Gross operating surplus") ...
        ./ (t_factors.("Compensation of employees") + t_factors.("Gross operating surplus")));

    % 1.6 Transpose to get ready to be joined with io_inputs
    t_factors = rows2vars(t_factors(:,["VA_Labour","VA_Capital"]));
    t_factors.Properties.RowNames = t_factors.OriginalVariableNames;
    t_factors.OriginalVariableNames = [];

end
