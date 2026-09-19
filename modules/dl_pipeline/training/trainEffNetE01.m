% src/trainEffNetE01.m
% Trains a pretrained EfficientNet-b0 network for 5-class DR classification

function trainEffNetE01()
    % Setup paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(fileparts(fileparts(srcDir)));
    
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'data_prep'));
    rng(42, 'twister');
    
    disp('Loading image datastores...');
    [imdsTrain, imdsVal, ~] = createAPTOSDatastores();
    
    inputSize = [224, 224, 3];
    augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain);
    augimdsVal = augmentedImageDatastore(inputSize(1:2), imdsVal);
    
    disp('Loading initialized EfficientNet-b0...');
    net = imagePretrainedNetwork("efficientnetb0", "NumClasses", 5, "Weights", "none");
    
    disp('Setting up training options...');
    opts = trainingOptions("adam", ...
        "InitialLearnRate", 1e-4, ...
        "MaxEpochs", 5, ...
        "MiniBatchSize", 16, ...
        "ValidationData", augimdsVal, ...
        "ExecutionEnvironment", "auto", ...
        "Plots", "training-progress", ...
        "Verbose", true);
        
    disp('Starting training for EffNet-E01 (baseline EfficientNet)...');
    [net, info] = trainnet(augimdsTrain, net, "crossentropy", opts);
    
    saveEffNetE01Path = fullfile(modelsDir, 'effnet_e01_best.mat');
    save(saveEffNetE01Path, 'net');
    
    config = struct();
    config.experiment_id = 'EffNet-E01';
    config.model = 'EfficientNet-b0';
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
    config.augmentation = 'none';
    config.normalization = 'efficientnet_default';
    config.checkpoint = 'effnet_e01_best.mat';
    config.notes = 'Baseline EfficientNet-b0';
    
    jsonStr = jsonencode(config, 'PrettyPrint', true);
    configPath = fullfile(resultsDir, 'effnet_e01_config.json');
    fid = fopen(configPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
    
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'evaluation'));
    evaluateExperiment('EffNet-E01', saveEffNetE01Path, config);
end
