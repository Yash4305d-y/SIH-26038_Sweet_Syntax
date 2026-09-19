% src/trainR50E02.m
% Trains a pretrained ResNet-50 network for 5-class DR classification
% Tests data augmentation.

function trainR50E02()
    % Setup paths relative to the project root
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(fileparts(fileparts(srcDir)));
    
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'data_prep'));
    rng(42, 'twister');
    
    disp('Loading image datastores...');
    [imdsTrain, imdsVal, ~] = createAPTOSDatastores();
    
    classes = string(categories(imdsTrain.Labels));
    
    disp('Creating augmentedImageDatastores with aggressive augmentation for training...');
    inputSize = [224, 224, 3];
    
    imageAugmenter = imageDataAugmenter( ...
        'RandXReflection', true, ...
        'RandYReflection', true, ...
        'RandRotation', [-15 15], ...
        'RandXTranslation', [-10 10], ...
        'RandYTranslation', [-10 10]);
        
    augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain, 'DataAugmentation', imageAugmenter);
    augimdsVal = augmentedImageDatastore(inputSize(1:2), imdsVal); % No aug on validation
    
    netPath = fullfile(modelsDir, 'baseline_resnet50_initialized.mat');
    disp('Loading configured pretrained ResNet-50...');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    disp('Setting up training options...');
    opts = trainingOptions("adam", ...
        "InitialLearnRate", 1e-4, ...
        "MaxEpochs", 5, ...
        "MiniBatchSize", 16, ...
        "ValidationData", augimdsVal, ...
        "ExecutionEnvironment", "auto", ...
        "Plots", "training-progress", ...
        "Verbose", true);
        
    disp('Starting training for R50-E02 (standard cross-entropy + augmentation)...');
    [net, info] = trainnet(augimdsTrain, net, "crossentropy", opts);
    
    saveR50E02Path = fullfile(modelsDir, 'r50_e02_best.mat');
    save(saveR50E02Path, 'net');
    saveR50E02Hist = fullfile(resultsDir, 'r50_e02_history.mat');
    save(saveR50E02Hist, 'info');
    
    config = struct();
    config.experiment_id = 'R50-E02';
    config.model = 'ResNet-50';
    config.pretrained = true;
    config.classes = 5;
    config.input_size = [224, 224, 3];
    config.loss = 'crossentropy';
    config.optimizer = 'adam';
    config.learning_rate = 1e-4;
    config.batch_size = 16;
    config.epochs = 5;
    config.scheduler = 'none';
    config.seed = 42;
    config.dataset = 'APTOS';
    config.augmentation = 'standard_flip_rot_trans';
    config.normalization = 'imagenet_default';
    config.checkpoint = 'r50_e02_best.mat';
    config.notes = 'Data augmentation added';
    
    jsonStr = jsonencode(config, 'PrettyPrint', true);
    configPath = fullfile(resultsDir, 'r50_e02_config.json');
    fid = fopen(configPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
    
    disp('R50-E02 network training complete!');
    
    % Evaluate
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'evaluation'));
    evaluateExperiment('R50-E02', saveR50E02Path, config);
end
