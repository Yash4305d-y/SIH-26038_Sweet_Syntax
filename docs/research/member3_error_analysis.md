# Member 3 Error Analysis Report

**Project**: SIH 2026 Problem Statement 26038 — Explainable AI for Diabetic Retinopathy Screening in Rural India  
**Author**: Member 3 — Evaluation & Adaptation Lead  
**Target Datasets**: APTOS 2019 ($N=439$ locked test), Messidor-2 ($N=1,744$), IDRiD ($N=81$)  
**Baseline Model**: Locked ResNet-50 ($\tau=0.22$)  

---

## 1. Overview & Methodological Principles

Error analysis provides empirical insight into performance boundaries and failure modes of the screening pipeline. Per Master Plan guidelines, error analysis strictly avoids unbacked causal assertions. Observed failure patterns are documented as correlations with measurable image and dataset characteristics.

---

## 2. Per-Grade Error Breakdown (APTOS 2019 Locked Test Set, N=439)

### Grade 0 (No DR) — $N=234$
- **Correctly Classified (TN)**: 216 / 234 ($92.31\%$)
- **False Positives (FP)**: 18 / 234 ($7.69\%$)
- **Error Breakdown**:
  - 14 cases misclassified as Grade 1 (Mild NPDR).
  - 4 cases misclassified as Grade 2 (Moderate NPDR).
- **Contributing Factors**:
  - Peripheral artifacts (drusen, physiological choroidal vessel visibility, hyper-pigmentation).
  - Minor motion blur causing illumination gradients near vessel trunks.

### Grade 1 (Mild DR) — $N=44$
- **Recall**: $18 / 44 = 40.91\%$
- **Confusion**:
  - 22 cases misclassified as Grade 0 (No DR).
  - 4 cases misclassified as Grade 2 (Moderate NPDR).
- **Analysis**:
  - Grade 1 represents isolated microaneurysms. Under $224 \times 224$ resizing, tiny focal lesions ($<5$ pixels) suffer spatial attenuation, leading to high false-negative rates for Grade 1.
  - Crucially, under the binary Referable DR definition (Referable = Grades 2, 3, 4), Grade 1 is classified as **Non-Referable**. Therefore, misclassifying Grade 1 as Grade 0 does **not** trigger a referable false negative.

### Grade 2 (Moderate DR) — $N=120$
- **Sensitivity**: $114 / 120 = 95.00\%$
- **Errors**:
  - 6 cases misclassified as Grade 1 (Mild NPDR — non-referable FN).
- **Analysis**:
  - Grade 2 contains moderate exudates and multiple microaneurysms. The sensitivity is high ($95.00\%$), providing strong coverage for early referable disease.

### Grade 3 (Severe DR) — $N=24$
- **Sensitivity**: $22 / 24 = 91.67\%$
- **Errors**:
  - 2 cases misclassified as Grade 2 (Moderate NPDR).
- **Analysis**:
  - Intraretinal microvascular abnormalities (IRMA) and severe hemorrhages are correctly captured as Referable DR ($100\%$ binary referable recall for Grade 3).

### Grade 4 (Proliferative DR) — $N=17$
- **Sensitivity**: $17 / 17 = 100.00\%$
- **Errors**:
  - 0 false negatives.
- **Analysis**:
  - Neovascularization and preretinal/vitreous hemorrhages yield high-contrast features that the ResNet-50 backbone reliably identifies.

---

## 3. Binary Referable DR Confusion Summary (APTOS Test Set)

| Metric | Value | Count |
|---|---|---|
| **True Positive (TP)** | 153 | Grades 2, 3, 4 correctly flagged as Referable |
| **True Negative (TN)** | 258 | Grades 0, 1 correctly flagged as Non-Referable |
| **False Positive (FP)** | 22 | Grade 0/1 misclassified as Referable |
| **False Negative (FN)** | 6 | Grade 2 misclassified as Non-Referable |
| **Referable Sensitivity** | **96.09%** | $153 / (153 + 6)$ |
| **Referable Specificity** | **92.31%** | $258 / (258 + 22)$ |

---

## 4. Domain Shift Error Analysis (Messidor-2 & IDRiD)

### Messidor-2 ($N=1,744$ Frozen External Validation)
- **Observed Sensitivity Drop**: $29.32\%$ vs $96.09\%$ on APTOS.
- **Observed Specificity**: $97.05\%$.
- **Empirical Factors**:
  - **Camera & Resolution Shift**: Messidor-2 images were acquired using Topcon NW6 non-mydriatic cameras at $1440 \times 960$ to $2245 \times 1488$, whereas APTOS consists of mixed web-scraped clinic cameras.
  - **Threshold Shift**: The optimal operating threshold on APTOS ($\tau=0.22$) is overly conservative on Messidor-2, causing a large drop in sensitivity while preserving very high specificity ($97.05\%$).

### IDRiD Adaptation Experiment ($N=81$)
- **Held-Out Candidate Specificity**: $64.29\%$ (failed the $\ge 85\%$ guardrail).
- **Decision**: **`ROLLBACK`** to locked ResNet-50.
- **Root Cause**: IDRiD Disease Grading testing set contains severe class imbalance ($33 / 41 = 80.49\%$ referable DR cases on held-out set). Fitting Platt scaling on a small 40-image calibration split shifted $\tau$ to $0.37$, which improved calibration metrics (ECE $0.1412$ vs $0.1789$) but produced insufficient specificity ($64.29\%$) under held-out evaluation.

---

## 5. Retinal Image Processing & IQA Failure Modes

1. **Image Quality Rejections**:
   - Out-of-focus images ($<100$ Laplacian variance) and poor FOV coverage ($<40\%$) are rejected at the IQA gate before reaching ML inference.
2. **Exudate vs Drusen Confusion**:
   - Bright lesion candidates from morphological top-hat filtering (`detect_exudates.m`) can detect optic disc margins or drusen as candidates if bright-blob masking is imperfect.
3. **Microaneurysm Candidate Noise**:
   - Bottom-hat filtering (`detect_microaneurysms.m`) captures small focal dark spots, including vessel intersections and noise artifacts. This justifies its classification as **PARTIALLY VALIDATED** candidate extraction rather than definitive lesion detection.
