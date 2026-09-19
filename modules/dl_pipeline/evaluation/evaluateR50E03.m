% src/evaluateR50E03.m
% Evaluates the R50-E03 experiment

function evaluateR50E03()
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(fileparts(fileparts(srcDir)));
    
    % Read config
    configPath = fullfile(projectDir, 'results', 'r50_e03_config.json');
    fid = fopen(configPath, 'r');
    if fid == -1
        error('Config file not found');
    end
    raw = fread(fid, inf);
    str = char(raw');
    fclose(fid);
    config = jsondecode(str);
    
    netPath = fullfile(projectDir, 'models', config.checkpoint);
    
    % Evaluate
    evaluateExperiment('R50-E03', netPath, config);
end
