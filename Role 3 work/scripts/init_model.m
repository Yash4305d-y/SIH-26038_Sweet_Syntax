%% init_model.m
%
% Role 3 - Environment and Workspace Initialization
% SIH 2026 - PS 38 / Explainable AI for DR Screening in Rural India
%

clear;
clc;

fprintf('======================================================\n');
fprintf('  INITIALIZING DR DIGITAL TWIN SIMULATION ENVIRONMENT  \n');
fprintf('======================================================\n');

% Set up project directory paths
currentDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(currentDir);

addpath(fullfile(rootDir, 'parameters'));
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'scripts'));
addpath(fullfile(rootDir, 'results'));
addpath(fullfile(rootDir, 'documentation'));

fprintf('Added project directories to MATLAB path.\n');

% Load Day 2 parameter set
paramScript = fullfile(rootDir, 'parameters', 'simulation_parameters_day2.m');
if exist(paramScript, 'file')
    run(paramScript);
    fprintf('Loaded simulation_parameters_day2.m into base workspace.\n');
else
    warning('Parameter script not found at: %s', paramScript);
end

% Reset queue wait statistics helper
if exist('queueWaitStats', 'file')
    queueWaitStats(0, true);
    fprintf('Queue statistics tracker reset.\n');
end

% Pre-load the Simulink model into memory
modelName = 'DR_DigitalTwin_Day2';
modelPath = fullfile(rootDir, 'model', [modelName, '.slx']);
if exist(modelPath, 'file')
    if ~bdIsLoaded(modelName)
        load_system(modelPath);
        fprintf('Loaded model into memory: %s.slx\n', modelName);
    end
else
    warning('Simulink model not found at: %s', modelPath);
end

fprintf('Initialization complete. Ready for simulation execution.\n');
fprintf('======================================================\n\n');