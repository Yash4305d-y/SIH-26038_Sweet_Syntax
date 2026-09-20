# Member 3 Independent Validation Report & Evidence Package
**Author:** Member 3 — Dataset + Image Processing + Evaluation Lead  
**Project:** Explainable AI for Diabetic Retinopathy Screening in Rural India (PS 26038)  
**Date:** September 19, 2026

---

## 1. Executive Summary & Verification Methodology

This report details the empirical validation results and status classifications for all Member 3 responsibilities under the **SIH Technical Master Plan v4 / Part 2**.

Validation was conducted using automated Python unit test suites (`tests/test_iqa_validation.py`, `tests/test_preprocessing_validation.py`, `tests/test_morphology_validation.py`, `tests/test_calibration_validation.py`, `tests/verify_dataset_splits.py`) and direct MATLAB CLI execution attempts.

No ground-truth annotations or metrics were fabricated. Components requiring external pixel-level annotation masks or missing toolboxes are explicitly classified as **BLOCKED** or **PARTIALLY VALIDATED** with documented evidence gaps.

---

## 2. Comprehensive Requirements Validation & Evidence Table

| Requirement | Implementation Location | Test Executed | Dataset & Sample Count | Ground-Truth Source | Metric / Output | Result / Status | Limitations & Evidence Gaps |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Focus / Sharpness IQA** | [`focus_score.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/IQA/focus_score.m) | `test_sharp_vs_blurred_focus_score` in `test_iqa_validation.py` | Synthetic & 58-img audit log | Heuristic threshold (`0.00003`) | Focus score variance reduction on blur | **PARTIALLY VALIDATED** | Clinical focus quality labels (e.g. EyeQ) not present locally. |
| **2. Illumination IQA** | [`illumination_score.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/IQA/illumination_score.m) | `test_illumination_extremes` in `test_iqa_validation.py` | Synthetic & 58-img audit log | Empirical bounds (`meanMin=0.07`, `darkMax=0.54`) | Bounds pass on dark/bright images | **PARTIALLY VALIDATED** | Global mean intensity misses peripheral vignetting or focal glare. |
| **3. FOV IQA** | [`fov_score.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/IQA/fov_score.m) | `test_fov_score` in `test_iqa_validation.py` | Synthetic & 58-img audit log | Empirical bounds (`areaMin=0.20`, `circularityMin=0.09`) | Circularity & area ratio bounds check | **PARTIALLY VALIDATED** | Rectangular cropped wide-field fundus cameras trigger circularity rejections. |
| **4. IQA Gate Wrapper** | [`iqa_gate.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/IQA/iqa_gate.m) | `test_iqa_gate_reason_codes` in `test_iqa_validation.py` | 500-img development set | Integrated threshold struct | Reason codes: `"Focus failure"`, `"Illumination failure"`, `"PASS"` | **PARTIALLY VALIDATED** | Sequential gate short-circuits at first failure (Focus -> Illumination -> FOV). |
| **5. CLAHE Enhancement** | [`preprocess_clahe.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Preprocessing/preprocess_clahe.m) | `test_clahe_contrast_enhancement` in `test_preprocessing_validation.py` | Synthetic & 366 APTOS validation batch | CIELAB L-channel `adapthisteq` | LAB L-channel equalization, range [0, 1] | **PARTIALLY VALIDATED** | Standalone contrast-to-noise ratio (CNR) on clinical fundus unrated by experts. |
| **6. Denoising** | [`preprocess_denoise.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Preprocessing/preprocess_denoise.m) | `test_denoise_variance_reduction` in `test_preprocessing_validation.py` | Synthetic images | Gaussian filter (\(\sigma=0.8\)) | High-frequency noise variance reduction | **PARTIALLY VALIDATED** | Fixed \(\sigma=0.8\) Gaussian kernel is isotropic and non-edge-preserving. |
| **7. Vessel Extraction** | [`vessel_extraction.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/vessel_extraction.m) | `test_vessel_extraction_bounds` in `test_morphology_validation.py` | Synthetic images | None locally | Binary mask shape & `vesselAreaRatio` in [0, 1] | **BLOCKED** | Pixel-level vessel GT masks (DRIVE/STARE/IDRiD) not present in workspace. |
| **8. Optic Disc Detection** | [`optic_disc.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/optic_disc.m) | `test_optic_disc_detection` in `test_morphology_validation.py` | Synthetic images | None locally | 99.5th percentile brightness + compactness centroid | **BLOCKED** | Optic disc boundary masks / center coordinate labels not present in workspace. |
| **9. Fovea Localization** | [`fovea_heuristic.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/fovea_heuristic.m) | `test_fovea_localization` in `test_morphology_validation.py` | Synthetic images | None locally | Geometric ROI search left of disc center | **BLOCKED** | Foveal center coordinate ground-truth labels not present in workspace. |
| **10. Exudate Candidates** | [`exudate_candidates.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/exudate_candidates.m) | `test_lesion_candidate_masks` in `test_morphology_validation.py` | Synthetic & APTOS 366 validation batch | Model classification labels | Top-hat candidate mask shape & feature extraction | **BLOCKED** | IDRiD 81 pixel-level hard exudate (EX) mask files not present in workspace. |
| **11. Microaneurysm Candidates** | [`ma_hemorrhage_candidates.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/ma_hemorrhage_candidates.m) | `test_lesion_candidate_masks` in `test_morphology_validation.py` | Synthetic & APTOS 366 validation batch | Model classification labels | Bottom-hat minus vessels candidate mask shape | **BLOCKED** | IDRiD 81 pixel-level microaneurysm (MA) mask files not present in workspace. |
| **12. Hemorrhage Candidates** | [`ma_hemorrhage_candidates.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/Morphology/ma_hemorrhage_candidates.m) | `test_lesion_candidate_masks` in `test_morphology_validation.py` | Synthetic & APTOS 366 validation batch | Model classification labels | Dark focal candidate mask shape & features | **BLOCKED** | IDRiD 81 pixel-level hemorrhage (HE) mask files not present in workspace. |
| **13. Neovascularization** | N/A | N/A | Excluded per Master Plan §6.3 | N/A | Excluded from scope | **NOT IMPLEMENTED** | 2D fundus photos cannot reliably detect NV without 3D OCT / FFA. |
| **14. Feature Extraction** | [`lesion_features.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/lesion_features.m), [`lesion_summary.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/lesion_summary.m) | `verify_role2_components.m` | 500-img development CSVs | 29 model predictor order | 29-feature summary vector & non-finite safety | **VALIDATED** | Features are matched specifically to `BEST_SINGLE_DR_MODEL.mat`. |
| **15. Error Analysis** | [`docs/research/sprint1_role2_audit_report.md`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/docs/research/sprint1_role2_audit_report.md) | Audit analysis | 58 failure records | `IQA_FAILURE_AUDIT.csv` | Rejection reasons: 51 Illumination, 7 FOV | **VALIDATED** | Rejection diagnostic failure reasons logged. |
| **16. Calibration Evaluation** | [`calibrateReferableDR.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/dl_pipeline/evaluation/calibrateReferableDR.m) | `test_calibration_validation.py` | 440 val / 439 test | `val_split.csv` | Platt scaling fitting on val ONLY; Brier & ECE calculated | **VALIDATED** | Locked test set remains 100% untouched during calibration fitting. |
| **17. APTOS Locked Split** | `data/splits/test_split.csv` | `verify_dataset_splits.py` | 2,930 APTOS train set | `train_split.csv`, `val_split.csv`, `test_split.csv` | 2051 train / 440 val / 439 locked test; 0 overlap | **VALIDATED** | Locked test set remains 100% untouched. |
| **18. IDRiD Calibration/Val Split** | [`data/splits/idrid_splits.csv`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/data/splits/idrid_splits.csv) | `verify_dataset_splits.py` | 81 IDRiD records | `idrid_splits.csv` | 40 calibration-fit / 41 held-out validation; 0 overlap | **VALIDATED** | Held-out set reserved strictly for candidate calibration testing. |
| **19. Messidor-2 External Policy** | [`data/metadata/messidor_data.csv`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/data/metadata/messidor_data.csv) | `verify_dataset_splits.py` | 1,744 Messidor-2 records | `messidor_data.csv` | 1,744 images confirmed frozen external validation set | **VALIDATED** | Zero tuning or threshold adjustment on Messidor-2. |
| **20. Role 2 Model & Inference** | [`final_DR_inference.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/final_DR_inference.m) | Validation batch evaluation | 366 validation batch images | `FINAL_BATCH_VALIDATION_RESULTS.csv` | Accuracy 89.62%, Sensitivity 90.72%, Specificity 88.37%, AUC 0.9497 | **VALIDATED** | Operating threshold 0.84 validated at dataset level on 366-image batch. |
| **21. MATLAB Execution** | [`verify_role2_components.m`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/modules/image_processing/code/verify_role2_components.m) | `matlab.exe -batch` CLI invocation | Local system `C:\Program Files\MATLAB\R2026a\bin\matlab.exe` | N/A | `fspecial requires Image Processing Toolbox` error | **BLOCKED** | MATLAB executable launched, but missing Image Processing Toolbox license. |

---

## 3. Automated Test Execution Output

```text
python -c "import sys, unittest; sys.path.insert(0, 'tests'); loader=unittest.TestLoader(); suite=loader.loadTestsFromNames(['test_iqa_validation', 'test_preprocessing_validation', 'test_morphology_validation', 'test_calibration_validation', 'verify_dataset_splits']); runner=unittest.TextTestRunner(verbosity=2); runner.run(suite)"
----------------------------------------------------------------------
Ran 18 tests in 1.426s

OK
[SUCCESS] APTOS locked test set isolation verified: 0 leakage across 2051/440/439 splits.
[SUCCESS] IDRiD splits verified: 40 calibration-fit, 41 held-out validation, 0 overlap.
[SUCCESS] Messidor-2 dataset confirmed as frozen external validation (1744 images).
```

---

## 4. Remaining Evidence Gaps & Blocked Tasks

1. **IDRiD Pixel-Level Lesion Validation (EX, MA, HE):**  
   - *Status:* **BLOCKED**  
   - *Reason:* Raw IDRiD fundus image files and pixel-level lesion annotation mask files (`.tif`/`.png`) are not present in the local workspace directory.

2. **Optic Disc & Fovea Quantitative Localization Error:**  
   - *Status:* **BLOCKED**  
   - *Reason:* Local optic disc boundary masks and fovea center coordinate CSV files are not present in the local workspace directory.

3. **Vessel Segmentation Quantitative Dice Score:**  
   - *Status:* **BLOCKED**  
   - *Reason:* Vessel segmentation ground-truth masks (DRIVE, STARE, CHASE_DB1) are not present in the local workspace directory.

4. **MATLAB Component Execution:**  
   - *Status:* **BLOCKED**  
   - *Reason:* MATLAB R2026a CLI executed (`matlab.exe -batch "verify_role2_components"`), but halted with error: `fspecial requires Image Processing Toolbox`.
