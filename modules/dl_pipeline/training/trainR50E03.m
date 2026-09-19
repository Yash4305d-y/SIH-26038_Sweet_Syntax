% src/trainR50E03.m
% Trains a pretrained ResNet-50 network for 5-class DR classification
% using a lower learning rate (1e-5) for R50-E03 experiment.

function trainR50E03()
    % Setup paths relative to the project root
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(fileparts(fileparts(srcDir)));
    
    % Ensure required directories exist
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    
    % Add required modules to path
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'data_prep'));
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    % Set random seed for reproducibility
    rng(42, 'twister');
    
    % 1-2. Load Datastores via our datastore creation script
    disp('Loading image datastores...');
    [imdsTrain, imdsVal, ~] = createAPTOSDatastores();
    
    % Verify categories are mapped correctly (sanity check)
    if ~all(ismember({'0', '1', '2', '3', '4'}, string(categories(imdsTrain.Labels))))
        error('Labels are not mapped to the expected 5 classes (0, 1, 2, 3, 4).');
    end
    
    % 3. Resize images to 224x224x3
    disp('Creating augmentedImageDatastores to resize images to 224x224...');
    inputSize = [224, 224, 3];
    augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain);
    augimdsVal = augmentedImageDatastore(inputSize(1:2), imdsVal);
    
    % 8. Load configured 5-class ResNet-50
    netPath = fullfile(modelsDir, 'baseline_resnet50_initialized.mat');
    if ~exist(netPath, 'file')
        error('Initialized network not found at: %s. Run createBaselineNetwork.m first.', netPath);
    end
    disp('Loading configured pretrained ResNet-50...');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    % 11-16. Configure training options
    disp('Setting up training options...');
    opts = trainingOptions("adam", ...
        "InitialLearnRate", 1e-5, ... % EXPERIMENT: lower learning rate
        "MaxEpochs", 5, ...
        "MiniBatchSize", 16, ...
        "ValidationData", augimdsVal, ...
        "ExecutionEnvironment", "auto", ... 
        "Plots", "training-progress", ...
        "Verbose", true);
        
    % 9-10. Train the network using modern trainnet workflow and cross-entropy loss
    disp('Starting training (R50-E03)...');
    [net, info] = trainnet(augimdsTrain, net, "crossentropy", opts);
    
    % 20. Save frozen R50-E03 artifacts
    saveR50Path = fullfile(modelsDir, 'r50_e03_best.mat');
    save(saveR50Path, 'net');
    
    saveR50Hist = fullfile(resultsDir, 'r50_e03_history.mat');
    save(saveR50Hist, 'info');
    
    % Save R50-E03 Config JSON
    config = struct();
    config.experiment_id = 'R50-E03';
    config.model = 'ResNet-50';
    config.pretrained = true;
    config.classes = 5;
    config.input_size = [224, 224, 3];
    config.loss = 'crossentropy';
    config.optimizer = 'adam';
    config.learning_rate = 1e-5;
    config.batch_size = 16;
    config.epochs = 5;
    config.scheduler = 'none';
    config.seed = 42;
    config.dataset = 'APTOS';
    config.augmentation = 'none';
    config.normalization = 'imagenet_default';
    config.checkpoint = 'r50_e03_best.mat';
    config.notes = 'Learning rate experiment (1e-5)';
    
    jsonStr = jsonencode(config, 'PrettyPrint', true);
    configPath = fullfile(resultsDir, 'r50_e03_config.json');
    fid = fopen(configPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
    
    disp('R50-E03 network training complete!');
end
