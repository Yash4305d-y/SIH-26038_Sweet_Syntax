function features = lesion_features(I, candidateMask, response, vesselMask, opticDisc, fovea)

if size(I,3) == 3
    green = im2double(I(:,:,2));
else
    green = im2double(I);
end

cc = bwconncomp(candidateMask);
stats = regionprops(cc, green, ...
    "Area", ...
    "Centroid", ...
    "BoundingBox", ...
    "Perimeter", ...
    "MeanIntensity", ...
    "MaxIntensity");

n = cc.NumObjects;

features = struct( ...
    "count", n, ...
    "area", [], ...
    "centroid", [], ...
    "boundingBox", [], ...
    "perimeter", [], ...
    "circularity", [], ...
    "meanIntensity", [], ...
    "maxResponse", [], ...
    "vesselOverlap", [], ...
    "distanceFromDisc", [], ...
    "distanceFromFovea", []);

if n == 0
    return;
end

area = zeros(n,1);
centroid = zeros(n,2);
boundingBox = zeros(n,4);
perimeter = zeros(n,1);
circularity = zeros(n,1);
meanIntensity = zeros(n,1);
maxResponse = zeros(n,1);
vesselOverlap = zeros(n,1);
distanceFromDisc = zeros(n,1);
distanceFromFovea = zeros(n,1);

for k = 1:n

    area(k) = stats(k).Area;
    centroid(k,:) = stats(k).Centroid;
    boundingBox(k,:) = stats(k).BoundingBox;
    perimeter(k) = stats(k).Perimeter;
    meanIntensity(k) = stats(k).MeanIntensity;

    pixels = cc.PixelIdxList{k};
    maxResponse(k) = max(response(pixels));

    if perimeter(k) > 0
        circularity(k) = min(1, 4*pi*area(k)/(perimeter(k)^2));
    end

    vesselOverlap(k) = sum(vesselMask(pixels)) / numel(pixels);

    if opticDisc.detected && ~isempty(opticDisc.bestCandidate)
        discCenter = opticDisc.bestCandidate.Centroid;
        distanceFromDisc(k) = norm(centroid(k,:) - discCenter);
    end

    if fovea.detected
        distanceFromFovea(k) = norm(centroid(k,:) - fovea.centroid);
    end

end

features.area = area;
features.centroid = centroid;
features.boundingBox = boundingBox;
features.perimeter = perimeter;
features.circularity = circularity;
features.meanIntensity = meanIntensity;
features.maxResponse = maxResponse;
features.vesselOverlap = vesselOverlap;
features.distanceFromDisc = distanceFromDisc;
features.distanceFromFovea = distanceFromFovea;

end