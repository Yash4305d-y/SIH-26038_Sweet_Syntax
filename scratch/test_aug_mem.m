% scratch/test_aug_mem.m
clc; clear;
[imdsTrain, ~, ~] = createAPTOSDatastores();
imdsTrain = subset(imdsTrain, 1:16); % Just 1 batch

imdsTrain.ReadFcn = @readAndResize;
augmenter = imageDataAugmenter('RandRotation', [-10, 10]);
augimdsTrain = augmentedImageDatastore([224 224], imdsTrain, 'DataAugmentation', augmenter);

try
    data = read(augimdsTrain);
    disp('Successfully read augmented batch of resized images!');
    disp(size(data.input{1}));
catch ME
    disp(ME.message);
end

function img = readAndResize(loc)
    img = imread(loc);
    if size(img, 3) == 1
        img = repmat(img, [1 1 3]);
    elseif size(img, 3) == 4
        img = img(:, :, 1:3);
    end
    img = imresize(img, [224 224]);
end
