%% run_test.m
% Role 3 - Day 1 topology test

clear;
clc;

%% Load parameters
run('../parameters/simulation_parameters.m');

%% Display test configuration

disp('======================================');
disp('ROLE 3 DIGITAL TWIN - DAY 1 TEST');
disp('======================================');

fprintf('Simulation time: %.2f s\n', simulation_time);
fprintf('Arrival rate: %.4f entities/s\n', arrival_rate);
fprintf('Maximum retries: %d\n', max_retries);
fprintf('Test IQA status: %d\n', test_iqa_status);
fprintf('Test DR severity: %d\n', test_dr_severity);
fprintf('Test confidence: %d\n', test_confidence_level);
fprintf('AI processing time: %.2f s\n', ai_processing_time);
fprintf('Review time: %.2f s\n', review_processing_time);
fprintf('Reviewer count: %d\n', reviewer_count);

%% Open model
model_path = fullfile('..', 'model', 'DR_DigitalTwin.slx');
open_system(model_path);

%% Run simulation
set_param('DR_DigitalTwin', ...
    'StopTime', num2str(simulation_time));

sim('DR_DigitalTwin');

disp('Simulation completed.');