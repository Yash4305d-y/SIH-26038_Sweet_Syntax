% gradcamBaselinePrototype.m
% Generates a Grad-CAM prototype for the Baseline ResNet-50 network.

function gradcamBaselinePrototype()
    % Setup Paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    outDir = fullfile(resultsDir, 'gradcam', 'prototype');
    
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    
    % 1. Load trained baseline ResNet-50
    netPath = fullfile(modelsDir, 'baseline_resnet50_smoketest.mat');
    disp(['Loading network: ', netPath]);
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    % Verify network
    if ~isa(net, 'dlnetwork')
        error('Expected a dlnetwork.');
    end
    
    % Verify Target Layer
    targetLayer = 'res5c_branch2c';
    if ~any(strcmp({net.Layers.Name}, targetLayer))
        error('Target layer %s not found in network.', targetLayer);
    end
    
    % Verify output size is 5
    if net.Layers(end-1).OutputSize ~= 5
        error('Expected 5 classes in final FC layer.');
    end
    
    % 2. Load Predictions
    predCsv = fullfile(resultsDir, 'baseline_test_predictions.csv');
    disp(['Loading predictions: ', predCsv]);
    if ~exist(predCsv, 'file')
        error('baseline_test_predictions.csv not found.');
    end
    t = readtable(predCsv, 'PreserveVariableNames', true);
    
    % Setup paths to test images
    dataDir = fullfile(projectDir, 'data');
    trainImgDir = fullfile(dataDir, 'raw', 'train_images');
    valImgDir = fullfile(dataDir, 'raw', 'val_images');
    testImgDir = fullfile(dataDir, 'raw', 'test_images');
    
    % 3. Select subset (1 correct per class, 3 misclassified)
    disp('Selecting representative images...');
    classes = [0, 1, 2, 3, 4];
    selectedIdx = [];
    
    % Find 1 correct prediction for each class
    for c = classes
        idx = find(t.true_diagnosis == c & t.predicted_diagnosis == c, 1);
        if ~isempty(idx)
            selectedIdx = [selectedIdx; idx];
        else
            warning('No correctly classified image for class %d found.', c);
        end
    end
    
    % Find 3 misclassified predictions
    missIdx = find(t.true_diagnosis ~= t.predicted_diagnosis);
    if length(missIdx) > 3
        missIdx = missIdx(1:3);
    end
    selectedIdx = [selectedIdx; missIdx];
    
    selectedIdx = unique(selectedIdx);
    numSelected = length(selectedIdx);
    fprintf('Selected %d images for prototype.\n', numSelected);
    
    summaryTable = table('Size', [numSelected, 6], ...
        'VariableTypes', {'string', 'double', 'double', 'logical', 'double', 'string'}, ...
        'VariableNames', {'ImageFilename', 'GroundTruth', 'Prediction', 'IsCorrect', 'Confidence', 'TargetLayer'});
    
    for i = 1:numSelected
        idx = selectedIdx(i);
        imgId = string(t.id_code(idx));
        gt = t.true_diagnosis(idx);
        predOriginal = t.predicted_diagnosis(idx);
        isCorrect = (gt == predOriginal);
        
        [~, name, ext] = fileparts(imgId);
        if isempty(char(ext)), ext = '.png'; end
        imgName = [char(name), char(ext)];
        
        % Locate physical file
        fullPathTrain = fullfile(trainImgDir, imgName);
        fullPathVal = fullfile(valImgDir, imgName);
        fullPathTest = fullfile(testImgDir, imgName);
        
        if exist(fullPathTrain, 'file')
            fullPath = fullPathTrain;
        elseif exist(fullPathVal, 'file')
            fullPath = fullPathVal;
        elseif exist(fullPathTest, 'file')
            fullPath = fullPathTest;
        else
            warning('Could not find image %s. Skipping.', imgName);
            continue;
        end
        
        % 4. Load and apply exact Baseline preprocessing (resizing to 224x224x3)
        img = imread(fullPath);
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        end
        imgResized = imresize(img, [224, 224]);
        
        % 5. Verify Prediction matches predictions.csv
        % Convert to formatted dlarray for prediction
        dlImg = dlarray(single(imgResized), 'SSC');
        scores = predict(net, dlImg);
        scores = extractdata(scores);
        [maxScore, maxIdx] = max(scores);
        predNew = maxIdx - 1; % 0-indexed classes
        
        if predNew ~= predOriginal
            error('Prediction mismatch on %s! Expected %d, got %d.', imgName, predOriginal, predNew);
        end
        
        % 6. Generate Grad-CAM 
        try
            % We specify the target layer explicitly as requested
            scoreMap = gradCAM(net, dlImg, maxIdx, 'FeatureLayer', targetLayer);
            
            % Resize map to match original image dimensions for overlay
            mapResized = imresize(extractdata(scoreMap), [224, 224]);
            
            % Normalize map
            mapResized = mapResized - min(mapResized(:));
            if max(mapResized(:)) > 0
                mapResized = mapResized / max(mapResized(:));
            end
            
            % Apply colormap and overlay
            cmap = jet(255);
            coloredMap = ind2rgb(uint8(mapResized * 255), cmap);
            overlay = 0.5 * im2double(imgResized) + 0.5 * coloredMap;
            
            % Save to disk
            statusStr = 'correct';
            if ~isCorrect, statusStr = 'wrong'; end
            outName = sprintf('%s_GT%d_Pred%d_%s.png', name, gt, predNew, statusStr);
            outPath = fullfile(outDir, outName);
            imwrite(overlay, outPath);
            
            fprintf('Processed %s successfully.\n', outName);
            
            summaryTable.ImageFilename(i) = imgName;
            summaryTable.GroundTruth(i) = gt;
            summaryTable.Prediction(i) = predNew;
            summaryTable.IsCorrect(i) = isCorrect;
            summaryTable.Confidence(i) = maxScore;
            summaryTable.TargetLayer(i) = targetLayer;
            
        catch ME
            warning('Grad-CAM failed for %s: %s', imgName, ME.message);
        end
    end
    
    % 8. Create contact sheet for easy visual review
    disp('Creating contact sheet...');
    files = dir(fullfile(outDir, '*.png'));
    % exclude any previous contact sheet
    files = files(~contains({files.name}, 'contact_sheet'));
    
    numFiles = length(files);
    if numFiles > 0
        cols = 4;
        rows = ceil(numFiles / cols);
        fig = figure('Visible', 'off', 'Position', [100 100 800 600]);
        for i = 1:numFiles
            subplot(rows, cols, i);
            I = imread(fullfile(outDir, files(i).name));
            imshow(I);
            title(strrep(files(i).name, '.png', ''), 'Interpreter', 'none', 'FontSize', 6);
        end
        saveas(fig, fullfile(outDir, 'contact_sheet.png'));
        close(fig);
    end
    
    % Save summary table
    summaryPath = fullfile(outDir, 'prototype_summary.csv');
    writetable(summaryTable, summaryPath);
    disp(['Summary saved to: ', summaryPath]);
    disp('Grad-CAM Prototype generation complete!');
end
