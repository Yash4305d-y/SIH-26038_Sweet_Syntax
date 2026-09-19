% runAllExperiments.m
function runAllExperiments()
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    
    % disp('=== RUNNING R50-V1 ===');
    % trainBaselineResNet50();
    
    % addpath(fullfile(fileparts(srcDir), 'evaluation'));
    % evaluateBaselineResNet50();
    
    % disp('=== RUNNING R50-E01 ===');
    % trainR50E01();
    
    % disp('=== RUNNING R50-E02 ===');
    % trainR50E02();
    
    disp('=== RUNNING EFFNET-E01 ===');
    trainEffNetE01();
    
    disp('=== RUNNING EFFNET-E02 ===');
    trainEffNetE02();
    
    disp('All experiments completed successfully.');
end
