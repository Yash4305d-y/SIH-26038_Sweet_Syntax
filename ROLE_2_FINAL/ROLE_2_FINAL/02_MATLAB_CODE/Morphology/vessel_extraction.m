function result = vessel_extraction(I)

if size(I, 3) == 3
    green = I(:, :, 2);
else
    green = I;
end

green = im2double(green);

response = fibermetric(green, [4 6 8 10 12 14], ...
    ObjectPolarity="dark");

response = mat2gray(response);

threshold = graythresh(response);

vesselMask = response >= threshold;

vesselMask = bwareaopen(vesselMask, 150);

result.response = response;
result.mask = vesselMask;
result.threshold = threshold;
result.vesselAreaRatio = nnz(vesselMask) / numel(vesselMask);

end