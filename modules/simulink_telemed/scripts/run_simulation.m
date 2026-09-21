%% run_simulation.m
%
% Role 3 - District-Scale Digital Twin Simulation Runner
% SIH 2026 - PS 38 / Explainable AI for DR Screening in Rural India
%
% Scenarios:
% 1. 30-Day verification run (AI-assisted)
% 2. 330-Day district-scale run (AI-assisted, 100,000 patients/year)
% 3. 330-Day manual baseline comparison
%
% Important:
% simulation_parameters_day2.m initializes the complete parameter
% structure and clears the previous simParams. Therefore each scenario
% loads the parameter script once and then applies its scenario-specific
% overrides WITHOUT re-running the parameter script afterward.

clear;
clc;

fprintf('======================================================\n');
fprintf('  ROLE 3: RUNNING DISTRICT-SCALE DIGITAL TWIN MODELS  \n');
fprintf('======================================================\n');

%% ============================================================
% 1. ENVIRONMENT & PATH SETUP
% =============================================================

currentDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(currentDir);

addpath(fullfile(rootDir, 'parameters'));
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'results'));

resultsDir = fullfile(rootDir, 'results');

if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

modelName = 'DR_DigitalTwin_Day2';

if ~bdIsLoaded(modelName)
    fprintf('Loading Simulink model: %s.slx...\n', modelName);
    load_system(modelName);
else
    fprintf('Simulink model %s is already loaded in memory.\n', modelName);
end

parameterFile = fullfile( ...
    rootDir, 'parameters', 'simulation_parameters_day2.m');

%% ============================================================
% Helper: apply scenario overrides without rerunning parameter file
% =============================================================

% The parameter script creates these derived variables:
% arrivalRate
% iqaFailRate
% maxRetries
% aiProcessingTime
% reviewerCount
% networkDelay
% networkDropoutEnabled
% manualReviewEnabled
% reviewProcessingTime
%
% After changing runDays/reviewMode, these must be refreshed manually.

%% ============================================================
% 2. SCENARIO 1: 30-DAY OPERATIONAL TEST (AI-ASSISTED)
% =============================================================

fprintf('\n------------------------------------------------------\n');
fprintf('[1/3] EXECUTING 30-DAY VERIFICATION RUN (AI MODE)\n');
fprintf('------------------------------------------------------\n');

run(parameterFile);

% Scenario-specific overrides
simParams.simulation.runDays = 30;
simParams.simulation.stopTime = ...
    simParams.simulation.runDays * 24 * 60 * 60;

simParams.experiment.reviewMode = "AI";
simParams.experiment.manualReviewEnabled = false;

% Recompute derived variables
arrivalRate = simParams.arrival.ratePerSecond;
iqaFailRate = simParams.iqa.failRate;
maxRetries = simParams.iqa.max_retries;
aiProcessingTime = simParams.ai.processingTime;
reviewerCount = simParams.review.reviewerCount;
networkDelay = simParams.network.delay;
networkDropoutEnabled = simParams.experiment.dropoutEnabled;
networkDropoutProbability = simParams.network.dropout_probability;
manualReviewEnabled = false;
reviewProcessingTime = simParams.review.processingTime;

% Push required variables into base workspace because Simulink
% MATLAB actions reference them directly.
assignin('base','simParams',simParams);
assignin('base','arrivalRate',arrivalRate);
assignin('base','iqaFailRate',iqaFailRate);
assignin('base','maxRetries',maxRetries);
assignin('base','aiProcessingTime',aiProcessingTime);
assignin('base','reviewerCount',reviewerCount);
assignin('base','networkDelay',networkDelay);
assignin('base','networkDropoutEnabled',networkDropoutEnabled);
assignin('base','networkDropoutProbability',networkDropoutProbability);
assignin('base','manualReviewEnabled',manualReviewEnabled);
assignin('base','reviewProcessingTime',reviewProcessingTime);

set_param(modelName, ...
    'StopTime', num2str(simParams.simulation.stopTime));

fprintf('Run days: %d\n', simParams.simulation.runDays);
fprintf('Review mode: %s\n', simParams.experiment.reviewMode);
fprintf('Review time: %.2f s\n', reviewProcessingTime);
fprintf('Stop time: %d s\n', simParams.simulation.stopTime);

tic;
simOut = sim(modelName, ...
    'StopTime', num2str(simParams.simulation.stopTime));
elapsedTime30 = toc;

fprintf('Simulation completed in %.2f seconds.\n', elapsedTime30);

saveFile30 = fullfile(resultsDir, 'results_30day.mat');

simParams_30day = simParams;
save(saveFile30, ...
    'simOut', ...
    'simParams_30day', ...
    'elapsedTime30');

fprintf('Artifact saved: %s\n', saveFile30);

%% ============================================================
% 3. SCENARIO 2: 330-DAY DISTRICT SCALE-UP (AI-ASSISTED)
% =============================================================

fprintf('\n------------------------------------------------------\n');
fprintf('[2/3] EXECUTING 330-DAY SCALE-UP RUN (AI MODE - 100K PTS)\n');
fprintf('------------------------------------------------------\n');

run(parameterFile);

% Scenario-specific overrides
simParams.simulation.runDays = 330;
simParams.simulation.stopTime = ...
    simParams.simulation.runDays * 24 * 60 * 60;

simParams.experiment.reviewMode = "AI";
simParams.experiment.manualReviewEnabled = false;

% Recompute derived variables
arrivalRate = simParams.arrival.ratePerSecond;
iqaFailRate = simParams.iqa.failRate;
maxRetries = simParams.iqa.max_retries;
aiProcessingTime = simParams.ai.processingTime;
reviewerCount = simParams.review.reviewerCount;
networkDelay = simParams.network.delay;
networkDropoutEnabled = simParams.experiment.dropoutEnabled;
networkDropoutProbability = simParams.network.dropout_probability;
manualReviewEnabled = false;
reviewProcessingTime = simParams.review.processingTime;

assignin('base','simParams',simParams);
assignin('base','arrivalRate',arrivalRate);
assignin('base','iqaFailRate',iqaFailRate);
assignin('base','maxRetries',maxRetries);
assignin('base','aiProcessingTime',aiProcessingTime);
assignin('base','reviewerCount',reviewerCount);
assignin('base','networkDelay',networkDelay);
assignin('base','networkDropoutEnabled',networkDropoutEnabled);
assignin('base','networkDropoutProbability',networkDropoutProbability);
assignin('base','manualReviewEnabled',manualReviewEnabled);
assignin('base','reviewProcessingTime',reviewProcessingTime);

set_param(modelName, ...
    'StopTime', num2str(simParams.simulation.stopTime));

fprintf('Run days: %d\n', simParams.simulation.runDays);
fprintf('Review mode: %s\n', simParams.experiment.reviewMode);
fprintf('Review time: %.2f s\n', reviewProcessingTime);
fprintf('Stop time: %d s\n', simParams.simulation.stopTime);

tic;
simOut = sim(modelName, ...
    'StopTime', num2str(simParams.simulation.stopTime));
elapsedTime330 = toc;

fprintf('Simulation completed in %.2f seconds.\n', elapsedTime330);

saveFile330 = fullfile(resultsDir, 'results_365day.mat');

simParams_330day = simParams;
save(saveFile330, ...
    'simOut', ...
    'simParams_330day', ...
    'elapsedTime330');

fprintf('Artifact saved: %s\n', saveFile330);

%% ============================================================
% 4. SCENARIO 3: 330-DAY MANUAL BASELINE
% =============================================================

fprintf('\n------------------------------------------------------\n');
fprintf('[3/3] EXECUTING 330-DAY MANUAL BASELINE RUN (NO AI)\n');
fprintf('------------------------------------------------------\n');

run(parameterFile);

% Scenario-specific overrides
simParams.simulation.runDays = 330;
simParams.simulation.stopTime = ...
    simParams.simulation.runDays * 24 * 60 * 60;

simParams.experiment.reviewMode = "MANUAL";
simParams.experiment.manualReviewEnabled = true;

% Recompute derived variables
arrivalRate = simParams.arrival.ratePerSecond;
iqaFailRate = simParams.iqa.failRate;
maxRetries = simParams.iqa.max_retries;
aiProcessingTime = simParams.ai.processingTime;
reviewerCount = simParams.review.reviewerCount;
networkDelay = simParams.network.delay;
networkDropoutEnabled = simParams.experiment.dropoutEnabled;
networkDropoutProbability = simParams.network.dropout_probability;
manualReviewEnabled = true;
reviewProcessingTime = simParams.review.manualProcessingTime;

assignin('base','simParams',simParams);
assignin('base','arrivalRate',arrivalRate);
assignin('base','iqaFailRate',iqaFailRate);
assignin('base','maxRetries',maxRetries);
assignin('base','aiProcessingTime',aiProcessingTime);
assignin('base','reviewerCount',reviewerCount);
assignin('base','networkDelay',networkDelay);
assignin('base','networkDropoutEnabled',networkDropoutEnabled);
assignin('base','networkDropoutProbability',networkDropoutProbability);
assignin('base','manualReviewEnabled',manualReviewEnabled);
assignin('base','reviewProcessingTime',reviewProcessingTime);

set_param(modelName, ...
    'StopTime', num2str(simParams.simulation.stopTime));

fprintf('Run days: %d\n', simParams.simulation.runDays);
fprintf('Review mode: %s\n', simParams.experiment.reviewMode);
fprintf('Review time: %.2f s\n', reviewProcessingTime);
fprintf('Stop time: %d s\n', simParams.simulation.stopTime);

tic;
simOut_manual = sim(modelName, ...
    'StopTime', num2str(simParams.simulation.stopTime));
elapsedTimeManual = toc;

fprintf('Simulation completed in %.2f seconds.\n', elapsedTimeManual);

saveFileManual = fullfile(resultsDir, ...
    'day2_experiment_results.mat');

simParams_manual = simParams;
save(saveFileManual, ...
    'simOut_manual', ...
    'simParams_manual', ...
    'elapsedTimeManual');

fprintf('Artifact saved: %s\n', saveFileManual);

%% ============================================================
% 5. COMPLETION
% =============================================================

fprintf('\n======================================================\n');
fprintf('  ALL DIGITAL TWIN SIMULATION RUNS COMPLETED\n');
fprintf('======================================================\n');
fprintf('1. 30-Day AI Run:       results/results_30day.mat\n');
fprintf('2. 330-Day AI Scale:    results/results_365day.mat\n');
fprintf('3. 330-Day Manual Run:  results/day2_experiment_results.mat\n');
fprintf('Run analyze_results.m next to inspect telemetry.\n');
fprintf('======================================================\n\n');