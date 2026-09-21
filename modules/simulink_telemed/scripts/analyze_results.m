%% analyze_results.m
%
% Role 3 - Discrete-Event Telemetry Extraction & Level-4 Analysis
% SIH 2026 - PS 38 / Explainable AI for DR Screening in Rural India
%
% This script extracts Level-4 operational metrics from the simulation results:
% 1. Triage volume & Image Quality Gate filter rate
% 2. Ophthalmologist review demand (AI-Assisted vs. Manual Workflow)
% 3. Specialist workload reduction and hours saved per district
% 4. Specialist queue utilization & backlog stability
%

clear;
clc;

fprintf('======================================================\n');
fprintf('  ROLE 3: DIGITAL TWIN OPERATIONAL TELEMETRY REPORT   \n');
fprintf('======================================================\n');

%% ============================================================
% 1. LOAD SIMULATION ARTIFACTS
% =============================================================

currentDir = fileparts(mfilename('fullpath'));
rootDir = fileparts(currentDir);
resultsDir = fullfile(rootDir, 'results');

targetFile = fullfile(resultsDir, 'results_365day.mat');
file30 = fullfile(resultsDir, 'results_30day.mat');
fileManual = fullfile(resultsDir, 'day2_experiment_results.mat');

if exist(targetFile, 'file')
    fprintf('Loading primary district results (330-DAY AI): %s\n', targetFile);
    data330 = load(targetFile);
    simParams_330day = data330.simParams_330day;
    primarySimOut = data330.simOut;
else
    error('Primary result file %s not found. Run scripts/run_simulation.m first.', targetFile);
end

data30 = struct();
if exist(file30, 'file')
    fprintf('Loading verification results (30-DAY AI): %s\n', file30);
    data30 = load(file30);
end

dataManual = struct();
if exist(fileManual, 'file')
    fprintf('Loading baseline results (330-DAY MANUAL): %s\n', fileManual);
    dataManual = load(fileManual);
end

%% ============================================================
% 2. CONFIGURATION SUMMARY (330-DAY AI)
% =============================================================

fprintf('\n--- CONFIGURATION BEING ANALYZED (330-DAY AI) ---\n');
fprintf('runDays:                     %d\n', simParams_330day.simulation.runDays);
fprintf('reviewMode:                  %s\n', simParams_330day.experiment.reviewMode);
fprintf('manualReviewEnabled:         %d\n', simParams_330day.experiment.manualReviewEnabled);
fprintf('patients/year:               %d\n', simParams_330day.district.patients_per_year);
fprintf('arrival rate:                %.6f\n', simParams_330day.arrival.ratePerSecond);
fprintf('IQA failure rate:            %.4f\n', simParams_330day.iqa.failRate);
fprintf('maximum retries:             %d\n', simParams_330day.iqa.max_retries);
fprintf('AI processing time:          %.2f s\n', simParams_330day.ai.processingTime);
fprintf('review processing time:      %.2f s\n', simParams_330day.review.processingTime);
fprintf('reviewer count:              %d\n', simParams_330day.review.reviewerCount);
fprintf('network delay:               %.2f s\n', simParams_330day.network.delay);
fprintf('network dropout enabled:     %d\n', simParams_330day.experiment.dropoutEnabled);

%% ============================================================
% 3. SCREENING VOLUME & TRIAGE DISTRIBUTION
% =============================================================

runDays = simParams_330day.simulation.runDays;
totalDistrictPopulation = simParams_330day.district.patients_per_year;

if isfield(simParams_330day.arrival, 'operational_days_per_year')
    operationalDaysYear = simParams_330day.arrival.operational_days_per_year;
else
    operationalDaysYear = 365;
end

totalScreened = totalDistrictPopulation * (runDays / operationalDaysYear);
iqaFailRate = simParams_330day.iqa.failRate;
iqaFailedTotal = totalScreened * iqaFailRate;
passingImages = totalScreened - iqaFailedTotal;

if isfield(simParams_330day.ai, 'total_review_rate')
    reviewRouteRate = simParams_330day.ai.total_review_rate;
    referableRate   = simParams_330day.ai.referable_dr_rate;
    lowConfRate     = simParams_330day.ai.low_conf_rate;
else
    referableRate   = 0.435080;
    lowConfRate     = 0.047836;
    reviewRouteRate = 0.482916;
end

casesToReview = passingImages * reviewRouteRate;
normalReportCases = passingImages * (1 - reviewRouteRate);

fprintf('\n--- 1. SCREENING & TRIAGE VOLUMETRICS ---\n');
fprintf('Scenario:                     330-DAY AI\n');
fprintf('Operational Horizon:          %d days\n', runDays);
fprintf('Total Patients Screened:      %d\n', round(totalScreened));
fprintf('IQA Gate Interventions:       %d (%.1f%% caught at edge)\n', ...
    round(iqaFailedTotal), iqaFailRate * 100);
fprintf('Clean Images Passed to CNN:   %d (%.1f%%)\n', ...
    round(passingImages), (1 - iqaFailRate) * 100);
fprintf('  - Direct Structured Report: %d (%.1f%% of clean images)\n', ...
    round(normalReportCases), (1 - reviewRouteRate) * 100);
fprintf('  - Referred to Specialist:   %d (%.1f%% of clean images)\n', ...
    round(casesToReview), reviewRouteRate * 100);
fprintf('      * Referable DR (>= 2):  %d cases (%.1f%%)\n', ...
    round(passingImages * referableRate), referableRate * 100);
fprintf('      * Low Confidence Amb.:  %d cases (%.1f%%)\n', ...
    round(passingImages * lowConfRate), lowConfRate * 100);

%% ============================================================
% 4. CLINICAL WORKLOAD & SPECIALIST TIME ANALYSIS
% =============================================================

manualReviewTimeSec = simParams_330day.review.manualProcessingTime; 
aiReviewTimeSec     = simParams_330day.review.processingTime;       

totalManualSeconds = casesToReview * manualReviewTimeSec;
totalAiSeconds     = casesToReview * aiReviewTimeSec;

totalManualHours = totalManualSeconds / 3600;
totalAiHours     = totalAiSeconds / 3600;
hoursSaved       = totalManualHours - totalAiHours;
percentReduction = (hoursSaved / totalManualHours) * 100;

fprintf('\n--- 2. SPECIALIST WORKLOAD REDUCTION ---\n');
fprintf('Unassisted Manual Workload:   %.1f specialist-hours\n', totalManualHours);
fprintf('AI-Assisted Workload:         %.1f specialist-hours\n', totalAiHours);
fprintf('Total Specialist Time Saved:  %.1f hours\n', hoursSaved);
fprintf('Efficiency Gain:              %.1f%% reduction in review time\n', percentReduction);


%% ============================================================
% 5. DISTRICT QUEUE CAPACITY & UTILIZATION
% =============================================================

operationalHoursPerDay = simParams_330day.arrival.operational_hours_per_day; 
reviewerCount = simParams_330day.review.reviewerCount;                         

dailyReviewArrivals = casesToReview / runDays;
maxDailyAiCapacity = (operationalHoursPerDay * 3600 * reviewerCount) / aiReviewTimeSec;
maxDailyManualCapacity = (operationalHoursPerDay * 3600 * reviewerCount) / manualReviewTimeSec;

aiUtilizationRate = (dailyReviewArrivals * aiReviewTimeSec) / ...
    (operationalHoursPerDay * 3600 * reviewerCount);

manualUtilizationRate = (dailyReviewArrivals * manualReviewTimeSec) / ...
    (operationalHoursPerDay * 3600 * reviewerCount);

fprintf('\n--- 3. DISTRICT QUEUE & SERVICE CAPACITY ---\n');
fprintf('Daily Review Arrivals:        %.1f cases/day\n', dailyReviewArrivals);
fprintf('District Reviewers:           %d tele-ophthalmologists\n', reviewerCount);
fprintf('Daily Reviewer Capacity (AI): %.1f cases/day\n', maxDailyAiCapacity);
fprintf('Specialist Utilization (AI):  %.2f%%\n', aiUtilizationRate * 100);
fprintf('Specialist Util. (Manual):    %.2f%%\n', manualUtilizationRate * 100);

%% ============================================================
% 6. QUEUE HEALTH: DIRECT TELEMETRY EXTRACTION
% =============================================================

fprintf('\n--- 3A. SAVED QUEUE TELEMETRY ---\n');
fprintf('Queue Health: Based on recorded simulation telemetry\n');

maxBacklog = NaN;
maxQueueLen = NaN;
avgQueueWait = NaN;
maxQueueWait = NaN;
maxUtil = NaN;
meanUtil = NaN;

if isa(primarySimOut, 'Simulink.SimulationOutput')
    
    dataBacklog = getSimulinkData(primarySimOut, 'backlog');
    if ~isempty(dataBacklog)
        maxBacklog = max(dataBacklog);
        if maxBacklog < 0, fprintf('WARNING: backlog is negative (%g)\n', maxBacklog); end
    end
    
    dataQlen = getSimulinkData(primarySimOut, 'reviewQueueLength');
    if ~isempty(dataQlen)
        maxQueueLen = max(dataQlen);
        if maxQueueLen < 0, fprintf('WARNING: reviewQueueLength is negative (%g)\n', maxQueueLen); end
    end
    
    dataQwait = getSimulinkData(primarySimOut, 'reviewQueueAverageWait');
    if ~isempty(dataQwait)
        avgQueueWait = mean(dataQwait);
        maxQueueWait = max(dataQwait);
        if maxQueueWait < 0 || avgQueueWait < 0
            fprintf('WARNING: reviewQueueAverageWait contains negative values\n');
        end
    end
    
    dataUtil = getSimulinkData(primarySimOut, 'reviewerUtilization');
    if ~isempty(dataUtil)
        maxUtil = max(dataUtil);
        meanUtil = mean(dataUtil);
        if maxUtil < 0
            fprintf('WARNING: reviewerUtilization violates expected non-negative range\n');
        end
    end
    
    % Additional specified signals (optional to print, but required to extract)
    dataRevEnt = getSimulinkData(primarySimOut, 'reviewEntities');
    dataCnnDep = getSimulinkData(primarySimOut, 'cnnDepartures');
    dataCnnIn = getSimulinkData(primarySimOut, 'cnnInBlock');
    dataIqaDep = getSimulinkData(primarySimOut, 'iqaDepartures');
    dataNetDep = getSimulinkData(primarySimOut, 'networkDepartures');
    
    if ~isempty(dataRevEnt), fprintf('Max reviewEntities:           %d\n', round(max(dataRevEnt))); end
    if ~isempty(dataCnnDep), fprintf('Max cnnDepartures:            %d\n', round(max(dataCnnDep))); end
    if ~isempty(dataCnnIn),  fprintf('Max cnnInBlock:               %d\n', round(max(dataCnnIn))); end
    if ~isempty(dataIqaDep), fprintf('Max iqaDepartures:            %d\n', round(max(dataIqaDep))); end
    if ~isempty(dataNetDep), fprintf('Max networkDepartures:        %d\n', round(max(dataNetDep))); end
end

if ~isnan(maxBacklog)
    fprintf('Maximum District Backlog:     %d\n', round(maxBacklog));
else
    fprintf('Maximum District Backlog:     NOT AVAILABLE IN SAVED TELEMETRY\n');
end

if ~isnan(maxQueueLen)
    fprintf('Maximum Review Queue Length:  %d\n', round(maxQueueLen));
else
    fprintf('Maximum Review Queue Length:  NOT AVAILABLE IN SAVED TELEMETRY\n');
end

if ~isnan(avgQueueWait)
    fprintf('Average Review Queue Wait:    %.2f s\n', avgQueueWait);
    fprintf('Maximum Review Queue Wait:    %.2f s\n', maxQueueWait);
else
    fprintf('Review Queue Wait:            NOT AVAILABLE IN SAVED TELEMETRY\n');
end

if ~isnan(maxUtil)
    fprintf('Reviewer Utilization (Mean):  %.4f\n', meanUtil);
    fprintf('Reviewer Utilization (Max):   %.4f\n', maxUtil);
else
    fprintf('Reviewer Utilization:         NOT AVAILABLE IN SAVED TELEMETRY\n');
end


%% ============================================================
% 7. COMPARATIVE SUMMARY TABLE FOR JUDGES
% =============================================================

manualBacklogStr = 'NOT AVAILABLE IN SAVED TELEMETRY';
manualQueueLenStr = 'NOT AVAILABLE IN SAVED TELEMETRY';

if isfield(dataManual, 'simOut_manual')
    sm = dataManual.simOut_manual;
    if isa(sm, 'Simulink.SimulationOutput')
        mDataBacklog = getSimulinkData(sm, 'backlog');
        if ~isempty(mDataBacklog)
            manualBacklogStr = sprintf('%d', round(max(mDataBacklog)));
        end
        
        mDataQlen = getSimulinkData(sm, 'reviewQueueLength');
        if ~isempty(mDataQlen)
            manualQueueLenStr = sprintf('%d', round(max(mDataQlen)));
        end
    end
end

aiBacklogStr = 'NOT AVAILABLE IN SAVED TELEMETRY';
if ~isnan(maxBacklog)
    aiBacklogStr = sprintf('%d', round(maxBacklog));
end

aiQueueLenStr = 'NOT AVAILABLE IN SAVED TELEMETRY';
if ~isnan(maxQueueLen)
    aiQueueLenStr = sprintf('%d', round(maxQueueLen));
end

fprintf('\n=================================================================================\n');
fprintf('                SUMMARY TABLE: 330-DAY MANUAL VS. 330-DAY AI                   \n');
fprintf('=================================================================================\n');
fprintf('%-30s | %-32s | %-32s\n', 'Metric', '330-DAY MANUAL', '330-DAY AI');
fprintf('---------------------------------------------------------------------------------\n');
fprintf('%-30s | %-32s | %-32s\n', 'Specialist Time / Case', ...
    sprintf('%d s', manualReviewTimeSec), sprintf('%d s', aiReviewTimeSec));
fprintf('%-30s | %-32s | %-32s\n', 'District Workload (330 d)', ...
    sprintf('%.1f hrs', totalManualHours), sprintf('%.1f hrs', totalAiHours));
fprintf('%-30s | %-32s | %-32s\n', 'Annual Time Saved', ...
    'Baseline', sprintf('%.1f hrs', hoursSaved));
fprintf('%-30s | %-32s | %-32s\n', 'Reviewer Utilization', ...
    sprintf('%.2f%%', manualUtilizationRate * 100), sprintf('%.2f%%', aiUtilizationRate * 100));
fprintf('%-30s | %-32s | %-32s\n', 'Max District Backlog', ...
    manualBacklogStr, aiBacklogStr);
fprintf('%-30s | %-32s | %-32s\n', 'Max Review Queue Length', ...
    manualQueueLenStr, aiQueueLenStr);
fprintf('=================================================================================\n\n');


%% ============================================================
% HELPER FUNCTIONS
% =============================================================

function data = getSimulinkData(simOutObj, sigName)
    data = [];
    if ismember(sigName, simOutObj.who)
        ts = simOutObj.get(sigName);
        if ~isempty(ts)
            if isprop(ts, 'Data')
                raw = ts.Data;
                data = raw(~isnan(raw));
            elseif isnumeric(ts)
                data = ts(~isnan(ts));
            end
        end
    end
end