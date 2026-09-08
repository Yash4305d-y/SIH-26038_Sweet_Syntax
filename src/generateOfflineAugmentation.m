% src/generateOfflineAugmentation.m
% Generates an offline augmented dataset (original + 1 augmented per image)
% without loading the full dataset into RAM.

function generateOfflineAugmentation()
    % Setup paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    outTrainDir = fullfile(projectDir, 'data', 'processed', 'offline_augmented', 'train');
    outValDir = fullfile(projectDir, 'data', 'processed', 'offline_augmented', 'val');
    
    if ~exist(outTrainDir, 'dir'), mkdir(outTrainDir); end
    if ~exist(outValDir, 'dir'), mkdir(outValDir); end
    
    % Load original datastores (paths only, no data in RAM)
    disp('Loading original APTOS image datastores for splits...');
    [imdsTrain, imdsVal, ~] = createAPTOSDatastores();
    
    % Deterministic RNG
    rng(42, 'twister');
    
    disp('Generating offline training dataset (Original + 1 Augmented)...');
    processDataset(imdsTrain, outTrainDir, true);
    
    disp('Generating offline validation dataset (Original only, NO augmentation)...');
    processDataset(imdsVal, outValDir, false);
    
    disp('Dataset generation complete!');
end

function processDataset(imds, outDir, doAugment)
    files = imds.Files;
    labels = imds.Labels;
    numFiles = numel(files);
    
    for i = 1:numFiles
        [~, name, ext] = fileparts(files{i});
        if isempty(ext), ext = '.png'; end
        
        % Read and convert
        img = imread(files{i});
        if size(img, 3) == 1
            img = repmat(img, [1 1 3]);
        elseif size(img, 3) == 4
            img = img(:, :, 1:3);
        end
        
        % Resize
        img224 = imresize(img, [224, 224]);
        
        % Save original (with label in filename for easy datastore creation)
        origName = sprintf('%s_orig_class%s.png', name, char(labels(i)));
        imwrite(img224, fullfile(outDir, origName));
        
        if doAugment
            augImg = applyConservativeAugmentation(img224);
            augName = sprintf('%s_aug_class%s.png', name, char(labels(i)));
            imwrite(augImg, fullfile(outDir, augName));
        end
        
        % Memory management
        clear img img224 augImg;
        
        if mod(i, 500) == 0
            fprintf('Processed %d/%d images...\n', i, numFiles);
        end
    end
end

function imgOut = applyConservativeAugmentation(imgIn)
    % Manual transformations on 224x224 image
    
    % 1. Rotation [-10, 10]
    angle = -10 + 20 * rand();
    
    % 2. Translation +/- 5% (11 pixels for 224)
    tx = -11 + 22 * rand();
    ty = -11 + 22 * rand();
    
    % 3. Scale [0.95, 1.05]
    scale = 0.95 + 0.1 * rand();
    
    % Create affine transformation
    tform = affine2d([scale*cosd(angle) -scale*sind(angle) 0; ...
                      scale*sind(angle)  scale*cosd(angle) 0; ...
                      tx ty 1]);
                      
    % Apply affine with reflection padding to avoid black borders if possible,
    % but imwarp uses fill values. We will use 'replicate' to be safe.
    imgOut = imwarp(imgIn, tform, 'OutputView', imref2d(size(imgIn)), 'FillValues', 0);
    
    % 4. Horizontal Flip (50%)
    if rand() > 0.5
        imgOut = fliplr(imgOut);
    end
    
    % 5. Brightness/Contrast
    % Convert to double for safe math
    imgD = im2double(imgOut);
    
    % Brightness: +/- 10%
    bDelta = -0.1 + 0.2 * rand();
    imgD = imgD + bDelta;
    
    % Contrast: 0.9 to 1.1
    cDelta = 0.9 + 0.2 * rand();
    imgD = (imgD - 0.5) * cDelta + 0.5;
    
    % Clip and convert back
    imgD(imgD < 0) = 0;
    imgD(imgD > 1) = 1;
    imgOut = im2uint8(imgD);
end
