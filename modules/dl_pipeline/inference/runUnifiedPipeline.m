function jsonStr = runUnifiedPipeline(imagePath, generateGradCAM)
    % Initialize unified result
    unifiedResult = struct();
    
    if nargin < 2
        generateGradCAM = false;
    end
    
    % Add Role 2 paths
    projectDir = getProjectRoot();
    
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
    
    % 2. Run Morphology (Role 3)
    morphology = struct();
    morphology.executed = true;
    
    % 2.1 Vessels
    try
        vessels = vessel_extraction(I);
        morphology.vessels.ratio = vessels.vesselAreaRatio;
        if vessels.vesselAreaRatio == 0
            morphology.vessels.status = 'NO_DETECTION';
        else
            morphology.vessels.status = 'SUCCESS';
        end
    catch ME
        morphology.vessels.status = 'PROCESSING_FAILED';
        morphology.vessels.ratio = [];
    end
    
    % 2.2 Optic Disc
    try
        disc = optic_disc(I);
        morphology.optic_disc.detected = disc.detected;
        if ~disc.detected
            morphology.optic_disc.status = 'NO_DETECTION';
            morphology.optic_disc.centroid = [];
        else
            morphology.optic_disc.status = 'SUCCESS';
            morphology.optic_disc.centroid = disc.bestCandidate.Centroid;
        end
    catch ME
        morphology.optic_disc.status = 'PROCESSING_FAILED';
        morphology.optic_disc.detected = false;
        morphology.optic_disc.centroid = [];
    end
    
    % 2.3 Fovea
    if strcmp(morphology.optic_disc.status, 'SUCCESS')
        try
            fovea = fovea_heuristic(I, disc);
            morphology.fovea.detected = fovea.detected;
            if ~fovea.detected
                morphology.fovea.status = 'NO_DETECTION';
                morphology.fovea.centroid = [];
            else
                morphology.fovea.status = 'SUCCESS';
                morphology.fovea.centroid = fovea.centroid;
            end
        catch ME
            morphology.fovea.status = 'PROCESSING_FAILED';
            morphology.fovea.detected = false;
            morphology.fovea.centroid = [];
        end
    else
        morphology.fovea.status = 'BLOCKED_BY_DEPENDENCY';
        morphology.fovea.detected = false;
        morphology.fovea.centroid = [];
    end
    
    % 2.4 Exudates
    try
        exudates = exudate_candidates(I);
        morphology.exudates.ratio = exudates.candidateAreaRatio;
        if exudates.candidateAreaRatio == 0
            morphology.exudates.status = 'NO_DETECTION';
        else
            morphology.exudates.status = 'SUCCESS';
        end
    catch ME
        morphology.exudates.status = 'PROCESSING_FAILED';
        morphology.exudates.ratio = [];
    end
    
    % 2.5 Microaneurysm & Hemorrhage
    if strcmp(morphology.vessels.status, 'SUCCESS') || strcmp(morphology.vessels.status, 'NO_DETECTION')
        try
            ma_hem_result = ma_hemorrhage_candidates(I, vessels.mask);
            
            morphology.microaneurysm.ratio = ma_hem_result.microaneurysm.candidateAreaRatio;
            morphology.microaneurysm.count = ma_hem_result.microaneurysm.candidateCount;
            if morphology.microaneurysm.count == 0
                morphology.microaneurysm.status = 'NO_DETECTION';
            else
                morphology.microaneurysm.status = 'SUCCESS';
            end
            
            morphology.hemorrhage.ratio = ma_hem_result.hemorrhage.candidateAreaRatio;
            morphology.hemorrhage.count = ma_hem_result.hemorrhage.candidateCount;
            if morphology.hemorrhage.count == 0
                morphology.hemorrhage.status = 'NO_DETECTION';
            else
                morphology.hemorrhage.status = 'SUCCESS';
            end
        catch ME
            morphology.microaneurysm.status = 'PROCESSING_FAILED';
            morphology.microaneurysm.ratio = [];
            morphology.microaneurysm.count = 0;
            
            morphology.hemorrhage.status = 'PROCESSING_FAILED';
            morphology.hemorrhage.ratio = [];
            morphology.hemorrhage.count = 0;
        end
    else
        morphology.microaneurysm.status = 'BLOCKED_BY_DEPENDENCY';
        morphology.microaneurysm.ratio = [];
        morphology.microaneurysm.count = 0;
        
        morphology.hemorrhage.status = 'BLOCKED_BY_DEPENDENCY';
        morphology.hemorrhage.ratio = [];
        morphology.hemorrhage.count = 0;
    end
    
    % 2.7 Neovascularization
    if strcmp(morphology.vessels.status, 'SUCCESS') || strcmp(morphology.vessels.status, 'NO_DETECTION')
        try
            nv_result = neovascularization_candidates(vessels.mask);
            morphology.neovascularization.ratio = nv_result.candidateAreaRatio;
            morphology.neovascularization.count = nv_result.candidateCount;
            morphology.neovascularization.method = nv_result.method;
            if morphology.neovascularization.count == 0
                morphology.neovascularization.status = 'NO_DETECTION';
            else
                morphology.neovascularization.status = 'SUCCESS';
            end
        catch ME
            morphology.neovascularization.status = 'PROCESSING_FAILED';
            morphology.neovascularization.ratio = [];
            morphology.neovascularization.count = 0;
            morphology.neovascularization.method = '';
        end
    else
        morphology.neovascularization.status = 'BLOCKED_BY_DEPENDENCY';
        morphology.neovascularization.ratio = [];
        morphology.neovascularization.count = 0;
        morphology.neovascularization.method = '';
    end
    
    % Overall Morphology Status
    statuses = {morphology.vessels.status, morphology.optic_disc.status, ...
                morphology.fovea.status, morphology.exudates.status, ...
                morphology.microaneurysm.status, morphology.hemorrhage.status, ...
                morphology.neovascularization.status};
            
    numFailed = sum(strcmp(statuses, 'PROCESSING_FAILED'));
    
    if numFailed == 5
        morphology.overall_status = 'PROCESSING_FAILED';
    elseif numFailed > 0
        morphology.overall_status = 'PARTIAL';
    else
        morphology.overall_status = 'SUCCESS';
    end
    
    unifiedResult.morphology = morphology;
    
    % 3. Run Inference (Role 1)
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
