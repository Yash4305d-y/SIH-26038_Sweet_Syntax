function result = fov_score(I)

if size(I, 3) == 3
    gray = rgb2gray(I);
else
    gray = I;
end

gray = im2double(gray);

mask = gray > 0.05;

mask = imfill(mask, "holes");
mask = bwareafilt(mask, 1);

areaRatio = nnz(mask) / numel(mask);

stats = regionprops(mask, "Area", "Perimeter", "BoundingBox", "Centroid");

if isempty(stats)
    result.areaRatio = 0;
    result.circularity = 0;
    result.boundingBoxRatio = 0;
    result.detected = false;
    return;
end

area = stats.Area;
perimeter = stats.Perimeter;

if perimeter > 0
    circularity = 4 * pi * area / perimeter^2;
else
    circularity = 0;
end

bbox = stats.BoundingBox;

boundingBoxArea = bbox(3) * bbox(4);
boundingBoxRatio = boundingBoxArea / numel(mask);

result.areaRatio = areaRatio;
result.circularity = circularity;
result.boundingBoxRatio = boundingBoxRatio;
result.detected = true;

end