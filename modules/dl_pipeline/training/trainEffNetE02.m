% src/trainEffNetE02.m
% Trains a pretrained EfficientNet-b0 network for 5-class DR classification
% Tests data augmentation + weighted cross-entropy.

function trainEffNetE02()
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
    
    classes = string(categories(imdsTrain.Labels));
    
    % Calculate Class Weights
    countsTbl = countEachLabel(imdsTrain);
    N_i = countsTbl.Count;
    N = sum(N_i);
    K = length(classes);
    classWeights = N ./ (K .* N_i);
    classWeightsRow = classWeights(:)';
    
    inputSize = [224, 224, 3];
    
    imageAugmenter = imageDataAugmenter( ...
        'RandXReflection', true, ...
        'RandYReflection', true, ...
        'RandRotation', [-15 15], ...
        'RandXTranslation', [-10 10], ...
        'RandYTranslation', [-10 10]);
        
    augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain, 'DataAugmentation', imageAugmenter);
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
        
    lossFcn = dlaccelerate(@(Y,T) crossentropy(Y,T,classWeightsRow,WeightsFormat="UC"));
    
    disp('Starting training for EffNet-E02 (EfficientNet + Augmentation + Weighted Loss)...');
    [net, info] = trainnet(augimdsTrain, net, lossFcn, opts);
    
    saveEffNetE02Path = fullfile(modelsDir, 'effnet_e02_best.mat');
    save(saveEffNetE02Path, 'net');
    
    config = struct();
    config.experiment_id = 'EffNet-E02';
    config.model = 'EfficientNet-b0';
    config.pretrained = true;
    config.classes = 5;
    config.input_size = [224, 224, 3];
    config.loss = 'weighted_crossentropy';
    config.class_weights = classWeightsRow;
    config.optimizer = 'adam';
    config.learning_rate = 1e-4;
    config.batch_size = 16;
    config.epochs = 5;
    config.scheduler = 'none';
    config.seed = 42;
    config.dataset = 'APTOS';
    config.augmentation = 'standard_flip_rot_trans';
    config.normalization = 'efficientnet_default';
    config.checkpoint = 'effnet_e02_best.mat';
    config.notes = 'Final Candidate: EffNet-b0 + Augmentation + Class Weights';
    
    jsonStr = jsonencode(config, 'PrettyPrint', true);
    configPath = fullfile(resultsDir, 'effnet_e02_config.json');
    fid = fopen(configPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
    
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'evaluation'));
    evaluateExperiment('EffNet-E02', saveEffNetE02Path, config);
end
