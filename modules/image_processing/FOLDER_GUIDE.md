# ROLE_2_FINAL Complete Folder Guide

## 1. Purpose

`ROLE_2_FINAL` is the Role 2 research and implementation package for diabetic retinopathy (DR) screening from retinal fundus images. It contains:

- Project documentation and integration notes.
- MATLAB image-quality assessment (IQA), preprocessing, morphology, feature extraction, and inference code.
- The frozen trained MATLAB model.
- Final validation and threshold-analysis results.
- Development datasets, model-selection experiments, hyperparameter searches, and IQA audits.

The production path is:

```text
Input fundus image
        |
        v
Image Quality Assessment (IQA)
        |
        +-- Focus check
        +-- Illumination check
        +-- Field-of-view check
        |
        v
Preprocessing
        |
        +-- CLAHE contrast enhancement
        +-- Gaussian denoising
        |
        v
Retinal morphology analysis
        |
        +-- Vessel extraction
        +-- Optic-disc detection
        +-- Fovea estimation
        +-- Exudate candidates
        +-- Microaneurysm/hemorrhage candidates
        |
        v
Lesion feature extraction and summary
        |
        v
29-feature final model
        |
        v
DR / NoDR decision
```

## 2. Complete Folder Structure

```text
ROLE_2_FINAL/
|
|-- README.md
|-- FOLDER_GUIDE.md                         This complete guide
|
|-- 01_DOCUMENTATION/                        Currently empty
|
|-- 02_MATLAB_CODE/
|   |-- final_DR_inference.m                 Public inference entry point
|   |-- lesion_features.m                    Per-lesion measurements
|   |-- lesion_summary.m                     Compact pipeline summary
|   |-- role2_pipeline.m                     IQA-to-feature pipeline
|   |
|   |-- IQA/
|   |   |-- focus_score.m
|   |   |-- fov_score.m
|   |   |-- illumination_score.m
|   |   `-- iqa_gate.m
|   |
|   |-- Morphology/
|   |   |-- exudate_candidates.m
|   |   |-- fovea_heuristic.m
|   |   |-- ma_hemorrhage_candidates.m
|   |   |-- optic_disc.m
|   |   `-- vessel_extraction.m
|   |
|   `-- Preprocessing/
|       |-- preprocess_clahe.m
|       |-- preprocess_denoise.m
|       `-- preprocess_fundus.m
|
|-- 03_FINAL_MODEL/
|   `-- BEST_SINGLE_DR_MODEL.mat              Frozen trained model
|
|-- 04_FINAL_RESULTS/
|   |-- FINAL_BATCH_VALIDATION_RESULTS.csv    366 image-level predictions
|   `-- FINAL_REFERABLE_DR_THRESHOLD_RESULTS.csv
|                                               99 threshold experiments
|
`-- 05_DEVELOPMENT/
    |-- BEST_SINGLE_DR_MODEL_SEARCH.csv
    |-- DR_BAGGED_FEATURE_SELECTION_RESULTS.csv
    |-- DR_CONTROLLED_MODEL_COMPARISON.csv
    |-- DR_FEATURE_ENGINEERED_BAGGED_RESULTS.csv
    |-- DR_FEATURE_SET_COMPARISON.csv
    |-- DR_MODEL_COMPARISON.csv
    |-- DR_SPECIFICITY_OPTIMIZATION_RESULTS.csv
    |-- DR_TREE_HYPERPARAMETER_RESULTS.csv
    |-- FINAL_15FEATURE_BAGGED_OPTIMIZATION.csv
    |-- IQA_FAILURE_AUDIT.csv
    |-- IQA_FAILURE_METRICS.csv
    |-- role2_features_50.csv
    |-- role2_features_balanced.csv
    `-- role2_features_corrected.csv
```

## 3. Root Files

### `README.md`

The short project README. It records the purpose, main folders, integration entry point, high-level pipeline, frozen threshold, reported validation metrics, and MATLAB setup reminder.

### `FOLDER_GUIDE.md`

This file. It provides the detailed folder, code, model, result, and data reference for a new reader.

## 4. Documentation Folder

### `01_DOCUMENTATION/`

This folder currently exists but contains no files. The root `README.md` and this guide are the available project documentation.

## 5. MATLAB Code

All production MATLAB source files are under `02_MATLAB_CODE/`. MATLAB Image Processing Toolbox functionality is used by the implementation, including functions such as `rgb2lab`, `adapthisteq`, `imgaussfilt`, `fibermetric`, `regionprops`, `bwareaopen`, `imtophat`, and `imbothat`.

### 5.1 Main entry points

#### `final_DR_inference.m`

The public inference interface. It accepts either:

- An image matrix already loaded in MATLAB, or
- A path to an image file.

It performs the following checks and operations:

1. Adds the configured MATLAB project directory and subfolders to the path.
2. Verifies that required functions are available.
3. Loads `BEST_SINGLE_DR_MODEL.mat`.
4. Validates the input image.
5. Runs `role2_pipeline`.
6. Rejects images that fail IQA.
7. Builds the 29 model features from the pipeline summary.
8. Matches feature names and order to the trained model.
9. Predicts DR probability.
10. Applies the final threshold of `0.84`.
11. Returns the decision, probability, features, summary, pipeline output, and model.

Returned fields include:

```text
result.status
result.decision
result.prediction
result.drProbability
result.threshold
result.features
result.featureNames
result.summary
result.pipeline
result.model
```

A normal call is:

```matlab
imagePath = "path_to_retinal_image.png";
result = final_DR_inference(imagePath);
```

Important implementation detail: the current file contains a hard-coded `rootFolder` and constructs the model path relative to it. Before deployment on another computer, update `rootFolder` to the local project location or refactor it to derive the path from the script location.

#### `role2_pipeline.m`

Runs the image-processing pipeline. It first applies the IQA gate. If IQA fails, it returns `status = "FAIL"` and a reason without running the later stages. If IQA passes, it runs preprocessing, morphology, lesion feature extraction, and summary generation.

The default IQA thresholds are:

| Check | Threshold |
|---|---:|
| Minimum focus score | `0.00003` |
| Minimum mean intensity | `0.07` |
| Maximum mean intensity | `0.70` |
| Maximum dark-pixel ratio | `0.54` |
| Maximum bright-pixel ratio | `0.50` |
| Minimum FOV area ratio | `0.20` |
| Minimum FOV circularity | `0.09` |

Successful pipeline output contains:

```text
result.status
result.iqa
result.preprocessed
result.vessels
result.opticDisc
result.fovea
result.exudates
result.maHemorrhage
result.summary
```

### 5.2 IQA folder

#### `IQA/focus_score.m`

Converts an RGB image to grayscale when necessary, applies a Laplacian filter, and returns the variance of the filtered image. Higher variance indicates more high-frequency detail and generally better focus.

#### `IQA/illumination_score.m`

Returns:

- `meanIntensity`: Mean grayscale intensity.
- `darkPixelRatio`: Proportion of pixels below `0.05`.
- `brightPixelRatio`: Proportion of pixels above `0.95`.

#### `IQA/fov_score.m`

Estimates the retinal field of view by thresholding grayscale intensity above `0.05`, filling holes, retaining the largest connected component, and measuring:

- `areaRatio`: Retinal mask area divided by image area.
- `circularity`: $4\pi A/P^2$.
- `boundingBoxRatio`: Bounding-box area divided by image area.
- `detected`: Whether a connected component was found.

#### `IQA/iqa_gate.m`

Combines focus, illumination, and FOV measurements. It returns each individual score, each pass/fail flag, the combined `pass` value, and the first applicable failure reason: `Focus failure`, `Illumination failure`, `FOV failure`, or `PASS`.

### 5.3 Preprocessing folder

#### `Preprocessing/preprocess_fundus.m`

The preprocessing wrapper. It calls CLAHE enhancement followed by denoising.

#### `Preprocessing/preprocess_clahe.m`

For RGB images, converts RGB to Lab, applies adaptive histogram equalization to the L channel using `8 x 8` tiles and `ClipLimit = 0.01`, then converts back to RGB. Grayscale images receive CLAHE directly. Output values are clipped to `[0, 1]`.

#### `Preprocessing/preprocess_denoise.m`

Applies Gaussian filtering with standard deviation `0.8`.

### 5.4 Morphology folder

#### `Morphology/vessel_extraction.m`

Uses the green channel and `fibermetric` with scales `[4 6 8 10 12 14]` and dark object polarity. It normalizes the response, uses Otsu thresholding, removes components smaller than 150 pixels, and returns:

- `response`
- `mask`
- `threshold`
- `vesselAreaRatio`

#### `Morphology/optic_disc.m`

Converts to grayscale, retains pixels at or above the 99.5th percentile, removes small components, and evaluates candidate compactness. Candidates with compactness at least `0.50` are valid. The selected candidate maximizes `compactness * sqrt(area)`. Output includes detection status, candidates, the best candidate, and compactness.

#### `Morphology/fovea_heuristic.m`

Requires a detected optic disc. It searches a region centered approximately `0.20 * image width` to the left of the disc, covering `25%` of image width and height. Dark regions are thresholded using Otsu's method, small components are removed, and the largest remaining component is selected as the fovea estimate.

#### `Morphology/exudate_candidates.m`

Uses a green-channel white top-hat transform with a disk structuring element of radius `8`. It combines Otsu and 99th-percentile response thresholds by taking the larger value, removes small components, closes small gaps, and returns a candidate mask, response, threshold, and candidate area ratio.

#### `Morphology/ma_hemorrhage_candidates.m`

Uses a green-channel black-hat transform with a disk radius of `10`. It thresholds at the 99.5th percentile, removes vessel pixels, removes small components, closes gaps, and returns candidate evidence and area ratio.

### 5.5 Feature and summary files

#### `lesion_features.m`

Measures each connected lesion candidate using `regionprops`. For every component it can return:

```text
count
area
centroid
boundingBox
perimeter
circularity
meanIntensity
maxResponse
vesselOverlap
distanceFromDisc
distanceFromFovea
```

Circularity is calculated as $4\pi A/P^2$ and limited to a maximum of `1`. Distances are populated when the corresponding optic-disc or fovea reference is detected.

#### `lesion_summary.m`

Condenses pipeline output into model-ready summary values, including vessel ratio, optic-disc status and compactness, fovea status and coordinates, exudate statistics, and MA/hemorrhage statistics.

## 6. Final Model

### `03_FINAL_MODEL/BEST_SINGLE_DR_MODEL.mat`

A binary MATLAB MAT-file containing the frozen trained model. The production code requires these variables:

- `finalModel`: The trained classification model. It must expose `PredictorNames`, `ClassNames`, and the MATLAB `predict` interface.
- `finalThreshold`: Stored threshold variable required by the inference validation check.

The inference code applies the frozen operating threshold `0.84`, checks that the model has the same 29 named predictors, reorders the generated feature vector to the model predictor order, and locates the class named `DR` in `ClassNames`.

The model is coupled to the current preprocessing, morphology, summary, feature names, and feature order. Changing those components requires model revalidation or retraining.

## 7. The 29 Final Model Features

The inference feature vector is built with these names:

1. `vesselAreaRatio`
2. `opticDiscDetected`
3. `opticDiscCompactness`
4. `foveaDetected`
5. `exudateCount`
6. `exudateAreaRatio`
7. `exudateLargestArea`
8. `exudateMeanCircularity`
9. `maHemorrhageCount`
10. `maHemorrhageAreaRatio`
11. `maHemorrhageLargestArea`
12. `maHemorrhageMeanCircularity`
13. `exCountDensity`
14. `maCountDensity`
15. `exMeanApproxArea`
16. `maMeanApproxArea`
17. `totalLesionCount`
18. `totalLesionAreaRatio`
19. `lesionCountRatio`
20. `lesionAreaRatio`
21. `exLargeToCount`
22. `maLargeToCount`
23. `exBurdenPerVessel`
24. `maBurdenPerVessel`
25. `combinedCircularity`
26. `lesionMorphologyIndex`
27. `vascularLesionInteraction`
28. `discLesionInteraction`
29. `foveaLesionInteraction`

Derived features are calculated from the lesion summary. For example:

- `totalLesionCount = exudateCount + maHemorrhageCount`
- `totalLesionAreaRatio = exudateAreaRatio + maHemorrhageAreaRatio`
- Count densities divide lesion counts by vessel area ratio, with a minimum denominator of `0.001`.
- Interaction features combine lesion burden with vessel, optic-disc, or fovea evidence.
- Non-finite feature values are replaced with zero before prediction.

## 8. Final Results

### `04_FINAL_RESULTS/FINAL_BATCH_VALIDATION_RESULTS.csv`

Image-level final validation output. It contains 366 data rows and these columns:

| Column | Meaning |
|---|---|
| `id_code` | Image identifier. |
| `diagnosis` | Original multiclass diagnosis label stored with the image. |
| `TrueClass` | Binary ground-truth class used for final validation. |
| `PredictedClass` | Binary model prediction, `DR` or `NoDR`. |
| `DRProbability` | Predicted probability for the `DR` class. |
| `Status` | Processing status; all 366 observed final rows are `PASS`. |
| `Reason` | Pipeline/inference status text. |

Observed final batch counts:

- `366` total records.
- `231` predicted `DR`.
- `135` predicted `NoDR`.
- `366` records with `PASS` status.

### `04_FINAL_RESULTS/FINAL_REFERABLE_DR_THRESHOLD_RESULTS.csv`

Threshold sweep used to choose the operating point. It contains 99 rows for thresholds from `0.01` through `0.99` and these columns:

```text
Threshold, Accuracy, Sensitivity, Specificity, Precision, F1,
TP, TN, FP, FN, AUC
```

At threshold `0.84`, the stored validation row reports approximately:

- Accuracy: `0.89617` (`89.62%`)
- Sensitivity: `0.90722` (`90.72%`)
- Specificity: `0.88372` (`88.37%`)
- AUC: `0.94971`

The project README rounds these to 90.72% sensitivity, 88.37% specificity, and 0.9497 AUC.

## 9. Development Data and Experiments

The `05_DEVELOPMENT` folder contains traceability artifacts. These files support research and reproducibility; they are not required for normal inference.

### 9.1 Feature datasets

All three feature datasets use the same 15 columns:

```text
id_code
diagnosis
iqaStatus
vesselAreaRatio
opticDiscDetected
opticDiscCompactness
foveaDetected
exudateCount
exudateAreaRatio
exudateLargestArea
exudateMeanCircularity
maHemorrhageCount
maHemorrhageAreaRatio
maHemorrhageLargestArea
maHemorrhageMeanCircularity
```

| File | Data rows | Observed diagnosis counts | IQA status |
|---|---:|---|---|
| `role2_features_50.csv` | 50 | 0: 24, 1: 6, 2: 15, 3: 2, 4: 3 | 44 PASS, 6 FAIL |
| `role2_features_balanced.csv` | 500 | 100 per label from 0 through 4 | 469 PASS, 31 FAIL |
| `role2_features_corrected.csv` | 469 | 0: 71, 1: 100, 2: 100, 3: 98, 4: 100 | 469 PASS |

The `diagnosis` column preserves the source multiclass labels. The final model converts the image evidence into a binary `DR`/`NoDR` prediction.

### 9.2 IQA audit files

#### `IQA_FAILURE_AUDIT.csv`

Contains 58 image-level records associated with IQA failures. Its columns are:

```text
id_code, diagnosis, TrueClass, PredictedClass,
DRProbability, Status, Reason
```

Observed failure reasons are:

- `Illumination failure`: 51 records.
- `FOV failure`: 7 records.

#### `IQA_FAILURE_METRICS.csv`

Contains the detailed IQA measurements for the 58 failures:

```text
id, diagnosis, reason, focusScore, meanIntensity,
darkPixelRatio, brightPixelRatio, retinalAreaRatio,
circularity, focusPass, illuminationPass, fovPass
```

This file is useful for diagnosing rejected images and checking whether thresholds are too strict or too lenient.

### 9.3 Model-search and comparison files

The remaining CSV files contain experiment grids or model comparisons. Common metric fields are accuracy, sensitivity, specificity, precision, F1, AUC, confusion-matrix counts, and target/score indicators.

| File | Rows | Contents |
|---|---:|---|
| `BEST_SINGLE_DR_MODEL_SEARCH.csv` | 192 | Search over tree count, split settings, leaf size, and threshold. |
| `DR_BAGGED_FEATURE_SELECTION_RESULTS.csv` | 8 | Bagged-model performance by number of selected features. |
| `DR_CONTROLLED_MODEL_COMPARISON.csv` | 3 | Controlled comparison of candidate model configurations. |
| `DR_FEATURE_ENGINEERED_BAGGED_RESULTS.csv` | 36 | Bagged-model search using engineered features. |
| `DR_FEATURE_SET_COMPARISON.csv` | 3 | Comparison of feature-set variants. |
| `DR_MODEL_COMPARISON.csv` | 3 | High-level comparison of candidate models and target status. |
| `DR_SPECIFICITY_OPTIMIZATION_RESULTS.csv` | 3,822 | Large grid prioritizing specificity across tree and threshold settings. |
| `DR_TREE_HYPERPARAMETER_RESULTS.csv` | 42 | Tree hyperparameter and threshold results. |
| `FINAL_15FEATURE_BAGGED_OPTIMIZATION.csv` | 80 | Optimization results for the selected 15-feature input representation. |

Typical experiment columns include:

```text
NumTrees, MaxNumSplits, MinLeafSize, Threshold,
Accuracy, Sensitivity, Specificity, Precision, F1, AUC,
TN, FP, FN, TP, TargetMet, TargetScore
```

Some files also contain percentage versions of metrics, such as `AccuracyPct`, `SensitivityPct`, `SpecificityPct`, `PrecisionPct`, and `F1Pct`, plus target flags such as `Meets90Spec`, `Meets90Sens`, or `Meets95Accuracy`.

## 10. Setup and Execution

From MATLAB, add the code folder and all subfolders to the path:

```matlab
projectRoot = 'path_to_ROLE_2_FINAL';
addpath(genpath(fullfile(projectRoot, '02_MATLAB_CODE')));
```

Then either call the public interface with a file path:

```matlab
result = final_DR_inference('path_to_retinal_image.png');
```

or with an already loaded image matrix:

```matlab
I = imread('path_to_retinal_image.png');
result = final_DR_inference(I);
```

A successful result has `result.status = "PASS"` and a `result.decision` of `"DR"` or `"NoDR"`. An image rejected by IQA has `result.status = "FAIL"`, a failure `result.reason`, and a `"REJECT"` decision.

## 11. Operational Notes and Limitations

1. The final model and MATLAB feature-generation code are a matched pair. Keep their predictor names and order synchronized.
2. The current inference file uses a machine-specific absolute root path. Update it before running on another machine.
3. The current final model file is binary and cannot be meaningfully read as text; load it in MATLAB to inspect the model object and its predictor names.
4. Development CSVs are experiment records, not interchangeable production inputs.
5. IQA failure means the image is rejected before DR classification; it does not mean the image is classified as `NoDR`.
6. The reported final metrics describe the recorded validation experiment and should be recomputed after changing code, thresholds, preprocessing, features, or model files.
7. `NaN` values in rejected feature rows are expected because later pipeline stages are not run after IQA failure.

## 12. Final Integration Package

For normal integration, the required parts are:

```text
README.md
02_MATLAB_CODE/
03_FINAL_MODEL/BEST_SINGLE_DR_MODEL.mat
```

`04_FINAL_RESULTS/` provides final evidence and validation records. `05_DEVELOPMENT/` provides research traceability. `01_DOCUMENTATION/` is reserved for future supporting documents.
