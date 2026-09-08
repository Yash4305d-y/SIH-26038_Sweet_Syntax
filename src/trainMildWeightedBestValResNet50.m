% src/trainMildWeightedBestValResNet50.m
% Trains a pretrained ResNet-50 network using mild square-root class-weighted 
% cross-entropy, tracking validation loss over 10 epochs, and retaining the 
% best-performing checkpoint on the validation set.

function trainMildWeightedBestValResNet50()
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
    
    % Resize images to 224x224x3
    disp('Creating augmentedImageDatastores to resize images to 224x224...');
    inputSize = [224, 224, 3];
    augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain);
    augimdsVal = augmentedImageDatastore(inputSize(1:2), imdsVal);
    
    % Ensure validation happens exactly once per epoch for clean tracking
    numTrainImages = numel(imdsTrain.Files);
    batchSize = 16;
    itersPerEpoch = floor(numTrainImages / batchSize);
    
    % Load configured 5-class ResNet-50
    netPath = fullfile(modelsDir, 'baseline_resnet50_initialized.mat');
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
    saveNetPath = fullfile(modelsDir, 'mild_weighted_resnet50_bestval.mat');
    disp(['Saving BEST trained network to: ', saveNetPath]);
    save(saveNetPath, 'net');
    
    saveInfoPath = fullfile(resultsDir, 'mild_weighted_bestval_training_history.mat');
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
