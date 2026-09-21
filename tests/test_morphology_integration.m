function test_morphology_integration()
    disp('========================================');
    disp('ROLE 1 MORPHOLOGY INTEGRATION TEST');
    disp('========================================');
    
    % Add Role 2 paths
    scriptPath = mfilename('fullpath');
    [srcDir, ~, ~] = fileparts(scriptPath);
    projectDir = fileparts(srcDir);
    
    % We need to make sure getProjectRoot is reachable. 
    % test_morphology_integration.m is in /tests
    % So projectDir is already correct here.
    
    % Add the inference path so we can call runUnifiedPipeline
    addpath(fullfile(projectDir, 'modules', 'dl_pipeline', 'inference'));
    
    testCsv = fullfile(projectDir, 'results', 'baseline_test_predictions.csv');
    t = readtable(testCsv, 'PreserveVariableNames', true);
    
    if ismember('image_path', t.Properties.VariableNames)
        imgNameRaw = string(t.image_path(1));
    else
        imgNameRaw = string(t.id_code(1));
    end
    [~, n, ext] = fileparts(imgNameRaw);
    if isempty(char(ext)), ext = '.png'; end
    imgName = [char(n), char(ext)];
    
    imgPath = fullfile(projectDir, 'data', 'raw', 'test_images', imgName);
    if ~exist(imgPath, 'file')
        imgPath = fullfile(projectDir, 'data', 'raw', 'train_images', imgName);
    end
    
    disp(['Testing with image: ', imgPath]);
    
    % Run pipeline
    jsonStr = runUnifiedPipeline(imgPath, false);
    result = jsondecode(jsonStr);
    
    % Check ML presence
    if ~isfield(result, 'predictedGrade')
        error('ML output missing');
    end
    disp('ML Inference execution: PASS');
    
    % Check morphology presence
    if ~isfield(result, 'morphology')
        error('Morphology object missing');
    end
    m = result.morphology;
    
    if ~m.executed
        error('Morphology not executed');
    end
    disp(['Overall Status: ', m.overall_status]);
    
    fields = {'vessels', 'optic_disc', 'fovea', 'exudates', 'microaneurysm', 'hemorrhage', 'neovascularization'};
    for i = 1:length(fields)
        f = fields{i};
        if ~isfield(m, f)
            error(['Missing field: ', f]);
        end
        disp([f, ' status: ', m.(f).status]);
        
        if ismember(f, {'microaneurysm', 'hemorrhage', 'neovascularization'})
            if ~isfield(m.(f), 'count')
                error(['Missing count field in ', f]);
            end
        end
        
        if isfield(m.(f), 'mask')
            error(['Mask illegally serialized in ', f]);
        end
    end
    
    disp('Masks correctly omitted: PASS');
    
    % Test Dependency Failure
    disp('Testing BLOCKED_BY_DEPENDENCY guard...');
    vesselReal = fullfile(projectDir, 'modules', 'image_processing', 'code', 'Morphology', 'vessel_extraction.m');
    vesselBackup = fullfile(projectDir, 'modules', 'image_processing', 'code', 'Morphology', 'vessel_extraction_backup.m');
    
    movefile(vesselReal, vesselBackup);
    try
        fid = fopen(vesselReal, 'w');
        fprintf(fid, 'function result = vessel_extraction(I); error(''Mock failure''); end');
        fclose(fid);
        
        jsonStrBlocked = runUnifiedPipeline(imgPath, false);
        resultBlocked = jsondecode(jsonStrBlocked);
        if ~strcmp(resultBlocked.morphology.neovascularization.status, 'BLOCKED_BY_DEPENDENCY')
            error('Failed to trigger BLOCKED_BY_DEPENDENCY');
        end
        disp('BLOCKED_BY_DEPENDENCY guard: PASS');
        
        delete(vesselReal);
        movefile(vesselBackup, vesselReal);
    catch ME
        if exist(vesselReal, 'file'), delete(vesselReal); end
        if exist(vesselBackup, 'file'), movefile(vesselBackup, vesselReal); end
        rethrow(ME);
    end
    
    % Test PROCESSING_FAILED guard
    disp('Testing PROCESSING_FAILED guard (without blocking CNN)...');
    nvReal = fullfile(projectDir, 'modules', 'image_processing', 'code', 'Morphology', 'neovascularization_candidates.m');
    nvBackup = fullfile(projectDir, 'modules', 'image_processing', 'code', 'Morphology', 'neovascularization_candidates_backup.m');
    
    movefile(nvReal, nvBackup);
    try
        fid = fopen(nvReal, 'w');
        fprintf(fid, 'function result = neovascularization_candidates(mask); error(''Mock failure''); end');
        fclose(fid);
        
        jsonStrProc = runUnifiedPipeline(imgPath, false);
        resultProc = jsondecode(jsonStrProc);
        if ~strcmp(resultProc.morphology.neovascularization.status, 'PROCESSING_FAILED')
            error('Failed to trigger PROCESSING_FAILED');
        end
        if ~isfield(resultProc, 'predictedGrade')
            error('CNN inference was blocked by morphology failure');
        end
        disp('PROCESSING_FAILED guard: PASS');
        
        delete(nvReal);
        movefile(nvBackup, nvReal);
    catch ME
        if exist(nvReal, 'file'), delete(nvReal); end
        if exist(nvBackup, 'file'), movefile(nvBackup, nvReal); end
        rethrow(ME);
    end
    
    disp('Overall status: PASS');
end
