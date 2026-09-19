% src/trainR50E01.m
% Trains a pretrained ResNet-50 network for 5-class DR classification
% using a class-weighted cross-entropy loss function to address class imbalance.
% Strictly mirrors R50-V1 settings (seed 42, 5 epochs, batch 16, lr 1e-4).

function trainR50E01()
    % Setup paths relative to the project root
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(fileparts(fileparts(srcDir)));
    
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    % Add required modules to path
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'data_prep'));
    
    % Set random seed for exact reproducibility matching R50-V1
    rng(42, 'twister');
    
    % 1. Load Datastores via our standard datastore creation script
    disp('Loading image datastores...');
    [imdsTrain, imdsVal, ~] = createAPTOSDatastores();
    
    % Verify categories map correctly
    classes = string(categories(imdsTrain.Labels));
    if ~all(ismember({'0', '1', '2', '3', '4'}, classes))
        error('Labels are not mapped to the expected 5 classes (0, 1, 2, 3, 4).');
    end
    
    % Calculate Balanced Inverse-Frequency Class Weights
    disp('Calculating balanced class weights from training set ONLY...');
    countsTbl = countEachLabel(imdsTrain);
    N_i = countsTbl.Count;
    N = sum(N_i);
    K = length(classes);
    
    % Formula: weight_i = N / (K * N_i)
    classWeights = N ./ (K .* N_i);
    
    disp(' ');
    disp('--- Calculated Class Weights ---');
    for i = 1:K
        fprintf('Class %s (N_i = %-4d): Weight = %.4f\n', char(countsTbl.Label(i)), N_i(i), classWeights(i));
    end
    disp(' ');
    
    % Resize images to 224x224x3
    disp('Creating augmentedImageDatastores to resize images to 224x224...');
    inputSize = [224, 224, 3];
    augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain);
    augimdsVal = augmentedImageDatastore(inputSize(1:2), imdsVal);
    
    % Load configured 5-class ResNet-50
    netPath = fullfile(modelsDir, 'baseline_resnet50_initialized.mat');
    if ~exist(netPath, 'file')
        error('Initialized network not found at: %s. Run createBaselineNetwork.m first.', netPath);
    end
    disp('Loading configured pretrained ResNet-50...');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    % Configure identical training options as baseline
    disp('Setting up training options...');
    opts = trainingOptions("adam", ...
        "InitialLearnRate", 1e-4, ... % Conservative LR for transfer learning
        "MaxEpochs", 5, ...           % Smoke test
        "MiniBatchSize", 16, ...      % Batch size identical to baseline
        "ValidationData", augimdsVal, ...
        "ExecutionEnvironment", "auto", ... % Uses GPU if available
        "Plots", "training-progress", ...
        "Verbose", true);
        
    % Define custom loss function handle for weighted crossentropy
    classWeightsRow = classWeights(:)'; 
    lossFcn = dlaccelerate(@(Y,T) crossentropy(Y,T,classWeightsRow,WeightsFormat="UC"));
    
    disp('Starting training for R50-E01 (weighted cross-entropy)...');
    [net, info] = trainnet(augimdsTrain, net, lossFcn, opts);
    
    % Save trained network (R50-E01 artifacts)
    saveR50E01Path = fullfile(modelsDir, 'r50_e01_best.mat');
    disp(['Saving trained network to: ', saveR50E01Path]);
    save(saveR50E01Path, 'net');
    
    % Save training info
    saveR50E01Hist = fullfile(resultsDir, 'r50_e01_history.mat');
    disp(['Saving training history to: ', saveR50E01Hist]);
    save(saveR50E01Hist, 'info');
    
    % Save R50-E01 Config JSON
    config = struct();
    config.experiment_id = 'R50-E01';
    config.model = 'ResNet-50';
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
    config.augmentation = 'none';
    config.normalization = 'imagenet_default';
    config.checkpoint = 'r50_e01_best.mat';
    config.notes = 'Class-weighted cross-entropy';
    
    jsonStr = jsonencode(config, 'PrettyPrint', true);
    configPath = fullfile(resultsDir, 'r50_e01_config.json');
    fid = fopen(configPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonStr);
        fclose(fid);
    end
    
    disp('R50-E01 network training complete!');
    
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'evaluation'));
    evaluateExperiment('R50-E01', saveR50E01Path, config);
end
