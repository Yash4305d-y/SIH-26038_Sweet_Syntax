% modules/dl_pipeline/evaluation/extract_idrid_resnet50_predictions.m
% Member 3 - Sprint 3 (Corrected Execution)
% Extracts genuine 5-class softmax probabilities and raw referable DR probabilities
% from the locked Baseline ResNet-50 model artifact for all 81 IDRiD testing images.

function extract_idrid_resnet50_predictions()
    disp('=== PHASE 1: GENUINE BASELINE RESNET-50 INFERENCE ON IDRiD DATASET ===');
    
    % Setup project paths
    scriptPath = mfilename('fullpath');
    [evalDir, ~, ~] = fileparts(scriptPath);
    dlDir = fileparts(evalDir);
    modulesDir = fileparts(dlDir);
    projectDir = fileparts(modulesDir);
    
    netPath = fullfile(projectDir, 'models', 'baseline_resnet50_smoketest.mat');
    splitsPath = fullfile(projectDir, 'data', 'splits', 'idrid_splits.csv');
    imgDir = fullfile(projectDir, 'B. Disease Grading', '1. Original Images', 'b. Testing Set');
    lblCsvPath = fullfile(projectDir, 'B. Disease Grading', '2. Groundtruths', 'b. IDRiD_Disease Grading_Testing Labels.csv');
    
    outDir = fullfile(projectDir, 'outputs', 'evaluation', 'adaptation');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    outCsvPath = fullfile(outDir, 'idrid_raw_resnet50_predictions.csv');
    
    % 1. Load Locked Model
    if ~exist(netPath, 'file')
        error('Locked model artifact not found at %s', netPath);
    end
    fprintf('Loading locked model: %s...\n', netPath);
    loadedData = load(netPath, 'net');
    net = loadedData.net;
    fprintf('Model class: %s\n', class(net));
    
    % 2. Read Split Metadata and Groundtruth Labels
    if ~exist(splitsPath, 'file')
        error('IDRiD split CSV not found at %s', splitsPath);
    end
    if ~exist(lblCsvPath, 'file')
        error('IDRiD testing labels CSV not found at %s', lblCsvPath);
    end
    
    splitsData = readtable(splitsPath, 'Delimiter', ',', 'VariableNamingRule', 'preserve');
    lblsData = readtable(lblCsvPath, 'Delimiter', ',', 'VariableNamingRule', 'preserve');
    
    % Create map from ID to true grade
    imgColName = lblsData.Properties.VariableNames{1};
    drColName = lblsData.Properties.VariableNames{2};
    
    lblMap = containers.Map();
    for i = 1:height(lblsData)
        rawName = strtrim(string(lblsData.(imgColName)(i)));
        gradeVal = double(lblsData.(drColName)(i));
        lblMap(rawName) = gradeVal;
        parts = split(rawName, '_');
        if numel(parts) == 2
            numVal = str2double(parts(2));
            lblMap(sprintf('IDRiD_%02d', numVal)) = gradeVal;
            lblMap(sprintf('IDRiD_%03d', numVal)) = gradeVal;
        end
    end
    
    splitCol1 = splitsData.Properties.VariableNames{1};
    splitCol2 = splitsData.Properties.VariableNames{2};
    
    numSamples = height(splitsData);
    fprintf('Processing %d IDRiD split images...\n', numSamples);
    
    image_ids = strings(numSamples, 1);
    splits = strings(numSamples, 1);
    true_grades = zeros(numSamples, 1);
    p0 = zeros(numSamples, 1);
    p1 = zeros(numSamples, 1);
    p2 = zeros(numSamples, 1);
    p3 = zeros(numSamples, 1);
    p4 = zeros(numSamples, 1);
    p_ref_raw = zeros(numSamples, 1);
    
    max_sum_dev = 0;
    max_pref_dev = 0;
    min_prob = 1.0;
    max_prob = 0.0;
    
    % 3. Run Inference on Every IDRiD Image
    for i = 1:numSamples
        imgId = strtrim(string(splitsData.(splitCol1)(i)));
        splitName = strtrim(string(splitsData.(splitCol2)(i)));
        
        % Normalize image ID to find file name (e.g. IDRiD_01 -> IDRiD_001.jpg)
        parts = split(imgId, '_');
        imgNum = str2double(parts(2));
        fnCandidate1 = sprintf('IDRiD_%03d.jpg', imgNum);
        fnCandidate2 = sprintf('IDRiD_%02d.jpg', imgNum);
        
        imgPath1 = fullfile(imgDir, fnCandidate1);
        imgPath2 = fullfile(imgDir, fnCandidate2);
        
        if exist(imgPath1, 'file')
            fullImgPath = imgPath1;
            keyName = sprintf('IDRiD_%03d', imgNum);
        elseif exist(imgPath2, 'file')
            fullImgPath = imgPath2;
            keyName = sprintf('IDRiD_%02d', imgNum);
        else
            error('Could not find image file for ID %s in %s', imgId, imgDir);
        end
        
        if ~isKey(lblMap, keyName)
            error('Could not find groundtruth label for ID %s (key %s)', imgId, keyName);
        end
        
        trueGrade = lblMap(keyName);
        
        % Read Image
        img = imread(fullImgPath);
        
        % Preprocessing Chain (Exact runDRInference.m sequence)
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        elseif size(img, 3) == 4
            img = img(:, :, 1:3);
        end
        
        % Resize to 224x224 RGB
        img224 = imresize(img, [224 224]);
        
        % Predict 5-class softmax probabilities using locked ResNet-50
        scores = minibatchpredict(net, img224);
        scores = double(scores(:))';
        
        % Verification assertions per sample
        assert(numel(scores) == 5, 'Output must have exactly 5 class probabilities for image %s', imgId);
        assert(all(isfinite(scores)), 'All scores must be finite for image %s', imgId);
        assert(all(scores >= 0) && all(scores <= 1.0001), 'Scores must be in [0, 1] for image %s', imgId);
        
        sumScore = sum(scores);
        sumDev = abs(sumScore - 1.0);
        if sumDev > max_sum_dev
            max_sum_dev = sumDev;
        end
        assert(sumDev < 0.01, 'Scores must sum to approximately 1.0 for image %s', imgId);
        
        p0(i) = scores(1);
        p1(i) = scores(2);
        p2(i) = scores(3);
        p3(i) = scores(4);
        p4(i) = scores(5);
        
        prefCalc = p2(i) + p3(i) + p4(i);
        p_ref_raw(i) = prefCalc;
        
        prefDev = abs(p_ref_raw(i) - prefCalc);
        if prefDev > max_pref_dev
            max_pref_dev = prefDev;
        end
        
        min_prob = min([min_prob, scores]);
        max_prob = max([max_prob, scores]);
        
        image_ids(i) = imgId;
        splits(i) = splitName;
        true_grades(i) = trueGrade;
    end
    
    % 4. Validation Checks Across Dataset
    num_calib = sum(splits == "calibration_fit");
    num_heldout = sum(splits == "heldout_validation");
    num_unique_ids = numel(unique(image_ids));
    
    assert(numSamples == 81, 'Total images must be 81');
    assert(num_calib == 40, 'Calibration fit count must be 40');
    assert(num_heldout == 41, 'Heldout validation count must be 41');
    assert(num_unique_ids == 81, 'Duplicate image IDs found');
    assert(all(~isnan(true_grades)), 'Missing or NaN true_grade found');
    assert(all(true_grades >= 0 & true_grades <= 4), 'Invalid true_grade range');
    assert(all(isfinite(p0) & isfinite(p1) & isfinite(p2) & isfinite(p3) & isfinite(p4) & isfinite(p_ref_raw)), 'NaN/Inf in probabilities');
    
    prob_validity_pass = true;
    split_integrity_pass = (numSamples == 81) && (num_calib == 40) && (num_heldout == 41) && (num_unique_ids == 81);
    
    % 5. Export Prediction CSV
    outTable = table(image_ids, splits, true_grades, p0, p1, p2, p3, p4, p_ref_raw, ...
        'VariableNames', {'image_id', 'split', 'true_grade', 'p0', 'p1', 'p2', 'p3', 'p4', 'p_ref_raw'});
        
    writetable(outTable, outCsvPath);
    fprintf('\n[SUCCESS] Exported genuine ResNet-50 predictions for %d images to %s\n', numSamples, outCsvPath);
    
    % 6. Concise Summary Output
    fprintf('\n----------------------------------------\n');
    fprintf('EXTRACTION SUMMARY:\n');
    fprintf('Total images: %d\n', numSamples);
    fprintf('Calibration-fit: %d\n', num_calib);
    fprintf('Held-out: %d\n', num_heldout);
    fprintf('\nProbability validity:\n');
    if prob_validity_pass
        fprintf('PASS\n');
    else
        fprintf('FAIL\n');
    end
    fprintf('\nSplit integrity:\n');
    if split_integrity_pass
        fprintf('PASS\n');
    else
        fprintf('FAIL\n');
    end
    fprintf('\nModel:\nbaseline_resnet50_smoketest.mat\n');
    fprintf('\nInference:\nminibatchpredict\n');
    fprintf('----------------------------------------\n');
    fprintf('Probability min: %.6f, max: %.6f\n', min_prob, max_prob);
    fprintf('Max sum deviation from 1: %.8f\n', max_sum_dev);
    fprintf('Max P_ref calculation deviation: %.8f\n', max_pref_dev);
    fprintf('----------------------------------------\n');
end

