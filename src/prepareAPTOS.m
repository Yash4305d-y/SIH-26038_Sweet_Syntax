% prepareAPTOS.m
% This script reads the APTOS dataset metadata, prepares full image paths,
% and splits the dataset into training, validation, and testing sets.
% It ensures a reproducible, stratified split (70/15/15) across all 5 DR classes
% and verifies that no data leakage occurs between the splits.

function prepareAPTOS()
    % Define the project root and relevant directories relative to this script
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    dataDir = fullfile(projectDir, 'data');
    rawDir = fullfile(dataDir, 'raw');
    splitsDir = fullfile(dataDir, 'splits');
    
    imgDirTrain = fullfile(rawDir, 'train_images');
    imgDirVal = fullfile(rawDir, 'val_images');
    imgDirTest = fullfile(rawDir, 'test_images');
    
    if ~exist(splitsDir, 'dir')
        mkdir(splitsDir);
    end
    
    csvFile = fullfile(splitsDir, 'train.csv');
    
    % 1. Read the dataset metadata
    if ~exist(csvFile, 'file')
        error('Metadata file not found at: %s', csvFile);
    end
    
    disp('Loading dataset metadata...');
    opts = detectImportOptions(csvFile);
    opts.VariableNamingRule = 'preserve'; % Ensure original names are used
    data = readtable(csvFile, opts);
    
    % Ensure required columns exist
    if ~ismember('id_code', data.Properties.VariableNames) || ...
       ~ismember('diagnosis', data.Properties.VariableNames)
        error('train.csv must contain "id_code" and "diagnosis" columns.');
    end
    
    % 2. Convert id_code values into full image paths
    disp('Converting id_code to full image paths and verifying existence...');
    numSamples = height(data);
    imagePaths = strings(numSamples, 1);
    
    for i = 1:numSamples
        % Extract the ID and append '.png' if it is missing
        imgId = string(data.id_code(i));
        if ~endsWith(imgId, '.png', 'IgnoreCase', true)
            imgName = imgId + ".png";
        else
            imgName = imgId;
        end
        
        fullPathTrain = fullfile(imgDirTrain, imgName);
        fullPathVal = fullfile(imgDirVal, imgName);
        fullPathTest = fullfile(imgDirTest, imgName);
        
        % 3. Verify that every referenced image actually exists
        if exist(fullPathTrain, 'file')
            fullPath = fullPathTrain;
        elseif exist(fullPathVal, 'file')
            fullPath = fullPathVal;
        elseif exist(fullPathTest, 'file')
            fullPath = fullPathTest;
        else
            error('Image missing! Could not find: %s', imgName);
        end
        
        imagePaths(i) = fullPath;
    end
    
    % Append the new full paths to the table
    data.image_path = imagePaths;
    
    % 4. Stratified Split (70% Train, 15% Validation, 15% Test)
    disp('Performing stratified split (70/15/15)...');
    
    % Use a fixed RNG seed to ensure identical splits across runs
    rng(42);
    
    % First split: 70% Train, 30% Temporary (Validation + Test)
    % cvpartition preserves the class ratios (stratified) by default for categorical/numeric groups
    cv1 = cvpartition(data.diagnosis, 'HoldOut', 0.30);
    
    trainData = data(training(cv1), :);
    tempData = data(test(cv1), :);
    
    % Second split: Split the 30% temp data equally into 15% Validation and 15% Test
    cv2 = cvpartition(tempData.diagnosis, 'HoldOut', 0.50);
    
    valData = tempData(training(cv2), :);
    testData = tempData(test(cv2), :);
    
    % 5. Check for data leakage
    disp('Verifying no data leakage between splits...');
    % We use 'intersect' to check if any image_path exists in more than one subset.
    leakTrainVal = intersect(trainData.image_path, valData.image_path);
    leakTrainTest = intersect(trainData.image_path, testData.image_path);
    leakValTest = intersect(valData.image_path, testData.image_path);
    
    if ~isempty(leakTrainVal) || ~isempty(leakTrainTest) || ~isempty(leakValTest)
        % Throw an error if leakage is detected to prevent flawed evaluations
        error('LEAKAGE DETECTED! Overlapping images found between train/val/test splits.');
    end
    disp('Success: No image overlap between subsets.');
    
    % 6. Save the CSV files
    disp('Saving split datasets...');

    
    % Keep only the required columns
    trainOut = trainData(:, {'id_code', 'diagnosis'});
    valOut = valData(:, {'id_code', 'diagnosis'});
    testOut = testData(:, {'id_code', 'diagnosis'});
    
    trainCsvOut = fullfile(splitsDir, 'train_split.csv');
    valCsvOut = fullfile(splitsDir, 'val_split.csv');
    testCsvOut = fullfile(splitsDir, 'test_split.csv');
    
    % Delete existing files to ensure we overwrite malformed ones cleanly
    if exist(trainCsvOut, 'file'), delete(trainCsvOut); end
    if exist(valCsvOut, 'file'), delete(valCsvOut); end
    if exist(testCsvOut, 'file'), delete(testCsvOut); end
    
    writetable(trainOut, trainCsvOut);
    writetable(valOut, valCsvOut);
    writetable(testOut, testCsvOut);
    
    % 7. Print class counts for all three subsets
    disp(' ');
    disp('--- Train Set Class Counts ---');
    disp(groupsummary(trainOut, 'diagnosis'));
    
    disp('--- Validation Set Class Counts ---');
    disp(groupsummary(valOut, 'diagnosis'));
    
    disp('--- Test Set Class Counts ---');
    disp(groupsummary(testOut, 'diagnosis'));
    
    disp('Data preparation complete!');
end
