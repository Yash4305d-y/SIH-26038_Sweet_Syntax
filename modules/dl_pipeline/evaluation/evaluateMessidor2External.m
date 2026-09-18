% src/evaluateMessidor2External.m
% Evaluates the authoritative baseline predictions on Messidor-2 dataset.
function evaluateMessidor2External()
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    % Setup directories
    modelsDir = fullfile(projectDir, 'models');
    messidorDir = fullfile(projectDir, 'messidor-2');
    imgDir = fullfile(messidorDir, 'preprocess');
    
    outDir = fullfile(projectDir, 'outputs', 'evaluation', 'messidor2');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    
    % Load Authoritative Model
    netPath = fullfile(modelsDir, 'baseline_resnet50_smoketest.mat');
    if ~exist(netPath, 'file')
        error('Trained network not found.');
    end
    loadedNet = load(netPath, 'net');
    net = loadedNet.net;
    
    % Load Calibration Parameters
    calibPath = fullfile(projectDir, 'outputs', 'evaluation', 'referable_dr', 'calibration', 'calibration_parameters.mat');
    if ~exist(calibPath, 'file')
        error('Calibration parameters not found.');
    end
    loadedCalib = load(calibPath, 'calibMdl', 'optThreshold');
    calibMdl = loadedCalib.calibMdl;
    
    % Hardcoded threshold
    threshold = 0.22;
    if abs(loadedCalib.optThreshold - threshold) > 1e-4
        warning('Loaded threshold (%.4f) differs from requested 0.22. Using 0.22.', loadedCalib.optThreshold);
    end
    
    % Load Messidor CSV
    csvPath = fullfile(projectDir, 'messidor_data.csv');
    if ~exist(csvPath, 'file')
        % Try the messidorDir just in case
        csvPath = fullfile(messidorDir, 'messidor_data.csv');
        if ~exist(csvPath, 'file')
            error('Messidor CSV not found.');
        end
    end
    t = readtable(csvPath, 'PreserveVariableNames', true);
    numExpected = 1744;
    
    if height(t) ~= numExpected
        error('Expected %d rows in CSV, found %d.', numExpected, height(t));
    end
    
    % Image/CSV matching
    disp('Mapping images...');
    paths = strings(height(t), 1);
    valid = true(height(t), 1);
    
    for i = 1:height(t)
        baseName = char(t.id_code(i));
        % Try finding exactly as named
        fullPath = fullfile(imgDir, baseName);
        if exist(fullPath, 'file')
            paths(i) = fullPath;
        else
            % Try finding .JPG vs .png
            [~, n, ~] = fileparts(baseName);
            altPathPNG = fullfile(imgDir, [n, '.png']);
            altPathJPG = fullfile(imgDir, [n, '.JPG']);
            
            if exist(altPathPNG, 'file')
                paths(i) = altPathPNG;
            elseif exist(altPathJPG, 'file')
                paths(i) = altPathJPG;
            else
                valid(i) = false;
            end
        end
    end
    
    if sum(~valid) > 0
        error('Missing images for %d CSV rows.', sum(~valid));
    end
    
    % Verify unique paths
    if length(unique(paths)) ~= height(t)
        error('Duplicate paths found.');
    end
    
    % Ground truth
    labels5Class = t.diagnosis;
    if any(~ismember(labels5Class, 0:4))
        error('Invalid diagnosis values found. Expected 0-4.');
    end
    gtReferable = double(labels5Class >= 2);
    
    % --- Preprocessing Pipeline ---
    disp('Loading Datastore and running minibatchpredict...');
    imds = imageDatastore(paths);
    augimds = augmentedImageDatastore([224 224], imds);
    
    scores = minibatchpredict(net, augimds);
    
    % Verify probabilities
    if any(scores(:) < 0) || any(scores(:) > 1)
        error('Softmax probabilities out of bounds [0,1].');
    end
    scoreSums = sum(scores, 2);
    if any(abs(scoreSums - 1) > 1e-4)
        error('Probabilities do not sum to 1.');
    end
    
    % 5-class predictions
    [~, maxIdx] = max(scores, [], 2);
    pred5Class = maxIdx - 1; % 0 to 4
    
    % Raw Referable Probability
    rawRefProb = sum(scores(:, 3:5), 2);
    
    % Calibrate Referable Probability
    disp('Applying calibration mapping...');
    calibRefProb = predict(calibMdl, rawRefProb);
    
    if any(calibRefProb(:) < 0) || any(calibRefProb(:) > 1)
        error('Calibrated probabilities out of bounds [0,1].');
    end
    
    % Predicted Referable
    predReferable = double(calibRefProb >= threshold);
    rawPredReferable = double(rawRefProb >= 0.5);
    
    % --- Primary Binary Metrics (Calibrated @ 0.22) ---
    disp('Calculating binary metrics...');
    TP = sum(gtReferable == 1 & predReferable == 1);
    TN = sum(gtReferable == 0 & predReferable == 0);
    FP = sum(gtReferable == 0 & predReferable == 1);
    FN = sum(gtReferable == 1 & predReferable == 0);
    
    acc = (TP + TN) / numExpected;
    sens = TP / (TP + FN);
    spec = TN / (TN + FP);
    prec = TP / (TP + FP);
    npv = TN / (TN + FN);
    
    if isnan(prec), prec = 0; end
    if isnan(sens), sens = 0; end
    f1 = 2 * (prec * sens) / (prec + sens);
    if isnan(f1), f1 = 0; end
    
    [~, ~, ~, roc_auc] = perfcurve(gtReferable, calibRefProb, 1);
    
    brier = mean((calibRefProb - gtReferable).^2);
    ece = computeECE(calibRefProb, gtReferable, 10);
    
    % Raw binary metrics (@ 0.5)
    rTP = sum(gtReferable == 1 & rawPredReferable == 1);
    rTN = sum(gtReferable == 0 & rawPredReferable == 0);
    rFP = sum(gtReferable == 0 & rawPredReferable == 1);
    rFN = sum(gtReferable == 1 & rawPredReferable == 0);
    
    rAcc = (rTP + rTN) / numExpected;
    rSens = rTP / (rTP + rFN);
    rSpec = rTN / (rTN + rFP);
    rPrec = rTP / (rTP + rFP);
    rNpv = rTN / (rTN + rFN);
    
    if isnan(rPrec), rPrec = 0; end
    if isnan(rSens), rSens = 0; end
    rF1 = 2 * (rPrec * rSens) / (rPrec + rSens);
    if isnan(rF1), rF1 = 0; end
    
    rBrier = mean((rawRefProb - gtReferable).^2);
    rEce = computeECE(rawRefProb, gtReferable, 10);
    
    % --- Secondary 5-Class Metrics ---
    disp('Calculating 5-class metrics...');
    cTrue = categorical(labels5Class, 0:4);
    cPred = categorical(pred5Class, 0:4);
    
    O = confusionmat(labels5Class, pred5Class, 'Order', 0:4);
    acc5 = sum(diag(O)) / numExpected;
    
    prec5 = diag(O) ./ sum(O, 1)';
    prec5(isnan(prec5)) = 0;
    
    rec5 = diag(O) ./ sum(O, 2);
    rec5(isnan(rec5)) = 0;
    
    f1_5 = 2 .* (prec5 .* rec5) ./ (prec5 + rec5);
    f1_5(isnan(f1_5)) = 0;
    
    macroF1 = mean(f1_5);
    
    % QWK
    N_classes = 5;
    w = zeros(N_classes, N_classes);
    for i = 1:N_classes
        for j = 1:N_classes
            w(i,j) = (i - j)^2 / (N_classes - 1)^2;
        end
    end
    actualHist = sum(O, 2);
    predHist = sum(O, 1);
    E = (actualHist * predHist) / sum(O(:));
    if sum(w .* E, 'all') == 0
        qwk = 0;
    else
        qwk = 1 - sum(w .* O, 'all') / sum(w .* E, 'all');
    end
    
    % --- Save Outputs ---
    disp('Saving outputs...');
    
    % 1. messidor2_referable_results.csv (this seems to be messidor2_predictions.csv instead, I will output predictions as requested)
    predTbl = table(t.id_code, labels5Class, gtReferable, ...
        scores(:,1), scores(:,2), scores(:,3), scores(:,4), scores(:,5), ...
        rawRefProb, calibRefProb, predReferable, pred5Class, ...
        'VariableNames', {'filename', 'ground_truth_grade', 'ground_truth_referable', ...
        'P_grade_0', 'P_grade_1', 'P_grade_2', 'P_grade_3', 'P_grade_4', ...
        'raw_referable_probability', 'calibrated_referable_probability', ...
        'predicted_referable', 'predicted_grade'});
    writetable(predTbl, fullfile(outDir, 'messidor2_predictions.csv'));
    
    % Binary metrics CSV
    fid = fopen(fullfile(outDir, 'messidor2_referable_metrics.csv'), 'w');
    fprintf(fid, 'Metric,Raw_Thresh_0.5,Calibrated_Thresh_0.22\n');
    fprintf(fid, 'Accuracy,%.6f,%.6f\n', rAcc, acc);
    fprintf(fid, 'Sensitivity,%.6f,%.6f\n', rSens, sens);
    fprintf(fid, 'Specificity,%.6f,%.6f\n', rSpec, spec);
    fprintf(fid, 'Precision,%.6f,%.6f\n', rPrec, prec);
    fprintf(fid, 'NPV,%.6f,%.6f\n', rNpv, npv);
    fprintf(fid, 'F1,%.6f,%.6f\n', rF1, f1);
    fprintf(fid, 'ROC-AUC,,%.6f\n', roc_auc);
    fprintf(fid, 'Brier,%.6f,%.6f\n', rBrier, brier);
    fprintf(fid, 'ECE,%.6f,%.6f\n', rEce, ece);
    fclose(fid);
    
    % 5-class metrics CSV
    fid = fopen(fullfile(outDir, 'messidor2_5class_metrics.csv'), 'w');
    fprintf(fid, 'Class,Precision,Recall,F1\n');
    for i = 1:5
        fprintf(fid, '%d,%.6f,%.6f,%.6f\n', i-1, prec5(i), rec5(i), f1_5(i));
    end
    fprintf(fid, 'Overall,Accuracy=%.6f,MacroF1=%.6f,QWK=%.6f\n', acc5, macroF1, qwk);
    fclose(fid);
    
    % Binary Confusion Matrix Plot
    fig1 = figure('Visible', 'off');
    cGTBinary = categorical(gtReferable, [0 1], {'Non-Referable', 'Referable'});
    cPredBinary = categorical(predReferable, [0 1], {'Non-Referable', 'Referable'});
    cm = confusionchart(cGTBinary, cPredBinary);
    cm.Title = 'Messidor-2 Referable DR (Calibrated, Thresh 0.22)';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';
    saveas(fig1, fullfile(outDir, 'messidor2_referable_confusion_matrix.png'));
    close(fig1);
    
    % ROC Curve
    fig2 = figure('Visible', 'off');
    [X, Y, ~, AUC] = perfcurve(gtReferable, calibRefProb, 1);
    plot(X, Y, 'LineWidth', 2);
    hold on;
    plot([0 1], [0 1], 'k--');
    xlabel('False Positive Rate');
    ylabel('True Positive Rate');
    title(sprintf('Messidor-2 ROC Curve (AUC = %.4f)', AUC));
    grid on;
    saveas(fig2, fullfile(outDir, 'messidor2_referable_roc_curve.png'));
    close(fig2);
    
    % Reliability Curve
    fig3 = plotReliability(rawRefProb, calibRefProb, gtReferable, 'Messidor-2 Reliability Curve');
    saveas(fig3, fullfile(outDir, 'messidor2_referable_reliability_curve.png'));
    close(fig3);
    
    % 5-Class Confusion Matrix
    fig4 = figure('Visible', 'off');
    cm5 = confusionchart(cTrue, cPred);
    cm5.Title = 'Messidor-2 5-Class Confusion Matrix';
    cm5.RowSummary = 'row-normalized';
    cm5.ColumnSummary = 'column-normalized';
    saveas(fig4, fullfile(outDir, 'messidor2_5class_confusion_matrix.png'));
    close(fig4);
    
    % Save .mat
    save(fullfile(outDir, 'messidor2_external_validation.mat'), ...
        'predTbl', 'O', 'acc', 'sens', 'spec', 'prec', 'npv', 'f1', 'roc_auc', ...
        'brier', 'ece', 'acc5', 'macroF1', 'qwk', 'prec5', 'rec5', 'f1_5');
    
    % --- Final Report ---
    fprintf('\n=== MESSIDOR-2 EXTERNAL VALIDATION COMPLETE ===\n\n');
    fprintf('Dataset:\n');
    fprintf('Images = %d\n', numExpected);
    fprintf('Labels = %d\n', numExpected);
    fprintf('Mapping errors = 0\n\n');
    
    fprintf('Binary Referable-DR:\n');
    fprintf('Threshold = 0.22\n');
    fprintf('Accuracy = %.4f\n', acc);
    fprintf('Sensitivity = %.4f\n', sens);
    fprintf('Specificity = %.4f\n', spec);
    fprintf('Precision = %.4f\n', prec);
    fprintf('NPV = %.4f\n', npv);
    fprintf('F1 = %.4f\n', f1);
    fprintf('ROC-AUC = %.4f\n', roc_auc);
    fprintf('Brier = %.6f\n', brier);
    fprintf('ECE = %.6f\n\n', ece);
    
    fprintf('Secondary 5-Class:\n');
    fprintf('Accuracy = %.4f\n', acc5);
    fprintf('Macro-F1 = %.4f\n', macroF1);
    fprintf('QWK = %.4f\n\n', qwk);
    
    fprintf('Calibration:\n');
    fprintf('Method = APTOS validation-fitted Platt scaling\n');
    fprintf('Threshold = 0.22\n');
    fprintf('Messidor-2 tuning = NONE\n\n');
    
    fprintf('Verification:\n');
    fprintf('Status = PASS\n\n');
    
    fprintf('Output directory:\n');
    fprintf('%s\n', outDir);
end

function ece = computeECE(probs, labels, numBins)
    edges = linspace(0, 1, numBins + 1);
    binIdx = discretize(probs, edges);
    
    ece = 0;
    N = length(labels);
    
    for i = 1:numBins
        idx = (binIdx == i);
        if sum(idx) > 0
            binConf = mean(probs(idx));
            binAcc = mean(labels(idx));
            binCount = sum(idx);
            
            ece = ece + (binCount / N) * abs(binAcc - binConf);
        end
    end
end

function fig = plotReliability(rawProb, calibProb, labels, titleStr)
    fig = figure('Visible', 'off');
    
    [rAcc, rConf] = calcReliability(rawProb, labels, 10);
    [cAcc, cConf] = calcReliability(calibProb, labels, 10);
    
    plot(rConf, rAcc, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b'); hold on;
    plot(cConf, cAcc, 'rs-', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
    plot([0 1], [0 1], 'k--', 'LineWidth', 1);
    
    xlabel('Mean Predicted Probability (Confidence)');
    ylabel('Fraction of Positives (Accuracy)');
    title(titleStr);
    legend('Raw', 'Calibrated', 'Perfect Calibration', 'Location', 'northwest');
    grid on;
end

function [acc, conf] = calcReliability(probs, labels, numBins)
    edges = linspace(0, 1, numBins + 1);
    binIdx = discretize(probs, edges);
    
    acc = [];
    conf = [];
    for i = 1:numBins
        idx = (binIdx == i);
        if sum(idx) > 0
            conf = [conf; mean(probs(idx))];
            acc = [acc; mean(labels(idx))];
        end
    end
end
