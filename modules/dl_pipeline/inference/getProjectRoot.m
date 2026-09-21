function projectRoot = getProjectRoot()
    % getProjectRoot Resolves the absolute path to the root of the SIH-26038 project
    % Assumes this file is located in modules/dl_pipeline/inference
    scriptPath = mfilename('fullpath');
    [inferenceDir, ~, ~] = fileparts(scriptPath);
    [dlPipelineDir, ~, ~] = fileparts(inferenceDir);
    [modulesDir, ~, ~] = fileparts(dlPipelineDir);
    projectRoot = fileparts(modulesDir);
end
