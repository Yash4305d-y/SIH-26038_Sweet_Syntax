function result = exudate_candidates(I)

if size(I, 3) == 3
    green = I(:, :, 2);
else
    green = I;
end

green = im2double(green);

se = strel("disk", 8);

response = imtophat(green, se);
response = mat2gray(response);

otsuThreshold = graythresh(response);
percentileThreshold = prctile(response(:), 99);

threshold = max(otsuThreshold, percentileThreshold);

candidateMask = response >= threshold;

candidateMask = bwareaopen(candidateMask, 20);

candidateMask = imclose(candidateMask, strel("disk", 2));

candidateMask = bwareaopen(candidateMask, 20);

result.response = response;
result.mask = candidateMask;
result.threshold = threshold;
result.candidateAreaRatio = nnz(candidateMask) / numel(candidateMask);

end