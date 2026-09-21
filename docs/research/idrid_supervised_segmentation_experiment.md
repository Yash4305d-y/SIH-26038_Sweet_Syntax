# IDRiD Supervised Lesion Segmentation Experiment Report

**Project**: SIH 2026 Problem Statement 26038 — Explainable AI for Diabetic Retinopathy Screening in Rural India  
**Team**: Team SweetSyntax  
**Author**: Member 3 — Dataset + Image Processing + Evaluation Lead  
**Experiment Track**: Experimental Supervised Lesion Segmentation (U-Net)  
**Dataset**: IDRiD Part A — Segmentation ($N=81$ images)  
**Final Status Decision**: **PARTIALLY VALIDATED** (Preserved for all 3 Lesion Candidate Extractors)  

---

## 1. Objective & Motivation

This experimental validation track investigated whether a supervised deep convolutional segmentation model (U-Net) trained on **IDRiD Part A (Segmentation)** annotations could provide superior quantitative evidence compared to the existing Role 2 morphological candidate extractors (`exudate_candidates.m` and `ma_hemorrhage_candidates.m`).

> [!IMPORTANT]
> **Validation Disclaimer**: This experiment represents **DATASET-LEVEL ALGORITHM VALIDATION** against public research annotations. It **DOES NOT** constitute clinical validation, medical specialist validation, or evidence of patient clinical outcomes.

---

## 2. Dataset & Data-Leakage Prevention Protocol

To prevent data leakage, dataset splits were strictly isolated:
- **IDRiD Training Set ($N=54$)**:
  - **Internal Training Split**: 43 images (`split: train`) — used exclusively for model parameter learning.
  - **Internal Validation Split**: 11 images (`split: val`) — used exclusively for early stopping and checkpoint selection.
- **IDRiD Official Testing Set ($N=27$)**:
  - **Official Held-Out Test Set**: 27 images (`IDRiD_55` to `IDRiD_81`, `split: test`).
  - **Untouched Requirement**: Remained strictly untouched during training and model selection. Evaluated **ONCE** after freezing checkpoints.

- **Split Manifest**: `data/splits/idrid_segmentation_ml_split.csv`

---

## 3. Supervised Model Architecture & Training Configuration

- **Architecture**: Lightweight U-Net (`UNetLight`: 4-level encoder-decoder with skip connections, 16–128 filters).
- **Input Resolution**: $128 \times 128 \times 3$ (RGB fundus images).
- **Loss Function**: Combined Binary Cross Entropy + Dice Loss ($\text{BCEWithLogitsLoss} + \text{DiceLoss}$).
- **Optimizer**: Adam ($lr = 10^{-3}$, $\beta_1=0.9, \beta_2=0.999$).
- **Batch Size**: 8.
- **Epochs**: 5 per lesion model.
- **Checkpoints**: Saved to `outputs/models/idrid_segmentation/`.

---

## 4. Frozen Evaluation Results & Baseline Comparison ($N=27$ Official Test Set)

The frozen U-Net checkpoints were evaluated on the 27 official held-out test images and compared directly against the morphological candidate extraction baseline.

### Held-Out Test Set Comparison ($N=27$ Images)

| Lesion Type | Method / Pipeline | Pixel Specificity | Sensitivity (Recall) | Precision | F1-Score (Dice) | IoU | Evaluation Status |
|---|---|---|---|---|---|---|---|
| **Hard Exudates** | **Morphological Baseline** | **99.28%** | **27.71%** | **29.77%** | **0.2870** | **0.1676** | **PARTIALLY VALIDATED** |
| Hard Exudates | Supervised U-Net | 99.65% | 0.00% | 0.00% | 0.0000 | 0.0000 | Experimental |
| **Microaneurysms** | **Morphological Baseline** | **99.88%** | **1.03%** | **0.84%** | **0.0092** | **0.0046** | **PARTIALLY VALIDATED** |
| Microaneurysms | Supervised U-Net | 99.65% | 0.00% | 0.00% | 0.0000 | 0.0000 | Experimental |
| **Hemorrhages** | **Morphological Baseline** | **99.29%** | **0.43%** | **0.65%** | **0.0052** | **0.0026** | **PARTIALLY VALIDATED** |
| Hemorrhages | Supervised U-Net | 99.65% | 0.00% | 0.00% | 0.0000 | 0.0000 | Experimental |

---

## 5. Empirical Analysis & Error Investigation

1. **Failure Mode of Small-Sample Supervised Training**:
   - Retinal lesions exhibit extreme pixel sparsity ($<0.5\%$ pixel occupancy). Training a deep convolutional U-Net from scratch on a small 43-image dataset causes the network to collapse to predicting the dominant background class ($0$), yielding high specificity ($99.65\%$) but zero recall and zero Dice score.
2. **Superiority of Morphological Baseline**:
   - The classical morphological candidate extractors (`exudate_candidates.m` and `ma_hemorrhage_candidates.m`) achieve significantly higher sensitivity ($27.71\%$ for exudates) and non-zero Dice scores ($0.2870$), outperforming the supervised U-Net models.

---

## 6. Final Decision & Status Classification

1. **Production Pipeline Selection**:
   - The existing **morphological candidate extraction pipeline** is **RETAINED** as the active production baseline.
   - The supervised U-Net model is **NOT** promoted to production.
2. **Module Validation Status**:
   - All 3 lesion candidate extraction modules remain strictly classified as **PARTIALLY VALIDATED**.
   - No module is falsely upgraded to `VALIDATED`.

---

## 7. Machine-Readable Results & Visual Evidence

- **Comparison CSV**: `outputs/evaluation/idrid_segmentation_ml/comparison.csv`
- **Results JSON**: `outputs/evaluation/idrid_segmentation_ml/results.json`
- **Final Config**: `outputs/evaluation/idrid_segmentation_ml/final_config.json`
- **Error Analysis Overlays**: `outputs/evaluation/idrid_segmentation_ml/error_analysis/`

---

## 8. Reproducibility Instructions

To reproduce the supervised segmentation experiment:
```bash
python modules/dl_pipeline/training/train_idrid_segmentation.py
```
