% src/evaluateWeightedResNet50.m
% Evaluates the weighted ResNet-50 network on the test split.

function evaluateWeightedResNet50()
    % Setup paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    netPath = fullfile(modelsDir, 'weighted_resnet50_smoketest.mat');
    if ~exist(netPath, 'file')
        error('Trained network not found at %s. Please run trainWeightedResNet50.m first.', netPath);
    end
    
    % 1. Load trained weighted ResNet-50
    disp('Loading trained weighted network...');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    % 2. Load ONLY the fixed APTOS test split
    disp('Loading fixed APTOS test split...');
    dataDir = fullfile(projectDir, 'data');
    splitsDir = fullfile(dataDir, 'splits');
    imgDir = fullfile(dataDir, 'APTOS', 'train_images');
    testCsvFile = fullfile(splitsDir, 'aptos_test.csv');
    
    if ~exist(testCsvFile, 'file')
        error('Test split CSV not found.');
    end
    
    testData = readtable(testCsvFile, 'PreserveVariableNames', true);
    numSamples = height(testData);
    
    % Construct paths and verify existence
    paths = strings(numSamples, 1);
    for i = 1:numSamples
        if ismember('image_path', testData.Properties.VariableNames)
            imgId = string(testData.image_path(i));
        else
            imgId = string(testData.id_code(i));
        end
        [~, name, ext] = fileparts(imgId);
        if isempty(char(ext)), ext = '.png'; end
        fullPath = fullfile(imgDir, [char(name), char(ext)]);
        
        if ~exist(fullPath, 'file')
            error('Missing test image: %s', fullPath);
        end
        paths(i) = fullPath;
    end
    
    % Enforce categorical labels 0,1,2,3,4 exactly
    classes = {'0', '1', '2', '3', '4'};
    labels = categorical(string(testData.diagnosis), classes);
    
    % 3. Create the test image datastore
    imdsTest = imageDatastore(paths, 'Labels', labels);
    
    % 4. Resize images to 224x224x3 without augmenting or CLAHE
    disp('Creating augmentedImageDatastore to resize to 224x224...');
    augimdsTest = augmentedImageDatastore([224 224], imdsTest);
    
    % 7. Predict using minibatchpredict
    disp('Running predictions on test set...');
    scores = minibatchpredict(net, augimdsTest);
    
    % 8. Convert scores to predicted DR classes 0,1,2,3,4
    [~, maxIdx] = max(scores, [], 2);
    YPred = categorical(classes(maxIdx)', classes);
    YTest = imdsTest.Labels;
    
    fprintf('\nEvaluated %d test samples.\n\n', numSamples);
    
    % 9. Compare predictions against the true test labels
    O = confusionmat(YTest, YPred, 'Order', classes);
    
    % Metrics calculation
    N = length(classes);
    TP = diag(O);
    FP = sum(O, 1)' - TP;
    FN = sum(O, 2) - TP;
    
    precision = TP ./ (TP + FP);
    precision(isnan(precision)) = 0;
    
    recall = TP ./ (TP + FN);
    recall(isnan(recall)) = 0;
    
    f1 = 2 .* (precision .* recall) ./ (precision + recall);
    f1(isnan(f1)) = 0;
    
    macroF1 = mean(f1);
    accuracy = sum(TP) / numSamples;
    
    % QWK Calculation
    w = zeros(N, N);
    for i = 1:N
        for j = 1:N
            w(i,j) = (i - j)^2 / (N - 1)^2;
        end
    end
    
    actualHist = sum(O, 2);
    predHist = sum(O, 1);
    E = (actualHist * predHist) / sum(O(:));
    
    if sum(w .* E, 'all') == 0
        qwk = 0;
    else
        qwk = 1 - sum(w .* O, 'all') / sum(w .* E, 'all');
    end
    
    % Print Metrics
    disp('--- Final Weighted Evaluation Metrics ---');
    fprintf('Overall Accuracy: %.4f\n', accuracy);
    fprintf('Macro F1 Score:   %.4f\n', macroF1);
    fprintf('QWK (Quadratic Weighted Kappa): %.4f\n', qwk);
    disp(' ');
    disp('Per-Class Metrics:');
    fprintf('%-8s %-12s %-12s %-12s\n', 'Class', 'Precision', 'Recall', 'F1 Score');
    for i = 1:N
        fprintf('%-8s %-12.4f %-12.4f %-12.4f\n', char(classes(i)), precision(i), recall(i), f1(i));
    end
    disp(' ');
    
    % Compare with baseline
    baselinePath = fullfile(resultsDir, 'baseline_metrics.mat');
    if exist(baselinePath, 'file')
        disp('--- Comparison with Baseline ---');
        base = load(baselinePath);
        
        fprintf('QWK:        Weighted %.4f vs Baseline %.4f (%s)\n', ...
            qwk, base.qwk, getChangeStr(qwk, base.qwk));
        fprintf('Accuracy:   Weighted %.4f vs Baseline %.4f (%s)\n', ...
            accuracy, base.accuracy, getChangeStr(accuracy, base.accuracy));
        fprintf('Macro F1:   Weighted %.4f vs Baseline %.4f (%s)\n', ...
            macroF1, base.macroF1, getChangeStr(macroF1, base.macroF1));
            
        disp(' ');
        disp('Recall (Sensitivity) Comparison:');
        for i = 1:N
            fprintf('Class %s Recall: Weighted %.4f vs Baseline %.4f (%s)\n', ...
                char(classes(i)), recall(i), base.recall(i), getChangeStr(recall(i), base.recall(i)));
        end
        
        disp(' ');
        disp('Analysis Summary:');
        % Check minority classes 1 (idx 2), 3 (idx 4), 4 (idx 5)
        if (recall(2) > base.recall(2)) || (recall(4) > base.recall(4)) || (recall(5) > base.recall(5))
            disp('- Minority-class recall generally improved.');
        else
            disp('- Minority-class recall did NOT improve.');
        end
        
        % Check grade 0 (idx 1)
        if recall(1) < base.recall(1) - 0.05
            disp('- Grade-0 recall degraded significantly (>5%).');
        elseif recall(1) < base.recall(1)
            disp('- Grade-0 recall degraded slightly.');
        else
            disp('- Grade-0 recall improved or remained stable.');
        end
        
        % Check QWK
        if qwk > base.qwk
            disp('- Overall QWK improved.');
        else
            disp('- Overall QWK degraded.');
        end
        disp(' ');
    end
    
    % Save predictions to CSV
    csvOutPath = fullfile(resultsDir, 'weighted_test_predictions.csv');
    [~, fileNames, ~] = fileparts(paths);
    outTable = table(string(fileNames), string(YTest), string(YPred), ...
        'VariableNames', {'id_code', 'true_diagnosis', 'predicted_diagnosis'});
    writetable(outTable, csvOutPath);
    
    % Save metrics
    metricsPath = fullfile(resultsDir, 'weighted_metrics.mat');
    save(metricsPath, 'accuracy', 'precision', 'recall', 'f1', 'macroF1', 'qwk', 'O', 'classes');
    
    % Plot and save confusion matrix
    disp('Generating confusion matrix plot...');
    fig = figure('Name', 'Confusion Matrix', 'Visible', 'off');
    cm = confusionchart(YTest, YPred);
    cm.Title = 'Weighted ResNet-50 Test Confusion Matrix';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
    
    cmPath = fullfile(resultsDir, 'weighted_confusion_matrix.png');
    saveas(fig, cmPath);
    close(fig);
    
    disp(['Predictions saved to: ', csvOutPath]);
    disp(['Metrics saved to: ', metricsPath]);
    disp(['Confusion matrix saved to: ', cmPath]);
    
    disp('Evaluation script complete!');
end

function str = getChangeStr(newVal, oldVal)
    diff = newVal - oldVal;
    if diff > 0
        str = sprintf('+%.4f', diff);
    elseif diff < 0
        str = sprintf('%.4f', diff);
    else
        str = 'No change';
    end
end
