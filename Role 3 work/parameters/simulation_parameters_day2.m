%% simulation_parameters_day2.m
%
% Role 3 - Day 2 District-Scale Digital Twin
%
% Centralized simulation configuration
% SIH 2026 - PS 38 / Explainable AI for DR Screening in Rural India
%

clear simParams;

%% ============================================================
% SIMULATION SETTINGS
% =============================================================

simParams.simulation.runDays = 330;

simParams.simulation.stopTime = ...
    simParams.simulation.runDays * 24 * 60 * 60;


%% ============================================================
% DISTRICT SCALE
% =============================================================

simParams.district.patients_per_year = 100000;


%% ============================================================
% ARRIVAL RATE
% =============================================================

% Average number of patients arriving per day
simParams.arrival.patients_per_day = ...
    simParams.district.patients_per_year / 365;

% Assuming 8 operational hours per day
simParams.arrival.operational_hours_per_day = 8;

% Average patients arriving per operational hour
simParams.arrival.patients_per_hour = ...
    simParams.arrival.patients_per_day / ...
    simParams.arrival.operational_hours_per_day;

% Average arrival rate in patients/second
simParams.arrival.ratePerSecond = ...
    simParams.arrival.patients_per_hour / 3600;


%% ============================================================
% IMAGE QUALITY ASSESSMENT (IQA)
% ============================================================

% TEMPORARY TEST PARAMETER -> UPDATED TO RURAL BENCHMARK BASELINE
% Literature baseline for ungradable fundus rate in rural tele-ophthalmology (10-15%)
% Prevents ungradable images from triggering spurious CNN inference.
simParams.iqa.failRate = 0.136792;

% Maximum number of additional capture attempts
simParams.iqa.max_retries = 2;


%% ============================================================
% AI PROCESSING
% =============================================================

% Measured value from Role 1 pipeline execution (ResNet-50 forward pass + Grad-CAM)
simParams.ai.processingTime = 1.45;       % seconds

% Routing distributions measured from Role 1's 439 held-out test evaluations:
% Total cases: 439 | Grade >= 2: 191 (43.51%) | Low Confidence (<0.65): 21 (4.78%)
simParams.ai.referable_dr_rate = 0.435080; % dr_severity >= 2 (Level 2+)
simParams.ai.low_conf_rate     = 0.047836; % dr_severity < 2 & confidence < 0.65
simParams.ai.total_review_rate = 0.482916; % Probability entity requires Human Review


%% ============================================================
% HUMAN REVIEW
% =============================================================

% AI-assisted human review time.
% Reviewer evaluates pre-extracted morphological candidates and Grad-CAM overlay.
simParams.review.processingTime = 30;  % seconds

% Manual review duration.
%
% This is a simulation assumption within the specified
% 3-5 minute manual-review range.
%
% 240 seconds = 4 minutes.

simParams.review.manualProcessingTime = 240;  % seconds

% Number of parallel human reviewers
simParams.review.reviewerCount = 2;


%% ============================================================
% NETWORK / BANDWIDTH
% =============================================================

simParams.network.enabled = true;

% Edge-to-district telemedicine backhaul latency.
simParams.network.delay = 1.8;           % seconds

% Probability of network transmission failure / packet drop under rural connectivity
simParams.network.dropout_probability = 0.05;


%% ============================================================
% EXPERIMENT CONFIGURATION
% =============================================================

% Review mode:
%
% "AI"     = AI-assisted review
% "MANUAL" = Manual review

if ~isfield(simParams, 'experiment') || ~isfield(simParams.experiment, 'reviewMode')
    simParams.experiment.reviewMode = "AI";
end

% Network dropout:
%
% false = normal network
% true  = network dropout enabled

simParams.experiment.dropoutEnabled = true;


%% ============================================================
% DERIVED EXPERIMENT FLAGS
% =============================================================

% Logical flag used by SimEvents Event Actions.
%
% 0 = AI-assisted mode
% 1 = Manual-review mode

simParams.experiment.manualReviewEnabled = ...
    strcmpi(simParams.experiment.reviewMode, "MANUAL");


%% ============================================================
% DISPLAY CONFIGURATION
% =============================================================

disp('======================================');
disp('ROLE 3 DIGITAL TWIN - DAY 2');
disp('======================================');

fprintf('Simulation run: %d days\n', ...
    simParams.simulation.runDays);

fprintf('Simulation stop time: %d seconds\n', ...
    simParams.simulation.stopTime);

fprintf('\n');

fprintf('Patients/year: %d\n', ...
    simParams.district.patients_per_year);

fprintf('Patients/day: %.2f\n', ...
    simParams.arrival.patients_per_day);

fprintf('Operational hours/day: %.2f\n', ...
    simParams.arrival.operational_hours_per_day);

fprintf('Patients/hour: %.2f\n', ...
    simParams.arrival.patients_per_hour);

fprintf('Arrival rate: %.6f entities/s\n', ...
    simParams.arrival.ratePerSecond);

fprintf('\n');

fprintf('IQA failure rate (rural benchmark): %.2f\n', ...
    simParams.iqa.failRate);

fprintf('Maximum IQA retries: %d\n', ...
    simParams.iqa.max_retries);

fprintf('AI processing time: %.2f s\n', ...
    simParams.ai.processingTime);

fprintf('Referable DR rate (Grade >= 2): %.2f%%\n', ...
    simParams.ai.referable_dr_rate * 100);

fprintf('Total Human Review trigger rate: %.2f%%\n', ...
    simParams.ai.total_review_rate * 100);

fprintf('AI-assisted review time: %.2f s\n', ...
    simParams.review.processingTime);

fprintf('Manual review time: %.2f s\n', ...
    simParams.review.manualProcessingTime);

fprintf('Number of reviewers: %d\n', ...
    simParams.review.reviewerCount);

fprintf('\n');

fprintf('Review mode: %s\n', ...
    simParams.experiment.reviewMode);

fprintf('Manual review enabled: %d\n', ...
    simParams.experiment.manualReviewEnabled);

fprintf('Network enabled: %d\n', ...
    simParams.network.enabled);

fprintf('Network delay: %.2f s\n', ...
    simParams.network.delay);

fprintf('Network dropout probability: %.2f\n', ...
    simParams.network.dropout_probability);

fprintf('Network dropout enabled: %d\n', ...
    simParams.experiment.dropoutEnabled);


%% ============================================================
% VERIFICATION
% =============================================================

disp('======================================');
disp('SIMULATION TIME VERIFICATION');
disp('======================================');

disp('simParams.simulation.runDays =');
disp(simParams.simulation.runDays);

disp('simParams.simulation.stopTime =');
disp(simParams.simulation.stopTime);


%% ============================================================
% SIMEVENTS EVENT-ACTION PARAMETERS
% ============================================================

arrivalRate = simParams.arrival.ratePerSecond;

iqaFailRate = simParams.iqa.failRate;

maxRetries = simParams.iqa.max_retries;

aiProcessingTime = simParams.ai.processingTime;

reviewerCount = simParams.review.reviewerCount;

networkDelay = simParams.network.delay;

networkDropoutEnabled = ...
    simParams.experiment.dropoutEnabled;

networkDropoutProbability = ...
    simParams.network.dropout_probability;

manualReviewEnabled = ...
    simParams.experiment.manualReviewEnabled;

if manualReviewEnabled

    reviewProcessingTime = ...
        simParams.review.manualProcessingTime;

else

    reviewProcessingTime = ...
        simParams.review.processingTime;

end