function result = iqa_gate(I, thresholds)

focus = focus_score(I);
illumination = illumination_score(I);
fov = fov_score(I);

focusPass = focus >= thresholds.focusMin;

illuminationPass = ...
    illumination.meanIntensity >= thresholds.meanMin && ...
    illumination.meanIntensity <= thresholds.meanMax && ...
    illumination.darkPixelRatio <= thresholds.darkMax && ...
    illumination.brightPixelRatio <= thresholds.brightMax;

fovPass = ...
    fov.areaRatio >= thresholds.areaMin && ...
    fov.circularity >= thresholds.circularityMin;

result.focusScore = focus;
result.illumination = illumination;
result.fov = fov;

result.focusPass = focusPass;
result.illuminationPass = illuminationPass;
result.fovPass = fovPass;

result.pass = focusPass && illuminationPass && fovPass;

if ~focusPass
    result.reason = "Focus failure";
elseif ~illuminationPass
    result.reason = "Illumination failure";
elseif ~fovPass
    result.reason = "FOV failure";
else
    result.reason = "PASS";
end

end