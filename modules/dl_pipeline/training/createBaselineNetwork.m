% createBaselineNetwork.m
% Loads a pretrained ResNet-50 network and configures it for 
% 5-class Diabetic Retinopathy classification using the modern
% dlnetwork and trainnet workflow (R2026a API).

function net = createBaselineNetwork()
    disp('Loading pretrained ResNet-50 and configuring for 5 classes...');
    
    % Use modern imagePretrainedNetwork syntax to load resnet50
    % and automatically replace the final fully connected layer
    % to output 5 classes for our DR classification task.
    % This returns an uninitialized dlnetwork without a deprecated 
    % classificationLayer, perfectly suited for the trainnet workflow.
    net = imagePretrainedNetwork("resnet50", "NumClasses", 5);
    
    % Display the resulting network architecture
    disp('--- Configured Network Architecture ---');
    disp(net);
    
    % Verify the output size of the network
    % We loop through the layers to find the final fully connected layer
    layerArray = net.Layers;
    fcOutputs = [];
    
    if iscell(layerArray)
        for i = 1:numel(layerArray)
            if isa(layerArray{i}, 'nnet.cnn.layer.FullyConnectedLayer')
                fcOutputs = layerArray{i}.OutputSize;
            end
        end
    else
        for i = 1:numel(layerArray)
            if isa(layerArray(i), 'nnet.cnn.layer.FullyConnectedLayer')
                fcOutputs = layerArray(i).OutputSize;
            end
        end
    end
    
    if ~isempty(fcOutputs)
        fprintf('Verified: Final fully connected layer has %d outputs.\n', fcOutputs);
        if fcOutputs ~= 5
            error('The network does not have exactly 5 outputs. Check the configuration.');
        end
    else
        warning('Could not find a fully connected layer to verify the number of outputs. Please manually inspect the network.');
    end
    
    % Determine the project root directory and create 'models' directory
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    modelsDir = fullfile(projectDir, 'models');
    
    if ~exist(modelsDir, 'dir')
        disp(['Creating models directory at: ', modelsDir]);
        mkdir(modelsDir);
    end
    
    % Save the initialized network
    savePath = fullfile(modelsDir, 'baseline_resnet50_initialized.mat');
    disp(['Saving the configured network to: ', savePath]);
    save(savePath, 'net');
    
    disp('Baseline network creation complete!');
end
