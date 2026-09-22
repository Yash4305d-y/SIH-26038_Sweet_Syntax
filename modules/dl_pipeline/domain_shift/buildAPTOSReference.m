% buildAPTOSReference.m
function buildAPTOSReference()
    projectDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
    
    netPath = fullfile(projectDir, 'models', 'baseline_resnet50_smoketest.mat');
    loadedNet = load(netPath, 'net');
    net = loadedNet.net;
    
    csvPath = fullfile(projectDir, 'data', 'splits', 'train_split.csv');
    t = readtable(csvPath, 'PreserveVariableNames', true);
    imgDir = fullfile(projectDir, 'data', 'raw', 'train_images');
    
    paths = strings(height(t), 1);
    for i = 1:height(t)
        baseName = char(t.id_code(i));
        paths(i) = fullfile(imgDir, [baseName, '.png']);
    end
    
    [features, validPaths] = extractDomainFeatures(net, paths);
    validFeatures = features(validPaths, :);
    
    refMean = mean(validFeatures, 1);
    refCov = cov(validFeatures);
    
    % Regularize to ensure invertibility
    lambda = 1e-4;
    regCov = refCov + lambda * eye(size(refCov,1));
    regCov = (regCov + regCov') / 2;
    
    outDir = fullfile(projectDir, 'outputs', 'evaluation', 'domain_shift');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    
    aptosReferenceProfile = struct();
    aptosReferenceProfile.modelId = 'baseline_resnet50_smoketest';
    aptosReferenceProfile.featureLayer = 'avg_pool';
    aptosReferenceProfile.featureDimension = 2048;
    aptosReferenceProfile.preprocessing = 'imresize(image, [224 224]) via augmentedImageDatastore';
    aptosReferenceProfile.referenceDataset = 'APTOS_TRAIN';
    aptosReferenceProfile.sampleCount = size(validFeatures, 1);
    aptosReferenceProfile.meanVector = refMean;
    aptosReferenceProfile.covMatrix = regCov;
    
    save(fullfile(outDir, 'aptos_reference_profile.mat'), 'aptosReferenceProfile');
    disp('APTOS Reference Built.');
end
