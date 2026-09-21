loadedNet = load('models\baseline_resnet50_smoketest.mat', 'net');
if isprop(loadedNet.net, 'Layers')
    disp(loadedNet.net.Layers(end).Classes);
else
    disp('Not a DAGNetwork / No Layers property, it might be dlnetwork');
    disp(loadedNet.net.OutputNames);
end
