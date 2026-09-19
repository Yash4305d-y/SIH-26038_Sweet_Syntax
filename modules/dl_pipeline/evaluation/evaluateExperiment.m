function evaluateExperiment(experimentId, netPath, config)
    % Evaluates a given network and appends to the registry
    % config is a struct containing experiment details for the CSV

    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(fileparts(fileparts(srcDir)));
    
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    if ~exist(netPath, 'file')
        error('Trained network not found at %s.', netPath);
    end
    
    disp(['Loading trained network for ' experimentId '...']);
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    dataDir = fullfile(projectDir, 'data');
    splitsDir = fullfile(dataDir, 'splits');
    imgDir = fullfile(dataDir, 'raw', 'test_images');
    testCsvFile = fullfile(splitsDir, 'test_split.csv');
    
    testData = readtable(testCsvFile, 'PreserveVariableNames', true);
    numSamples = height(testData);
    
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
        paths(i) = fullPath;
    end
    
    classes = {'0', '1', '2', '3', '4'};
    labels = categorical(string(testData.diagnosis), classes);
    imdsTest = imageDatastore(paths, 'Labels', labels);
    
    inputSize = config.input_size;
    augimdsTest = augmentedImageDatastore([inputSize(1) inputSize(2)], imdsTest);
    
    disp('Running predictions on test set...');
    scores = minibatchpredict(net, augimdsTest);
    
    [~, maxIdx] = max(scores, [], 2);
    YPred = categorical(classes(maxIdx)', classes);
    YTest = imdsTest.Labels;
    
    O = confusionmat(YTest, YPred, 'Order', classes);
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
    
    support = sum(O, 2)';
    if sum(support) > 0
        weightedF1 = sum(f1 .* support) / sum(support);
    else
        weightedF1 = 0;
    end
    
    disp(['--- ' experimentId ' Evaluation Metrics ---']);
    fprintf('Overall Accuracy: %.4f\n', accuracy);
    fprintf('Macro F1 Score:   %.4f\n', macroF1);
    
    fig = figure('Name', 'Confusion Matrix', 'Visible', 'off');
    cm = confusionchart(YTest, YPred);
    cm.Title = [experimentId ' Test Confusion Matrix'];
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
    
    cmExpPath = fullfile(resultsDir, [lower(strrep(experimentId, '-', '_')) '_confusion_matrix.png']);
    saveas(fig, cmExpPath);
    close(fig);
    
    expMetrics = struct();
    expMetrics.experiment_id = experimentId;
    expMetrics.accuracy = accuracy;
    expMetrics.macro_f1 = macroF1;
    expMetrics.weighted_f1 = weightedF1;
    expMetrics.precision = mean(precision);
    expMetrics.recall = mean(recall);
    
    metricsJsonStr = jsonencode(expMetrics, 'PrettyPrint', true);
    metricsJsonPath = fullfile(resultsDir, [lower(strrep(experimentId, '-', '_')) '_metrics.json']);
    fid = fopen(metricsJsonPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', metricsJsonStr);
        fclose(fid);
    end
    
    docsDir = fullfile(projectDir, 'docs', 'experiments');
    if ~exist(docsDir, 'dir'), mkdir(docsDir); end
    registryPath = fullfile(docsDir, 'experiment_registry.csv');
    
    precStr = sprintf('%.4f', expMetrics.precision);
    recStr = sprintf('%.4f', expMetrics.recall);
    accStr = sprintf('%.4f', expMetrics.accuracy);
    mf1Str = sprintf('%.4f', expMetrics.macro_f1);
    wf1Str = sprintf('%.4f', expMetrics.weighted_f1);
    
    inputSizeStr = sprintf('%dx%dx%d', config.input_size(1), config.input_size(2), config.input_size(3));
    
    csvRow = sprintf('%s,%s,%s,%s,%s,%s,%s,%d,%d,%s,%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,NaN,NaN,%s,completed,%s\n', ...
        experimentId, config.model, 'true', inputSizeStr, config.loss, config.optimizer, ...
        '1e-4', config.batch_size, config.epochs, config.augmentation, 'none', config.seed, ...
        'APTOS', 'train_split', 'val_split', 'test_split', ...
        accStr, mf1Str, wf1Str, precStr, recStr, config.checkpoint, config.notes);
        
    fidCsv = fopen(registryPath, 'a');
    if fidCsv ~= -1
        fprintf(fidCsv, '%s', csvRow);
        fclose(fidCsv);
    end
    disp('Evaluation script complete!');
end
