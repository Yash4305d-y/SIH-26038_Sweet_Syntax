# Messidor-2 External Generalization Validation

## 1. Purpose
This document details the external generalization validation of the frozen Baseline ResNet-50 model on the Messidor-2 dataset. The objective is to evaluate how well the model generalizes to completely unseen data from different acquisition sources (French hospitals vs. Aravind Eye Hospital in India) without any dataset-specific tuning or calibration.

This is a research evaluation intended to highlight domain shift characteristics, not a clinical validation.

## 2. Dataset Description
- **Dataset**: Messidor-2
- **Dataset Size**: 1,744 images (1057 `.png` and 687 `.JPG`)
- **Acquisition Source**: Multiple French hospitals

## 3. Label Definition
The official labels for Messidor-2 are provided by third-party annotations in `messidor_data.csv`. The `diagnosis` column provides integer grades from 0 to 4, mapping to the International Clinical Diabetic Retinopathy (ICDR) scale:
- 0 = No DR
- 1 = Mild
- 2 = Moderate
- 3 = Severe
- 4 = Proliferative

**Referable Mapping**:
- **Non-referable**: Grades 0 and 1
- **Referable**: Grades 2, 3, and 4
- The ground truth referable flag is computed as `diagnosis >= 2`.

## 4. Image/Label Matching Methodology
The mapping strictly matched the filenames in the CSV against the available files in the directory. A custom script automatically resolved the mixed `.png` and `.JPG` file extensions on disk to perfectly map all 1,744 rows from the CSV to exactly 1,744 images with no missing files and zero mapping errors.

## 5. Model and Pipeline
- **Frozen APTOS Model**: The authoritative model (`models/baseline_resnet50_smoketest.mat`) was evaluated strictly in inference mode. Model weights were not modified.
- **Preprocessing Pipeline**: The original `augmentedImageDatastore([224 224])` and `minibatchpredict` pipeline was applied directly to the Messidor-2 images.
- **APTOS-fitted Platt Calibration**: The probability calibration function fitted previously on the APTOS validation set was applied to the raw referable probabilities. **No Messidor-2 data was used to fit calibration**.
- **Frozen Threshold**: The operating threshold was rigidly locked at **0.22**, as determined by the APTOS validation set. No threshold tuning was permitted on Messidor-2.

## 6. Important Preprocessing Limitation
> [!WARNING]
> Messidor-2 images were evaluated using the supplied images in the project's `preprocess` directory. The upstream operations that produced this directory were not independently reconstructed; therefore, external generalization results should be interpreted in the context of the supplied dataset representation.
>
> The exact nature of this preprocessing (e.g., cropping, illumination correction) is undocumented and may differ fundamentally from APTOS preprocessing, contributing to domain shift.

## 7. Results Comparison

### Binary Referable DR Evaluation
The binary referable metrics are drastically lower than the internal held-out test, highlighting a severe domain shift problem.

| Metric | APTOS Test (Internal) <br> Raw Threshold 0.5 | APTOS Test (Internal) <br> Calibrated Thresh 0.22 | Messidor-2 (External) <br> Frozen Calibrated Thresh 0.22 |
|---|---|---|---|
| **N** | 439 | 439 | 1744 |
| **Accuracy** | 0.9385 | 0.9317 | 0.7930 |
| **Sensitivity** | 0.9609 | 0.9888 | 0.2932 |
| **Specificity** | 0.9231 | 0.8923 | 0.9705 |
| **Precision** | 0.8958 | 0.8634 | 0.7791 |
| **NPV** | 0.9717 | 0.9915 | 0.7945 |
| **F1 Score** | 0.9272 | 0.9219 | 0.4261 |
| **ROC-AUC** | 0.9816 | 0.9816 | 0.7669 |
| **Brier Score**| 0.0499 | 0.0485 | 0.1938 |
| **ECE** | 0.0364 | 0.0307 | 0.1827 |

### Secondary 5-Class Evaluation
Since all 5 classes were present, an un-tuned secondary 5-class evaluation was performed:
- **Accuracy**: 0.5998
- **Macro-F1**: 0.2581
- **Quadratic Weighted Kappa (QWK)**: 0.3231

## 8. Generalization Observations
- **Catastrophic Sensitivity Drop**: The referable sensitivity plummeted from 98.88% (APTOS) to just 29.32% (Messidor-2). The model heavily biases toward under-predicting severity (high false-negative rate) on the Messidor-2 distribution.
- **Specificity Surge**: As a side-effect of under-prediction, the specificity surged to 97.05%.
- **ROC-AUC Degradation**: The rank-ordering capability dropped from 0.9816 to 0.7669, proving the model lost fundamental discriminative power on the new image domains, regardless of operating thresholds.
- **Calibration Failure**: The Brier score (0.1938) and ECE (0.1827) significantly deteriorated. The Platt scaling curve calibrated for APTOS camera optics entirely failed to calibrate probabilities for Messidor-2.

## 9. Limitations
- **Domain Shift**: There is a profound domain shift between the APTOS (Indian clinics, specific fundus cameras) and Messidor-2 datasets (French hospitals, different cameras, FOV, and resolutions).
- **Undocumented Preprocessing**: The lack of knowledge about the operations that produced `messidor-2/preprocess` restricts the ability to normalize distributions.
- **Unadjusted Thresholds**: Rigidly locking the threshold to 0.22 evaluates the model strictly as an *out-of-the-box* screener. In reality, external deployment often requires light re-calibration on local target populations, though our strict protocol explicitly forbade this.
