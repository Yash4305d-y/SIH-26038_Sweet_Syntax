function jsonStr = runUnifiedPipeline(imagePath, generateGradCAM)
    % Initialize unified result
    unifiedResult = struct();
    
    if nargin < 2
        generateGradCAM = false;
    end
    
    % Add Role 2 paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    iqaDir = fullfile(projectDir, 'modules', 'image_processing', 'code', 'IQA');
    morphDir = fullfile(projectDir, 'modules', 'image_processing', 'code', 'Morphology');
    preprocDir = fullfile(projectDir, 'modules', 'image_processing', 'code', 'Preprocessing');
    
    addpath(iqaDir);
    addpath(morphDir);
    addpath(preprocDir);
    
    try
        I = imread(imagePath);
    catch ME
        unifiedResult.success = false;
        unifiedResult.errorMessage = 'Failed to read image file: ' + string(ME.message);
        jsonStr = exportDRInferenceContractJSON(unifiedResult);
        return;
    end
    
    % Convert grayscale or RGBA to RGB for IQA if needed
    if size(I, 3) == 1
        I = repmat(I, [1 1 3]);
    elseif size(I, 3) == 4
        I = I(:, :, 1:3);
    end
    
    % 1. Run IQA (Role 2)
    iqaThresholds.focusMin = 0.00003;
    iqaThresholds.meanMin = 0.07;
    iqaThresholds.meanMax = 0.70;
    iqaThresholds.darkMax = 0.54;
    iqaThresholds.brightMax = 0.50;
    iqaThresholds.areaMin = 0.20;
    iqaThresholds.circularityMin = 0.09;
    
    try
        iqa = iqa_gate(I, iqaThresholds);
        unifiedResult.iqa = iqa;
    catch ME_IQA
        unifiedResult.success = false;
        unifiedResult.errorMessage = 'IQA execution failed: ' + string(ME_IQA.message);
        jsonStr = exportDRInferenceContractJSON(unifiedResult);
        return;
    end
    
    if ~iqa.pass
        unifiedResult.success = true; % Request successful, just rejected
        unifiedResult.referableStatus = 'Rejected by IQA';
        unifiedResult.errorMessage = iqa.reason;
        
        % Fill in blank model fields to satisfy UI contract
        unifiedResult.modelName = 'Baseline ResNet-50';
        unifiedResult.modelVersion = '1.0';
        unifiedResult.modelStatus = 'LOCKED';
        unifiedResult.predictedGrade = NaN;
        unifiedResult.classLabels = [0, 1, 2, 3, 4];
        unifiedResult.probabilities = NaN(1,5);
        unifiedResult.predictedClassProbability = NaN;
        unifiedResult.confidence = NaN;
        unifiedResult.referableProbability = NaN;
        unifiedResult.calibratedReferableProbability = NaN;
        unifiedResult.referableThreshold = 0.22;
        unifiedResult.calibrationMethod = 'Platt scaling';
        unifiedResult.gradCAM = [];
        
        jsonStr = exportDRInferenceContractJSON(unifiedResult);
        return;
    end
    
    % 2. Run Inference (Role 1)
    mlResult = runDRInference(imagePath, generateGradCAM);
    
    % 3. Merge results
    fields = fieldnames(mlResult);
    for i = 1:numel(fields)
        unifiedResult.(fields{i}) = mlResult.(fields{i});
    end
    
    % Ensure success carries over properly
    unifiedResult.success = mlResult.success;
    
    % Output
    jsonStr = exportDRInferenceContractJSON(unifiedResult);
end
