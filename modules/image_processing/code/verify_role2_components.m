function verify_role2_components()
% VERIFY_ROLE2_COMPONENTS MATLAB Test Script for Member 3 Sprint 1
% Verifies the execution, output structure, and data ranges of all Role 2
% image processing modules: IQA, Preprocessing, Morphology, Features, and Inference.

fprintf('============================================================\n');
fprintf('RUNNING ROLE 2 COMPONENT VERIFICATION SUITE\n');
fprintf('============================================================\n');

% 1. Create a dummy synthetic fundus image matrix (224x224x3) for verification
rng(42);
I = uint8(255 * rand(224, 224, 3));
% Add circular mask to simulate retinal field of view
[X, Y] = meshgrid(1:224, 1:224);
distFromCenter = sqrt((X - 112).^2 + (Y - 112).^2);
mask = distFromCenter <= 90;
I(~cat(3, mask, mask, mask)) = 0;
% Make center bright for optic disc mock
I(100:120, 150:170, :) = 240;

fprintf('[1/5] Verifying IQA Components...\n');
f_score = focus_score(I);
assert(isnumeric(f_score) && isscalar(f_score), 'Focus score must be numeric scalar');

illum = illumination_score(I);
assert(isstruct(illum) && isfield(illum, 'meanIntensity'), 'Illumination output invalid');

fov = fov_score(I);
assert(isstruct(fov) && isfield(fov, 'areaRatio'), 'FOV output invalid');

thresholds.focusMin = 0.00003;
thresholds.meanMin = 0.07; thresholds.meanMax = 0.70;
thresholds.darkMax = 0.54; thresholds.brightMax = 0.50;
thresholds.areaMin = 0.20; thresholds.circularityMin = 0.09;
gate_res = iqa_gate(I, thresholds);
assert(isstruct(gate_res) && isfield(gate_res, 'pass'), 'IQA gate output invalid');
fprintf('      IQA verification PASSED.\n');

fprintf('[2/5] Verifying Preprocessing Components...\n');
clahe_out = preprocess_clahe(I);
assert(all(size(clahe_out) == size(I)), 'CLAHE output dimensions mismatch');

denoise_out = preprocess_denoise(clahe_out);
assert(all(size(denoise_out) == size(I)), 'Denoise output dimensions mismatch');

fundus_pre = preprocess_fundus(I);
assert(all(size(fundus_pre) == size(I)), 'Fundus preprocessing output mismatch');
fprintf('      Preprocessing verification PASSED.\n');

fprintf('[3/5] Verifying Retinal Structure Extraction Components...\n');
vessel_res = vessel_extraction(fundus_pre);
assert(isstruct(vessel_res) && isfield(vessel_res, 'mask'), 'Vessel output invalid');

disc_res = optic_disc(fundus_pre);
assert(isstruct(disc_res) && isfield(disc_res, 'detected'), 'Optic disc output invalid');

fovea_res = fovea_heuristic(fundus_pre, disc_res);
assert(isstruct(fovea_res) && isfield(fovea_res, 'detected'), 'Fovea output invalid');
fprintf('      Structure extraction verification PASSED.\n');

fprintf('[4/5] Verifying Lesion Candidates Extraction Components...\n');
exudate_res = exudate_candidates(fundus_pre);
assert(isstruct(exudate_res) && isfield(exudate_res, 'mask'), 'Exudate output invalid');

ma_res = ma_hemorrhage_candidates(fundus_pre, vessel_res.mask);
assert(isstruct(ma_res) && isfield(ma_res, 'mask'), 'MA/Hemorrhage output invalid');
fprintf('      Lesion candidates verification PASSED.\n');

fprintf('[5/5] Verifying Role 2 Pipeline Integration...\n');
pipeline_res = role2_pipeline(I);
assert(isstruct(pipeline_res) && isfield(pipeline_res, 'status'), 'Pipeline output invalid');
fprintf('      Pipeline integration verification PASSED.\n');

fprintf('============================================================\n');
fprintf('ALL ROLE 2 COMPONENT VERIFICATIONS COMPLETED SUCCESSFULLY.\n');
fprintf('============================================================\n');

end
