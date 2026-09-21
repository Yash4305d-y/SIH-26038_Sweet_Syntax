function result = fovea_heuristic(I, disc)

if size(I, 3) == 3
    gray = rgb2gray(I);
else
    gray = I;
end

gray = im2double(gray);

if ~disc.detected
    result.detected = false;
    result.centroid = [];
    result.score = [];
    return;
end

discCenter = disc.bestCandidate.Centroid;

[height, width] = size(gray);

searchCenterX = discCenter(1) - 0.20 * width;
searchCenterY = discCenter(2);

searchWidth = 0.25 * width;
searchHeight = 0.25 * height;

x1 = max(1, round(searchCenterX - searchWidth / 2));
x2 = min(width, round(searchCenterX + searchWidth / 2));

y1 = max(1, round(searchCenterY - searchHeight / 2));
y2 = min(height, round(searchCenterY + searchHeight / 2));

roi = gray(y1:y2, x1:x2);

darkThreshold = graythresh(roi);

darkMask = roi <= darkThreshold;

darkMask = bwareaopen(darkMask, 20);

stats = regionprops(darkMask, ...
    "Area", ...
    "Centroid");

if isempty(stats)
    result.detected = false;
    result.centroid = [];
    result.score = [];
    result.roi = [x1 y1 x2-x1+1 y2-y1+1];
    return;
end

scores = zeros(length(stats), 1);

for k = 1:length(stats)
    scores(k) = stats(k).Area;
end

[~, bestIndex] = max(scores);

localCentroid = stats(bestIndex).Centroid;

globalCentroid = [ ...
    localCentroid(1) + x1 - 1, ...
    localCentroid(2) + y1 - 1];

result.detected = true;
result.centroid = globalCentroid;
result.score = scores(bestIndex);
result.roi = [x1 y1 x2-x1+1 y2-y1+1];

end