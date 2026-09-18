function [meanWait, maxWait, totalEntities] = queueWaitStats(waitTime, resetFlag)
% QUEUEWAITSTATS Persistent accumulator for SimEvents entity queue wait times
%
% Syntax:
%   [meanWait, maxWait, totalEntities] = queueWaitStats(waitTime, resetFlag)
%
% Inputs:
%   waitTime  - Wait duration of an entity leaving a queue (in seconds)
%   resetFlag - Logical (true/false) to reset accumulated statistics
%
% Outputs:
%   meanWait      - Running average wait time (seconds)
%   maxWait       - Peak wait time recorded (seconds)
%   totalEntities - Total count of entities processed

    persistent accumulatedTime;
    persistent peakWait;
    persistent entityCount;

    % Initialize persistent memory if empty or if reset is requested
    if isempty(accumulatedTime) || (nargin > 1 && resetFlag)
        accumulatedTime = 0;
        peakWait = 0;
        entityCount = 0;
    end

    % If called only to reset or query with zero time
    if nargin > 1 && resetFlag
        meanWait = 0;
        maxWait = 0;
        totalEntities = 0;
        return;
    end

    % Update statistics
    if waitTime >= 0
        accumulatedTime = accumulatedTime + waitTime;
        entityCount = entityCount + 1;
        if waitTime > peakWait
            peakWait = waitTime;
        end
    end

    % Return metrics
    totalEntities = entityCount;
    maxWait = peakWait;
    if entityCount > 0
        meanWait = accumulatedTime / entityCount;
    else
        meanWait = 0;
    end
end