% computeDomainDistance.m
function distances = computeDomainDistance(features, aptosReferenceProfile)
    refMean = aptosReferenceProfile.meanVector;
    refCov = aptosReferenceProfile.covMatrix;
    
    invCov = inv(refCov);
    numSamples = size(features, 1);
    distances = NaN(numSamples, 1);
    
    for i = 1:numSamples
        % Check if feature is not perfectly zero (invalid feature)
        if any(features(i, :))
            delta = features(i, :) - refMean;
            distSq = delta * invCov * delta';
            distances(i) = sqrt(max(0, distSq));
        end
    end
end
