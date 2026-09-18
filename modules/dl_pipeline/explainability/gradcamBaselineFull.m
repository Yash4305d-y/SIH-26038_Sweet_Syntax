% src/gradcamBaselineFull.m
% Generates Grad-CAM overlays for the COMPLETE 439-image test set
% using the Baseline ResNet-50 network.

function gradcamBaselineFull()
    % Setup Paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    outDir = fullfile(projectDir, 'outputs', 'gradcam', 'final');
    
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    
    % 1. Load Network
    netPath = fullfile(modelsDir, 'baseline_resnet50_smoketest.mat');
    disp(['Loading network: ', netPath]);
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    targetLayer = 'res5c_branch2c';
    
    % 2. Load Predictions
    predCsv = fullfile(resultsDir, 'baseline_test_predictions.csv');
    if ~exist(predCsv, 'file')
        error('Predictions file not found: %s', predCsv);
    end
    t = readtable(predCsv, 'PreserveVariableNames', true);
    numImgs = height(t);
    
    % Setup Data Paths
    dataDir = fullfile(projectDir, 'data');
    trainImgDir = fullfile(dataDir, 'raw', 'train_images');
    valImgDir = fullfile(dataDir, 'raw', 'val_images');
    testImgDir = fullfile(dataDir, 'raw', 'test_images');
    
    % Initialize Table Variables
    imgFiles = strings(numImgs, 1);
    gts = zeros(numImgs, 1);
    preds = zeros(numImgs, 1);
    correct = false(numImgs, 1);
    confs = zeros(numImgs, 1);
    meanActs = zeros(numImgs, 1);
    maxActs = zeros(numImgs, 1);
    actArea = zeros(numImgs, 1);
    distFromCenter = zeros(numImgs, 1);
    
    disp(['Starting full test set Grad-CAM generation for ', num2str(numImgs), ' images...']);
    
    for i = 1:numImgs
        imgId = string(t.id_code(i));
        gt = t.true_diagnosis(i);
        predOriginal = t.predicted_diagnosis(i);
        
        [~, name, ext] = fileparts(imgId);
        if isempty(char(ext)), ext = '.png'; end
        imgName = [char(name), char(ext)];
        
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
            warning('Skipping %s, file not found.', imgName);
            continue;
        end
        
        % Load and explicitly preprocess EXACTLY as original evaluation
        imds = imageDatastore(fullPath);
        augimds = augmentedImageDatastore([224 224], imds);
        dataTbl = read(augimds);
        imgAug = dataTbl.input{1};
        imgResized = imgAug; % Keep for overlay
        
        % Verify Prediction
        dlImg = dlarray(single(imgAug), 'SSC');
        scores = predict(net, dlImg);
        scores = extractdata(scores);
        [maxScore, maxIdx] = max(scores);
        predNew = maxIdx - 1;
        
        if predNew ~= predOriginal
            error('Mismatch on %s: Expected %d, got %d. Halting execution.', imgName, predOriginal, predNew);
        end
        
        % Grad-CAM
        try
            scoreMap = gradCAM(net, dlImg, maxIdx, 'FeatureLayer', targetLayer);
            mapResized = imresize(extractdata(scoreMap), [224, 224]);
            
            % Stats computation
            meanActs(i) = mean(mapResized(:));
            maxActs(i) = max(mapResized(:));
            
            mapNorm = mapResized - min(mapResized(:));
            if max(mapNorm(:)) > 0
                mapNorm = mapNorm / max(mapNorm(:));
            end
            
            % Activated Area > 30% intensity
            actArea(i) = sum(mapNorm(:) > 0.3) / numel(mapNorm);
            
            % Centroid calculation for border artifact detection
            [R, C] = ndgrid(1:224, 1:224);
            totalMass = sum(mapNorm(:));
            if totalMass > 0
                centR = sum(R(:) .* mapNorm(:)) / totalMass;
                centC = sum(C(:) .* mapNorm(:)) / totalMass;
                distFromCenter(i) = sqrt((centR - 112)^2 + (centC - 112)^2);
            else
                distFromCenter(i) = 0;
            end
            
            % Overlays
            cmap = jet(255);
            coloredMap = ind2rgb(uint8(mapNorm * 255), cmap);
            overlay = 0.5 * im2double(imgResized) + 0.5 * coloredMap;
            
            statusStr = 'correct';
            if gt ~= predNew, statusStr = 'wrong'; end
            
            % Create subdirectories for organization
            outSubDir = fullfile(outDir, statusStr, sprintf('class_%d', gt));
            if ~exist(outSubDir, 'dir'), mkdir(outSubDir); end
            
            outPath = fullfile(outSubDir, sprintf('%s_GT%d_Pred%d.png', name, gt, predNew));
            imwrite(overlay, outPath);
            
            imgFiles(i) = imgName;
            gts(i) = gt;
            preds(i) = predNew;
            correct(i) = (gt == predNew);
            confs(i) = maxScore;
            
        catch ME
            warning('Grad-CAM failed for %s: %s', imgName, ME.message);
        end
        
        if mod(i, 50) == 0
            fprintf('Processed %d/%d images...\n', i, numImgs);
        end
    end
    
    % Build Table
    summaryTable = table(imgFiles, gts, preds, correct, confs, ...
        repmat(string(targetLayer), numImgs, 1), meanActs, maxActs, actArea, distFromCenter, ...
        'VariableNames', {'ImageFilename', 'GroundTruth', 'Prediction', 'IsCorrect', ...
        'Confidence', 'TargetLayer', 'MeanActivation', 'MaxActivation', 'ActivatedAreaPct', 'CentroidDist'});
    
    % Save Full Table
    baseOutDir = outDir;
    if ~exist(baseOutDir, 'dir'), mkdir(baseOutDir); end
    
    writetable(summaryTable, fullfile(baseOutDir, 'gradcam_results.csv'));
    
    % Save Sub-tables
    correctTbl = summaryTable(summaryTable.IsCorrect == true, :);
    wrongTbl = summaryTable(summaryTable.IsCorrect == false, :);
    writetable(correctTbl, fullfile(baseOutDir, 'gradcam_correct.csv'));
    writetable(wrongTbl, fullfile(baseOutDir, 'gradcam_misclassified.csv'));
    
    for c = 0:4
        classTbl = summaryTable(summaryTable.GroundTruth == c, :);
        if ~isempty(classTbl)
            writetable(classTbl, fullfile(baseOutDir, sprintf('gradcam_class_%d.csv', c)));
        end
    end
    
    % Contact Sheet Creation
    fig = figure('Visible', 'off', 'Position', [100 100 1200 800]);
    for i = 1:5
        c = i - 1;
        idx = find(summaryTable.GroundTruth == c & summaryTable.IsCorrect == true, 1);
        if ~isempty(idx)
            subplot(2, 3, i);
            filePath = fullfile(outDir, 'correct', sprintf('class_%d', c), ...
                sprintf('%s_GT%d_Pred%d.png', strrep(summaryTable.ImageFilename(idx),'.png',''), c, c));
            if exist(filePath, 'file')
                imshow(imread(filePath));
                title(sprintf('Grade %d Correct', c));
            end
        end
    end
    
    [~, maxWrongIdx] = max(wrongTbl.Confidence);
    if ~isempty(maxWrongIdx)
        row = wrongTbl(maxWrongIdx, :);
        subplot(2, 3, 6);
        filePath = fullfile(outDir, 'wrong', sprintf('class_%d', row.GroundTruth), ...
            sprintf('%s_GT%d_Pred%d.png', strrep(row.ImageFilename,'.png',''), row.GroundTruth, row.Prediction));
        if exist(filePath, 'file')
            imshow(imread(filePath));
            title(sprintf('High Conf Wrong:\nGT%d Pred%d', row.GroundTruth, row.Prediction));
        end
    end
    
    saveas(fig, fullfile(baseOutDir, 'representative_contact_sheet.png'));
    close(fig);
    
    disp('Grad-CAM Full Scale generation complete!');
end
