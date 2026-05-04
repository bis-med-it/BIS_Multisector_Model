function io = f_setup_oecd2025e(folder_path, mapping_file, source, iso2, io_raw)
% -------------------------------------------------------------------------
% This function processes OECD ICIO data (2025 edition) for a selected country
% (specified using the ISO-2 code) and maps it into broader industries based
% on the provided mapping file. It performs the following tasks:
%
% 1. Extracts country-specific data from the OECD ICIO (2025 edition) table,
%    aggregating data for Euro Area (EA) member countries if EA is selected.
%
% 2. Maps the data to broader industry classifications as defined in the
%    mapping file (\input\data\IO_mapping.xlsx).
%
% 3. Decomposes value added into factors of production (labour and capital)
%    using industry-specific ratios derived from the US BEA IO table (see
%    `f_factor_shares.m` for details).
%
% 4. Saves the following variables into a structured format (`io`) for
%    further use in the model:
%    a. Country code: `iso2'
%    b. Names of industries in the matrix order: `industry_names`
%    c. Total number of sectors: `nsectors`
%    d. Matrix of intermediate inputs and factor shares: `io_inputs`
%       - The top rows of the matrix represent intermediate input shares.
%       - The bottom rows represent the shares of labour and capital as
%         factors of production.
%    e. Weights of final demand components by industry:
%       - `consumption_weights`, `investment_weights`, and `government_weights`
%    f. Shares of total final demand components in GDP:
%       - `consumption_share`, `investment_share`, and `government_share`
%    g. Share of taxes in gross output: `taxes_ishare`
%
% 5. Saves the `io` struct for the specified country into a `.mat` file
%    under the `\input` folder.
% -------------------------------------------------------------------------

%% 1 Convert country code
% Notes:
% 1 OECD country codes follow ISO-3 standard
% 2 For EA, we add up data for member economies that are available

% 1.1 Economies other than China, euro area and Mexico
if ~ismember(iso2,{'CN','EA','MX'})
    oecdcode = f_iso2_to_oecdicio(iso2);
    fprintf('\n  %s -> in OECD ICIO (2025 edition) : %s \n', iso2, oecdcode{:});
end

% 1.2 China
if strcmp(iso2,'CN')
    oecdcode = {'CN1','CN2'};
end

% 1.3 Euro area
% List of EA member countries needed for aggregation when EA is selected
ea = {'AT','BE','CY','DE','EE','ES','FI','FR','GR','HR','IE','IT','LT','LU','LV','MT','NL','PT','SI','SK'};
if strcmp(iso2,'EA')
    oecdcode = cell(numel(ea),1);
    for c = 1:numel(ea)
        oecdcode(c) = f_iso2_to_oecdicio(ea{c});
    end
    fprintf('\n  %s -> in OECD ICIO (2025 edition): Sum of %s \n' , iso2, strjoin(oecdcode, ', '));
end

% 1.4 Mexico
if strcmp(iso2,'MX')
    oecdcode = {'MX1','MX2'};
end

%% 2 Extract data that belongs to the selected economy
% 2.1 Check if the country is included in the OECD ICIO (2025 edition) table
if isempty(oecdcode)
    fprintf('\nThe country "%s" was not found in the OECD ICIO (2025 edition) table.\n', iso2);
end

% 2.2 Extract data that belongs to the selected economy
if ~isempty(oecdcode)
    fprintf('\n  Processing data for %s...\n',iso2)

    % 2.2.1 Determine rows and columns to be selected
    select_row = ~ismissing(io_raw(:,1)) & ~strcmp(io_raw(:,1), 'V1');

    row_country_sector = io_raw(:,1);
    row_sector = extractAfter(row_country_sector,'_');
    row_sector(end-2:end) = row_country_sector(end-2:end); % TLS VA OUT

    column_country_sector = io_raw(1,:);
    column_sector = extractAfter(column_country_sector,'_');
    column_country = extractBefore(column_country_sector,'_');

    select_col = contains(column_country,oecdcode);
    num = cell2mat(io_raw(select_row,select_col));

    % 2.2.2 Create a new table with the data for the selected country
    % 2.2.2.1 Economies other than CN, EA, MX
    if ~ismember(iso2,{'CN','EA','MX'})
        colShortName_industry = column_sector(select_col);
        t_io = array2table(num,'VariableNames',colShortName_industry);
    end

    % 2.2.2.2 EA: take the sum of numbers for member countries
    if ismember(iso2,{'EA','CN','MX'})
        col_country_industry = column_country_sector(select_col);
        t_ea = array2table(num,'VariableNames',col_country_industry);

        sectors = unique(column_sector,'stable');
        sectors = sectors(~ismissing(sectors));
        t_io = table();

        for sc_ = 1:numel(sectors)
            t_sector = t_ea(:, endsWith(t_ea.Properties.VariableNames, ['_' sectors{sc_}]));
            t_io(:,sectors{sc_}) = sum(t_sector, 2);
        end
    end

    t_io.Code = row_sector(select_row);

    % 2.2.3 Process rows
    % 2.2.3.1 Add up domestic and international parts of intermediate inputs and final use (add up rows)
    t_io_sum = groupsummary(t_io,"Code","sum");

    % 2.2.3.2 Load broader industry codes and join with the table
    row_codes = readtable(mapping_file, 'Sheet', ['IO_RowCodes_' upper(source)]);
    var_codes = readtable(mapping_file, 'Sheet', ['IO_VariableCodes_' upper(source)]);
    t_io_sum_brd = innerjoin(t_io_sum,row_codes,'Keys','Code');

    % 2.2.3.3 Aggregate rows according to the broader industry classification
    t_io_sum_brd(:, {'Code', 'GroupCount', 'Definition'}) = [];
    t_io_sum_brd = groupsummary(t_io_sum_brd,"Code_std_18","sum");
    t_io_sum_brd.GroupCount = [];

    % 2.2.3.4 Sort
    row_codes_brd = table(unique(row_codes.Code_std_18,'stable'));
    row_codes_brd.Properties.VariableNames = {'Code_std_18'};
    row_codes_brd.Code_nums = (1:size(row_codes_brd,1))';
    t_io_sum_brd = innerjoin(t_io_sum_brd,row_codes_brd);
    t_io_sum_brd = sortrows(t_io_sum_brd,"Code_nums");
    t_io_sum_brd.Properties.VariableNames = replace(t_io_sum_brd.Properties.VariableNames,"sum_sum_","");
    t_io_sum_brd.Properties.RowNames = t_io_sum_brd.Code_std_18;
    t_io_sum_brd(:,{'Code_std_18', 'Code_nums'}) = [];

    % 2.2.4 Process columns/variables
    % 2.2.4.1 Transpose table t_io_sum_brd
    t_io_sum_brd_tr = rows2vars(t_io_sum_brd);
    t_io_sum_brd_tr.Properties.VariableNames = replace(t_io_sum_brd_tr.Properties.VariableNames,'OriginalVariableNames','Code');

    % 2.2.4.2 Aggregate rows according to the broader industry classification
    t_io_sum_brd_tr_brd = innerjoin(t_io_sum_brd_tr,var_codes,'Keys','Code');
    t_io_sum_brd_tr_brd(:,{'Code','Definition'}) = [];
    t_io_sum_brd_tr_brd = groupsummary(t_io_sum_brd_tr_brd,"Code_std_18","sum");
    t_io_sum_brd_tr_brd.GroupCount = [];

    % 2.2.4.3 Sort
    var_codes_brd = table(unique(var_codes.Code_std_18,'stable'));
    var_codes_brd.Properties.VariableNames = {'Code_std_18'};
    var_codes_brd.Code_nums = (1:size(var_codes_brd,1))';
    t_io_sum_brd_tr_brd = innerjoin(t_io_sum_brd_tr_brd,var_codes_brd);
    t_io_sum_brd_tr_brd = sortrows(t_io_sum_brd_tr_brd,"Code_nums");
    t_io_sum_brd_tr_brd.Properties.VariableNames = replace(t_io_sum_brd_tr_brd.Properties.VariableNames,"sum_","");
    t_io_sum_brd_tr_brd.Properties.RowNames = t_io_sum_brd_tr_brd.Code_std_18;
    t_io_sum_brd_tr_brd(:,{'Code_std_18', 'Code_nums'}) = [];

    % 2.2.5 Final clean table for the selected economy
    t_io_final = rows2vars(t_io_sum_brd_tr_brd); % transpose back
    t_io_final.Properties.RowNames = t_io_final.OriginalVariableNames;
    t_io_final.OriginalVariableNames = [];


end

%% 3 Format the table into a struct to be fed into the model

if exist('t_io_final','var')

    fprintf('\n  Saving the mat file for %s... \n', iso2)

    % 3.1 Define the first and last industries
    first_name= {'Agriculture'} ; % First industry
    last_name = {'Other'} ;% Last industry

    idx_1 = find(strcmp(t_io_final.Properties.VariableNames, first_name)); % Index of first industry
    idx_2 = find(strcmp(t_io_final.Properties.VariableNames, last_name)); % Index of last industry

    % Check: Row and column names for the sectors should be the same
    % display([t_io_final.Properties.RowNames(1:idx_2) t_io_final.Properties.VariableNames(1:idx_2)'])
    assert(sum(~strcmp(t_io_final.Properties.RowNames(1:idx_2),t_io_final.Properties.VariableNames(1:idx_2)')) == 0)

    % 3.2 Extract matrix of intermediate inputs
    io_inputs = t_io_final(idx_1 : idx_2, 1 : idx_2);
    industry_names = io_inputs.Properties.RowNames;

    % 3.2.1 Replace nans and eliminate zeros
    idx = ismissing(io_inputs);
    io_inputs{:,:}(idx) = 0;
    io_inputs = io_inputs{:,:} + 1;

    % 3.3 Load factors of production >> separate function
    t_factors = f_factor_shares(folder_path,mapping_file,source,industry_names,t_io_final);
    assert(sum(~strcmp(t_factors.Properties.VariableNames',industry_names))== 0)
    % industry names should follow the same order - factor inputs are appended at the end of the intermediate inputs later on
    io_factors = t_factors{:,:};

    % 3.4 Extract taxes
    taxes_matrix = t_io_final{strcmp('Taxes',t_io_final.Properties.RowNames), 1 : idx_2};

    % 3.5 Extract final uses

    % 3.5.1 Consumption
    consumption = t_io_final.Consumption(idx_1 : idx_2) + 100;
    total_consumption = sum(consumption);
    consumption_weights = consumption ./ total_consumption;

    % 3.5.2 Investment
    investment = t_io_final.Investment(idx_1 : idx_2) + 100;
    total_investment = sum(investment);
    investment_weights = investment ./ total_investment;

    % 3.5.3 Government
    government_demand = t_io_final.Government_Demand(idx_1 : idx_2) + 100;
    total_government_demand = sum(government_demand);
    government_demand_weights = government_demand ./ total_government_demand;

    % 3.5.4 Total GDP and shares
    total_gdp = total_consumption + total_investment + total_government_demand;
    consumption_share = total_consumption / total_gdp;
    investment_share = total_investment / total_gdp;
    government_share = total_government_demand / total_gdp;
    final_demand = consumption + investment + government_demand;
    industry_ii = sum(io_inputs,2);
    gross_output = final_demand + industry_ii;
    taxes_ishare = taxes_matrix' ./ gross_output;

    % 3.6 Save data into a struct, io
    io.iso2 = iso2;
    io.industry_names = industry_names;
    io.nsectors = size(industry_names,1);
    io.io_inputs= [io_inputs; io_factors];

    io.consumption_weights = consumption_weights;
    io.investment_weights = investment_weights;
    io.government_weights = government_demand_weights;

    io.consumption_share= consumption_share;
    io.investment_share = investment_share;
    io.government_share = government_share;
    io.taxes_ishare = taxes_ishare;

    % 3.7 Save
    save(fullfile(folder_path, 'input', [iso2 '_io_results_oecd2025e.mat']),'io');
    fprintf('\n  %s_io_results_oecd2025e.mat saved under: \n  %s \n\n ', iso2, fullfile(folder_path, 'input'));
end
end
