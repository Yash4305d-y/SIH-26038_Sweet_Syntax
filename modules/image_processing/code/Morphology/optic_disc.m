function result = optic_disc(I)

if size(I, 3) == 3
    gray = rgb2gray(I);
else
    gray = I;
end

gray = im2double(gray);

threshold = prctile(gray(:), 99.5);
brightMask = gray >= threshold;

brightMask = bwareaopen(brightMask, 50);

stats = regionprops(brightMask, ...
    "Area", ...
    "Perimeter", ...
    "Centroid", ...
    "BoundingBox");

candidates = [];

for k = 1:length(stats)

    area = stats(k).Area;
    perimeter = stats(k).Perimeter;

    if perimeter > 0
        compactness = 4 * pi * area / perimeter^2;
    else
        compactness = 0;
    end

    candidates = [candidates; ...
        k, area, perimeter, compactness];
end

if isempty(candidates)
    result.detected = false;
    result.candidates = [];
    result.bestCandidate = [];
    return;
end

valid = candidates(:,4) >= 0.50;

validCandidates = candidates(valid,:);

if isempty(validCandidates)
    result.detected = false;
    result.candidates = candidates;
    result.bestCandidate = [];
    return;
end

score = validCandidates(:,4) .* sqrt(validCandidates(:,2));

[~, idx] = max(score);

bestIndex = validCandidates(idx,1);
result.detected = true;
result.candidates = candidates;
result.bestCandidate = stats(bestIndex);
result.compactness = validCandidates(idx,4);

end