% src/evaluateMildWeightedBestValResNet50.m
% Evaluates the mild square-root weighted ResNet-50 network (BEST Validation Checkpoint).

function evaluateMildWeightedBestValResNet50()
    % Setup paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results', 'mild_weighted_bestval');
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    % Load the BEST validation ResNet-50 network
    netPath = fullfile(modelsDir, 'mild_weighted_resnet50_bestval.mat');
    
    fprintf('Looking for trained model at: %s\n', netPath);
    if ~isfile(netPath)
        error('Trained network not found at %s.', netPath);
    else
        fprintf('Model file found successfully!\n');
    end
    
    disp('Loading BEST trained mild weighted network...');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    % Load ONLY the fixed APTOS test split
    disp('Loading fixed APTOS test split...');
    dataDir = fullfile(projectDir, 'data');
    splitsDir = fullfile(dataDir, 'splits');
    imgDir = fullfile(dataDir, 'raw', 'test_images');
    testCsvFile = fullfile(splitsDir, 'test_split.csv');
    
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
    
    % Create the test image datastore
    imdsTest = imageDatastore(paths, 'Labels', labels);
    
    % Resize images to 224x224x3
    disp('Creating augmentedImageDatastore to resize to 224x224...');
    augimdsTest = augmentedImageDatastore([224 224], imdsTest);
    
    % Predict using minibatchpredict
    disp('Running predictions on test set...');
    scores = minibatchpredict(net, augimdsTest);
    
    % Convert scores to predicted DR classes 0,1,2,3,4
    [~, maxIdx] = max(scores, [], 2);
    YPred = categorical(classes(maxIdx)', classes);
    YTest = imdsTest.Labels;
    
    fprintf('\nEvaluated %d test samples.\n\n', numSamples);
    
    % Compare predictions against the true test labels
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
    
    macroPrecision = mean(precision);
    macroRecall = mean(recall);
    macroF1 = mean(f1);
    accuracy = sum(TP) / numSamples;
    balancedAccuracy = mean(recall); % Balanced accuracy is macro-recall
    
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
    disp('================================================================');
    disp('       Mild Weighted Best Validation Model Evaluation           ');
    disp('================================================================');
    
    % Check history to find the best epoch
    historyPath = fullfile(resultsDir, 'training_history.mat');
    if exist(historyPath, 'file')
        histData = load(historyPath);
        if isfield(histData.info, 'ValidationHistory')
            valLoss = histData.info.ValidationHistory.Loss;
            valEpochs = histData.info.ValidationHistory.Epoch;
            [~, bestIdx] = min(valLoss);
            fprintf('Best Validation Epoch: %d\n', valEpochs(bestIdx));
        end
    end
    
    fprintf('Test Accuracy:        %.4f\n', accuracy);
    fprintf('Balanced Accuracy:    %.4f\n', balancedAccuracy);
    fprintf('Macro Precision:      %.4f\n', macroPrecision);
    fprintf('Macro Recall:         %.4f\n', macroRecall);
    fprintf('Macro F1 Score:       %.4f\n', macroF1);
    fprintf('QWK:                  %.4f\n', qwk);
    disp('----------------------------------------------------------------');
    disp('Per-Class Metrics:');
    fprintf('%-8s | %-12s | %-12s | %-12s\n', 'Class', 'Precision', 'Recall', 'F1 Score');
    fprintf('----------------------------------------------------------------\n');
    for i = 1:N
        fprintf('%-8s | %-12.4f | %-12.4f | %-12.4f\n', char(classes(i)), precision(i), recall(i), f1(i));
    end
    disp('================================================================');
    
    % Save predictions to CSV
    csvOutPath = fullfile(resultsDir, 'mild_weighted_bestval_predictions.csv');
    [~, fileNames, ~] = fileparts(paths);
    outTable = table(string(fileNames), string(YTest), string(YPred), ...
        'VariableNames', {'id_code', 'true_diagnosis', 'predicted_diagnosis'});
    writetable(outTable, csvOutPath);
    
    % Save metrics
    metricsPath = fullfile(resultsDir, 'mild_weighted_bestval_metrics.mat');
    save(metricsPath, 'accuracy', 'balancedAccuracy', 'macroPrecision', 'macroRecall', ...
        'precision', 'recall', 'f1', 'macroF1', 'qwk', 'O', 'classes', 'YTest', 'YPred');
    
    % Plot and save confusion matrix
    disp('Generating confusion matrix plot...');
    fig = figure('Name', 'Confusion Matrix', 'Visible', 'off');
    cm = confusionchart(YTest, YPred);
    cm.Title = 'Mild Weighted Best Validation Model';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
    
    cmPath = fullfile(resultsDir, 'mild_weighted_bestval_confusion_matrix.png');
    saveas(fig, cmPath);
    close(fig);
    
    % Save a TXT summary
    txtPath = fullfile(resultsDir, 'mild_weighted_bestval_summary.txt');
    fid = fopen(txtPath, 'w');
    fprintf(fid, 'Evaluation Summary\n\n');
    fprintf(fid, 'Test Accuracy:        %.4f\n', accuracy);
    fprintf(fid, 'Balanced Accuracy:    %.4f\n', balancedAccuracy);
    fprintf(fid, 'Macro Precision:      %.4f\n', macroPrecision);
    fprintf(fid, 'Macro Recall:         %.4f\n', macroRecall);
    fprintf(fid, 'Macro F1 Score:       %.4f\n', macroF1);
    fprintf(fid, 'QWK:                  %.4f\n\n', qwk);
    fprintf(fid, 'Class | Precision | Recall | F1 Score\n');
    for i = 1:N
        fprintf(fid, '%-5s | %-9.4f | %-6.4f | %.4f\n', char(classes(i)), precision(i), recall(i), f1(i));
    end
    fclose(fid);
    
    disp(['Predictions saved to: ', csvOutPath]);
    disp(['Metrics/Labels saved to: ', metricsPath]);
    disp(['Confusion matrix saved to: ', cmPath]);
    disp(['Summary saved to: ', txtPath]);
    
    disp('Evaluation script complete!');
end
