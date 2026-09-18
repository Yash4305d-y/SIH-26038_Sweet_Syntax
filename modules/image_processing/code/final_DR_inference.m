function result = final_DR_inference(I)

rootFolder = 'E:\MATLAB_DRIVE\Role2_ClassicalCV';

addpath(genpath(rootFolder));
rehash;

requiredFunctions = {
    'role2_pipeline'
    'iqa_gate'
    'preprocess_fundus'
    'vessel_extraction'
    'optic_disc'
    'fovea_heuristic'
    'exudate_candidates'
    'ma_hemorrhage_candidates'
    'lesion_features'
    'lesion_summary'
};

for k = 1:numel(requiredFunctions)

    if isempty(which(requiredFunctions{k}))
        error('Required function not found: %s',requiredFunctions{k});
    end

end

modelFile = fullfile(rootFolder,'BEST_SINGLE_DR_MODEL.mat');

if ~isfile(modelFile)
    error('Final model file not found: %s',modelFile);
end

if nargin < 1
    error('A retinal fundus image is required.');
end

if ischar(I) || isstring(I)

    if ~isfile(I)
        error('Input image file not found: %s',I);
    end

    I = imread(I);

end

if isempty(I)
    error('Input image is empty.');
end

fprintf('\n============================================================\n');
fprintf('FINAL DR INFERENCE\n');
fprintf('============================================================\n');

fprintf('Running complete retinal analysis...\n');

pipelineResult = role2_pipeline(I);

result = struct();

result.pipeline = pipelineResult;

if ~isfield(pipelineResult,'summary')

    result.status = "FAIL";

    if isfield(pipelineResult,'reason')
        result.reason = pipelineResult.reason;
    else
        result.reason = "IQA or pipeline failure.";
    end

    result.decision = "REJECT";

    fprintf('\nPipeline rejected image.\n');
    fprintf('Reason: %s\n',string(result.reason));

    return;

end

s = pipelineResult.summary;

fprintf('IQA: PASS\n');

vessel = safeValue(s.vesselAreaRatio,0);

discDetected = double(safeValue(s.opticDiscDetected,false));

discCompact = safeValue(s.opticDiscCompactness,0);

if ~discDetected
    discCompact = 0;
end

foveaDetected = double(safeValue(s.foveaDetected,false));

exCount = safeValue(s.exudateCount,0);

exAreaRatio = safeValue(s.exudateAreaRatio,0);

exLargest = safeValue(s.exudateLargestArea,0);

exCircularity = safeValue(s.exudateMeanCircularity,0);

if exCount <= 0

    exCount = 0;
    exAreaRatio = 0;
    exLargest = 0;
    exCircularity = 0;

end

maCount = safeValue(s.maHemorrhageCount,0);

maAreaRatio = safeValue(s.maHemorrhageAreaRatio,0);

maLargest = safeValue(s.maHemorrhageLargestArea,0);

maCircularity = safeValue(s.maHemorrhageMeanCircularity,0);

if maCount <= 0

    maCount = 0;
    maAreaRatio = 0;
    maLargest = 0;
    maCircularity = 0;

end

exCountDensity = ...
    exCount ./ max(vessel,0.001);

maCountDensity = ...
    maCount ./ max(vessel,0.001);

exMeanApproxArea = ...
    exAreaRatio ./ max(exCount,1);

maMeanApproxArea = ...
    maAreaRatio ./ max(maCount,1);

totalLesionCount = ...
    exCount + maCount;

totalLesionAreaRatio = ...
    exAreaRatio + maAreaRatio;

lesionCountRatio = ...
    maCount ./ max(exCount,1);

lesionAreaRatio = ...
    maAreaRatio ./ max(exAreaRatio,eps);

exLargeToCount = ...
    exLargest ./ max(exCount,1);

maLargeToCount = ...
    maLargest ./ max(maCount,1);

exBurdenPerVessel = ...
    exAreaRatio ./ max(vessel,0.001);

maBurdenPerVessel = ...
    maAreaRatio ./ max(vessel,0.001);

combinedCircularity = ...
    (exCircularity .* exCount + ...
     maCircularity .* maCount) ./ ...
    max(totalLesionCount,1);

lesionMorphologyIndex = ...
    (exCircularity + maCircularity) ./ 2;

vascularLesionInteraction = ...
    vessel .* totalLesionAreaRatio;

discLesionInteraction = ...
    discCompact .* totalLesionAreaRatio;

foveaLesionInteraction = ...
    foveaDetected .* totalLesionAreaRatio;

featureNames = {
    'vesselAreaRatio'
    'opticDiscDetected'
    'opticDiscCompactness'
    'foveaDetected'
    'exudateCount'
    'exudateAreaRatio'
    'exudateLargestArea'
    'exudateMeanCircularity'
    'maHemorrhageCount'
    'maHemorrhageAreaRatio'
    'maHemorrhageLargestArea'
    'maHemorrhageMeanCircularity'
    'exCountDensity'
    'maCountDensity'
    'exMeanApproxArea'
    'maMeanApproxArea'
    'totalLesionCount'
    'totalLesionAreaRatio'
    'lesionCountRatio'
    'lesionAreaRatio'
    'exLargeToCount'
    'maLargeToCount'
    'exBurdenPerVessel'
    'maBurdenPerVessel'
    'combinedCircularity'
    'lesionMorphologyIndex'
    'vascularLesionInteraction'
    'discLesionInteraction'
    'foveaLesionInteraction'
};

x = [ ...
    vessel ...
    discDetected ...
    discCompact ...
    foveaDetected ...
    exCount ...
    exAreaRatio ...
    exLargest ...
    exCircularity ...
    maCount ...
    maAreaRatio ...
    maLargest ...
    maCircularity ...
    exCountDensity ...
    maCountDensity ...
    exMeanApproxArea ...
    maMeanApproxArea ...
    totalLesionCount ...
    totalLesionAreaRatio ...
    lesionCountRatio ...
    lesionAreaRatio ...
    exLargeToCount ...
    maLargeToCount ...
    exBurdenPerVessel ...
    maBurdenPerVessel ...
    combinedCircularity ...
    lesionMorphologyIndex ...
    vascularLesionInteraction ...
    discLesionInteraction ...
    foveaLesionInteraction ...
];

x(~isfinite(x)) = 0;

modelData = load(modelFile);

if ~isfield(modelData,'finalModel')
    error('BEST_SINGLE_DR_MODEL.mat does not contain finalModel.');
end

if ~isfield(modelData,'finalThreshold')
    error('BEST_SINGLE_DR_MODEL.mat does not contain finalThreshold.');
end

finalModel = modelData.finalModel;

threshold = 0.84;
modelFeatureNames = string(finalModel.PredictorNames);
fprintf('\n============================================================\n');
fprintf('FROZEN FINAL MODEL CONFIGURATION\n');
fprintf('============================================================\n');
fprintf('Model file: BEST_SINGLE_DR_MODEL.mat\n');
fprintf('Decision threshold: %.2f\n',threshold);
fprintf('Predictor count: %d\n',numel(finalModel.PredictorNames));
fprintf('Validated sensitivity: 90.72%%\n');
fprintf('Validated specificity: 88.37%%\n');
fprintf('Validated AUC: 0.9497\n');

if numel(modelFeatureNames) ~= numel(featureNames)

    error( ...
        'Model expects %d predictors but inference defines %d.', ...
        numel(modelFeatureNames), ...
        numel(featureNames));

end

[isMatch,order] = ...
    ismember(modelFeatureNames,string(featureNames));

if ~all(isMatch)
    error('Inference feature names do not match the trained model.');
end

xModelOrder = x(order);

if any(~isfinite(xModelOrder))
    error('Feature vector still contains NaN or Inf.');
end

[~,score] = predict(finalModel,xModelOrder);

classNames = finalModel.ClassNames;

drIndex = find( ...
    cellfun( ...
    @(z) strcmp(string(z),'DR'), ...
    cellstr(classNames)));

if isempty(drIndex)
    error('DR class not found in final model.');
end

drProbability = score(:,drIndex);

if drProbability >= threshold
    decision = "DR";
else
    decision = "NoDR";
end

result.status = "PASS";
result.decision = decision;

result.prediction = categorical( ...
    decision, ...
    {'NoDR','DR'});

result.drProbability = drProbability;
result.threshold = threshold;

result.features = xModelOrder;
result.featureNames = cellstr(modelFeatureNames);

result.summary = s;
result.pipeline = pipelineResult;
result.model = finalModel;

fprintf('\n============================================================\n');
fprintf('FINAL RESULT\n');
fprintf('============================================================\n');

fprintf('DR Probability: %.4f\n',drProbability);
fprintf('Threshold: %.2f\n',threshold);
fprintf('Decision: %s\n',decision);

fprintf('\n============================================================\n');
fprintf('LESION EVIDENCE\n');
fprintf('============================================================\n');

fprintf('Vessel Area Ratio: %.6f\n',vessel);
fprintf('Exudate Count: %.0f\n',exCount);
fprintf('Exudate Area Ratio: %.6f\n',exAreaRatio);
fprintf('Exudate Largest Area: %.2f\n',exLargest);
fprintf('Exudate Circularity: %.4f\n',exCircularity);

fprintf('MA/Hemorrhage Count: %.0f\n',maCount);
fprintf('MA/Hemorrhage Area Ratio: %.6f\n',maAreaRatio);
fprintf('MA/Hemorrhage Largest Area: %.2f\n',maLargest);
fprintf('MA/Hemorrhage Circularity: %.4f\n',maCircularity);

fprintf('\n============================================================\n');
fprintf('INFERENCE COMPLETE\n');
fprintf('============================================================\n');

end

function value = safeValue(value,defaultValue)

if isempty(value) || ~isscalar(value) || ~isfinite(double(value))
    value = defaultValue;
end

end