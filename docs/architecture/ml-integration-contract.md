# ML Integration Contract

This document formally defines the integration boundaries and the machine-readable data contract for consuming the Role 1 (ML Architect) inference interface. It is the authoritative contract for Role 2 (Quality Gate), Role 3 (Simulink/System), and Role 4 (App Designer/UI).

## A. INPUT
- **Accepted input:** The `runDRInference.m` wrapper accepts either a valid MATLAB numeric image array (e.g., `uint8` or `single`) or a string/char file path to an image.
- **Validation:** Internal checks prevent empty arrays, NaNs, Infs, or invalid file paths. If an image path is provided, the wrapper loads it.
- **RGB conversion:** Grayscale images are automatically mapped to 3-channel RGB.

## B. OUTPUT
The `runDRInference.m` function strictly returns a single MATLAB `struct` containing the following fields:

- `modelName`: Model identifier (String).
- `modelVersion`: Version label (String).
- `modelStatus`: Execution deployment state (String).
- `predictedGrade`: Final integer classification 0-4 (Integer).
- `classLabels`: 1x5 array `[0 1 2 3 4]`.
- `probabilities`: 1x5 array of raw softmax probabilities.
- `predictedClassProbability`: Float probability matching the max class.
- `confidence`: Alias for the max probability (Float).
- `referableProbability`: Uncalibrated raw pathogenic sum (Float).
- `calibratedReferableProbability`: Calibrated pathogenic sum (Float).
- `referableThreshold`: The frozen decision scalar `0.22` (Float).
- `referableStatus`: Final decision string: `"Referable"` or `"Non-referable"`.
- `calibrationMethod`: Strategy name `"Platt scaling"` (String).
- `uncertaintyStatus`: State of Bayesian or epistemic uncertainty implementation (String).
- `gradCAM`: Output visualization array or string message. `[]` if disabled.
- `success`: Boolean execution status (True/False).
- `errorMessage`: String diagnostic if `success` is `false`.

## C. CLASS DEFINITIONS
- **Grade 0** = No DR
- **Grade 1** = Mild DR
- **Grade 2** = Moderate DR
- **Grade 3** = Severe DR
- **Grade 4** = Proliferative DR

**Referable Rule:** Grades 2, 3, 4 are pathogenic (Referable). Grades 0, 1 are Non-referable.

## D. PROBABILITIES
The field `probabilities` is a 1x5 array corresponding to [P0, P1, P2, P3, P4]. 
Because it uses softmax activation, `sum(P0:P4) ≈ 1`.
`referableProbability` is rigorously calculated as `P2 + P3 + P4`.

## E. CALIBRATION
The pipeline applies Platt scaling using the validated model natively retrieved from `calibration_parameters.mat` stored during the Role 1 validation phase. The calibration model (`GeneralizedLinearModel`) maps `referableProbability` directly to `calibratedReferableProbability`. No refitting or test-set peeking occurs during inference.

## F. DECISION THRESHOLD
The operating point is completely frozen from the validation calibration sweep at `0.22`.
- `calibratedReferableProbability >= 0.22` → **Referable**
- `calibratedReferableProbability < 0.22` → **Non-referable**

## G. CONFIDENCE
`confidence` is mathematically identical to `max(probabilities)` (the predicted class probability). It denotes neural activation magnitude, not true clinical certainty. 

## H. GRAD-CAM
If enabled via `runDRInference(img, true)`, `gradCAM` contains the numerical heatmap activated at layer `res5c_branch2c`. This is an explainability visualization, not proof of clinical lesion localization. If disabled, it returns an empty array `[]`.

## I. MODEL
- **Name:** Baseline ResNet-50
- **File:** `baseline_resnet50_smoketest.mat`
- **Input size:** `[224 224 3]`
- **Status:** Frozen / Locked
