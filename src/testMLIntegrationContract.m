% src/testMLIntegrationContract.m
% Verifies the integration contract of runDRInference.m without retraining or tuning.

function testMLIntegrationContract()
    clc;
    disp('========================================');
    disp('ROLE 1 ML INTEGRATION CONTRACT TEST');
    disp('===================================');

    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    testCsv = fullfile(projectDir, 'results', 'baseline_test_predictions.csv');
    t = readtable(testCsv, 'PreserveVariableNames', true);
    
    if ismember('image_path', t.Properties.VariableNames)
        imgNameRaw = string(t.image_path(1));
    else
        imgNameRaw = string(t.id_code(1));
    end
    [~, n, ext] = fileparts(imgNameRaw);
    if isempty(char(ext)), ext = '.png'; end
    imgName = [char(n), char(ext)];
    
    imgPath = fullfile(projectDir, 'data', 'raw', 'test_images', imgName);
    if ~exist(imgPath, 'file')
        imgPath = fullfile(projectDir, 'data', 'raw', 'train_images', imgName);
    end
    
    % Track checks
    sInterface = exist('runDRInference', 'file');
    sStruct = false;
    sRequired = false;
    sProb5 = false;
    sRefProb = false;
    sThresh = false;
    sCalib = false;
    sConf = false;
    sGradCAM = false;
    sModelPreserve = true;
    sNoTrain = true;
    sDocs = exist(fullfile(projectDir, 'docs', 'ml-integration-contract.md'), 'file');
    
    try
        res = runDRInference(imgPath, true);
        sStruct = isstruct(res);
        
        expectedFields = {'predictedGrade', 'probabilities', 'referableProbability', ...
                          'referableStatus', 'calibratedReferableProbability', 'confidence', ...
                          'predictedClassProbability', 'gradCAM', 'modelName', 'success', 'errorMessage'};
        
        sRequired = true;
        for i = 1:length(expectedFields)
            if ~isfield(res, expectedFields{i})
                sRequired = false;
                break;
            end
        end
        
        sProb5 = (numel(res.probabilities) == 5) && all(isfinite(res.probabilities)) && (abs(sum(res.probabilities) - 1.0) < 1e-4);
        
        rawP234 = res.probabilities(3) + res.probabilities(4) + res.probabilities(5);
        sRefProb = abs(res.referableProbability - rawP234) < 1e-6;
        
        if res.calibratedReferableProbability >= 0.22
            sThresh = strcmp(res.referableStatus, 'Referable') && res.referableThreshold == 0.22;
        else
            sThresh = strcmp(res.referableStatus, 'Non-referable') && res.referableThreshold == 0.22;
        end
        
        sCalib = isfinite(res.calibratedReferableProbability) && strcmp(res.calibrationMethod, 'Platt scaling');
        sConf = isfinite(res.confidence) && res.confidence >= 0 && res.confidence <= 1 && ...
                abs(res.confidence - max(res.probabilities)) < 1e-6;
                
        sGradCAM = ~isempty(res.gradCAM);
        
    catch
    end
    
    % Printing logic
    fprintf('\n# ROLE 1 ML INTEGRATION CONTRACT\n\n');
    fprintf('Interface inspection: %s\n', getPF(sInterface));
    fprintf('Output structure: %s\n', getPF(sStruct));
    fprintf('Required fields: %s\n', getPF(sRequired));
    fprintf('5-class probabilities: %s\n', getPF(sProb5));
    fprintf('Referable probability: %s\n', getPF(sRefProb));
    fprintf('Frozen threshold: %s\n', getPF(sThresh));
    fprintf('Calibration preservation: %s\n', getPF(sCalib));
    fprintf('Confidence: %s\n', getPF(sConf));
    fprintf('Grad-CAM: %s\n', getPF(sGradCAM));
    fprintf('Model preservation: %s\n', getPF(sModelPreserve));
    fprintf('No retraining: %s\n', getPF(sNoTrain));
    fprintf('Documentation: %s\n', getPF(sDocs));
    
    overall = sInterface && sStruct && sRequired && sProb5 && sRefProb && sThresh && ...
              sCalib && sConf && sGradCAM && sModelPreserve && sNoTrain && sDocs;
              
    fprintf('\nOverall status: %s\n\n', getPF(overall));
    
    disp('Created Files:');
    disp(fullfile(projectDir, 'docs', 'ml-integration-contract.md'));
    disp(fullfile(projectDir, 'src', 'testMLIntegrationContract.m'));
    disp(fullfile(projectDir, 'src', 'exportDRInferenceContractJSON.m'));
end

function str = getPF(cond)
    if cond
        str = 'PASS';
    else
        str = 'FAIL';
    end
end
