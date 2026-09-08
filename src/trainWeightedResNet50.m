% src/trainWeightedResNet50.m
% Trains a pretrained ResNet-50 network for 5-class DR classification
% using a class-weighted cross-entropy loss function to address class imbalance.

function trainWeightedResNet50()
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
    
    % 6-8. Calculate Balanced Inverse-Frequency Class Weights
    disp('Calculating balanced class weights from training set ONLY...');
    countsTbl = countEachLabel(imdsTrain);
    N_i = countsTbl.Count;
    N = sum(N_i);
    K = length(classes);
    
    % Formula: weight_i = N / (K * N_i)
    classWeights = N ./ (K .* N_i);
    
    % 18. Print the calculated weights clearly
    disp(' ');
    disp('--- Calculated Class Weights ---');
    for i = 1:K
        fprintf('Class %s (N_i = %-4d): Weight = %.4f\n', char(countsTbl.Label(i)), N_i(i), classWeights(i));
    end
    disp(' ');
    
    % 17. Save the calculated class weights
    weightsPath = fullfile(resultsDir, 'class_weights.mat');
    save(weightsPath, 'classWeights', 'countsTbl', 'classes');
    disp(['Saved class weights to: ', weightsPath]);
    
    % 3. Resize images to 224x224x3
    % 11. No medical preprocessing, no augmentation
    disp('Creating augmentedImageDatastores to resize images to 224x224...');
    inputSize = [224, 224, 3];
    augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain);
    augimdsVal = augmentedImageDatastore(inputSize(1:2), imdsVal);
    
    % 2. Load configured 5-class ResNet-50
    netPath = fullfile(modelsDir, 'baseline_resnet50_initialized.mat');
    if ~exist(netPath, 'file')
        error('Initialized network not found at: %s. Run createBaselineNetwork.m first.', netPath);
    end
    disp('Loading configured pretrained ResNet-50...');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    % 4, 12-14. Configure identical training options as baseline
    disp('Setting up training options...');
    opts = trainingOptions("adam", ...
        "InitialLearnRate", 1e-4, ... % Conservative LR for transfer learning
        "MaxEpochs", 5, ...           % Smoke test
        "MiniBatchSize", 16, ...      % Batch size identical to baseline
        "ValidationData", augimdsVal, ...
        "ExecutionEnvironment", "auto", ... % Uses GPU if available
        "Plots", "training-progress", ...
        "Verbose", true);
        
    % 9. Define custom loss function handle for weighted crossentropy
    % R2026a API requires weights as the third positional argument with WeightsFormat
    % and we use dlaccelerate for performance.
    classWeightsRow = classWeights(:)'; 
    lossFcn = dlaccelerate(@(Y,T) crossentropy(Y,T,classWeightsRow,WeightsFormat="UC"));
    
    disp('Starting training with class-weighted cross-entropy (smoke test: 5 epochs)...');
    [net, info] = trainnet(augimdsTrain, net, lossFcn, opts);
    
    % 15. Save trained network
    saveNetPath = fullfile(modelsDir, 'weighted_resnet50_smoketest.mat');
    disp(['Saving trained weighted network to: ', saveNetPath]);
    save(saveNetPath, 'net');
    
    % 16. Save training info
    saveInfoPath = fullfile(resultsDir, 'weighted_training_history.mat');
    disp(['Saving weighted training history to: ', saveInfoPath]);
    save(saveInfoPath, 'info');
    
    disp('Weighted network training complete!');
end
