% src/trainGeometryNormalizedResNet50.m
% Trains a pretrained ResNet-50 network for 5-class DR classification
% using 1:1 deterministic center crop (geometry normalization).
% Uses ahead-of-time preprocessing to disk for memory safety.

function trainGeometryNormalizedResNet50()
    % Setup paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    modelsDir = fullfile(projectDir, 'models', 'geometry_normalized_resnet50');
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
    
    resultsDir = fullfile(projectDir, 'results', 'geometry_normalized_training');
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    evalDir = fullfile(projectDir, 'outputs', 'evaluation', 'geometry_normalized');
    if ~exist(evalDir, 'dir'), mkdir(evalDir); end
    
    docsDir = fullfile(projectDir, 'docs');
    
    procTrainDir = fullfile(projectDir, 'data', 'processed', 'geometry_normalized', 'train');
    procValDir = fullfile(projectDir, 'data', 'processed', 'geometry_normalized', 'val');
    if ~exist(procTrainDir, 'dir'), mkdir(procTrainDir); end
    if ~exist(procValDir, 'dir'), mkdir(procValDir); end
    
    % 1. Load Original Datastores
    disp('Loading original APTOS image datastores...');
    [imdsTrainOrig, imdsValOrig, ~] = createAPTOSDatastores();
    
    classes = categorical({'0', '1', '2', '3', '4'});
    if ~all(ismember(string(classes), string(categories(imdsTrainOrig.Labels))))
        error('Labels are not mapped to the expected 5 classes (0, 1, 2, 3, 4).');
    end
    
    % 2. Process Training Images
    disp('Preprocessing Training images ahead-of-time...');
    trainFiles = imdsTrainOrig.Files;
    numTrain = numel(trainFiles);
    procTrainFiles = cell(numTrain, 1);
    trainProcessedCount = 0;
    trainReusedCount = 0;
    
    for i = 1:numTrain
        [~, name, ext] = fileparts(trainFiles{i});
        outPath = fullfile(procTrainDir, [name ext]);
        procTrainFiles{i} = outPath;
        
        if exist(outPath, 'file')
            trainReusedCount = trainReusedCount + 1;
        else
            processAndSaveImage(trainFiles{i}, outPath);
            trainProcessedCount = trainProcessedCount + 1;
        end
        
        if mod(i, 500) == 0
            fprintf('Train progress: %d/%d\n', i, numTrain);
        end
    end
    fprintf('Train preprocessing complete. Processed: %d, Reused: %d\n', trainProcessedCount, trainReusedCount);
    
    % 3. Process Validation Images
    disp('Preprocessing Validation images ahead-of-time...');
    valFiles = imdsValOrig.Files;
    numVal = numel(valFiles);
    procValFiles = cell(numVal, 1);
    valProcessedCount = 0;
    valReusedCount = 0;
    
    for i = 1:numVal
        [~, name, ext] = fileparts(valFiles{i});
        outPath = fullfile(procValDir, [name ext]);
        procValFiles{i} = outPath;
        
        if exist(outPath, 'file')
            valReusedCount = valReusedCount + 1;
        else
            processAndSaveImage(valFiles{i}, outPath);
            valProcessedCount = valProcessedCount + 1;
        end
    end
    fprintf('Validation preprocessing complete. Processed: %d, Reused: %d\n', valProcessedCount, valReusedCount);
    
    % 4. Create Normalized Datastores
    imdsTrainProc = imageDatastore(procTrainFiles, 'Labels', imdsTrainOrig.Labels);
    imdsValProc = imageDatastore(procValFiles, 'Labels', imdsValOrig.Labels);
    
    imdsTrainProc.ReadFcn = @readGeometryNormalizedImage;
    imdsValProc.ReadFcn = @readGeometryNormalizedImage;
    
    dsTrain = augmentedImageDatastore([224 224], imdsTrainProc, 'ColorPreprocessing', 'gray2rgb');
    dsVal = augmentedImageDatastore([224 224], imdsValProc, 'ColorPreprocessing', 'gray2rgb');
    
    % 5. DATASTORE SANITY CHECK
    disp('=== DATASTORE SANITY CHECK ===');
    sanityPass = true;
    
    try
        testData = readByIndex(dsTrain, 1:4);
        disp('Training datastore: PASS');
    catch ME
        disp('Training datastore: FAIL');
        disp(ME.message);
        sanityPass = false;
    end
    
    try
        testDataVal = readByIndex(dsVal, 1:4);
        disp('Validation datastore: PASS');
    catch ME
        disp('Validation datastore: FAIL');
        disp(ME.message);
        sanityPass = false;
    end
    
    if sanityPass
        img = testData.input{1};
        if isnumeric(img) && ~ischar(img) && ~isstring(img)
            disp('Image data returned: PASS');
        else
            disp('Image data returned: FAIL');
            sanityPass = false;
        end
        
        if size(img, 3) == 3
            disp('3-channel compatibility: PASS');
        else
            disp('3-channel compatibility: FAIL');
            sanityPass = false;
        end
        
        if size(img, 1) == 224 && size(img, 2) == 224
            disp('224x224 compatibility: PASS');
        else
            disp('224x224 compatibility: FAIL');
            sanityPass = false;
        end
        
        if isequal(imdsTrainProc.Labels(1:4), imdsTrainOrig.Labels(1:4))
            disp('Labels matched correctly: PASS');
        else
            disp('Labels matched correctly: FAIL');
            sanityPass = false;
        end
    else
        disp('Image data returned: FAIL');
        disp('3-channel compatibility: FAIL');
        disp('224x224 compatibility: FAIL');
        disp('Labels matched correctly: FAIL');
    end
    
    if ~sanityPass
        error('Datastore sanity check failed. Halting before training.');
    end
    
    reset(dsTrain);
    reset(dsVal);
    
    % 6. Load Baseline Initialization
    baseNetPath = fullfile(projectDir, 'models', 'baseline_resnet50_initialized.mat');
    if ~exist(baseNetPath, 'file')
        error('Initialized network not found at: %s', baseNetPath);
    end
    disp('Loading configured pretrained ResNet-50...');
    loadedData = load(baseNetPath, 'net');
    net = loadedData.net;
    clear loadedData; % Free memory
    
    % Reset GPU device to prevent Out Of Memory caused by fragmentation
    try
        reset(gpuDevice(1));
    catch
        disp('No GPU reset required or supported.');
    end
    
    % 7. Configure Training Options
    disp('Setting up training options...');
    opts = trainingOptions("adam", ...
        "InitialLearnRate", 1e-4, ... 
        "MaxEpochs", 5, ...           
        "MiniBatchSize", 16, ...      
        "ValidationData", augimdsVal, ...
        "ExecutionEnvironment", "auto", ... 
        "Plots", "training-progress", ...
        "Verbose", true);
        
    % 8. Train the Network
    disp('Starting training (smoke test: exactly 5 epochs)...');
    [net, info] = trainnet(dsTrain, net, "crossentropy", opts);
    
    % Save trained network
    saveNetPath = fullfile(modelsDir, 'geometry_normalized_resnet50_smoketest.mat');
    disp(['Saving trained network to: ', saveNetPath]);
    save(saveNetPath, 'net');
    
    % Save training history
    saveInfoPath = fullfile(resultsDir, 'history.mat');
    disp(['Saving training history to: ', saveInfoPath]);
    save(saveInfoPath, 'info');
    
    % 9. VALIDATION EVALUATION
    disp('Evaluating on validation set...');
    scores = minibatchpredict(net, dsVal);
    
    [~, maxIdx] = max(scores, [], 2);
    YPred = categorical(string(classes(maxIdx)'), string(classes));
    YVal = imdsValProc.Labels;
    
    % Metrics
    O = confusionmat(YVal, YPred, 'Order', classes);
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
    accuracy = sum(TP) / numel(YVal);
    
    % QWK
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
    
    % Save evaluation artifacts
    metricsPath = fullfile(evalDir, 'geometry_normalized_validation_metrics.mat');
    save(metricsPath, 'accuracy', 'macroF1', 'qwk', 'macroPrecision', 'macroRecall', 'precision', 'recall', 'f1', 'O', 'classes');
    
    csvPredPath = fullfile(evalDir, 'geometry_normalized_validation_predictions.csv');
    [~, valNames, ~] = fileparts(imdsValProc.Files);
    predTable = table(string(valNames), string(YVal), string(YPred), ...
        'VariableNames', {'id_code', 'true_diagnosis', 'predicted_diagnosis'});
    writetable(predTable, csvPredPath);
    
    % Metric CSV for this experiment
    metricNames = ["Accuracy"; "Macro_F1"; "QWK"; "Macro_Precision"; "Macro_Recall"];
    metricVals = [accuracy; macroF1; qwk; macroPrecision; macroRecall];
    for i = 1:N
        metricNames(end+1) = "Precision_Class_" + string(classes(i));
        metricVals(end+1) = precision(i);
        metricNames(end+1) = "Recall_Class_" + string(classes(i));
        metricVals(end+1) = recall(i);
        metricNames(end+1) = "F1_Class_" + string(classes(i));
        metricVals(end+1) = f1(i);
    end
    metricTable = table(metricNames(:), metricVals(:), 'VariableNames', {'Metric', 'Value'});
    writetable(metricTable, fullfile(evalDir, 'geometry_normalized_validation_metrics.csv'));
    
    % Confusion matrix
    fig = figure('Visible', 'off');
    cm = confusionchart(YVal, YPred);
    cm.Title = 'Geometry-Normalized Validation Confusion Matrix';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
    cmPath = fullfile(evalDir, 'geometry_normalized_validation_confusion_matrix.png');
    saveas(fig, cmPath);
    close(fig);
    
    % 10. BASELINE COMPARISON
    baseAcc = 0.8292;
    baseF1 = 0.6358;
    baseQWK = 0.8713;
    
    compNames = {'Accuracy'; 'Macro-F1'; 'QWK'};
    baseVals = [baseAcc; baseF1; baseQWK];
    expVals = [accuracy; macroF1; qwk];
    diffVals = expVals - baseVals;
    
    compTable = table(string(compNames), baseVals, expVals, diffVals, ...
        'VariableNames', {'Metric', 'Baseline', 'Geometry_Normalized', 'Difference'});
    writetable(compTable, fullfile(evalDir, 'baseline_vs_geometry_comparison.csv'));
    
    % 11. Generate Report
    reportPath = fullfile(docsDir, 'geometry-normalized-experiment.md');
    fid = fopen(reportPath, 'w');
    fprintf(fid, '# ML Experiment 1 — Geometry-Normalized APTOS ResNet-50\n\n');
    fprintf(fid, '## Objective\n');
    fprintf(fid, 'Test whether reducing APTOS aspect-ratio variation through a 1:1 center crop improves the ResNet-50 DR classification model.\n\n');
    fprintf(fid, '## Configuration\n');
    fprintf(fid, '- **Preprocessing:** Ahead-of-time deterministic 1:1 center crop + 224x224 resize\n');
    fprintf(fid, '- **Optimizer:** Adam\n');
    fprintf(fid, '- **Learning Rate:** 1e-4\n');
    fprintf(fid, '- **Epochs:** 5\n');
    fprintf(fid, '- **Batch Size:** 16\n\n');
    
    fprintf(fid, '## Results\n');
    fprintf(fid, '| Metric | Baseline | Geometry Normalized | Difference |\n');
    fprintf(fid, '|---|---|---|---|\n');
    for i = 1:height(compTable)
        fprintf(fid, '| %s | %.4f | %.4f | %+.4f |\n', ...
            compTable.Metric(i), compTable.Baseline(i), compTable.Geometry_Normalized(i), compTable.Difference(i));
    end
    fprintf(fid, '\n');
    
    fprintf(fid, '## Experiment Interpretation\n\n');
    fprintf(fid, '### OBSERVATION\n');
    fprintf(fid, 'Compared to the baseline test evaluation, the validation accuracy changed by %+.4f, Macro-F1 by %+.4f, and QWK by %+.4f.\n\n', ...
        diffVals(1), diffVals(2), diffVals(3));
    fprintf(fid, '### HYPOTHESIS\n');
    if diffVals(3) > 0 || diffVals(2) > 0
        fprintf(fid, 'Results support further investigation of geometry normalization.\n\n');
    else
        fprintf(fid, 'Results do not support geometry normalization as a sufficient improvement under this experimental configuration.\n\n');
    end
    fprintf(fid, '### LIMITATION\n');
    fprintf(fid, 'This is only a 5-epoch smoke-test experiment. Do NOT claim causality from one experiment or that it solves domain shift on Messidor-2.\n');
    fclose(fid);
    
    % 12. SUMMARY
    disp(' ');
    disp('=== GEOMETRY-NORMALIZED EXPERIMENT COMPLETE ===');
    fprintf('Training images processed/reused: %d / %d\n', trainProcessedCount, trainReusedCount);
    fprintf('Validation images processed/reused: %d / %d\n', valProcessedCount, valReusedCount);
    disp('Sanity check: PASS');
    disp('Training completed: YES');
    disp('Validation completed: YES');
    disp(' ');
    fprintf('Accuracy: %.4f\n', accuracy);
    fprintf('Macro-F1: %.4f\n', macroF1);
    fprintf('QWK: %.4f\n', qwk);
    disp(' ');
    disp('Comparison with baseline:');
    fprintf('Accuracy Delta: %+.4f\n', diffVals(1));
    fprintf('Macro-F1 Delta: %+.4f\n', diffVals(2));
    fprintf('QWK Delta: %+.4f\n', diffVals(3));
    disp(' ');
    disp('Overall status: PASS');
    
end

function processAndSaveImage(inPath, outPath)
    try
        img = imread(inPath);
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        elseif size(img, 3) == 4
            img = img(:, :, 1:3);
        end
        
        [h, w, ~] = size(img);
        if h ~= w
            sz = min(h, w);
            r0 = floor((h - sz) / 2) + 1;
            c0 = floor((w - sz) / 2) + 1;
            img = img(r0:r0+sz-1, c0:c0+sz-1, :);
        end
        
        img = imresize(img, [224 224]);
        imwrite(img, outPath, 'png');
    catch ME
        fprintf('Failed to process image %s: %s\n', inPath, ME.message);
    end
end

function img = readGeometryNormalizedImage(filename)
    % Reads the already-processed 224x224 PNG
    img = imread(filename);
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    elseif size(img, 3) == 4
        img = img(:, :, 1:3);
    end
end
