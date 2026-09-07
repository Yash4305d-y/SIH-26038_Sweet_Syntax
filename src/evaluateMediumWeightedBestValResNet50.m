% src/evaluateMediumWeightedBestValResNet50.m
% Evaluates the medium weighted ResNet-50 network (BEST Validation Checkpoint).

function evaluateMediumWeightedBestValResNet50()
    disp('================================================================');
    disp('       Medium Weighted Best Validation Model Evaluation         ');
    disp('================================================================');

    % Setup paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    modelsDir = fullfile(projectDir, 'models', 'medium_weighted_resnet50_bestval');
    resultsDir = fullfile(projectDir, 'results', 'medium_weighted_bestval');
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    % Load the BEST validation ResNet-50 network
    netPath = fullfile(modelsDir, 'bestval.mat');
    
    fprintf('Looking for trained model at: %s\n', netPath);
    if ~isfile(netPath)
        error('Trained network not found at %s. Please train the model first.', netPath);
    else
        fprintf('Model file found successfully!\n');
    end
    
    disp('Loading BEST trained medium weighted network...');
    try
        loadedData = load(netPath, 'net');
        net = loadedData.net;
        disp('Network loaded successfully.');
    catch ME
        error('Failed to load the trained network: %s', ME.message);
    end
    
    % Load ONLY the fixed APTOS test split using robust datastore logic
    disp('Loading fixed APTOS test split via createAPTOSDatastores...');
    [~, ~, imdsTest] = createAPTOSDatastores();
    
    % Verify Test Datastore
    if isempty(imdsTest.Files)
        error('Test datastore is completely empty! Aborting evaluation.');
    end
    
    % Enforce categorical labels 0,1,2,3,4 exactly
    classes = {'0', '1', '2', '3', '4'};
    classNames = {'No DR', 'Mild', 'Moderate', 'Severe', 'Proliferative DR'};
    
    uniqueLabels = unique(imdsTest.Labels);
    if ~all(ismember({'0', '1', '2', '3', '4'}, string(uniqueLabels)))
        warning('Not all 5 DR classes are present in the test labels.');
    end
    
    imdsTest.ReadSize = 1; % PREVENT BAD ALLOCATION OOM
    numValidSamples = numel(imdsTest.Files);
    
    % Resize images to 224x224x3
    disp('Creating augmentedImageDatastore to resize to 224x224...');
    augimdsTest = augmentedImageDatastore([224 224], imdsTest);
    
    % Predict using minibatchpredict
    disp('Running predictions on test set...');
    try
        scores = minibatchpredict(net, augimdsTest, 'MiniBatchSize', 4, 'ExecutionEnvironment', 'auto');
    catch ME
        error('Failed to run inference on test datastore: %s', ME.message);
    end
    
    if size(scores, 1) ~= numValidSamples
        error('Number of predictions (%d) does not match ground-truth labels (%d)!', size(scores, 1), numValidSamples);
    end
    
    % Convert scores to predicted DR classes 0,1,2,3,4
    [~, maxIdx] = max(scores, [], 2);
    YPred = categorical(classes(maxIdx)', classes);
    YTest = imdsTest.Labels;
    
    if any(isundefined(YPred))
        error('NaN or undefined prediction labels found!');
    end
    
    fprintf('\nSuccessfully evaluated %d test samples.\n\n', numValidSamples);
    
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
    accuracy = sum(TP) / numValidSamples;
    
    % Weighted Metrics
    support = sum(O, 2);
    weight = support / sum(support);
    weightedPrecision = sum(precision .* weight);
    weightedRecall = sum(recall .* weight);
    weightedF1 = sum(f1 .* weight);
    
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
    
    % Print Metrics to Console
    fprintf('Test Accuracy:        %.4f\n', accuracy);
    fprintf('Macro Precision:      %.4f\n', macroPrecision);
    fprintf('Macro Recall:         %.4f\n', macroRecall);
    fprintf('Macro F1 Score:       %.4f\n', macroF1);
    fprintf('Weighted Precision:   %.4f\n', weightedPrecision);
    fprintf('Weighted Recall:      %.4f\n', weightedRecall);
    fprintf('Weighted F1 Score:    %.4f\n', weightedF1);
    fprintf('QWK:                  %.4f\n', qwk);
    disp('----------------------------------------------------------------');
    disp('Per-Class Metrics:');
    fprintf('%-20s | %-12s | %-12s | %-12s\n', 'Class', 'Precision', 'Recall', 'F1 Score');
    fprintf('----------------------------------------------------------------\n');
    for i = 1:N
        fprintf('%-20s | %-12.4f | %-12.4f | %-12.4f\n', classNames{i}, precision(i), recall(i), f1(i));
    end
    disp('================================================================');
    
    % Save predictions to .mat
    predOutPath = fullfile(resultsDir, 'predictions.mat');
    ImageFilenames = imdsTest.Files;
    GroundTruthLabels = YTest;
    PredictedLabels = YPred;
    PredictionScores = scores;
    save(predOutPath, 'ImageFilenames', 'GroundTruthLabels', 'PredictedLabels', 'PredictionScores');
    
    % Save metrics to .mat
    metricsPath = fullfile(resultsDir, 'metrics.mat');
    PrecisionPerClass = precision;
    RecallPerClass = recall;
    F1PerClass = f1;
    MacroPrecision = macroPrecision;
    MacroRecall = macroRecall;
    MacroF1 = macroF1;
    WeightedPrecision = weightedPrecision;
    WeightedRecall = weightedRecall;
    WeightedF1 = weightedF1;
    QWK = qwk;
    ConfusionMatrix = O;
    ClassNames = classNames;
    NumberOfTestImages = numValidSamples;
    Accuracy = accuracy;
    
    save(metricsPath, 'Accuracy', 'PrecisionPerClass', 'RecallPerClass', 'F1PerClass', ...
        'MacroPrecision', 'MacroRecall', 'MacroF1', 'WeightedPrecision', 'WeightedRecall', ...
        'WeightedF1', 'QWK', 'ConfusionMatrix', 'ClassNames', 'NumberOfTestImages');
    
    % Plot and save confusion matrix with correct labels
    disp('Generating confusion matrix plot...');
    % Remap class labels for the plot safely
    YTestPlot = renamecats(YTest, classes, classNames);
    YPredPlot = renamecats(YPred, classes, classNames);
    
    fig = figure('Name', 'Confusion Matrix', 'Visible', 'off');
    cm = confusionchart(YTestPlot, YPredPlot);
    cm.Title = 'Medium Weighted Best Validation Model';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
    
    cmPath = fullfile(resultsDir, 'confusion_matrix.png');
    saveas(fig, cmPath);
    close(fig);
    
    % Save a TXT summary
    txtPath = fullfile(resultsDir, 'summary.txt');
    fid = fopen(txtPath, 'w');
    fprintf(fid, 'Evaluation Summary\n');
    fprintf(fid, 'Date/Time: %s\n\n', datestr(now));
    fprintf(fid, 'Model Name: Medium Weighted Best-Validation ResNet-50\n');
    fprintf(fid, 'Dataset Name: APTOS\n');
    fprintf(fid, 'Number of evaluated test images: %d\n\n', numValidSamples);
    
    fprintf(fid, 'Test Accuracy:        %.4f\n', accuracy);
    fprintf(fid, 'Macro F1 Score:       %.4f\n', macroF1);
    fprintf(fid, 'Weighted F1 Score:    %.4f\n', weightedF1);
    fprintf(fid, 'QWK:                  %.4f\n\n', qwk);
    
    fprintf(fid, 'Class | Precision | Recall | F1 Score\n');
    for i = 1:N
        fprintf(fid, '%-20s | %-9.4f | %-6.4f | %.4f\n', classNames{i}, precision(i), recall(i), f1(i));
    end
    
    fprintf(fid, '\nConfusion Matrix (Rows=True, Cols=Predicted):\n');
    for i = 1:N
        fprintf(fid, '%d ', O(i, :));
        fprintf(fid, '\n');
    end
    
    fclose(fid);
    
    disp(['Predictions saved to: ', predOutPath]);
    disp(['Metrics saved to: ', metricsPath]);
    disp(['Confusion matrix saved to: ', cmPath]);
    disp(['Summary saved to: ', txtPath]);
    
    disp('Evaluation script complete!');
end
