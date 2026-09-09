function result = role2_pipeline(I)

result = struct();

iqaThresholds.focusMin = 0.00003;

iqaThresholds.meanMin = 0.07;
iqaThresholds.meanMax = 0.70;

iqaThresholds.darkMax = 0.54;
iqaThresholds.brightMax = 0.50;

iqaThresholds.areaMin = 0.20;
iqaThresholds.circularityMin = 0.09;

iqa = iqa_gate(I, iqaThresholds);

result.iqa = iqa;

if ~iqa.pass
    result.status = "FAIL";
    result.reason = iqa.reason;
    return;
end

preprocessed = preprocess_fundus(I);

result.status = "PASS";
result.preprocessed = preprocessed;

result.vessels = vessel_extraction(preprocessed);

result.opticDisc = optic_disc(preprocessed);

result.fovea = fovea_heuristic(preprocessed, result.opticDisc);

result.exudates = exudate_candidates(preprocessed);

result.exudates.features = lesion_features( ...
    preprocessed, ...
    result.exudates.mask, ...
    result.exudates.response, ...
    result.vessels.mask, ...
    result.opticDisc, ...
    result.fovea);

result.maHemorrhage = ma_hemorrhage_candidates(preprocessed, result.vessels.mask);

result.maHemorrhage.features = lesion_features( ...
    preprocessed, ...
    result.maHemorrhage.mask, ...
    result.maHemorrhage.response, ...
    result.vessels.mask, ...
    result.opticDisc, ...
    result.fovea);

result.summary = lesion_summary(result);

end