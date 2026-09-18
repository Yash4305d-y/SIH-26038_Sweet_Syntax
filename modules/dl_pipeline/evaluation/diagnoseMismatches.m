function diagnoseMismatches()
    % Setup paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    modelsDir = fullfile(projectDir, 'models');
    
    netPath = fullfile(modelsDir, 'baseline_resnet50_smoketest.mat');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    imgName = '67f5d89da548.png';
    testImgDir = fullfile(projectDir, 'data', 'raw', 'test_images');
    trainImgDir = fullfile(projectDir, 'data', 'raw', 'train_images');
    
    fullPath = fullfile(trainImgDir, imgName);
    if ~exist(fullPath, 'file')
        fullPath = fullfile(testImgDir, imgName);
    end
    
    % Method 1: Original Evaluation Method
    imds = imageDatastore(fullPath);
    augimds = augmentedImageDatastore([224 224], imds);
    
    scores1 = minibatchpredict(net, augimds);
    [~, maxIdx1] = max(scores1, [], 2);
    fprintf('Scores1: %f %f %f %f %f\n', scores1);
    fprintf('Pred1: %d\n', maxIdx1 - 1);
    
    % Method 3: Using augimds output + minibatchpredict directly
    reset(augimds);
    dataTbl = read(augimds);
    imgAug = dataTbl.input{1};
    
    dlImgBatch = dlarray(single(imgAug), 'SSCB');
    scores3 = predict(net, dlImgBatch);
    scores3 = extractdata(scores3)';
    [~, maxIdx3] = max(scores3, [], 2);
    fprintf('Scores3 (predict on augimds output): %f %f %f %f %f\n', scores3);
    fprintf('Pred3: %d\n', maxIdx3 - 1);
    
    diff = max(abs(scores1(:) - scores3(:)));
    fprintf('Max score diff: %f\n', diff);
end
