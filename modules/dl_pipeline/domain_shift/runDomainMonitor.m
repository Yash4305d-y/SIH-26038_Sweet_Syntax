function domainShift = runDomainMonitor(inputImage)
    % Initialize default fail-safe object
    domainShift = struct(...
        'status', 'UNAVAILABLE', ...
        'distance', NaN, ...
        'thresholdPotentialShift', NaN, ...
        'thresholdHighMismatch', NaN, ...
        'featureLayer', 'avg_pool', ...
        'featureDimension', 2048, ...
        'referenceDataset', 'APTOS train', ...
        'monitorVersion', '1.0', ...
        'warning', 'Domain monitoring was unavailable. The DR inference result was generated without the domain-shift signal.', ...
        'available', false ...
    );

    try
        projectDir = getProjectRoot();
        
        % 1. Input Validation
        if ischar(inputImage) || isstring(inputImage)
            if ~exist(inputImage, 'file')
                return;
            end
            try
                img = imread(inputImage);
            catch
                return;
            end
        elseif isnumeric(inputImage) || islogical(inputImage)
            img = inputImage;
            if isempty(img) || any(isnan(img(:))) || any(isinf(img(:)))
                return;
            end
        else
            return;
        end
        
        % Convert grayscale or RGBA to RGB
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        elseif size(img, 3) == 4
            img = img(:, :, 1:3);
        end
        
        img224 = imresize(img, [224 224]);
        
        % 2. Load Persistent State
        persistent net refProfile threshShift threshMismatch;
        
        if isempty(net)
            netPath = fullfile(projectDir, 'models', 'baseline_resnet50_smoketest.mat');
            if ~exist(netPath, 'file')
                return;
            end
            loadedNet = load(netPath, 'net');
            net = loadedNet.net;
        end
        
        if isempty(refProfile)
            refPath = fullfile(projectDir, 'outputs', 'evaluation', 'domain_shift', 'aptos_reference_profile.mat');
            if ~exist(refPath, 'file')
                return;
            end
            loadedRef = load(refPath, 'aptosReferenceProfile');
            refProfile = loadedRef.aptosReferenceProfile;
        end
        
        if isempty(threshShift) || isempty(threshMismatch)
            threshPath = fullfile(projectDir, 'outputs', 'evaluation', 'domain_shift', 'threshold_selection.json');
            if ~exist(threshPath, 'file')
                return;
            end
            threshJson = jsondecode(fileread(threshPath));
            threshShift = threshJson.thresholds.POTENTIAL_SHIFT;
            threshMismatch = threshJson.thresholds.HIGH_MISMATCH;
        end
        
        domainShift.thresholdPotentialShift = threshShift;
        domainShift.thresholdHighMismatch = threshMismatch;
        
        % 3. Extract Feature (Read-only second forward pass for avg_pool)
        featOutput = minibatchpredict(net, img224, 'Outputs', 'avg_pool');
        
        featVec = squeeze(featOutput);
        if size(featVec, 1) == 2048
            featVec = featVec';
        end
        
        % 4. Compute Distance
        invCov = inv(refProfile.covMatrix);
        delta = featVec - refProfile.meanVector;
        distSq = delta * invCov * delta';
        distance = sqrt(max(0, distSq));
        domainShift.distance = distance;
        
        % 5. Assess Domain Shift
        if distance > threshMismatch
            domainShift.status = 'HIGH_MISMATCH';
            domainShift.warning = 'Input representation is substantially outside the APTOS reference distribution. This signal does not determine prediction correctness; consider specialist review when interpreting the result.';
        elseif distance > threshShift
            domainShift.status = 'POTENTIAL_SHIFT';
            domainShift.warning = 'Input representation differs from the APTOS reference distribution. This is a distribution-monitoring signal and does not indicate that the prediction is incorrect.';
        else
            domainShift.status = 'WITHIN_REFERENCE';
            domainShift.warning = 'Input representation is within the APTOS reference distribution.';
        end
        
        domainShift.available = true;
        
    catch ME
        % In any failure case, fall back safely to UNAVAILABLE
        % We don't throw an error because the main DR inference must succeed.
        domainShift.warning = 'Domain monitoring was unavailable. The DR inference result was generated without the domain-shift signal.';
    end
end
