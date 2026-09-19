% src/runDRInference.m
% Role 1 ML Inference Interface - Baseline ResNet-50

function result = runDRInference(inputImage, generateGradCAM)
    % Initialize default result structure
    result = struct(...
        'modelName', 'ResNet-50 (R50-V1 Final Frozen)', ...
        'modelVersion', '2.0', ...
        'modelStatus', 'LOCKED', ...
        'predictedGrade', NaN, ...
        'classLabels', [0, 1, 2, 3, 4], ...
        'probabilities', NaN(1,5), ...
        'predictedClassProbability', NaN, ...
        'confidence', NaN, ...
        'referableProbability', NaN, ...
        'calibratedReferableProbability', NaN, ...
        'referableThreshold', 0.22, ...
        'referableStatus', 'Unknown', ...
        'calibrationMethod', 'Platt scaling', ...
        'uncertaintyStatus', 'Not implemented in frozen inference interface', ...
        'gradCAM', [], ...
        'success', false, ...
        'errorMessage', '' ...
    );

    if nargin < 2
        generateGradCAM = false;
    end

    try
        % 1. Input Validation
        if ischar(inputImage) || isstring(inputImage)
            if ~exist(inputImage, 'file')
                error('Input image file does not exist: %s', inputImage);
            end
            try
                img = imread(inputImage);
            catch
                error('Failed to read image file.');
            end
        elseif isnumeric(inputImage) || islogical(inputImage)
            img = inputImage;
            if isempty(img)
                error('Input image array is empty.');
            end
            if any(isnan(img(:))) || any(isinf(img(:)))
                error('Input image contains NaN or Inf values.');
            end
        else
            error('Input must be a valid image path or numeric array.');
        end
        
        % Convert grayscale or RGBA to RGB
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        elseif size(img, 3) == 4
            img = img(:, :, 1:3);
        end
        
        % 2. Model Preprocessing
        % We reproduce augmentedImageDatastore([224 224]) behavior which is equivalent to imresize
        img224 = imresize(img, [224 224]);
        
        % 3. Load Persistent State (Model & Calibration)
        persistent net calibMdl;
        
        scriptPath = mfilename('fullpath');
        [srcDir, ~, ~] = fileparts(scriptPath);
        projectDir = fileparts(fileparts(fileparts(srcDir)));
        
        if isempty(net)
            netPath = fullfile(projectDir, 'models', 'final', 'R50-V1', 'r50_v1_best.mat');
            if ~exist(netPath, 'file')
                error('Trained final network not found at: %s', netPath);
            end
            loadedNet = load(netPath, 'net');
            net = loadedNet.net;
        end
        
        if isempty(calibMdl)
            calibPath = fullfile(projectDir, 'outputs', 'evaluation', 'referable_dr', 'calibration', 'calibration_parameters.mat');
            if ~exist(calibPath, 'file')
                error('Calibration parameters not found.');
            end
            loadedCalib = load(calibPath, 'calibMdl');
            calibMdl = loadedCalib.calibMdl;
        end
        
        % 4. Run Inference
        % Since input is a single image, predict accepts single images natively if formatted correctly.
        % dlnetwork expects numeric array, we use predict directly.
        % Note: minibatchpredict supports direct array input.
        scores = minibatchpredict(net, img224);
        
        result.probabilities = double(scores);
        [maxProb, maxIdx] = max(result.probabilities);
        result.predictedGrade = result.classLabels(maxIdx);
        result.predictedClassProbability = maxProb;
        result.confidence = maxProb;
        
        % 5. Referable DR Mapping
        % P2 + P3 + P4 (indices 3, 4, 5)
        rawRefProb = result.probabilities(3) + result.probabilities(4) + result.probabilities(5);
        result.referableProbability = rawRefProb;
        
        % 6. Calibration
        calibProb = predict(calibMdl, rawRefProb);
        result.calibratedReferableProbability = calibProb;
        
        % 7. Threshold Decision
        if calibProb >= result.referableThreshold
            result.referableStatus = 'Referable';
        else
            result.referableStatus = 'Non-referable';
        end
        
        % 8. Grad-CAM
        if generateGradCAM
            % Find the class node name, which is usually 'softmax' or similar for GradCAM.
            % However, gradcam function works directly with dlnetwork.
            classIdx = categorical(result.predictedGrade, result.classLabels, string(result.classLabels));
            % MATLAB gradcam expects categorical classes matching the network's output classes.
            dlImg = dlarray(single(img224), 'SSC');
            try
                % GradCAM generation
                % We specify the feature layer per requirement
                heatMap = gradCAM(net, dlImg, classIdx, 'FeatureLayer', 'res5c_branch2c');
                result.gradCAM = extractdata(heatMap);
            catch ME_GRADCAM
                % If it fails (e.g. older MATLAB version or syntax difference), safely document it.
                result.gradCAM = 'Failed to generate Grad-CAM: ' + string(ME_GRADCAM.message);
            end
        end
        
        % 9. Success
        result.success = true;
        
    catch ME
        result.success = false;
        result.errorMessage = ME.message;
    end
end
