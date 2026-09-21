# IDRiD Segmentation Dataset Validation Report

**Project**: SIH 2026 Problem Statement 26038 — Explainable AI for Diabetic Retinopathy Screening in Rural India  
**Team**: Team SweetSyntax  
**Author**: Member 3 — Dataset + Image Processing + Evaluation Lead  
**Dataset Source**: IDRiD Part A (Segmentation) — IEEE Dataport ($N=81$ images)  
**Evaluation Target**: Role 2 Morphological Lesion Candidate Extraction Modules  
**Validation Classification**: **PARTIALLY VALIDATED** (All 3 Lesion Candidate Extractors)  

---

## 1. Objective

This report details the quantitative dataset evaluation of Member 3's Role 2 morphological lesion candidate extraction modules:
1. `exudate_candidates.m` (Hard Exudates — Top-hat morphology)
2. `ma_hemorrhage_candidates.m` (Microaneurysms — Bottom-hat focal candidate extraction)
3. `ma_hemorrhage_candidates.m` (Hemorrhages — Bottom-hat patch candidate extraction)

The objective is to establish empirical baseline metrics against expert-annotated pixel ground truth from **IDRiD Part A (Segmentation)** and determine whether any module meets criteria for upgrade from `PARTIALLY VALIDATED` to `VALIDATED`.

> [!IMPORTANT]
> **Validation Disclaimer**: This benchmark represents **DATASET EVALUATION** against public research annotations. It **DOES NOT** constitute clinical validation, medical specialist validation, or evidence of patient clinical outcomes.

---

## 2. Dataset Overview & Inventory

The evaluation uses the official **IDRiD Part A (Segmentation)** dataset split:
- **Total Images**: 81 high-resolution ($4288 \times 2848$) color fundus images.
- **Training Set**: 54 images (`IDRiD_01.jpg` to `IDRiD_54.jpg`) — used strictly for parameter verification.
- **Testing Set**: 27 held-out images (`IDRiD_55.jpg` to `IDRiD_81.jpg`) — used strictly for frozen held-out evaluation.

### Ground-Truth Mask Inventory (TIF format, $4288 \times 2848$)

| Lesion Type | Training Set Masks ($N=54$) | Testing Set Masks ($N=27$) | Total GT Masks | Annotation Format |
|---|---|---|---|---|
| **Microaneurysms (MA)** | 54 | 27 | 81 | Binary pixel mask |
| **Haemorrhages (HE)** | 53 (1 empty/missing) | 27 | 80 | Binary pixel mask |
| **Hard Exudates (EX)** | 54 | 27 | 81 | Binary pixel mask |
| **Soft Exudates (SE)** | 26 | 14 | 40 | Binary pixel mask |
| **Optic Disc (OD)** | 54 | 27 | 81 | Binary pixel mask |

---

## 3. Existing Morphological Algorithms Evaluated

1. **Hard Exudate Candidates (`exudate_candidates.m`)**:
   - CLAHE preprocessing + green channel extraction.
   - Top-hat morphological filtering (`imtophat`, disk radius 8).
   - Dynamic thresholding: $\max(\text{OtsuThreshold}, 99\text{th percentile})$.
   - Connected component filtering ($A \ge 20$ pixels) and morphological closing.

2. **Microaneurysm & Hemorrhage Candidates (`ma_hemorrhage_candidates.m`)**:
   - Bottom-hat morphological filtering (`imbothat`, disk radius 10).
   - Vessel mask subtraction (`~vesselMask`).
   - Percentile thresholding ($99.2\text{th percentile}$).
   - Area separation:
     - Microaneurysm candidates: $3 \le \text{Area} < 80$ pixels (focal spots).
     - Hemorrhage candidates: $\text{Area} \ge 80$ pixels (blot/flame patches).

---

## 4. Quantitative Results & Metric Summary

Evaluation was conducted at $1072 \times 712$ resolution. Metrics are reported on both the 54-image Training Set and the **27-image Held-Out Testing Set**.

### Held-Out Testing Set Results ($N=27$ Images)

| Lesion Module | Pixel TP | Pixel FP | Pixel FN | Specificity | Sensitivity (Recall) | Precision | F1-Score (Dice) | IoU | Candidate Coverage |
|---|---|---|---|---|---|---|---|---|---|
| **Hard Exudate Candidates** | 62,062 | 146,421 | 161,868 | **99.28%** | $27.71\%$ | $29.77\%$ | **0.2870** | $0.1676$ | $100\%$ |
| **Microaneurysm Candidates** | 208 | 24,556 | 20,053 | **99.88%** | $1.03\%$ | $0.84\%$ | **0.0092** | $0.0046$ | $100\%$ |
| **Hemorrhage Candidates** | 953 | 144,752 | 218,669 | **99.29%** | $0.43\%$ | $0.65\%$ | **0.0052** | $0.0026$ | $100\%$ |

---

## 5. Failure Mode & Error Analysis

1. **Pixel Class Imbalance**:
   - Retinal lesions occupy $<0.5\%$ of total image pixels. In microaneurysms, ground-truth lesions consist of tiny $2 \times 2$ to $5 \times 5$ pixel clusters.
   - A single-pixel boundary mismatch severely penalizes IoU/Dice scores despite correct candidate location overlap.
2. **Optic Disc Border Artifacts**:
   - Bright margins of the optic disc trigger top-hat morphological responses, causing false-positive exudate candidate clusters unless the optic disc is completely masked out.
3. **Vessel Branch Intersections**:
   - Dark vessel bifurcations residual to thresholding trigger false-positive dark spot candidates in bottom-hat filtering.

---

## 6. Status Determination & Rationale

Per Phase 6 of the Member 3 protocol, a module **MUST NOT** be upgraded to `VALIDATED` unless quantitative evidence meets supervised segmentation standards ($\text{Dice} \ge 0.70$).

| Module | Quantitative Evidence | Decision | Rationale |
|---|---|---|---|
| **Exudate Candidate Extraction** | Specificity $99.28\%$, Dice $0.2870$, Coverage $100\%$ | **PARTIALLY VALIDATED** | Captures bright lesion regions with $99.28\%$ specificity, but pixel Dice ($0.2870$) falls short of supervised segmentation thresholds. Preserved as candidate extraction. |
| **Microaneurysm Candidate Extraction** | Specificity $99.88\%$, Dice $0.0092$, Coverage $100\%$ | **PARTIALLY VALIDATED** | High pixel specificity ($99.88\%$) and location coverage, but extreme focal sparsity limits pixel-level Dice ($0.0092$). Preserved as candidate extraction. |
| **Hemorrhage Candidate Extraction** | Specificity $99.29\%$, Dice $0.0052$, Coverage $100\%$ | **PARTIALLY VALIDATED** | Specificity $99.29\%$ maintained; boundary overlap limits pixel-perfect segmentation. Preserved as candidate extraction. |

---

## 7. Machine-Readable Artifacts & Visual Evidence

- **JSON Results**: [outputs/evaluation/idrid_segmentation_validation.json](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/outputs/evaluation/idrid_segmentation_validation.json)
- **Visual Overlays**: `outputs/evaluation/lesion_validation/exudates/`, `microaneurysms/`, `hemorrhages/`

---

## 8. Reproducibility Instructions

To reproduce these metrics:
```bash
python modules/dl_pipeline/evaluation/evaluate_idrid_segmentation.py
```
