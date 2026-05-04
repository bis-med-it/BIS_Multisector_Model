function [io, empl] = f_main_prepare_data(folder_path, iso2, source)

%% Function to prepare data input for the model
% -------------------------------------------------------------------------
% This function processes raw input-output (IO) and employment data for
% selected economies and data sources, standardising it for use in the
% model. It performs the following tasks:
%
% 1. Prepares data input for the selected economy (specified using
%    their ISO-2 codes) from the specified data source.
%
% 2. Saves the processed data as `.mat` files under the `input` folder,
%    with separate files for each economy and data source.
%
% Functions used:
% - `f_setup_adb.m`: Processes ADB MRIO data.
% - `f_iso2_to_adbmrio.m`: Converts ISO-2 codes to ADB MRIO codes.
% - `f_setup_bea.m`: Processes US BEA IO data.
% - `f_setup_oecd.m`: Processes OECD ICIO data.
% - `f_setup_oecd2025e.m`: Processes OECD ICIO (2025 edition) data.
% - `f_iso2_to_oecdicio.m`: Converts ISO-2 codes to OECD ICIO (for both 20233 and 2025 editions) codes.
% - `f_factor_shares.m`: Computes factor shares (labour and capital).
% - `f_setup_employment_shares.m`: Computes employment shares by industry.
% -------------------------------------------------------------------------

%% 1 Check if the `.mat' files already exist, if so simply load existing files
source = source(2:end);
file_io = fullfile(folder_path, 'input', [iso2 '_io_results_' source '.mat']);
file_emp = fullfile(folder_path, 'input', [iso2 '_employment_results_' source '.mat']);

if exist(file_io,'file') == 2 && exist(file_emp,'file') == 2
    fprintf("-------------------\n\n Loading %s ...\n\n",file_io);
    load(file_io,'io');
    fprintf("-------------------\n\n Loading %s ...\n\n",file_emp);
    load(file_emp,'empl');
    fprintf('-------------------\n\n');
    fprintf(' Input files are ready. Proceeding to the next step...\n\n'); pause(5);
    fprintf('-------------------\n\n');
else

    %% 2 Generate `.mat' files from raw data

    % 2.1 Folders
    restoredefaultpath;
    % Restore the MATLAB default path to avoid conflicts with commands
    % that might mistakenly use functions or files from the Dynare path.
    cd(folder_path); addpath(genpath(folder_path));

    % 2.2 Files needed

    % 2.2.1 Raw data files
    file_adb = fullfile(folder_path, 'input', 'data', 'ADB-MRIO62-2019_Dec2022.xlsx');
    file_us_bea = fullfile(folder_path, 'input', 'data', 'US_Input_Output_Detail_2019.xlsx');
    file_oecd = fullfile(folder_path, 'input', 'data', 'ICIO2023_2019.csv');
    file_oecd2025e = fullfile(folder_path, 'input', 'data', 'ICIO2025edition_2019.csv');
    file_bls_emp = fullfile(folder_path, 'input', 'data', 'emp2022.csv');

    % 2.2.2 File used to map industries in raw tables to broader, standardised industries
    mapping_file = fullfile(folder_path, 'input', 'data', 'IO_mapping.xlsx');

    % 2.3 Set warnings to `off' to silence warnings about table variables names
    warning('off','all')

    %% 3 Process raw data into standardised format
    if ismember(source,{'adb','bea','oecd','oecd2025e'})
        fprintf('-------------------\n\n Loading raw data ... \n\n');

        % Load employment data
        fprintf('-------------------\n\n 1 Loading employment data (estimated runtime: 1 minute) ... \n\n');
        t_empl = readtable(file_bls_emp, 'ReadVariableNames', true, 'ReadRowNames', true);

    end

    if strcmp(source,'adb')

        % Load data
        fprintf('-------------------\n\n 2 Loading ADB MRIO (estimated runtime: 1 minute) ... \n');
        io_raw = readcell(file_adb,'Sheet','ADB MRIO 2019', 'Range','C6');
        io_raw(cellfun(@(x) any(ismissing(x)), io_raw)) = {''};

        % Process
        io = f_setup_adb(folder_path, mapping_file, source, iso2, io_raw);
        empl = f_setup_employment_shares(folder_path, mapping_file, source, iso2, t_empl);

        fprintf(' Input files are ready. Proceeding to the next step...\n\n'); pause(5);
        fprintf('-------------------\n\n');

    elseif strcmp(source,'bea')

        if strcmp(iso2,'US')

            % Load data
            opts = detectImportOptions(file_us_bea,'VariableNamesRange','C6', 'DataRange','C8:CR86', 'RowNamesRange','A8');
            opts.VariableTypes = repmat({'double'},1,94);
            fprintf('-------------------\n\n 2 Loading US BEA IO (estimated runtime: 2 seconds) ... \n');
            io_raw = readtable(file_us_bea,opts, 'ReadVariableNames',true, 'ReadRowNames',true);

            % Process
            io = f_setup_bea(folder_path, mapping_file, source, iso2, io_raw);
            empl = f_setup_employment_shares(folder_path, mapping_file, source, iso2, t_empl);

            fprintf(' Input files are ready. Proceeding to the next step...\n\n'); pause(5);
            fprintf('-------------------\n\n');

        else
            fprintf('\n US BEA IO table includes data for only the US.\n');
        end

    elseif strcmp(source,'oecd')

        % Load data
        fprintf('-------------------\n\n 2 Loading OECD ICIO (estimated runtime: 2 minutes) ... \n');
        io_raw = readcell(file_oecd);
        io_raw(cellfun(@(x) any(ismissing(x)), io_raw)) = {''};

        % Process
        io = f_setup_oecd(folder_path, mapping_file, source, iso2, io_raw);
        empl = f_setup_employment_shares(folder_path, mapping_file, source, iso2, t_empl);

        fprintf(' Input files are ready. Proceeding to the next step...\n\n'); pause(5);
        fprintf('-------------------\n\n');

    elseif strcmp(source,'oecd2025e')

        % Load data
        fprintf('-------------------\n\n 2 Loading OECD ICIO 2025 edition (estimated runtime: 2 minutes) ... \n');
        io_raw = readcell(file_oecd2025e);
        io_raw(cellfun(@(x) any(ismissing(x)), io_raw)) = {''};

        % Process
        io = f_setup_oecd2025e(folder_path, mapping_file, source, iso2, io_raw);
        empl = f_setup_employment_shares(folder_path, mapping_file, source, iso2, t_empl);

        fprintf(' Input files are ready. Proceeding to the next step...\n\n'); pause(5);
        fprintf('-------------------\n\n');
    else
        fprintf("-------------------\n\n Source not found.\n");
    end

    fprintf('-------------------\n\n')

    % Set warnings back to `on'
    warning('on','all')

end
end



