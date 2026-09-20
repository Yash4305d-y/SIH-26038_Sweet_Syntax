function verifyFix()
    % Setup paths
    projectDir = getProjectRoot();
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    
    netPath = fullfile(modelsDir, 'baseline_resnet50_smoketest.mat');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    testImgDir = fullfile(projectDir, 'data', 'raw', 'test_images');
    trainImgDir = fullfile(projectDir, 'data', 'raw', 'train_images');
    valImgDir = fullfile(projectDir, 'data', 'raw', 'val_images');
    
    mismatched = ["67f5d89da548.png", "76be29bb30b2.png", "92d8a7c8e718.png", ...
        "ab1c20a94f3f.png", "b94c58d063bf.png", "c102db7634d8.png", "c9ea9d5eab65.png"];
        
    expectedPreds = [2, 1, 2, 2, 4, 2, 2];
    
    success = true;
    
    for i = 1:length(mismatched)
        imgName = mismatched(i);
        expected = expectedPreds(i);
        
        fullPath = fullfile(trainImgDir, char(imgName));
        if ~exist(fullPath, 'file'), fullPath = fullfile(valImgDir, char(imgName)); end
        if ~exist(fullPath, 'file'), fullPath = fullfile(testImgDir, char(imgName)); end
        
        imds = imageDatastore(fullPath);
        augimds = augmentedImageDatastore([224 224], imds);
        dataTbl = read(augimds);
        imgAug = dataTbl.input{1};
        
        dlImg = dlarray(single(imgAug), 'SSC');
        scores = predict(net, dlImg);
        scores = extractdata(scores);
        [~, maxIdx] = max(scores);
        predNew = maxIdx - 1;
        
        if predNew ~= expected
            fprintf('FAILED: %s -> Expected %d, got %d\n', imgName, expected, predNew);
            success = false;
        else
            fprintf('SUCCESS: %s -> Output %d matched expected.\n', imgName, predNew);
        end
    end
    
    if success
        disp('All 7 mismatches successfully resolved in verification.');
    end
end
