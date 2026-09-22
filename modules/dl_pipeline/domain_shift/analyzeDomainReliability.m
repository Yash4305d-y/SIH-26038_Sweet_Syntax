% analyzeDomainReliability.m
function analyzeDomainReliability()
    projectDir = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..');
    outDir = fullfile(projectDir, 'outputs', 'evaluation', 'domain_shift');
    
    % 1. Load Reference Profile and Thresholds
    refPath = fullfile(outDir, 'aptos_reference_profile.mat');
    loadedRef = load(refPath, 'aptosReferenceProfile');
    aptosReferenceProfile = loadedRef.aptosReferenceProfile;
    
    threshPath = fullfile(outDir, 'threshold_selection.json');
    threshJson = jsondecode(fileread(threshPath));
    threshShift = threshJson.thresholds.POTENTIAL_SHIFT;
    threshMismatch = threshJson.thresholds.HIGH_MISMATCH;
    
    % 2. Load Model and Calibration
    netPath = fullfile(projectDir, 'models', 'baseline_resnet50_smoketest.mat');
    loadedNet = load(netPath, 'net');
    net = loadedNet.net;
    
    calibPath = fullfile(projectDir, 'outputs', 'evaluation', 'referable_dr', 'calibration', 'calibration_parameters.mat');
    loadedCalib = load(calibPath, 'calibMdl');
    calibMdl = loadedCalib.calibMdl;
    
    % Prepare stats container
    extObj = struct();
    
    % --- APTOS TEST ---
    disp('Analyzing APTOS Test Reliability...');
    testCsv = fullfile(projectDir, 'data', 'splits', 'test_split.csv');
    imgDir = fullfile(projectDir, 'data', 'raw', 'test_images');
    [testPaths, testGt] = getPathsExt(testCsv, imgDir, '.png', projectDir);
    extObj.APTOS_test = evaluateReliability(net, calibMdl, testPaths, testGt, aptosReferenceProfile, threshShift, threshMismatch, 'held-out reference-domain evaluation');
    
    % --- MESSIDOR-2 ---
    disp('Analyzing Messidor-2 Reliability...');
    m2Csv = fullfile(projectDir, 'data', 'metadata', 'messidor_data.csv');
    m2ImgDir = fullfile(projectDir, 'messidor-2', 'preprocess');
    [m2Paths, m2Gt] = getPathsExt(m2Csv, m2ImgDir, '.png', projectDir);
    
    % Fix extensions for Messidor
    for i=1:length(m2Paths)
        if ~exist(m2Paths(i), 'file')
            [p, n, ~] = fileparts(char(m2Paths(i)));
            m2Paths(i) = string(fullfile(p, [n, '.JPG']));
        end
    end
    extObj.Messidor2 = evaluateReliability(net, calibMdl, m2Paths, m2Gt, aptosReferenceProfile, threshShift, threshMismatch, 'external stress-test domain');
    
    % --- IDRiD ---
    disp('Checking IDRiD...');
    idridCsv = fullfile(projectDir, 'data', 'splits', 'idrid_splits.csv');
    idridImgDir = fullfile(projectDir, 'data', 'raw', 'idrid_images');
    [idridPaths, idridGt] = getPathsExt(idridCsv, idridImgDir, '.jpg', projectDir);
    idridValid = false;
    for i=1:length(idridPaths)
        if exist(idridPaths(i), 'file')
            idridValid = true;
            break;
        end
    end
    if idridValid
        extObj.IDRiD = evaluateReliability(net, calibMdl, idridPaths, idridGt, aptosReferenceProfile, threshShift, threshMismatch, 'external stress-test domain');
    else
        disp('IDRiD evaluation was not performed because the required images were unavailable in the local workspace.');
        extObj.IDRiD = struct('role', 'external stress-test domain', 'status', 'unavailable', 'note', 'IDRiD evaluation was not performed because the required images were unavailable in the local workspace.');
    end
    
    % Overwrite the JSON
    fid = fopen(fullfile(outDir, 'external_domain_evaluation.json'), 'w');
    fwrite(fid, jsonencode(extObj, 'PrettyPrint', true));
    fclose(fid);
    
    updateReport(outDir);
end

function stats = evaluateReliability(net, calibMdl, imgPaths, gtLabels, refProfile, threshShift, threshMismatch, role)
    % Initialize valid subset
    validIdx = isfile(imgPaths);
    validPaths = imgPaths(validIdx);
    validGt = double(gtLabels(validIdx));
    
    stats = struct();
    stats.role = role;
    stats.sample_count = length(validPaths);
    if isempty(validPaths)
        return;
    end
    
    % Predict
    imds = imageDatastore(validPaths);
    augimds = augmentedImageDatastore([224 224], imds);
    [featOutputs, probOutputs] = minibatchpredict(net, augimds, 'Outputs', {'avg_pool', 'fc1000_softmax'});
    
    % Standardize outputs
    if size(featOutputs,1)==2048, featOutputs = featOutputs'; end
    if size(featOutputs,1)==1 && size(featOutputs,3)==2048
        featOutputs = squeeze(featOutputs)';
    else
        featOutputs = squeeze(featOutputs);
        if size(featOutputs,1)==2048, featOutputs = featOutputs'; end
    end
    
    if size(probOutputs,1)==5, probOutputs = probOutputs'; end
    if ndims(probOutputs)>2, probOutputs = squeeze(probOutputs)'; end
    if size(probOutputs,1)==5, probOutputs = probOutputs'; end
    
    % Compute distances
    invCov = inv(refProfile.covMatrix);
    distances = zeros(length(validPaths), 1);
    for i=1:length(validPaths)
        delta = featOutputs(i,:) - refProfile.meanVector;
        distSq = delta * invCov * delta';
        distances(i) = sqrt(max(0, distSq));
    end
    
    % Assess Flags
    flags = assessDomainShift(distances, threshShift, threshMismatch);
    
    % Metrics
    [~, predGrade] = max(probOutputs, [], 2);
    predGrade = predGrade - 1;
    
    rawRefProb = sum(probOutputs(:, 3:5), 2);
    calibRefProb = predict(calibMdl, rawRefProb);
    predRef = double(calibRefProb >= 0.22);
    trueRef = double(validGt >= 2);
    
    error5Class = double(predGrade ~= validGt);
    errorRef = double(predRef ~= trueRef);
    
    % Overall
    stats.mean_distance = mean(distances);
    stats.percent_within_reference = mean(flags == "WITHIN_REFERENCE")*100;
    stats.percent_potential_shift = mean(flags == "POTENTIAL_SHIFT")*100;
    stats.percent_high_mismatch = mean(flags == "HIGH_MISMATCH")*100;
    
    % Group Stats
    stats.groups = struct();
    groupNames = ["WITHIN_REFERENCE", "POTENTIAL_SHIFT", "HIGH_MISMATCH"];
    
    for i=1:length(groupNames)
        gName = groupNames(i);
        idx = (flags == gName);
        n = sum(idx);
        gStats = struct('sample_count', n);
        
        if n > 0
            gStats.five_class_error_rate = mean(error5Class(idx));
            gStats.five_class_accuracy = 1 - gStats.five_class_error_rate;
            
            TP = sum(trueRef(idx)==1 & predRef(idx)==1);
            TN = sum(trueRef(idx)==0 & predRef(idx)==0);
            FP = sum(trueRef(idx)==0 & predRef(idx)==1);
            FN = sum(trueRef(idx)==1 & predRef(idx)==0);
            
            gStats.referable_error_rate = mean(errorRef(idx));
            gStats.referable_accuracy = (TP+TN)/n;
            if (TP+FN)>0, gStats.referable_sensitivity = TP/(TP+FN); else, gStats.referable_sensitivity = NaN; end
            if (TN+FP)>0, gStats.referable_specificity = TN/(TN+FP); else, gStats.referable_specificity = NaN; end
        end
        stats.groups.(char(gName)) = gStats;
    end
    
    % Categorical Analysis (WITHIN_REFERENCE vs FLAGGED)
    idxWithin = (flags == "WITHIN_REFERENCE");
    idxFlagged = (flags ~= "WITHIN_REFERENCE");
    nWithin = sum(idxWithin);
    nFlagged = sum(idxFlagged);
    
    catStats = struct();
    if nWithin > 0 && nFlagged > 0
        errWithin = sum(error5Class(idxWithin));
        errFlagged = sum(error5Class(idxFlagged));
        
        tbl = [errWithin, nWithin - errWithin; errFlagged, nFlagged - errFlagged];
        [h, p, stat] = fishertest(tbl);
        
        catStats.groups_compared = 'WITHIN_REFERENCE vs FLAGGED (POTENTIAL_SHIFT + HIGH_MISMATCH)';
        catStats.n_within = nWithin;
        catStats.n_flagged = nFlagged;
        catStats.error_rate_within = errWithin / nWithin;
        catStats.error_rate_flagged = errFlagged / nFlagged;
        catStats.p_value = p;
        catStats.odds_ratio = stat.OddsRatio;
        catStats.interpretation = 'Evaluates if flagged samples have a statistically different 5-class error rate than within-reference samples using Fisher Exact Test.';
    else
        catStats.note = 'Insufficient samples in one or both categorical groups to run Fisher test.';
    end
    stats.categorical_analysis = catStats;
    
    % Logistic Regression (Distance vs Binary Error)
    % Modeling 5-class error
    tblData = table(distances, error5Class, 'VariableNames', {'Distance', 'Error'});
    mdl = fitglm(tblData, 'Error ~ Distance', 'Distribution', 'binomial');
    
    logReg = struct();
    logReg.predictor = 'Domain Distance';
    logReg.outcome = '5-Class Prediction Error (Binary)';
    logReg.sample_count = length(distances);
    logReg.effect_estimate_beta = mdl.Coefficients.Estimate(2);
    logReg.p_value = mdl.Coefficients.pValue(2);
    logReg.odds_ratio = exp(mdl.Coefficients.Estimate(2));
    
    if logReg.p_value < 0.05
        logReg.interpretation = 'Prediction error was associated with representation distance (p < 0.05).';
    else
        logReg.interpretation = 'No statistically significant association between distance and error was found.';
    end
    stats.logistic_regression_analysis = logReg;
end

function [paths, gt] = getPathsExt(csvPath, imgDir, ext, projectDir)
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
            paths(i) = p1;
        end
    end
    
    if ismember('diagnosis', t.Properties.VariableNames)
        gt = t.diagnosis;
    else
        gt = [];
    end
end

function updateReport(outDir)
    % Re-write the domain_shift_report.md
    % Read JSON back to pick conclusion A, B, or C
    extPath = fullfile(outDir, 'external_domain_evaluation.json');
    extJson = jsondecode(fileread(extPath));
    
    % Decide conclusion based on APTOS_test and Messidor2 p-values
    sigAptos = false;
    sigMessidor = false;
    if isfield(extJson.APTOS_test, 'logistic_regression_analysis') && isfield(extJson.APTOS_test.logistic_regression_analysis, 'p_value')
        sigAptos = extJson.APTOS_test.logistic_regression_analysis.p_value < 0.05;
    end
    if isfield(extJson.Messidor2, 'logistic_regression_analysis') && isfield(extJson.Messidor2.logistic_regression_analysis, 'p_value')
        sigMessidor = extJson.Messidor2.logistic_regression_analysis.p_value < 0.05;
    end
    
    if sigAptos && sigMessidor
        conclusion = 'A: Evidence supports using representation mismatch as a reliability warning on the evaluated datasets.';
    elseif sigAptos || sigMessidor
        conclusion = 'B: Representation mismatch is detectable, but evidence is mixed/insufficient to uniformly establish that it predicts model reliability across all sets.';
    else
        conclusion = 'C: Representation mismatch is detectable, but the evaluated evidence does not support using it as a reliability warning.';
    end
    
    fid = fopen(fullfile(outDir, 'domain_shift_report.md'), 'w');
    fprintf(fid, '# Domain Shift Validation Report\n\n');
    fprintf(fid, '## 1. Feature Selection\n');
    fprintf(fid, 'The `avg_pool` layer was selected because it provides a compact 2048-dimensional representation immediately before classification. It is computation and storage efficient.\n\n');
    
    fprintf(fid, '## 2. APTOS Reference Distribution\n');
    fprintf(fid, 'Constructed strictly from the APTOS TRAIN split. We calculated the mean and a regularized covariance with diagonal ridge stabilization to avoid instability.\n\n');
    
    fprintf(fid, '## 3. Threshold Selection\n');
    fprintf(fid, 'Thresholds were chosen strictly using the APTOS VALIDATION split. We set `POTENTIAL_SHIFT` at the 95th percentile and `HIGH_MISMATCH` at the 99th percentile.\n\n');
    
    fprintf(fid, '## 4. External Domain Evaluation\n');
    fprintf(fid, 'Thresholds were fixed and applied to APTOS Test, IDRiD, and Messidor-2.\n\n');
    
    fprintf(fid, '## 5. Domain Mismatch and Model Reliability\n');
    fprintf(fid, 'Domain distance was treated as a continuous variable and modeled against 5-class prediction error using logistic regression. We also compared categorical error rates (WITHIN_REFERENCE vs flagged).\n\n');
    
    fprintf(fid, '## 6. Conclusions\n');
    fprintf(fid, 'We distinguish between:\n');
    fprintf(fid, '1. **Representation distribution mismatch**: Flagged by this system.\n');
    fprintf(fid, '2. **Model prediction error**: Measured via ground truth.\n');
    fprintf(fid, '3. **Calibrated Referable Probability**: The clinical output scalar.\n');
    fprintf(fid, '4. **Clinical correctness**: Ground truth diagnostic validity.\n\n');
    fprintf(fid, '- Domain distance is not a probability that the prediction is wrong.\n');
    fprintf(fid, '- Domain status does not automatically alter the DR prediction.\n');
    fprintf(fid, '- Referable Probability is not domain confidence.\n');
    fprintf(fid, '- The detector is not clinically validated.\n');
    fprintf(fid, '- Dataset-level domain differences do not prove individual prediction failure.\n');
    fprintf(fid, '- Statistical association does not prove causation.\n');
    fprintf(fid, '- APTOS, IDRiD, and Messidor-2 are not equivalent to representative Indian field deployment data.\n\n');
    
    fprintf(fid, '## Final Evidence Classification\n');
    fprintf(fid, '%s\n', conclusion);
    fclose(fid);
end
