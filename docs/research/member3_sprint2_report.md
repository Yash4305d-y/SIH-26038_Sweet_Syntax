# Member 3 Sprint 2 Validation Report
**Team SweetSyntax — Diabetic Retinopathy Technical Master Plan**

---

## 1. Scope

This official report presents the completed Member 3 Sprint 2 validation, error analysis, calibration evaluation, Messidor-2 external validation, benchmark comparison, and end-to-end pipeline verification.

### Core Objectives Executed:
1. **Role 2 Validation**: Verification of Image Quality Assessment (Focus, Illumination, FOV, Quality Gate), preprocessing (CLAHE, Denoising), structural localization (Vessels, Optic Disc, Fovea), and morphological lesion candidate extractors. **Summary: 9 components VALIDATED and 3 lesion-candidate components PARTIALLY VALIDATED.**
2. **Error Analysis**: Per-grade breakdown of classification errors on the locked holdout test set (N = 439), distinguishing observed facts from hypotheses.
3. **Calibration Evaluation**: Verification of Platt scaling, calibration parameters on `val_split.csv` only, Brier score reduction, and ECE evaluation without data leakage.
4. **Messidor-2 External Validation**: External generalization assessment on Messidor-2 (N = 1,744) under strict frozen evaluation guardrails (zero tuning, zero threshold/calibration refitting).
5. **Benchmark Evidence**: Empirical comparison of Baseline ResNet-50 vs weighted loss variants on the locked test set.
6. **End-to-End Pipeline**: Verification of available pipeline stages, documenting stage verification status and Member 1 / Member 2 dependencies.

---

## 2. Role 2 Validation

**Summary**: 9 components VALIDATED and 3 lesion-candidate components PARTIALLY VALIDATED.

| Component | Implementation Exists | Execution Status | Output Validity | Deterministic | Ground Truth Status | Validation Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Focus IQA** | Yes (`FocusEvaluator`) | Validated | Valid score \([0, 1]\) | Yes | N/A | **VALIDATED** |
| **Illumination IQA** | Yes (`IlluminationEvaluator`) | Validated | Valid score \([0, 1]\) | Yes | N/A | **VALIDATED** |
| **FOV IQA** | Yes (`FieldOfViewEvaluator`) | Validated | Valid score \([0, 1]\) | Yes | N/A | **VALIDATED** |
| **IQA Gate** | Yes (`QualityGate`) | Validated | Pass/Fail Decision | Yes | N/A | **VALIDATED** |
| **CLAHE** | Yes (`GreenChannelCLAHE`) | Validated | Contrast Enhanced | Yes | N/A | **VALIDATED** |
| **Denoising** | Yes (`GaussianDenoise`) | Validated | Denoised Image | Yes | N/A | **VALIDATED** |
| **Vessel Extraction** | Yes (`VesselExtractor`) | Validated | Binary Mask | Yes | IDRiD segmentation | **VALIDATED** |
| **Optic Disc Detection** | Yes (`OpticDiscDetector`) | Validated | Bounding Box/Mask | Yes | IDRiD localization | **VALIDATED** |
| **Fovea Estimation** | Yes (`FoveaEstimator`) | Validated | Center Coordinates | Yes | IDRiD localization | **VALIDATED** |
| **Exudate Candidates** | Yes (`ExudateExtractor`) | Validated | Candidate Mask | Yes | IDRiD GT (188.75% FP ratio) | **PARTIALLY VALIDATED** |
| **Microaneurysm Candidates** | Yes (`MAExtractor`) | Validated | Candidate Mask | Yes | IDRiD GT (Low recall <3px) | **PARTIALLY VALIDATED** |
| **Hemorrhage Candidates** | Yes (`HemorrhageExtractor`)| Validated | Candidate Mask | Yes | IDRiD GT (Overlaps vessel) | **PARTIALLY VALIDATED** |

*Note on Ground Truth:* The three partially validated components (Exudate candidates, Microaneurysm candidates, Hemorrhage candidates) function as candidate screeners. Quantitative evaluation against IDRiD ground-truth masks confirmed candidate detection capability, but fine pixel-level segmentations require deep learning refinement (Member 2 scope).

---

## 3. Error Analysis

### Holdout Test Set Performance Summary (N = 439)
- **Overall Accuracy**: **82.92%** (364/439 correct)
- **Macro F1-Score**: **0.6358**
- **Quadratic Weighted Kappa (QWK)**: **0.8713**

### Per-Grade Breakdown:

| Grade | Description | True Count | Predicted Count | Recall (Sensitivity) | Precision | F1 Score |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: |
| 0 | No DR | 215 | 219 | 98.14% | 96.35% | 0.9724 |
| 1 | Mild DR | 45 | 28 | 48.89% | 78.57% | 0.6027 |
| 2 | Moderate DR | 121 | 168 | 94.21% | 67.86% | 0.7889 |
| 3 | Severe DR | 23 | 9 | 26.09% | 66.67% | 0.3750 |
| 4 | Proliferative DR | 35 | 15 | 31.43% | 73.33% | 0.4400 |

### Fact vs Hypothesis Separation:
- **Observed Fact 1**: Grade 1 recall is lower (48.89%) than Grade 0 (98.14%) or Grade 2 (94.21%).
  - **Observed Pattern / Possible Contributing Factor**: Small lesion structures (microaneurysms) may be affected by spatial downsampling at 224x224 resolution and Gaussian filtering. Establishing causality would require controlled multi-resolution ablation experiments.
- **Observed Fact 2**: Grade 3 (Severe) and Grade 4 (PDR) are frequently misclassified as Grade 2 (Moderate).
  - **Possible Explanation**: Unweighted cross-entropy loss biased the feature representation toward Moderate DR due to higher class frequency in the training set (Grade 2 N=999 vs Grade 3 N=193).
- **Observed Fact 3**: Referable DR (Grade 2+) recall is **96.09%** at the uncalibrated argmax level and **98.88%** after validation threshold optimization (\(\tau = 0.22\)).

---

## 4. Calibration Evaluation

### Methodology & Safeguards
- **Fitting Data**: `val_split.csv` ONLY (N = 367).
- **Locked Test Data**: `test_split.csv` ONLY (N = 439). **ZERO leakage from test set during threshold or calibration fitting.**
- **Calibration Method**: Platt Scaling (Logistic Sigmoidal Regression on validation logits).
- **Optimal Threshold Selection**: \(\tau = 0.22\) selected on validation set to achieve \(\ge 90\%\) target sensitivity.

### Calibration Results on Holdout Test Set:

| Metric | Uncalibrated Raw | Calibrated (Platt Scaled \(\tau=0.22\)) | Improvement |
| :--- | :--- | :--- | :--- |
| **Brier Score** | 0.049931 | **0.048506** | -0.001425 (Lower is better) |
| **Expected Calibration Error (ECE)** | 0.036375 | **0.030670** | -0.005705 (Lower is better) |
| **Referable DR Sensitivity** | 96.09% | **98.88%** | +2.79% |
| **Referable DR Specificity** | 92.31% | **89.23%** | -3.08% (Controlled tradeoff) |
| **Referable DR NPV** | 97.50% | **99.15%** | +1.65% |

---

## 5. Messidor-2 External Validation

### External Test Conditions (N = 1,744)
- **Dataset**: Messidor-2 (1,744 annotated records, `data/metadata/messidor_data.csv`).
- **Model State**: Frozen Baseline ResNet-50.
- **Guardrails**: **ZERO tuning**, **ZERO threshold optimization**, **ZERO calibration fitting** on Messidor-2.

### Quantitative External Results:
- **5-Class Accuracy**: **59.98%**
- **Macro F1-Score**: **0.2581**
- **Quadratic Weighted Kappa (QWK)**: **0.3231**
- **Binary Referable ROC-AUC**: **0.7669**
- **Referable Sensitivity (\(\tau=0.22\))**: **29.32%**
- **Referable Specificity (\(\tau=0.22\))**: **97.05%**

### Analysis of External Generalization:
The drop in sensitivity on Messidor-2 under the fixed threshold reflects significant **domain shift** (differences in camera resolution, color temperature, FOV cropping, and lighting). This empirical finding confirms that models trained strictly on single-source datasets (APTOS) require domain adaptation or multi-dataset training before deployment in heterogeneous clinical settings.

---

## 6. Benchmark Evidence

Empirical comparison across model variants trained on APTOS 2019 and evaluated on the locked holdout test set (N = 439):

| Model Variant | Strategy | 5-Class Acc | Macro F1 | QWK | Ref. Sens | Ref. Spec | Ref. Prec |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline ResNet-50 (Locked)** | Unweighted CE, Softmax | **82.92%** | 0.6358 | **0.8713** | **96.09%** | 92.31% | 89.29% |
| **Mild Weighted ResNet-50** | Inverse Class Weights | 79.95% | **0.6467** | 0.8730 | 83.80% | **97.31%** | **95.54%** |
| **Strong Weighted ResNet-50** | Sqrt Class Weights | 73.12% | 0.6103 | 0.8437 | 83.24% | 96.54% | 94.30% |

**Decision Rationale**: Baseline ResNet-50 was selected and locked because high sensitivity (96.09%) for referable DR is clinically paramount to prevent false negatives in screening.

---

## 7. End-to-End Pipeline

### Pipeline Verification & Handoff Audit:

- **VERIFIED STAGES** (Executed and tested in code):
  - `Image` $\rightarrow$ `Validation` $\rightarrow$ `IQA` $\rightarrow$ `Processing` $\rightarrow$ `DR` $\rightarrow$ `Referable` $\rightarrow$ `Explanation`
- **PREPARED STAGES**:
  - `Report` data contract / handoff interface (Payload schema and metadata formatting defined).
- **DEPENDENT ON MEMBER 1**:
  - `Report` PDF rendering and Web UI display.

```
[VERIFIED: Raw Image] 
   │
   ▼
[VERIFIED: Stage 1 Validation] ────► RetinalDetector (Pass/Fail)
   │
   ▼
[VERIFIED: Stage 2 IQA] ───────────► Focus, Illumination, FOV, QualityGate
   │
   ▼
[VERIFIED: Stage 3 Processing] ────► CLAHE, Denoise, Structural Candidates
   │
   ▼
[VERIFIED: Stage 4 DR Model] ──────► ResNet-50 Logits (5-Class)
   │
   ▼
[VERIFIED: Stage 5 Referable] ─────► Platt Scaling & Threshold (tau=0.22)
   │
   ▼
[VERIFIED: Stage 6 Explanation] ───► Grad-CAM Heatmap
   │
   ▼
[PREPARED / DEPENDENT: Stage 7] ──► Clinical PDF & UI Display (Member 1 Scope)
```

---

## 8. Test Results

All test suites executed locally:

- **Integration Pipeline Unit Tests (`tests/test_pipeline_integration.py`)**: 4/4 Passed (100%)
- **Preprocessing Validation Tests (`tests/test_preprocessing_validation.py`)**: 3/3 Passed (100%)
- **IQA Validation Tests (`tests/test_iqa_validation.py`)**: 4/4 Passed (100%)
- **Calibration Validation Tests (`tests/test_calibration_validation.py`)**: 4/4 Passed (100%)
- **Morphology Validation Tests (`tests/test_morphology_validation.py`)**: 4/4 Passed (100%)
- **Dataset Split Verification (`tests/verify_dataset_splits.py`)**: 3/3 Passed (100%)
- **MATLAB Verification (`modules/image_processing/code/verify_role2_components.m`)**: **BLOCKED** (MATLAB Image Processing Toolbox not installed on local host).

**Total Python Tests Passed:** **22 / 22 (100%)**

---

## 9. Completed

- [x] Role 2 Python component execution and outputs verification.
- [x] Hardened pipeline integration testing (`test_pipeline_integration.py`).
- [x] Error analysis per DR grade (N=439 test set) with observed facts vs hypotheses.
- [x] Calibration evaluation (Platt scaling fitting on val split ONLY, Brier score, ECE reduction).
- [x] Messidor-2 external validation (N=1,744) under frozen guardrails.
- [x] Empirical benchmark model comparison (Baseline vs Weighted loss variants).
- [x] End-to-end pipeline execution through Stage 6 and Member 1/2 dependency mapping.

---

## 10. Partially Validated

- **Lesion Candidate Extractors**: Exudate candidates, Microaneurysm candidates, and Hemorrhage candidates are executable and produce candidate masks, but pixel-level precision is limited without deep learning segmentation.

---

## 11. Blocked

- **MATLAB Executable Tests**: Blocked due to missing local MATLAB Image Processing Toolbox license.

---

## 12. Dependencies on Member 1 / Member 2

- **Member 1 Dependency**: Stage 7 Report PDF rendering and Web UI display.
- **Member 2 Dependency**: Deep learning lesion segmentation models.

---

## 13. Remaining Work

- Integration of final Member 1 report export module when delivered.

---

## 14. Sprint 2 Exit Condition

**Exit Condition Status:** **FULLY SATISFIED FOR MEMBER 3**

The core processing, validation, quality gating, DR classification, referable scaling, and explanation stages:
$$\text{Image} \rightarrow \text{Validation} \rightarrow \text{IQA} \rightarrow \text{Processing} \rightarrow \text{DR} \rightarrow \text{Referable} \rightarrow \text{Explanation}$$
are **fully executable, verified, and backed by empirical evidence**. Stage 7 (Report) is prepared with clear data contract interfaces for Member 1/2 final delivery.
