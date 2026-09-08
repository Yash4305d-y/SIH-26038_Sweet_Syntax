% src/analyzeGradCAMRepresentativeCases.m
% Analyzes the verified Grad-CAM dataset to select the best representative cases.

function analyzeGradCAMRepresentativeCases()
    % Setup paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    csvPath = fullfile(projectDir, 'outputs', 'gradcam', 'final', 'gradcam_results.csv');
    sourceImgDir = fullfile(projectDir, 'outputs', 'gradcam', 'final');
    outDir = fullfile(projectDir, 'outputs', 'gradcam', 'selected_cases');
    
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    
    % 1. Load gradcam_results.csv
    if ~exist(csvPath, 'file')
        error('Results CSV not found at %s', csvPath);
    end
    t = readtable(csvPath, 'PreserveVariableNames', true);
    
    % 2. Verify 439 rows
    if height(t) ~= 439
        error('Expected 439 rows, found %d', height(t));
    end
    
    % Ensure IsCorrect is logical
    t.IsCorrect = logical(t.IsCorrect);
    
    disp('Successfully loaded Grad-CAM results.');
    fprintf('Total images: %d\n', height(t));
    fprintf('Correct: %d\n', sum(t.IsCorrect));
    fprintf('Misclassified: %d\n', sum(~t.IsCorrect));
    
    % Initialize selection table
    selectedTbl = table('Size', [0, 8], ...
        'VariableTypes', {'string', 'double', 'double', 'logical', 'double', 'string', 'double', 'logical'}, ...
        'VariableNames', {'ImageFilename', 'GroundTruth', 'Prediction', 'IsCorrect', 'Confidence', 'Category', 'Rank', 'GradCAMStatisticsAvailable'});
        
    % Helper function to resolve source path
    function p = getSourcePath(row)
        [~, name, ~] = fileparts(string(row.ImageFilename));
        status = 'correct';
        if ~row.IsCorrect, status = 'wrong'; end
        fileName = sprintf('%s_GT%d_Pred%d.png', name, row.GroundTruth, row.Prediction);
        p = fullfile(sourceImgDir, status, sprintf('class_%d', row.GroundTruth), fileName);
    end

    % Helper function to copy and record
    function recordCase(row, category, rank, newNamePrefix)
        % Add to table
        newRow = {string(row.ImageFilename), row.GroundTruth, row.Prediction, ...
            row.IsCorrect, row.Confidence, string(category), rank, true};
        selectedTbl = [selectedTbl; newRow];
        
        % Copy file
        srcPath = getSourcePath(row);
        [~, name, ~] = fileparts(string(row.ImageFilename));
        
        if exist(srcPath, 'file')
            destName = sprintf('%s_%s.png', newNamePrefix, name);
            destPath = fullfile(outDir, destName);
            copyfile(srcPath, destPath);
        else
            warning('Source file not found: %s', srcPath);
        end
    end

    disp('--- Identifying Representative Cases ---');
    
    % A. Top 10 high-confidence correct predictions
    correctTbl = t(t.IsCorrect, :);
    % Sort by Confidence (descending), then CentroidDist (ascending - more centered focus)
    correctTbl = sortrows(correctTbl, {'Confidence', 'CentroidDist'}, {'descend', 'ascend'});
    
    numTopCorrect = min(10, height(correctTbl));
    for i = 1:numTopCorrect
        recordCase(correctTbl(i,:), 'Top10_Correct_HighConf', i, sprintf('top_correct_%02d_GT%d', i, correctTbl.GroundTruth(i)));
    end
    
    % B. Top 10 high-confidence misclassifications
    wrongTbl = t(~t.IsCorrect, :);
    wrongTbl = sortrows(wrongTbl, {'Confidence', 'CentroidDist'}, {'descend', 'ascend'});
    
    numTopWrong = min(10, height(wrongTbl));
    for i = 1:numTopWrong
        recordCase(wrongTbl(i,:), 'Top10_Wrong_HighConf', i, sprintf('top_wrong_%02d_GT%d_Pred%d', i, wrongTbl.GroundTruth(i), wrongTbl.Prediction(i)));
    end
    
    % C. Best representative case for each DR grade
    for g = 0:4
        classTbl = correctTbl(correctTbl.GroundTruth == g, :);
        if ~isempty(classTbl)
            % Best = highest confidence
            recordCase(classTbl(1,:), 'Best_Representative_Grade', 1, sprintf('grade%d_best_rep', g));
        end
    end
    
    % D. Most interesting misclassification for each grade
    for g = 0:4
        classWrongTbl = wrongTbl(wrongTbl.GroundTruth == g, :);
        if ~isempty(classWrongTbl)
            % For interesting misclassifications, prefer high centroid distance (artifacts)
            % Fall back to high confidence if centroid differences are negligible.
            classWrongTbl = sortrows(classWrongTbl, {'CentroidDist', 'Confidence'}, {'descend', 'descend'});
            recordCase(classWrongTbl(1,:), 'Interesting_Misclassification_Grade', 1, sprintf('grade%d_interesting_wrong', g));
        end
    end
    
    % Remove duplicates in selectedTbl if any image was selected multiple times
    [~, uniqueIdx] = unique(selectedTbl.ImageFilename, 'stable');
    selectedTbl = selectedTbl(uniqueIdx, :);
    
    % Save CSV
    csvOutPath = fullfile(outDir, 'representative_cases.csv');
    writetable(selectedTbl, csvOutPath);
    
    % Report
    fprintf('\nSelection complete. Copied %d unique files to %s.\n', height(selectedTbl), outDir);
    fprintf('Saved selection summary to %s.\n\n', csvOutPath);
    
    % Print Report
    disp('=== TOP 5 CORRECT CASES ===');
    for i = 1:min(5, height(correctTbl))
        row = correctTbl(i,:);
        fprintf('GT: %d | Pred: %d | Conf: %.4f | File: %s\n', row.GroundTruth, row.Prediction, row.Confidence, char(row.ImageFilename));
    end
    
    disp('=== TOP 5 MISCLASSIFIED CASES ===');
    for i = 1:min(5, height(wrongTbl))
        row = wrongTbl(i,:);
        fprintf('GT: %d | Pred: %d | Conf: %.4f | File: %s\n', row.GroundTruth, row.Prediction, row.Confidence, char(row.ImageFilename));
    end
    
    disp('=== BEST REPRESENTATIVE BY GRADE ===');
    for g = 0:4
        classTbl = correctTbl(correctTbl.GroundTruth == g, :);
        if ~isempty(classTbl)
            row = classTbl(1,:);
            fprintf('Grade %d | Conf: %.4f | Centroid Dist: %.2f | File: %s\n', g, row.Confidence, row.CentroidDist, char(row.ImageFilename));
        end
    end
    
    disp('Analysis script completed successfully.');
end
