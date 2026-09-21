> [!WARNING]
> **Historical Document** — superseded by current integrated implementation. The claims, limitations, and paths below represent historical research/member handoff and do NOT reflect the final integrated product state.

# Sprint 1 Exit Condition & Role 2 Audit Documentation
**Author:** Member 3 — Dataset + Image Processing + Evaluation Lead  
**Project:** Explainable AI for Diabetic Retinopathy Screening in Rural India (PS 26038)  
**Date:** September 19, 2026

---

## 1. Executive Summary

This document presents the formal audit findings, dataset isolation verification, component status matrix, and Sprint 1 exit evidence for Member 3's responsibilities under the **SIH Technical Master Plan v4 / Part 2**.

All audits were conducted empirically by analyzing existing MATLAB modules in `modules/image_processing/code/`, locked dataset splits in `data/splits/`, and validation outputs in `outputs/` and `results/`.

---

## 2. Complete Component Audit Matrix

| Role 2 Component | Code Location | Input | Processing Method | Output | Dataset Used | Ground Truth / Annotations | Validation Metric | Representative Evidence | Failure Cases | Limitations | Current Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Focus Score** | [`focus_score.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/IQA/focus_score.m) | Fundus Image | 2D Laplacian Filter Variance | Scalar Focus Score | 500-img development set | Heuristic threshold (`0.00003`) | Pass/Fail audit count | `IQA_FAILURE_AUDIT.csv` | Smooth macula or soft gradients yield low variance | Heuristic variance threshold, not a trained blur classifier | **IMPLEMENTED BUT NOT VALIDATED** |
| **Illumination Score** | [`illumination_score.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/IQA/illumination_score.m) | Fundus Image | Mean intensity, dark/bright pixel ratios | Struct (mean, dark, bright ratios) | Development set | Empirical thresholds | Audit rejection count (51 ill-illuminated images) | `IQA_FAILURE_AUDIT.csv` | Peripheral vignetting while optic disc is overexposed | Global intensity metrics miss localized contrast loss | **IMPLEMENTED BUT NOT VALIDATED** |
| **Field of View (FOV)** | [`fov_score.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/IQA/fov_score.m) | Fundus Image | Grayscale threshold, area ratio, circularity | Struct (areaRatio, circularity) | Development set | Empirical thresholds | Audit rejection count (7 FOV failures) | `IQA_FAILURE_AUDIT.csv` | Rectangular cropped wide-field photos trigger circularity rejection | Assumes standard circular aperture fundus photos | **IMPLEMENTED BUT NOT VALIDATED** |
| **IQA Gate Wrapper** | [`iqa_gate.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/IQA/iqa_gate.m) | Image & thresholds | Sequential focus, illumination, & FOV checks | Struct (`pass` boolean, `reason`) | 500-img development set | Integrated threshold struct | 58 total failure cases logged | `IQA_FAILURE_METRICS.csv` | Sequential short-circuiting hides secondary failure reasons | Hardcoded heuristic thresholds | **IMPLEMENTED BUT NOT VALIDATED** |
| **CLAHE** | [`preprocess_clahe.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Preprocessing/preprocess_clahe.m) | Fundus Image | CIELAB L-channel `adapthisteq` | Contrast-enhanced image | APTOS validation set | None | Integrated model performance | `FINAL_BATCH_VALIDATION_RESULTS.csv` | Amplifies background noise in dark peripheral regions | Fixed tile size and clip limit regardless of resolution | **IMPLEMENTED BUT NOT VALIDATED** |
| **Denoising** | [`preprocess_denoise.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Preprocessing/preprocess_denoise.m) | Fundus Image | Gaussian filtering (`\sigma=0.8`) | Denoised image | APTOS validation set | None | None standalone | `result.preprocessed` in pipeline | Isotropic Gaussian smoothing can blur tiny microaneurysms | Fixed `\sigma=0.8`; non-edge-preserving | **IMPLEMENTED BUT NOT VALIDATED** |
| **Blood Vessels** | [`vessel_extraction.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/vessel_extraction.m) | Preprocessed Image | Green-channel multiscale `fibermetric` + Otsu | Struct (`mask`, `vesselAreaRatio`) | Development & APTOS validation | None | None (Dice/IoU uncalculated) | Model feature #1 (`vesselAreaRatio`) | Thin capillaries missed; dark hemorrhage edges misidentified | Unsupervised Hessian response; no UNet vessel segmenter | **IMPLEMENTED BUT NOT VALIDATED** |
| **Optic Disc** | [`optic_disc.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/optic_disc.m) | Preprocessed Image | Brightness percentile + compactness scoring | Struct (`detected`, `bestCandidate`) | Development & APTOS validation | None | Detection rate boolean | Model features #2 & #3 | Large confluent bright exudates near macula cause false OD | Brightness-compactness heuristic without vessel convergence | **IMPLEMENTED BUT NOT VALIDATED** |
| **Fovea** | [`fovea_heuristic.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/fovea_heuristic.m) | Preprocessed Image & Disc | ROI search left of OD + Otsu dark threshold | Struct (`detected`, `centroid`) | Development set | Geometric position rule | None | Model feature #4 (`foveaDetected`) | Fails if OD is not detected or on right eye without side check | Assumes OD is to the right of fovea | **IMPLEMENTED BUT NOT VALIDATED** |
| **Exudate Candidates** | [`exudate_candidates.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/exudate_candidates.m) | Preprocessed Image | Green-channel Top-hat + Otsu/percentile | Struct (`mask`, `candidateAreaRatio`) | Development & APTOS validation | Model classification labels | Indirect model performance | Model features #5–#8 | Bright optic disc margins or drusen trigger false exudates | Candidate extractor, not supervised pixel classifier; pixel IoU unmeasured | **IMPLEMENTED BUT NOT VALIDATED** |
| **MA / Hemorrhages** | [`ma_hemorrhage_candidates.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/ma_hemorrhage_candidates.m) | Preprocessed Image & Vessels | Green-channel Bottom-hat minus vessel mask | Struct (`mask`, `candidateAreaRatio`) | Development & APTOS validation | Model classification labels | Indirect model performance | Model features #9–#12 | Vessel intersection artifacts or choroidal spots flagged as MAs | Combined candidate filter; cannot separate MAs vs blot hemorrhages | **IMPLEMENTED BUT NOT VALIDATED** |
| **Neovascularization** | N/A | Fundus Image | Dropped from MVP scope (Master Plan §6.3) | None | N/A | N/A | N/A | N/A | Unsolvable reliably from 2D fundus photos alone | Excluded from scope | **NOT IMPLEMENTED** |
| **29-Feature Model & Inference** | [`final_DR_inference.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/final_DR_inference.m) | Image / File path | 29 Role 2 summary features -> `BEST_SINGLE_DR_MODEL.mat` | Struct (`drProbability`, `decision`) | APTOS 2019 validation set (366 imgs) | 366 binary ground-truth labels | Sensitivity: `90.72%`, Specificity: `88.37%`, AUC: `0.9497` | `FINAL_BATCH_VALIDATION_RESULTS.csv` | Borderline Grade 1/2 cases near 0.84 threshold | Dependent on exact feature vector order | **VALIDATED** (Dataset-level operating point) |

---

## 3. Dataset Integrity & Split Verification

1. **APTOS 2019 Dataset Isolation:**
   - Evaluated using `tests/verify_dataset_splits.py`.
   - Verified zero patient/image leakage across `train_split.csv` (2,051), `val_split.csv` (440), and locked `test_split.csv` (439).
   - Confirmed locked test set remains 100% untouched.

2. **IDRiD Dataset Split Protocol:**
   - Total available: 81 annotated images.
   - Generated `data/splits/idrid_splits.csv` separating 40 calibration-fit images from 41 held-out validation images.
   - Verification confirmed zero overlap between calibration-fit and held-out subsets.

3. **Messidor-2 External Validation Protocol:**
   - 1,744 images in `data/metadata/messidor_data.csv`.
   - Confirmed as **frozen external validation**. Zero training or hyperparameter tuning is allowed on Messidor-2.

---

## 4. Verification Evidence & Test Execution

The automated verification suite was executed with the following results:

```text
python tests/verify_dataset_splits.py
----------------------------------------------------------------------
Ran 3 tests in 0.199s

OK
[SUCCESS] APTOS locked test set isolation verified: 0 leakage across 2051/440/439 splits.
[SUCCESS] IDRiD splits verified: 40 calibration-fit, 41 held-out validation, 0 overlap.
[SUCCESS] Messidor-2 dataset confirmed as frozen external validation (1744 images).
```

---

## 5. Sprint 1 Exit Condition Status

Member 3 has completed all assigned Sprint 1 responsibilities:
- [x] Full audit of existing Role 2 image-processing implementation.
- [x] Verification of all IQA components (Focus, Illumination, FOV).
- [x] Verification of retinal structures (blood vessels, optic disc, fovea).
- [x] Verification of lesion candidate outputs (microaneurysms, exudates, hemorrhages, neovascularization status).
- [x] Comprehensive status matrix (IMPLEMENTED, PARTIALLY IMPLEMENTED, NOT IMPLEMENTED, IMPLEMENTED BUT NOT VALIDATED, VALIDATED).
- [x] Dataset isolation & non-contamination verification for locked APTOS test set.
- [x] IDRiD calibration-fit (40) and held-out validation (41) split preparation.
- [x] Messidor-2 frozen external validation policy confirmation.
- [x] `main` branch left 100% untouched.
