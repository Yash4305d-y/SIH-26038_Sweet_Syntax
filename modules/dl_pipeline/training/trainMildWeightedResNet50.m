% src/trainMildWeightedResNet50.m
% Trains a pretrained ResNet-50 network for 5-class DR classification
% using a mild square-root class-weighted cross-entropy loss function.

function trainMildWeightedResNet50()
    % Setup paths relative to the project root
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    modelsDir = fullfile(projectDir, 'models');
    resultsDir = fullfile(projectDir, 'results');
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    % 1. Load Datastores via our standard datastore creation script
    disp('Loading image datastores...');
    [imdsTrain, imdsVal, ~] = createAPTOSDatastores();
    
    % Verify categories map correctly
    classes = string(categories(imdsTrain.Labels));
    if ~all(ismember({'0', '1', '2', '3', '4'}, classes))
        error('Labels are not mapped to the expected 5 classes (0, 1, 2, 3, 4).');
    end
    
    % Calculate Mild Square-Root Class Weights
    disp('Calculating mild class weights from training set ONLY...');
    countsTbl = countEachLabel(imdsTrain);
    N_i = countsTbl.Count;
    N = sum(N_i);
    K = length(classes);
    
    % Formula: rawWeight_i = sqrt(N / N_i)
    rawWeights = sqrt(N ./ N_i);
    % Normalize so mean is 1
    classWeights = rawWeights / mean(rawWeights);
    
    % Print the calculated weights clearly
    disp(' ');
    disp('--- Calculated Mild Class Weights ---');
    for i = 1:K
        fprintf('Class %s (N_i = %-4d): Weight = %.4f\n', char(countsTbl.Label(i)), N_i(i), classWeights(i));
    end
    disp(' ');
    
    % Save the calculated class weights
    weightsPath = fullfile(resultsDir, 'mild_class_weights.mat');
    save(weightsPath, 'classWeights', 'countsTbl', 'classes');
    disp(['Saved mild class weights to: ', weightsPath]);
    
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
    % R2026a API requires weights as the third positional argument with WeightsFormat
    % and we use dlaccelerate for performance.
    classWeightsRow = classWeights(:)'; 
    lossFcn = dlaccelerate(@(Y,T) crossentropy(Y,T,classWeightsRow,WeightsFormat="UC"));
    
    disp('Starting training with mild class-weighted cross-entropy (smoke test: 5 epochs)...');
    [net, info] = trainnet(augimdsTrain, net, lossFcn, opts);
    
    % Save trained network
    saveNetPath = fullfile(modelsDir, 'mild_weighted_resnet50_smoketest.mat');
    disp(['Saving trained mild weighted network to: ', saveNetPath]);
    save(saveNetPath, 'net');
    
    % Save training info
    saveInfoPath = fullfile(resultsDir, 'mild_weighted_training_history.mat');
    disp(['Saving mild weighted training history to: ', saveInfoPath]);
    save(saveInfoPath, 'info');
    
    disp('Mild weighted network training complete!');
end
