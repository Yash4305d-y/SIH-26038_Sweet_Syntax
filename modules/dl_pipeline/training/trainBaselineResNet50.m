% src/trainBaselineResNet50.m
% Trains a pretrained ResNet-50 network for 5-class DR classification
% using the modern trainnet API.

function trainBaselineResNet50()
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
    
    % Set random seed for reproducibility (R50-V1)
    rng(42, 'twister');
    
    % 1-2. Load Datastores via our datastore creation script
    disp('Loading image datastores...');
    [imdsTrain, imdsVal, ~] = createAPTOSDatastores();
    
    % Verify categories are mapped correctly (sanity check)
    if ~all(ismember({'0', '1', '2', '3', '4'}, string(categories(imdsTrain.Labels))))
        error('Labels are not mapped to the expected 5 classes (0, 1, 2, 3, 4).');
    end
    
    % 3. Resize images to 224x224x3
    % 4-7. No preprocessing, CLAHE, or aggressive augmentation used here.
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
        "InitialLearnRate", 1e-4, ... % Conservative LR for transfer learning
        "MaxEpochs", 5, ...           % Smoke test
        "MiniBatchSize", 16, ...      % Batch size as requested
        "ValidationData", augimdsVal, ...
        "ExecutionEnvironment", "auto", ... % Uses GPU if available
        "Plots", "training-progress", ...
        "Verbose", true);
        
    % 9-10. Train the network using modern trainnet workflow and cross-entropy loss
    disp('Starting training (smoke test: exactly 5 epochs)...');
    [net, info] = trainnet(augimdsTrain, net, "crossentropy", opts);
    
    % 18. Save trained network
    saveNetPath = fullfile(modelsDir, 'baseline_resnet50_smoketest.mat');
    disp(['Saving trained network to: ', saveNetPath]);
    save(saveNetPath, 'net');
    
    % 19. Save training info
    saveInfoPath = fullfile(resultsDir, 'baseline_training_history.mat');
    disp(['Saving training history to: ', saveInfoPath]);
    save(saveInfoPath, 'info');
    
    % 20. Save frozen R50-V1 artifacts
    saveR50Path = fullfile(modelsDir, 'r50_v1_best.mat');
    save(saveR50Path, 'net');
    
    saveR50Hist = fullfile(resultsDir, 'r50_v1_history.mat');
    save(saveR50Hist, 'info');
    
    % Save R50-V1 Config JSON
    config = struct();
    config.experiment_id = 'R50-V1';
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
    config.augmentation = 'none';
    config.normalization = 'imagenet_default';
    
    jsonStr = jsonencode(config, 'PrettyPrint', true);
    configPath = fullfile(resultsDir, 'r50_v1_config.json');
    fid = fopen(configPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
    
    disp('Baseline network training complete!');
end
