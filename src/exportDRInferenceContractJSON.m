% src/exportDRInferenceContractJSON.m
% Helper script to serialize an inference result struct to JSON string natively

function jsonString = exportDRInferenceContractJSON(resultStruct)
    % Verify input is a valid result struct
    if ~isstruct(resultStruct) || ~isfield(resultStruct, 'success')
        error('Input must be a valid inference result structure.');
    end
    
    % If gradCAM is large array, we might want to discard it for standard lightweight JSON 
    % transmission depending on Role 4's bandwidth, but JSONEncode natively handles it.
    % To keep JSON clean for debugging:
    if isnumeric(resultStruct.gradCAM) && numel(resultStruct.gradCAM) > 0
        % just export shape metadata so we don't blow up JSON size if large
        resultStruct.gradCAM_shape = size(resultStruct.gradCAM);
        resultStruct = rmfield(resultStruct, 'gradCAM');
    end
    
    jsonString = jsonencode(resultStruct, 'PrettyPrint', true);
end
