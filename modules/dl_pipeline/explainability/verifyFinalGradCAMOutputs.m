% verifyFinalGradCAMOutputs.m
% Verifies the generated Grad-CAM dataset against the authoritative predictions.

function verifyFinalGradCAMOutputs()
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    % Paths
    predPath = fullfile(projectDir, 'results', 'baseline_test_predictions.csv');
    gradcamPath = fullfile(projectDir, 'outputs', 'gradcam', 'final', 'gradcam_results.csv');
    finalOutDir = fullfile(projectDir, 'outputs', 'gradcam', 'final');
    
    % Load Data
    fprintf('Loading authoritative predictions from: %s\n', predPath);
    origTbl = readtable(predPath, 'PreserveVariableNames', true);
    
    fprintf('Loading Grad-CAM results from: %s\n', gradcamPath);
    gradTbl = readtable(gradcamPath, 'PreserveVariableNames', true);
    
    totalOrig = height(origTbl);
    totalGrad = height(gradTbl);
    
    fprintf('\nVerification started.\n');
    fprintf('Total authoritative predictions: %d\n', totalOrig);
    fprintf('Total Grad-CAM result rows: %d\n', totalGrad);
    
    if totalOrig ~= 439 || totalGrad ~= 439
        error('Row counts do not match expected 439.');
    end
    
    mismatches = 0;
    missingFiles = 0;
    
    for i = 1:totalOrig
        origId = string(origTbl.id_code(i));
        
        [~, name, ~] = fileparts(origId);
        imgName = name + ".png";
        
        % Find corresponding row in gradTbl
        idx = find(string(gradTbl.ImageFilename) == imgName, 1);
        
        if isempty(idx)
            fprintf('Missing Grad-CAM result for %s\n', imgName);
            mismatches = mismatches + 1;
            continue;
        end
        
        % Compare predictions
        origPred = origTbl.predicted_diagnosis(i);
        gradPred = gradTbl.Prediction(idx);
        origGt = origTbl.true_diagnosis(i);
        
        if origPred ~= gradPred
            mismatches = mismatches + 1;
        end
        
        % Check file exists
        statusStr = 'correct';
        if origGt ~= gradPred, statusStr = 'wrong'; end
        outName = sprintf('%s_GT%d_Pred%d.png', name, origGt, gradPred);
        outPath = fullfile(finalOutDir, statusStr, sprintf('class_%d', origGt), outName);
        
        if ~exist(outPath, 'file')
            fprintf('Missing image file: %s\n', outPath);
            missingFiles = missingFiles + 1;
        end
    end
    
    fprintf('\n--- FINAL VERIFICATION REPORT ---\n');
    fprintf('Total images: %d\n', totalOrig);
    fprintf('Prediction mismatches: %d\n', mismatches);
    fprintf('Missing output files: %d\n', missingFiles);
    
    if mismatches == 0 && missingFiles == 0
        fprintf('SUCCESS: The Grad-CAM final generation is fully verified.\n');
    else
        fprintf('FAILED: There are discrepancies.\n');
    end
end
