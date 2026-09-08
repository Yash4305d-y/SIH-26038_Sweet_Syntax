# ML Inference Interface

## Purpose
This document specifies the single-image inference interface for the finalized SIH-26038 Diabetic Retinopathy screening model. The interface is encapsulated in `runDRInference.m`.

## Input
The function accepts a single retinal fundus image as either:
- A local absolute/relative file path (string/char).
- A numeric MATLAB image array.
It optionally accepts a boolean flag `generateGradCAM` to enable spatial interpretability visualizations.

## Preprocessing
Images are strictly resized to `[224 224]` and converted to 3-channel RGB to match the frozen `Baseline ResNet-50` geometry and training conventions. Quality checks (e.g., glare, blur) are intentionally omitted from this ML script, relying instead on the Role 2 quality gate to reject images before passing them to inference.

## Model
The interface statically evaluates the locked `baseline_resnet50_smoketest.mat` artifact. Training, validation splitting, and tuning are explicitly prohibited in this execution path.

## Five-Class Output
The function outputs raw, uncalibrated softmax probabilities for all five grades:
- `0`: No DR
- `1`: Mild DR
- `2`: Moderate DR
- `3`: Severe DR
- `4`: Proliferative DR
The predicted grade corresponds strictly to the maximum output probability.

## Referable-DR Output
Referable DR is computed analytically by summing the probabilities of pathogenic grades (P2 + P3 + P4). 

## Calibration
The interface applies pre-computed, static Platt scaling parameters to the referable probability. These parameters are rigorously loaded from the `calibration_parameters.mat` validation artifact and do not learn or adapt at runtime.

## Frozen Threshold
The classification threshold is strictly frozen at `0.22`. Images with a calibrated referable probability ≥ 0.22 are classified as `Referable`.

## Confidence
Model confidence is reported as the maximum class probability (`predictedClassProbability`). This metric represents the mathematical confidence of the network's maximal activation class, and should strictly *not* be interpreted as an absolute measure of clinical diagnostic certainty.

## Grad-CAM
When enabled, Grad-CAM attention heatmaps are generated against the final convolutional layer (`res5c_branch2c`). Grad-CAM provides a spatial attention visualization of model activity and should not be interpreted as proof of detection of a specific clinical lesion.

## Error Handling
The interface catches all execution, dimension, and loading faults securely, returning a structured fault object with `success = false` and descriptive diagnostic context in `errorMessage` instead of generating a hard crash. 

## Output Structure
```matlab
result = 
                         modelName: 'Baseline ResNet-50'
                      modelVersion: '1.0'
                       modelStatus: 'LOCKED'
                    predictedGrade: 0
                       classLabels: [0 1 2 3 4]
                     probabilities: [0.9998 0.0001 0.0000 0.0000 0.0000]
         predictedClassProbability: 0.9998
                        confidence: 0.9998
              referableProbability: 0.0000
    calibratedReferableProbability: 0.0055
                referableThreshold: 0.2200
                   referableStatus: 'Non-referable'
                 calibrationMethod: 'Platt scaling'
                 uncertaintyStatus: 'Not implemented in frozen inference interface'
                           gradCAM: []
                           success: 1
                      errorMessage: ''
```

## Example Usage
```matlab
% Basic execution:
result = runDRInference('D:\SIH-26038\data\raw\test_images\0024cdab0c1e.png');

% With Grad-CAM enabled:
result = runDRInference('D:\SIH-26038\data\raw\test_images\0024cdab0c1e.png', true);
```

## Limitations
- **This is a screening research prototype. It is not a clinical diagnostic tool.**
- Model was trained/evaluated on APTOS.
- External Messidor-2 generalization is substantially weaker.
- The threshold 0.22 is frozen from validation calibration.
- No Messidor-2 tuning occurs during inference.
- Grad-CAM is an interpretability aid, not lesion proof.
