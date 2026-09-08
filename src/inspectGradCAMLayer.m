% src/inspectGradCAMLayer.m
function inspectGradCAMLayer()
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    netPath = fullfile(projectDir, 'models', 'baseline_resnet50_smoketest.mat');
    
    if ~exist(netPath, 'file')
        error('Model not found at %s', netPath);
    end
    
    disp('Loading the Baseline ResNet-50 network...');
    loaded = load(netPath, 'net');
    net = loaded.net;
    
    fprintf('Network class: %s\n', class(net));
    
    % Get input layer
    inputLayer = net.Layers(1);
    fprintf('Input Layer Name: %s\n', inputLayer.Name);
    fprintf('Input Size: [%d, %d, %d]\n', inputLayer.InputSize(1), inputLayer.InputSize(2), inputLayer.InputSize(3));
    
    % Find all Convolutional layers
    layers = net.Layers;
    convLayers = [];
    
    for i = 1:numel(layers)
        if contains(class(layers(i)), 'Convolution2DLayer')
            convLayers = [convLayers; i];
        end
    end
    
    % Print last 5 conv layers
    disp('--- Last 5 Convolutional Layers ---');
    for i = max(1, length(convLayers)-4):length(convLayers)
        idx = convLayers(i);
        layer = layers(idx);
        fprintf('Layer %d: Name = %s, Type = %s\n', idx, layer.Name, class(layer));
    end
    
    lastConvIdx = convLayers(end);
    fprintf('\nSelected Grad-CAM Layer (Last Conv Layer): %s\n', layers(lastConvIdx).Name);
    
    % Print layers after the last conv layer
    disp('--- Layers after the last Convolutional Layer ---');
    for i = lastConvIdx+1:numel(layers)
        layer = layers(i);
        fprintf('Layer %d: Name = %s, Type = %s\n', i, layer.Name, class(layer));
        if isa(layer, 'nnet.cnn.layer.FullyConnectedLayer')
            fprintf('  -> FullyConnected Output Size: %d\n', layer.OutputSize);
        end
    end
end
