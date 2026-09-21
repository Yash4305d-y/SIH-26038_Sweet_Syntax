% src/evaluateReferableDR.m
% Evaluates the authoritative baseline predictions on the binary Referable DR task.

function evaluateReferableDR()
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    resultsDir = fullfile(projectDir, 'results');
    
    outDir = fullfile(projectDir, 'outputs', 'evaluation', 'referable_dr');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    
    % 1. Load authoritative baseline predictions
    csvPath = fullfile(resultsDir, 'baseline_test_predictions.csv');
    if ~exist(csvPath, 'file')
        error('Authoritative predictions CSV not found.');
    end
    t = readtable(csvPath, 'PreserveVariableNames', true);
    numImgs = height(t);
    
    % 2. Attempt to find PredictionScores, or compute them on the fly
    % If a global predictions.mat exists, try loading it
    predMatPath = fullfile(resultsDir, 'predictions.mat');
    if exist(predMatPath, 'file')
        loaded = load(predMatPath);
        if isfield(loaded, 'PredictionScores')
            scores = loaded.PredictionScores;
            disp('Loaded PredictionScores from results/predictions.mat');
        else
            scores = computeScores(projectDir, t);
        end
    else
        % We don't save to file to strictly honor "Do not overwrite authoritative files"
        disp('predictions.mat not found in results/. Computing baseline scores dynamically in memory...');
        scores = computeScores(projectDir, t);
    end
    
    % 3. Extract authoritative predictions
    yTrue = t.true_diagnosis;
    yPredAuthoritative = t.predicted_diagnosis;
    
    % 4. Binary Mapping
    % Non-referable (0,1) -> 0
    % Referable (2,3,4) -> 1
    yTrueBinary = double(yTrue >= 2);
    yPredBinary = double(yPredAuthoritative >= 2);
    
    % 5. Referable Probability
    % P(Referable) = P(2) + P(3) + P(4)
    refProb = sum(scores(:, 3:5), 2);
    
    % 6. Metrics Calculation
    TP = sum(yTrueBinary == 1 & yPredBinary == 1);
    TN = sum(yTrueBinary == 0 & yPredBinary == 0);
    FP = sum(yTrueBinary == 0 & yPredBinary == 1);
    FN = sum(yTrueBinary == 1 & yPredBinary == 0);
    
    accuracy = (TP + TN) / numImgs;
    sensitivity = TP / (TP + FN); % Recall
    specificity = TN / (TN + FP);
    precision = TP / (TP + FP);
    
    if isnan(precision), precision = 0; end
    if isnan(sensitivity), sensitivity = 0; end
    
    npv = TN / (TN + FN);
    f1 = 2 * (precision * sensitivity) / (precision + sensitivity);
    if isnan(f1), f1 = 0; end
    
    % 7. ROC Curve and AUC
    [X, Y, ~, AUC] = perfcurve(yTrueBinary, refProb, 1);
    
    % Print Report
    fprintf('\n=== REFERABLE-DR EVALUATION ===\n');
    fprintf('Total images: %d\n', numImgs);
    fprintf('Non-referable: %d\n', sum(yTrueBinary == 0));
    fprintf('Referable: %d\n\n', sum(yTrueBinary == 1));
    
    fprintf('Correctly classified: %d\n', TP + TN);
    fprintf('Incorrectly classified: %d\n\n', FP + FN);
    
    fprintf('Accuracy: %.4f\n', accuracy);
    fprintf('Sensitivity: %.4f\n', sensitivity);
    fprintf('Specificity: %.4f\n', specificity);
    fprintf('Precision: %.4f\n', precision);
    fprintf('F1: %.4f\n', f1);
    fprintf('ROC-AUC: %.4f\n', AUC);
    
    % 8. Save Outputs
    
    % metrics.mat
    matOut = fullfile(outDir, 'referable_dr_metrics.mat');
    save(matOut, 'accuracy', 'sensitivity', 'specificity', 'precision', 'npv', 'f1', 'AUC', 'TP', 'TN', 'FP', 'FN');
    
    % metrics.csv
    metricsTbl = table(accuracy, sensitivity, specificity, precision, npv, f1, AUC);
    writetable(metricsTbl, fullfile(outDir, 'referable_dr_metrics.csv'));
    
    % results.csv
    isCorrect = (yTrueBinary == yPredBinary);
    resultsTbl = table(string(t.id_code) + ".png", yTrue, yPredAuthoritative, ...
        yTrueBinary, yPredBinary, refProb, isCorrect, ...
        'VariableNames', {'ImageFilename', 'GroundTruthGrade', 'PredictedGrade', ...
        'GroundTruthReferable', 'PredictedReferable', 'ReferableProbability', 'CorrectBinaryClassification'});
    writetable(resultsTbl, fullfile(outDir, 'referable_dr_results.csv'));
    
    % Confusion Matrix Plot
    fig1 = figure('Visible', 'off');
    cTrue = categorical(yTrueBinary, [0 1], {'Non-Referable', 'Referable'});
    cPred = categorical(yPredBinary, [0 1], {'Non-Referable', 'Referable'});
    cm = confusionchart(cTrue, cPred);
    cm.Title = 'Referable DR (Binary) Confusion Matrix';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
    saveas(fig1, fullfile(outDir, 'referable_dr_confusion_matrix.png'));
    close(fig1);
    
    % ROC Curve Plot
    fig2 = figure('Visible', 'off');
    plot(X, Y, 'LineWidth', 2);
    hold on;
    plot([0 1], [0 1], 'k--');
    xlabel('False Positive Rate (1 - Specificity)');
    ylabel('True Positive Rate (Sensitivity)');
    title(sprintf('ROC Curve for Referable DR (AUC = %.4f)', AUC));
    grid on;
    saveas(fig2, fullfile(outDir, 'referable_dr_roc_curve.png'));
    close(fig2);
    
    disp(['Outputs saved to: ', outDir]);
end

function scores = computeScores(projectDir, t)
    % Compute scores dynamically using the EXACT baseline pipeline
    modelsDir = fullfile(projectDir, 'models');
    netPath = fullfile(modelsDir, 'baseline_resnet50_smoketest.mat');
    loaded = load(netPath, 'net');
    net = loaded.net;
    
    imgDirTrain = fullfile(projectDir, 'data', 'raw', 'train_images');
    imgDirVal = fullfile(projectDir, 'data', 'raw', 'val_images');
    imgDirTest = fullfile(projectDir, 'data', 'raw', 'test_images');
    
    paths = strings(height(t), 1);
    for i = 1:height(t)
        imgId = string(t.id_code(i));
        [~, name, ext] = fileparts(imgId);
        if isempty(char(ext)), ext = '.png'; end
        imgName = [char(name), char(ext)];
        
        fullPath = fullfile(imgDirTrain, imgName);
        if ~exist(fullPath, 'file')
            fullPath = fullfile(imgDirVal, imgName);
        end
        if ~exist(fullPath, 'file')
            fullPath = fullfile(imgDirTest, imgName);
        end
        
        if ~exist(fullPath, 'file')
            error('Test image not found in any raw folder: %s', imgName);
        end
        paths(i) = fullPath;
    end
    
    imds = imageDatastore(paths);
    augimds = augmentedImageDatastore([224 224], imds);
    disp('Running minibatchpredict to recover scores in memory...');
    scores = minibatchpredict(net, augimds);
end
