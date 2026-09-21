function result = neovascularization_candidates(vesselMask)
% NEOVASCULARIZATION_CANDIDATES
% Heuristic neovascularization candidate extraction
%
% This is a conservative morphology-based candidate evidence extractor.
% It identifies regions with abnormally high branching concentration
% as a proxy for neovascular mesh networks. 
% IMPORTANT: This is candidate evidence, NOT a clinically validated
% neovascularization classification.

% 1. Skeletonize the vessel mask to find centerlines
skel = bwmorph(vesselMask, 'skel', Inf);

% 2. Extract branch points from the skeleton
bp = bwmorph(skel, 'branchpoints');

% 3. Calculate local branch point density
% Use a 61x61 disk neighborhood to count branch points locally
se = strel('disk', 30);
bp_density = imfilter(double(bp), double(se.Neighborhood), 'same');

% 4. Threshold for abnormally dense branching
% A region with >= 15 branch points in this radius is flagged
threshold = 15;
nvMask = bp_density >= threshold;

% 5. Clean up isolated noise
nvMask = bwareaopen(nvMask, 50);

% 6. Compile candidate evidence
cc = bwconncomp(nvMask);

result.detected = cc.NumObjects > 0;
result.candidateCount = cc.NumObjects;
result.candidateAreaRatio = nnz(nvMask) / numel(nvMask);
result.mask = nvMask;
result.method = 'Local branch point density heuristic';

end
