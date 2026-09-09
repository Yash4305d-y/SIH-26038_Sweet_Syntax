%% run_simulation.m
%
% Role 3 - District-Scale Digital Twin Simulation Runner
% SIH 2026 - PS 38 / Explainable AI for DR Screening in Rural India
%
% This script coordinates execution across all required project scenarios:
% 1. 30-Day verification run (AI-assisted mode)
% 2. 330-Day district scale-up run (AI-assisted mode, 100,000 patients/year)
% 3. 330-Day manual baseline comparison run (Unassisted manual review)
%
% Outputs are saved to the results/ folder for telemetry extraction.
%

clear;
clc;

fprintf('======================================================\n');
fprintf('  ROLE 3: RUNNING DISTRICT-SCALE DIGITAL TWIN MODELS  \n');
fprintf('======================================================\n');

%% ============================================================
% 1. ENVIRONMENT & PATH SETUP
% =============================================================

% Determine project root directory
currentDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(currentDir);

% Add required subdirectories to MATLAB search path
addpath(fullfile(rootDir, 'parameters'));
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'results'));

% Verify results directory exists
resultsDir = fullfile(rootDir, 'results');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

% Target model name
modelName = 'DR_DigitalTwin_Day2';

% Load Simulink system into memory if not already loaded
if ~bdIsLoaded(modelName)
    fprintf('Loading Simulink model: %s.slx...\n', modelName);
    load_system(modelName);
else
    fprintf('Simulink model %s is already loaded in memory.\n', modelName);
end


%% ============================================================
% 2. SCENARIO 1: 30-DAY OPERATIONAL TEST (AI-ASSISTED MODE)
% =============================================================

fprintf('\n------------------------------------------------------\n');
fprintf('[1/3] EXECUTING 30-DAY VERIFICATION RUN (AI MODE)\n');
fprintf('------------------------------------------------------\n');

% Load baseline parameters
run(fullfile(rootDir, 'parameters', 'simulation_parameters_day2.m'));

% Configure for 30 days
simParams.simulation.runDays = 30;
simParams.simulation.stopTime = simParams.simulation.runDays * 24 * 60 * 60;
simParams.experiment.reviewMode = "AI";

% Re-evaluate parameter dependencies
run(fullfile(rootDir, 'parameters', 'simulation_parameters_day2.m'));

% Verify simulation time in Simulink configuration
set_param(modelName, 'StopTime', num2str(simParams.simulation.stopTime));

fprintf('Running simulation for %d days (%d seconds)...\n', ...
    simParams.simulation.runDays, simParams.simulation.stopTime);

tic;
simOut = sim(modelName, 'StopTime', num2str(simParams.simulation.stopTime));
elapsedTime30 = toc;

fprintf('Simulation completed in %.2f seconds.\n', elapsedTime30);

% Save results
saveFile30 = fullfile(resultsDir, 'results_30day.mat');
save(saveFile30, 'simOut', 'simParams');
fprintf('Artifact saved: %s\n', saveFile30);


%% ============================================================
% 3. SCENARIO 2: 330-DAY DISTRICT SCALE-UP RUN (AI-ASSISTED)
% =============================================================

fprintf('\n------------------------------------------------------\n');
fprintf('[2/3] EXECUTING 330-DAY SCALE-UP RUN (AI MODE - 100K PTS)\n');
fprintf('------------------------------------------------------\n');

% Load baseline parameters
run(fullfile(rootDir, 'parameters', 'simulation_parameters_day2.m'));

% Configure for full district scale (330 days)
simParams.simulation.runDays = 330;
simParams.simulation.stopTime = simParams.simulation.runDays * 24 * 60 * 60;
simParams.experiment.reviewMode = "AI";

% Re-evaluate parameter dependencies
run(fullfile(rootDir, 'parameters', 'simulation_parameters_day2.m'));

% Apply stop time to model
set_param(modelName, 'StopTime', num2str(simParams.simulation.stopTime));

fprintf('Running simulation for %d days (%d seconds)...\n', ...
    simParams.simulation.runDays, simParams.simulation.stopTime);

tic;
simOut = sim(modelName, 'StopTime', num2str(simParams.simulation.stopTime));
elapsedTime330 = toc;

fprintf('Simulation completed in %.2f seconds.\n', elapsedTime330);

% Save results
saveFile365 = fullfile(resultsDir, 'results_365day.mat');
save(saveFile365, 'simOut', 'simParams');
fprintf('Artifact saved: %s\n', saveFile365);


%% ============================================================
% 4. SCENARIO 3: 330-DAY MANUAL BASELINE COMPARISON
% =============================================================

fprintf('\n------------------------------------------------------\n');
fprintf('[3/3] EXECUTING 330-DAY MANUAL BASELINE RUN (NO AI)\n');
fprintf('------------------------------------------------------\n');

% Load baseline parameters
run(fullfile(rootDir, 'parameters', 'simulation_parameters_day2.m'));

% Configure for manual review mode
simParams.simulation.runDays = 330;
simParams.simulation.stopTime = simParams.simulation.runDays * 24 * 60 * 60;
simParams.experiment.reviewMode = "MANUAL";

% Re-evaluate parameter dependencies
run(fullfile(rootDir, 'parameters', 'simulation_parameters_day2.m'));

% Apply stop time to model
set_param(modelName, 'StopTime', num2str(simParams.simulation.stopTime));

fprintf('Running simulation for %d days (%d seconds)...\n', ...
    simParams.simulation.runDays, simParams.simulation.stopTime);

tic;
simOut_manual = sim(modelName, 'StopTime', num2str(simParams.simulation.stopTime));
elapsedTimeManual = toc;

fprintf('Simulation completed in %.2f seconds.\n', elapsedTimeManual);

% Save manual baseline results
saveFileManual = fullfile(resultsDir, 'day2_experiment_results.mat');
save(saveFileManual, 'simOut_manual', 'simParams');
fprintf('Artifact saved: %s\n', saveFileManual);


%% ============================================================
% 5. COMPLETION & VERIFICATION
% =============================================================

fprintf('\n======================================================\n');
fprintf('  ALL DIGITAL TWIN SIMULATION RUNS COMPLETED          \n');
fprintf('======================================================\n');
fprintf('1. 30-Day AI Run:       results/results_30day.mat\n');
fprintf('2. 330-Day AI Scale:    results/results_365day.mat\n');
fprintf('3. 330-Day Manual Run:  results/day2_experiment_results.mat\n');
fprintf('Run analyze_results.m next to print full telemetry.\n');
fprintf('======================================================\n\n');