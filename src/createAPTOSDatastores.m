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
    imgDir = fullfile(dataDir, 'APTOS', 'train_images');
    
    trainCsvFile = fullfile(splitsDir, 'aptos_train.csv');
    valCsvFile = fullfile(splitsDir, 'aptos_val.csv');
    testCsvFile = fullfile(splitsDir, 'aptos_test.csv');
    
    if ~exist(trainCsvFile, 'file') || ~exist(valCsvFile, 'file') || ~exist(testCsvFile, 'file')
        error('Split CSV files not found. Please run prepareAPTOS.m first.');
    end
    
    % 1. Read the split CSV files
    disp('Loading split datasets...');
    trainData = readtable(trainCsvFile, 'PreserveVariableNames', true);
    valData = readtable(valCsvFile, 'PreserveVariableNames', true);
    testData = readtable(testCsvFile, 'PreserveVariableNames', true);
    
    % Helper function to build paths, verify existence, and extract labels
    function [paths, labels] = processData(dataTbl, imgDirName, datasetName)
        disp(['Verifying images for ', datasetName, ' dataset...']);
        numSamples = height(dataTbl);
        paths = strings(numSamples, 1);
        
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
            
            % 3. Build full image paths
            fullPath = fullfile(imgDirName, [char(name), char(ext)]);
            
            % 6. Verify that every image exists
            if ~exist(fullPath, 'file')
                error('Missing image in %s dataset: %s', datasetName, fullPath);
            end
            
            paths(i) = fullPath;
        end
        
        % 5. Labels must be categorical with the five DR classes: 0, 1, 2, 3, 4
        labels = categorical(dataTbl.diagnosis);
    end
    
    [trainPaths, trainLabels] = processData(trainData, imgDir, 'Train');
    [valPaths, valLabels] = processData(valData, imgDir, 'Validation');
    [testPaths, testLabels] = processData(testData, imgDir, 'Test');
    
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
