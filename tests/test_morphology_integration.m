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
    
    fields = {'vessels', 'optic_disc', 'fovea', 'exudates', 'ma_hemorrhage'};
    for i = 1:length(fields)
        f = fields{i};
        if ~isfield(m, f)
            error(['Missing field: ', f]);
        end
        disp([f, ' status: ', m.(f).status]);
        
        if isfield(m.(f), 'mask')
            error(['Mask illegally serialized in ', f]);
        end
    end
    
    disp('Masks correctly omitted: PASS');
    
    disp('Overall status: PASS');
end
