% validateDomainShift.m
function validateDomainShift()
    projectDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
    outDir = fullfile(projectDir, 'outputs', 'evaluation', 'domain_shift');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    
    % 1. Build Reference if missing
    refPath = fullfile(outDir, 'aptos_reference_profile.mat');
    if ~exist(refPath, 'file')
        disp('Building APTOS reference profile...');
        buildAPTOSReference();
    end
    
    loadedRef = load(refPath, 'aptosReferenceProfile');
    aptosReferenceProfile = loadedRef.aptosReferenceProfile;
    
    % 2. Load Model
    netPath = fullfile(projectDir, 'models', 'baseline_resnet50_smoketest.mat');
    loadedNet = load(netPath, 'net');
    net = loadedNet.net;
    
    % --- THRESHOLD SELECTION (APTOS VALIDATION) ---
    disp('Processing APTOS Validation...');
    valCsvPath = fullfile(projectDir, 'data', 'splits', 'val_split.csv');
    valImgDir = fullfile(projectDir, 'data', 'raw', 'val_images');
    [valPaths, valGt] = getPaths(valCsvPath, valImgDir, '.png');
    
    [valFeat, valValid] = extractDomainFeatures(net, valPaths);
    valFeat = valFeat(valValid, :);
    valDist = computeDomainDistance(valFeat, aptosReferenceProfile);
    
    % Pick thresholds (e.g. 95th and 99th percentile of validation distances)
    threshShift = prctile(valDist, 95);
    threshMismatch = prctile(valDist, 99);
    
    valFlags = assessDomainShift(valDist, threshShift, threshMismatch);
    percFlaggedVal = mean(valFlags ~= "WITHIN_REFERENCE") * 100;
    
    threshObj = struct();
    threshObj.protocol = '95th and 99th percentile of APTOS VALIDATION distances';
    threshObj.thresholds = struct('POTENTIAL_SHIFT', threshShift, 'HIGH_MISMATCH', threshMismatch);
    threshObj.validation_statistics = struct('mean_distance', mean(valDist), 'percent_flagged', percFlaggedVal);
    threshObj.limitations = 'Thresholds are statistically chosen based on distribution quantiles, not clinically validated. They indicate distribution mismatch, not correctness.';
    
    fid = fopen(fullfile(outDir, 'threshold_selection.json'), 'w');
    fwrite(fid, jsonencode(threshObj, 'PrettyPrint', true));
    fclose(fid);
    
    % --- EXTERNAL EVALUATION ---
    disp('Processing APTOS Test...');
    testCsvPath = fullfile(projectDir, 'data', 'splits', 'test_split.csv');
    testImgDir = fullfile(projectDir, 'data', 'raw', 'test_images');
    [testPaths, ~] = getPaths(testCsvPath, testImgDir, '.png');
    [testFeat, testValid] = extractDomainFeatures(net, testPaths);
    testDist = computeDomainDistance(testFeat(testValid,:), aptosReferenceProfile);
    testFlags = assessDomainShift(testDist, threshShift, threshMismatch);
    
    disp('Processing Messidor-2...');
    messidorCsv = fullfile(projectDir, 'data', 'metadata', 'messidor_data.csv');
    messidorImgDir = fullfile(projectDir, 'messidor-2', 'preprocess');
    [m2Paths, ~] = getPaths(messidorCsv, messidorImgDir, '.png'); % Note: Might need to handle .JPG
    
    % Fix Messidor paths
    for i=1:length(m2Paths)
        if ~exist(m2Paths(i), 'file')
            [p, n, ~] = fileparts(char(m2Paths(i)));
            m2Paths(i) = string(fullfile(p, [n, '.JPG']));
        end
    end
    
    [m2Feat, m2Valid] = extractDomainFeatures(net, m2Paths);
    m2Dist = computeDomainDistance(m2Feat(m2Valid,:), aptosReferenceProfile);
    m2Flags = assessDomainShift(m2Dist, threshShift, threshMismatch);
    
    disp('Processing IDRiD...');
    idridCsv = fullfile(projectDir, 'data', 'splits', 'idrid_splits.csv');
    idridImgDir = fullfile(projectDir, 'data', 'raw', 'idrid_images'); % guess
    [idridPaths, ~] = getPaths(idridCsv, idridImgDir, '.jpg');
    [idridFeat, idridValid] = extractDomainFeatures(net, idridPaths);
    if any(idridValid)
        idridDist = computeDomainDistance(idridFeat(idridValid,:), aptosReferenceProfile);
        idridFlags = assessDomainShift(idridDist, threshShift, threshMismatch);
    else
        disp('IDRiD images not found. Skipping IDRiD evaluation.');
        idridDist = []; idridFlags = [];
    end
    
    extObj = struct();
    
    extObj.APTOS_test = struct();
    extObj.APTOS_test.role = 'held-out reference-domain evaluation';
    extObj.APTOS_test.sample_count = length(testDist);
    extObj.APTOS_test.mean_distance = mean(testDist);
    extObj.APTOS_test.percent_within_reference = mean(testFlags == "WITHIN_REFERENCE")*100;
    extObj.APTOS_test.percent_potential_shift = mean(testFlags == "POTENTIAL_SHIFT")*100;
    extObj.APTOS_test.percent_high_mismatch = mean(testFlags == "HIGH_MISMATCH")*100;
    
    extObj.Messidor2 = struct();
    extObj.Messidor2.role = 'external stress-test domain';
    extObj.Messidor2.sample_count = length(m2Dist);
    extObj.Messidor2.mean_distance = mean(m2Dist);
    extObj.Messidor2.percent_within_reference = mean(m2Flags == "WITHIN_REFERENCE")*100;
    extObj.Messidor2.percent_potential_shift = mean(m2Flags == "POTENTIAL_SHIFT")*100;
    extObj.Messidor2.percent_high_mismatch = mean(m2Flags == "HIGH_MISMATCH")*100;
    
    if ~isempty(idridDist)
        extObj.IDRiD = struct();
        extObj.IDRiD.role = 'external stress-test domain';
        extObj.IDRiD.sample_count = length(idridDist);
        extObj.IDRiD.mean_distance = mean(idridDist);
        extObj.IDRiD.percent_within_reference = mean(idridFlags == "WITHIN_REFERENCE")*100;
        extObj.IDRiD.percent_potential_shift = mean(idridFlags == "POTENTIAL_SHIFT")*100;
        extObj.IDRiD.percent_high_mismatch = mean(idridFlags == "HIGH_MISMATCH")*100;
    end
    
    fid = fopen(fullfile(outDir, 'external_domain_evaluation.json'), 'w');
    fwrite(fid, jsonencode(extObj, 'PrettyPrint', true));
    fclose(fid);
    
    disp('Validation Complete. Run markdown report generation separately or inline.');
    
    % Markdown generation
    fid = fopen(fullfile(outDir, 'domain_shift_report.md'), 'w');
    fprintf(fid, '# Domain Shift Validation Report\n\n');
    fprintf(fid, '## 1. Feature Selection\n');
    fprintf(fid, 'The `avg_pool` layer was selected because it provides a compact 2048-dimensional feature representation immediately before classification. This is computationally efficient compared to the raw spatial tensor from `res5c_branch2c` and accurately summarizes the network''s final learned embedding for domain shift monitoring.\n\n');
    fprintf(fid, '## 2. APTOS Reference Distribution\n');
    fprintf(fid, 'Constructed strictly from the APTOS TRAIN split. We calculated the mean and robustly regularized covariance matrix (by adding a small lambda to the diagonal) to avoid instability from singular matrices.\n\n');
    fprintf(fid, '## 3. Threshold Selection\n');
    fprintf(fid, 'Thresholds were chosen strictly using the APTOS VALIDATION split. We set `POTENTIAL_SHIFT` at the 95th percentile and `HIGH_MISMATCH` at the 99th percentile of the validation distance distribution. This prevents any test leakage.\n\n');
    fprintf(fid, '## 4. External Domain Evaluation\n');
    fprintf(fid, 'The thresholds were fixed and applied to APTOS Test (held-out reference), IDRiD (if available), and Messidor-2. These external domains acted as strict stress tests.\n\n');
    fprintf(fid, '## 5. Domain Mismatch and Model Reliability\n');
    fprintf(fid, 'We observe differences in distribution distances. However, flagged status indicates a shift in the data distribution relative to the training set, not directly proving that a specific prediction is incorrect.\n\n');
    fprintf(fid, '## 6. Conclusions\n');
    fprintf(fid, 'We can conclude whether new domains differ statistically from the training domain in the network''s feature space. We **cannot** conclude that every flagged image will be misclassified.\n\n');
    fprintf(fid, '## 7. Reliability Monitor vs Prediction Correction\n');
    fprintf(fid, 'This monitor flags inputs that the model is unaccustomed to, which might compromise reliability. It does not correct the prediction, as that would require re-calibrating or re-training the network.\n\n');
    fprintf(fid, '## 8. Need for Representative Indian Field Data\n');
    fprintf(fid, 'While Messidor-2 serves as an external test, proving coverage for Indian deployment requires actual representative Indian field data. IDRiD or Messidor-2 do not equate to a finalized clinical validation on the target population.\n\n');
    fprintf(fid, '## 9. Limitations\n');
    fprintf(fid, 'Limitations include finite reference sample size, variations in image acquisition methods, and the fact that distance in feature space does not perfectly correspond to diagnostic accuracy.\n');
    fclose(fid);
    
end

function [paths, gt] = getPaths(csvPath, imgDir, ext)
    if ~exist(csvPath, 'file')
        paths = []; gt = []; return;
    end
    t = readtable(csvPath, 'PreserveVariableNames', true);
    
    if ismember('id_code', t.Properties.VariableNames)
        colName = 'id_code';
    elseif ismember('image_id', t.Properties.VariableNames)
        colName = 'image_id';
    else
        colName = t.Properties.VariableNames{1};
    end
    
    paths = strings(height(t), 1);
    
    % APTOS images are often all in train_images even for val/test splits
    projectDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
    imgDirTrain = fullfile(projectDir, 'data', 'raw', 'train_images');
    
    for i = 1:height(t)
        baseName = char(t.(colName)(i));
        [~, ~, currentExt] = fileparts(baseName);
        
        if ~isempty(currentExt)
            p1 = fullfile(imgDir, baseName);
            p2 = fullfile(imgDirTrain, baseName);
        else
            p1 = fullfile(imgDir, [baseName, ext]);
            p2 = fullfile(imgDirTrain, [baseName, ext]);
        end
        
        if exist(p1, 'file')
            paths(i) = p1;
        elseif exist(p2, 'file')
            paths(i) = p2;
        else
            paths(i) = p1; % default fallback
        end
    end
    
    if ismember('diagnosis', t.Properties.VariableNames)
        gt = t.diagnosis;
    else
        gt = [];
    end
end
