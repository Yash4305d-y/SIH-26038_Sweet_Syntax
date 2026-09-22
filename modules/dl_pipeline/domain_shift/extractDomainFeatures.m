% extractDomainFeatures.m
% Extracts 2048-D features from the avg_pool layer of the locked baseline model.
function [features, validPaths] = extractDomainFeatures(net, imagePaths)
    % net: loaded dlnetwork
    % imagePaths: string array or cell array of image paths
    
    numImages = length(imagePaths);
    features = zeros(numImages, 2048, 'single');
    validPaths = true(numImages, 1);
    
    % Use augmentedImageDatastore to replicate exactly the preprocessing in runDRInference
    % but we have to filter out non-existent files first to avoid imageDatastore errors.
    
    % Check file existence
    for i = 1:numImages
        if ~exist(imagePaths(i), 'file')
            validPaths(i) = false;
        end
    end
    
    validImagePaths = imagePaths(validPaths);
    if isempty(validImagePaths)
        features = [];
        return;
    end
    
    % Create datastore for valid paths
    imds = imageDatastore(validImagePaths);
    augimds = augmentedImageDatastore([224 224], imds);
    
    % Extract features using minibatchpredict
    disp(['Extracting features from ' num2str(length(validImagePaths)) ' images...']);
    featOutputs = minibatchpredict(net, augimds, 'Outputs', 'avg_pool');
    
    % Feat outputs could be 1x1x2048xN or 2048xN or Nx2048 depending on MATLAB format
    % Ensure it is Nx2048
    sz = size(featOutputs);
    
    % MATLAB minibatchpredict typically returns numObservations-by-...
    if length(sz) >= 2
        % Flatten spatial dimensions if any
        featOutputs = squeeze(featOutputs);
        % Depending on squeeze result, it might be 2048xN or Nx2048
        if size(featOutputs, 1) == 2048 && size(featOutputs, 2) == length(validImagePaths) && length(validImagePaths) > 1
            featOutputs = featOutputs';
        elseif size(featOutputs, 1) == length(validImagePaths) && size(featOutputs, 2) == 2048
            % Correct orientation
        elseif size(featOutputs, 1) == 2048 && length(validImagePaths) == 1
            featOutputs = featOutputs';
        else
            error('Unexpected feature dimensions extracted.');
        end
    end
    
    % Validate 2048-D
    if size(featOutputs, 2) ~= 2048
        error('Feature extraction failed to produce exactly 2048 dimensions.');
    end
    
    % Validate no NaNs or Infs
    if any(isnan(featOutputs(:))) || any(isinf(featOutputs(:)))
        error('Feature extraction produced NaN or Inf values.');
    end
    
    % Reconstruct into the pre-allocated array matching the original input indices
    validIdx = find(validPaths);
    features(validIdx, :) = featOutputs;
    
    % For invalid paths, we leave as zero but validPaths tells the caller to ignore them.
end
