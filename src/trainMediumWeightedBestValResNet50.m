% src/trainMediumWeightedBestValResNet50.m
% Trains a pretrained ResNet-50 network using medium (Power 0.50) class-weighted 
% cross-entropy, tracking validation loss over 10 epochs, and retaining the 
% best-performing checkpoint on the validation set.

function trainMediumWeightedBestValResNet50()
    % Setup paths relative to the project root
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    modelsDir = fullfile(projectDir, 'models', 'medium_weighted_resnet50_bestval');
    resultsDir = fullfile(projectDir, 'results', 'medium_weighted_bestval');
    if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
    if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end
    
    % 1. Load Datastores via our standard datastore creation script
    disp('Loading image datastores...');
    [imdsTrain, imdsVal, imdsTest] = createAPTOSDatastores();
    
    % Force serial reading of 1 image at a time to prevent RAM exhaustion
    imdsTrain.ReadSize = 1;
    imdsVal.ReadSize = 1;
    imdsTest.ReadSize = 1;
    
    % Verify categories map correctly
    classes = string(categories(imdsTrain.Labels));
    if ~all(ismember({'0', '1', '2', '3', '4'}, classes))
        error('Labels are not mapped to the expected 5 classes (0, 1, 2, 3, 4).');
    end
    
    % Calculate Medium (Power 0.50) Class Weights
    disp('Calculating medium class weights using fixed original counts...');
    countsTbl = countEachLabel(imdsTrain);
    classCounts = [1004; 209; 566; 108; 164];
    N = sum(classCounts);
    K = length(classes);
    
    % Formula exactly as requested:
    rawWeights = (N ./ classCounts).^0.50;
    classWeights = rawWeights / mean(rawWeights);
    
    % Print the calculated weights clearly
    disp(' ');
    disp('--- Calculated Medium (Power 0.50) Class Weights ---');
    for i = 1:K
        fprintf('Class %s (N_i = %-4d): Weight = %.4f\n', char(countsTbl.Label(i)), classCounts(i), classWeights(i));
    end
    disp(' ');
    
    % Resize images to 224x224x3
    disp('Creating augmentedImageDatastores to resize images to 224x224...');
    inputSize = [224, 224, 3];
    augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain);
    augimdsVal = augmentedImageDatastore(inputSize(1:2), imdsVal);
    
    disp('--- Pre-testing Validation Datastore for Corrupt Files ---');
    badFiles = 0;
    for vIdx = 1:numel(imdsVal.Files)
        fileToTest = imdsVal.Files{vIdx};
        try
            imfinfo(fileToTest);
        catch ME
            warning('Validation pre-test failed on image: %s. Error: %s', fileToTest, ME.message);
            badFiles = badFiles + 1;
        end
    end
    reset(imdsVal);
    reset(augimdsVal);
    fprintf('Validation pre-test complete. Bad files found: %d\n', badFiles);
    disp('--------------------------------------------------------');
    
    % Ensure validation happens exactly once per epoch for clean tracking
    numTrainImages = numel(imdsTrain.Files);
    batchSize = 4;
    itersPerEpoch = floor(numTrainImages / batchSize);
    
    % Load configured 5-class ResNet-50
    netPath = fullfile(projectDir, 'models', 'baseline_resnet50_initialized.mat');
    if ~exist(netPath, 'file')
        error('Initialized network not found at: %s. Run createBaselineNetwork.m first.', netPath);
    end
    disp('Loading configured pretrained ResNet-50...');
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    
    % Configure training options
    % Crucially, we set OutputNetwork to 'best-validation' so it returns the optimal network.
    disp('Setting up training options for 10 epochs with Best Validation Checkpoint...');
    opts = trainingOptions("adam", ...
        "InitialLearnRate", 1e-4, ... 
        "MaxEpochs", 10, ...           % Train for 10 epochs
        "MiniBatchSize", batchSize, ...      
        "ValidationData", augimdsVal, ...
        "ValidationFrequency", itersPerEpoch, ... % Validate exactly once per epoch
        "OutputNetwork", "best-validation", ...   % Return best validation loss model!
        "ExecutionEnvironment", "auto", ... 
        "DispatchInBackground", false, ...
        "Plots", "training-progress", ...
        "Verbose", true);
        
    % Define custom loss function handle for weighted crossentropy
    classWeightsRow = classWeights(:)'; 
    lossFcn = dlaccelerate(@(Y,T) crossentropy(Y,T,classWeightsRow,WeightsFormat="UC"));
    
    disp('Starting training...');
    [net, info] = trainnet(augimdsTrain, net, lossFcn, opts);
    
    % -------------------------------------------------------------
    % CRITICAL: Save the network and info IMMEDIATELY after training 
    % so that if summary parsing fails, the 10-epoch training isn't lost.
    % -------------------------------------------------------------
    saveNetPath = fullfile(modelsDir, 'bestval.mat');
    disp(['Saving BEST trained network to: ', saveNetPath]);
    save(saveNetPath, 'net');
    
    saveInfoPath = fullfile(resultsDir, 'training_history.mat');
    disp(['Saving training history to: ', saveInfoPath]);
    save(saveInfoPath, 'info');
    
    % Print Training & Validation Metrics robustly
    disp(' ');
    disp('--- Training Summary ---');
    
    history = info.TrainingHistory;
    vars = history.Properties.VariableNames;
    
    % In modern MATLAB (R2024a+), validation metrics are often stored in info.ValidationHistory
    if isfield(info, 'ValidationHistory') && ~isempty(info.ValidationHistory)
        valHistory = info.ValidationHistory;
        valVars = valHistory.Properties.VariableNames;
        
        valEpochCol = valVars{contains(valVars, 'Epoch', 'IgnoreCase', true)};
        valLossCol = valVars{contains(valVars, 'Loss', 'IgnoreCase', true)};
        trainEpochCol = vars{contains(vars, 'Epoch', 'IgnoreCase', true)};
        trainLossCol = vars{contains(vars, 'Loss', 'IgnoreCase', true)};
        
        valEpochs = valHistory.(valEpochCol);
        valLoss = valHistory.(valLossCol);
        
        fprintf('%-8s | %-15s | %-15s\n', 'Epoch', 'Training Loss', 'Validation Loss');
        fprintf('---------------------------------------------------\n');
        for i = 1:length(valEpochs)
            % Find the last iteration of the current validation epoch in training history
            tIdx = find(history.(trainEpochCol) == valEpochs(i), 1, 'last');
            if ~isempty(tIdx)
                tLoss = history.(trainLossCol)(tIdx);
            else
                tLoss = NaN;
            end
            fprintf('Epoch %-2d | %-15.5f | %-15.5f\n', valEpochs(i), tLoss, valLoss(i));
        end
        
        % Identify best epoch
        [bestValLoss, bestIdx] = min(valLoss);
        bestEpoch = valEpochs(bestIdx);
        finalValLoss = valLoss(end);
        
        disp(' ');
        fprintf('Best Validation Loss:  %.5f (Epoch %d)\n', bestValLoss, bestEpoch);
        fprintf('Final Validation Loss: %.5f (Epoch %d)\n', finalValLoss, valEpochs(end));
        
        if bestEpoch ~= valEpochs(end)
            disp('Notice: The network returned by trainnet is the BEST validation checkpoint, not the final epoch.');
        end
    else
        disp('No separate ValidationHistory found. Checking TrainingHistory...');
        disp('Available columns in TrainingHistory:');
        disp(vars);
    end
    
    disp('Best Validation training complete!');
end
