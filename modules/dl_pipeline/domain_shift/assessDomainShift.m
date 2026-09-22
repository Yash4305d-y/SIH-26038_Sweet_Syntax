% assessDomainShift.m
function flags = assessDomainShift(distances, threshShift, threshMismatch)
    numSamples = length(distances);
    flags = strings(numSamples, 1);
    for i = 1:numSamples
        if isnan(distances(i))
            flags(i) = 'INVALID';
        elseif ~isnan(threshMismatch) && distances(i) >= threshMismatch
            flags(i) = 'HIGH_MISMATCH';
        elseif distances(i) >= threshShift
            flags(i) = 'POTENTIAL_SHIFT';
        else
            flags(i) = 'WITHIN_REFERENCE';
        end
    end
end
