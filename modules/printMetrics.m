% printMetrics.m
function printMetrics(experimentId, netPath, configPath)
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    fid = fopen(configPath, 'r');
    raw = fread(fid, inf);
    str = char(raw');
    fclose(fid);
    config = jsondecode(str);
    
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
    
    scores = minibatchpredict(net, augimdsTest);
    [~, maxIdx] = max(scores, [], 2);
    YPred = categorical(classes(maxIdx)', classes);
    YTest = imdsTest.Labels;
    
    O = confusionmat(YTest, YPred, 'Order', classes);
    TP = diag(O);
    FP = sum(O, 1)' - TP;
    FN = sum(O, 2) - TP;
    
    precision = TP ./ (TP + FP); precision(isnan(precision)) = 0;
    recall = TP ./ (TP + FN); recall(isnan(recall)) = 0;
    f1 = 2 .* (precision .* recall) ./ (precision + recall); f1(isnan(f1)) = 0;
    
    macroF1 = mean(f1);
    accuracy = sum(TP) / numSamples;
    
    support = sum(O, 2)';
    weightedF1 = sum(f1 .* support') / sum(support);
    
    fprintf('Accuracy: %.4f\n', accuracy);
    fprintf('MacroF1: %.4f\n', macroF1);
    fprintf('WeightedF1: %.4f\n', weightedF1);
    for i = 1:5
        fprintf('Grade %d - Precision: %.4f, Recall: %.4f, F1: %.4f\n', i-1, precision(i), recall(i), f1(i));
    end
end
