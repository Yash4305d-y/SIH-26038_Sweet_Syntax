function result = ma_hemorrhage_candidates(I, vesselMask)

if size(I, 3) == 3
    green = I(:, :, 2);
else
    green = I;
end

green = im2double(green);

se = strel("disk", 10);

response = imbothat(green, se);
response = mat2gray(response);

threshold = prctile(response(:), 99.5);

candidateMask = response >= threshold;

candidateMask = candidateMask & ~vesselMask;

candidateMask = bwareaopen(candidateMask, 20);

candidateMask = imclose(candidateMask, strel("disk", 2));

result.response = response;
result.mask = candidateMask;
result.threshold = threshold;
result.candidateAreaRatio = nnz(candidateMask) / numel(candidateMask);

end