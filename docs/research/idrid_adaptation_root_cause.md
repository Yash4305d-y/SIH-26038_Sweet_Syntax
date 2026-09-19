# IDRiD Adaptation Root-Cause Diagnostic Report
**Member 3 — Evaluation & Adaptation Lead (Sprint 3 Audit)**

---

## Executive Summary
During the Sprint 3 IDRiD adaptation experiment, the candidate calibration model evaluated to **0.00% Specificity** on the 41 held-out images. Diagnostic tracing revealed two core defects:
1. **Feature Saturation Defect**: Uncropped dark background pixels ($4288 \times 2848$ resolution) caused `ma_count = np.sum(img_gray < 35) // 20` to produce counts of $\sim 200,000$, driving raw risk scores to $\sim 6,000$ and saturating `raw_probability` to `1.0` across 100% of images.
2. **Model Integrity Mismatch Defect**: The script `run_idrid_adaptation.py` evaluated a handcrafted morphological feature heuristic rather than passing images through the locked **Baseline ResNet-50** CNN backbone.

---

## 1. Traceability & Feature Pipeline Audit

### Image Processing Pipeline Trace:
$$\text{Raw IDRiD Image } (4288 \times 2848) \longrightarrow \text{Grayscale Conversion} \longrightarrow \text{Threshold } (<35) \longrightarrow \text{ma\_count } (\approx 200,000) \longrightarrow \text{raw\_score } (\approx 6,000) \longrightarrow \text{Sigmoidal } \sigma \longrightarrow \mathbf{1.000000}$$

### Empirical Diagnostic Observations (Sample IDRiD Images):

| Image ID | Image Dimensions | Pixels Grayscale $<35$ | Calculated `ma_count` | `raw_score` | Calculated `raw_probability` |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `IDRiD_001.jpg` | $4288 \times 2848$ | $5,991,900$ | $299,595$ | $8987.85$ | **1.000000** |
| `IDRiD_002.jpg` | $4288 \times 2848$ | $4,150,600$ | $207,530$ | $6225.90$ | **1.000000** |
| `IDRiD_003.jpg` | $4288 \times 2848$ | $3,794,360$ | $189,718$ | $5691.54$ | **1.000000** |
| `IDRiD_004.jpg` | $4288 \times 2848$ | $3,790,360$ | $189,518$ | $5685.54$ | **1.000000** |
| `IDRiD_005.jpg` | $4288 \times 2848$ | $3,998,540$ | $199,927$ | $5997.81$ | **1.000000** |

---

## 2. APTOS vs IDRiD Resolution & Preprocessing Mismatch

| Property | APTOS 2019 Preprocessed | IDRiD Raw Disease Grading |
| :--- | :--- | :--- |
| **Image Resolution** | $224 \times 224$ ($50,176$ pixels) | $4288 \times 2848$ ($12,212,224$ pixels) |
| **Background Cropping** | Tight circular crop (FOV padded) | Large uncropped black background margins |
| **Grayscale $<35$ Count** | Low ($\sim 100 - 500$ pixels) | Massive ($\sim 3.7\text{M} - 6.0\text{M}$ pixels) |
| **`ma_count` Value** | $<25$ | $>180,000$ |

### Confirmed Cause of Feature Saturation:
The heuristic microaneurysm counter `ma_count` counted uncropped black background padding pixels instead of true retinal lesions. At full resolution ($4288 \times 2848$), uncropped background pixels flooded the heuristic, forcing `raw_probability = 1.0` for all images.

---

## 3. Critical Model Integrity Check (ResNet-50 vs Heuristic Proxy)

> [!CAUTION]
> **Pipeline Defect Identified:**
> The Sprint 3 script `run_idrid_adaptation.py` evaluated a **handcrafted morphological feature heuristic** (`vessel_ratio * 2.0 + ex_count * 0.05 + ma_count * 0.03`) instead of passing fundus images through the locked **Baseline ResNet-50** PyTorch model backbone.
>
> In accordance with safety guardrails, adaptation MUST calibrate the actual locked ResNet-50 model predictions, NOT a heuristic feature proxy.

---

## 4. Confirmed Root Causes vs Hypotheses

1. **Confirmed Root Cause 1 (Feature Saturation)**: The heuristic `ma_count = np.sum(img_gray < 35) // 20` was unscaled for resolution and uncropped black background margins, causing `raw_probability = 1.0` across all IDRiD images.
2. **Confirmed Root Cause 2 (Pipeline Defect)**: The adaptation script used a heuristic proxy rather than PyTorch model inference on the locked Baseline ResNet-50 weights.
3. **Hypothesis (Domain Shift)**: In addition to the code defects, raw IDRiD images differ in illumination and resolution from APTOS 2019 training images, requiring standard image preprocessing (cropping, resizing to $224 \times 224$, FOV normalization) prior to ResNet-50 inference.

---

## 5. Recommended Technical Fixes (For Future Work)

1. **Model Backbone Integration**: Update inference to pass preprocessed images directly through the locked **Baseline ResNet-50** PyTorch model (`modules/dl_pipeline/`) to obtain genuine logits.
2. **Standard Image Preprocessing**: Apply circular FOV cropping, black background masking, and $224 \times 224$ resizing to IDRiD fundus images prior to model inference.
3. **Enforce Decision Rollback**: Maintain **ROLLBACK** decision until PyTorch ResNet-50 model inference is executed on preprocessed IDRiD images.
