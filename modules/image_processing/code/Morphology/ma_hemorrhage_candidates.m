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

cc = bwconncomp(candidateMask);
stats = regionprops(cc, 'Area');
areas = [stats.Area];

ma_idx = find(areas <= 100);
hem_idx = find(areas > 100);

maMask = false(size(candidateMask));
if ~isempty(ma_idx)
    maMask(vertcat(cc.PixelIdxList{ma_idx})) = true;
end

hemMask = false(size(candidateMask));
if ~isempty(hem_idx)
    hemMask(vertcat(cc.PixelIdxList{hem_idx})) = true;
end

result.microaneurysm.detected = nnz(maMask) > 0;
result.microaneurysm.candidateCount = length(ma_idx);
result.microaneurysm.candidateAreaRatio = nnz(maMask) / numel(maMask);
result.microaneurysm.mask = maMask;

result.hemorrhage.detected = nnz(hemMask) > 0;
result.hemorrhage.candidateCount = length(hem_idx);
result.hemorrhage.candidateAreaRatio = nnz(hemMask) / numel(hemMask);
result.hemorrhage.mask = hemMask;

end