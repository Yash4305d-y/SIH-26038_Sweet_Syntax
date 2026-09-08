% src/runDRInferenceBatch.m
% Wrapper to run runDRInference on a batch of images.

function results = runDRInferenceBatch(imagePaths, generateGradCAM)
    if nargin < 2
        generateGradCAM = false;
    end
    
    numImages = numel(imagePaths);
    results = cell(numImages, 1);
    
    for i = 1:numImages
        results{i} = runDRInference(imagePaths{i}, generateGradCAM);
    end
    
    % Convert to struct array for convenience if possible
    try
        results = [results{:}];
    catch
    end
end
