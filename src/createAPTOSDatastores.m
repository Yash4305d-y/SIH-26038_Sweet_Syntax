% createAPTOSDatastores.m
% This script reads the APTOS dataset splits, verifies image paths,
% creates imageDatastore objects, and displays a sample image.

function [imdsTrain, imdsVal, imdsTest] = createAPTOSDatastores()
    % Define directories relative to the project root
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    dataDir = fullfile(projectDir, 'data');
    splitsDir = fullfile(dataDir, 'splits');
    rawDir = fullfile(dataDir, 'raw');
    
    trainImgDir = fullfile(rawDir, 'train_images');
    valImgDir = fullfile(rawDir, 'val_images');
    testImgDir = fullfile(rawDir, 'test_images');
    
    trainCsvFile = fullfile(splitsDir, 'train_split.csv');
    valCsvFile = fullfile(splitsDir, 'val_split.csv');
    testCsvFile = fullfile(splitsDir, 'test_split.csv');
    
    if ~exist(trainCsvFile, 'file') || ~exist(valCsvFile, 'file') || ~exist(testCsvFile, 'file')
        error('Split CSV files not found. Please run prepareAPTOS.m first.');
    end
    
    % 1. Read the split CSV files
    disp('Loading split datasets...');
    trainData = readtable(trainCsvFile, 'PreserveVariableNames', true);
    valData = readtable(valCsvFile, 'PreserveVariableNames', true);
    testData = readtable(testCsvFile, 'PreserveVariableNames', true);
    
    % Helper function to build paths, verify existence, extract labels, and check integrity
    function [paths, labels] = processData(dataTbl, imgDirName, datasetName)
        disp(['Verifying images for ', datasetName, ' dataset...']);
        numSamples = height(dataTbl);
        
        % Initialize as empty string array, NOT <missing> to avoid bad allocation later
        paths = repmat("", numSamples, 1);
        missingCount = 0;
        corruptCount = 0;
        
        for i = 1:numSamples
            % Determine image identifier column
            if ismember('image_path', dataTbl.Properties.VariableNames)
                imgId = string(dataTbl.image_path(i));
            elseif ismember('id_code', dataTbl.Properties.VariableNames)
                imgId = string(dataTbl.id_code(i));
            else
                error('CSV must contain either "image_path" or "id_code".');
            end
            
            % Robust path construction
            [~, name, ext] = fileparts(imgId);
            if isempty(char(ext))
                ext = '.png';
            end
            
            imgName = [char(name), char(ext)];
            fullPathTrain = fullfile(trainImgDir, imgName);
            fullPathVal = fullfile(valImgDir, imgName);
            fullPathTest = fullfile(testImgDir, imgName);
            
            % 3. Build full image paths by checking all three directories
            if exist(fullPathTrain, 'file')
                fullPath = fullPathTrain;
            elseif exist(fullPathVal, 'file')
                fullPath = fullPathVal;
            elseif exist(fullPathTest, 'file')
                fullPath = fullPathTest;
            else
                warning('Missing image in %s dataset: %s. Skipping.', datasetName, imgName);
                missingCount = missingCount + 1;
                continue;
            end
            
            % Check if file is readable
            try
                imfinfo(fullPath);
            catch
                warning('Unreadable/corrupt image in %s dataset: %s. Skipping.', datasetName, imgName);
                corruptCount = corruptCount + 1;
                continue;
            end
            
            paths(i) = fullPath;
        end
        
        % Safely remove skipped paths by checking string length (filters out "" and <missing>)
        validIdx = strlength(paths) > 0;
        paths = paths(validIdx);
        labels = categorical(dataTbl.diagnosis(validIdx));
        
        % Print integrity summary
        validCount = numel(paths);
        fprintf('\n--- %s Dataset Integrity Summary ---\n', datasetName);
        fprintf('Original CSV rows: %d\n', numSamples);
        fprintf('Missing files    : %d\n', missingCount);
        fprintf('Unreadable files : %d\n', corruptCount);
        fprintf('Valid files      : %d\n', validCount);
        fprintf('----------------------------------------\n\n');
    end
    
    [trainPaths, trainLabels] = processData(trainData, trainImgDir, 'Train');
    [valPaths, valLabels] = processData(valData, valImgDir, 'Validation');
    [testPaths, testLabels] = processData(testData, testImgDir, 'Test');
    
    % Sanity check: confirm all 5 classes exist in the training labels
    uniqueTrainClasses = unique(trainLabels);
    disp(' ');
    disp('--- Sanity Check ---');
    if length(uniqueTrainClasses) == 5 && all(ismember({'0', '1', '2', '3', '4'}, string(uniqueTrainClasses)))
        disp('Success: All 5 DR classes (0, 1, 2, 3, 4) are present in the training labels.');
    else
        warning('Not all 5 DR classes are present in the training labels!');
        disp(uniqueTrainClasses);
    end
    
    % 4. Create MATLAB imageDatastore objects
    disp('Creating imageDatastores...');
    imdsTrain = imageDatastore(trainPaths, 'Labels', trainLabels);
    imdsVal = imageDatastore(valPaths, 'Labels', valLabels);
    imdsTest = imageDatastore(testPaths, 'Labels', testLabels);
    
    % 7. Print counts and distributions
    disp(' ');
    disp('--- Dataset Summary ---');
    fprintf('Number of training images: %d\n', numel(imdsTrain.Files));
    fprintf('Number of validation images: %d\n', numel(imdsVal.Files));
    fprintf('Number of test images: %d\n', numel(imdsTest.Files));
    
    disp(' ');
    disp('--- Class Distribution (Train) ---');
    disp(countEachLabel(imdsTrain));
    
    disp('--- Class Distribution (Validation) ---');
    disp(countEachLabel(imdsVal));
    
    disp('--- Class Distribution (Test) ---');
    disp(countEachLabel(imdsTest));
    
    % 8. Display one sample image from the training datastore with its label
    disp('Displaying a sample image from the training set...');
    [sampleImg, sampleInfo] = read(imdsTrain);
    figure('Name', 'Sample Image from Training Datastore');
    imshow(sampleImg);
    title(sprintf('Training Sample - Label: %s', char(sampleInfo.Label)));
    
    % Reset the datastore so it can be reused from the beginning
    reset(imdsTrain);
    
    disp('Datastore creation complete!');
end
