function summary = lesion_summary(result)

summary = struct();

summary.iqaStatus = result.status;

summary.vesselAreaRatio = result.vessels.vesselAreaRatio;

summary.opticDiscDetected = result.opticDisc.detected;

if result.opticDisc.detected
    summary.opticDiscCompactness = result.opticDisc.compactness;
else
    summary.opticDiscCompactness = 0;
end

summary.foveaDetected = result.fovea.detected;

if result.fovea.detected
    summary.foveaX = result.fovea.centroid(1);
    summary.foveaY = result.fovea.centroid(2);
else
    summary.foveaX = NaN;
    summary.foveaY = NaN;
end

summary.exudateCount = result.exudates.features.count;
summary.exudateAreaRatio = result.exudates.candidateAreaRatio;
summary.exudateMeanArea = mean(result.exudates.features.area);
summary.exudateLargestArea = max(result.exudates.features.area);
summary.exudateMeanCircularity = mean(result.exudates.features.circularity);
summary.exudateMeanVesselOverlap = mean(result.exudates.features.vesselOverlap);

summary.maHemorrhageCount = result.maHemorrhage.features.count;
summary.maHemorrhageAreaRatio = result.maHemorrhage.candidateAreaRatio;
summary.maHemorrhageMeanArea = mean(result.maHemorrhage.features.area);
if result.maHemorrhage.features.count > 0
    summary.maHemorrhageLargestArea = max(result.maHemorrhage.features.area);
else
    summary.maHemorrhageLargestArea = NaN;
end
summary.maHemorrhageMeanCircularity = mean(result.maHemorrhage.features.circularity);
summary.maHemorrhageMeanVesselOverlap = mean(result.maHemorrhage.features.vesselOverlap);

end