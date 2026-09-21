# Member 3 — Sprint 2 Calibration Evaluation Report

## 1. Executive Summary
This report documents the calibration evaluation for binary **Referable DR** prediction using **Platt Scaling** fitted exclusively on the validation split (`val_split.csv`, 440 images) and evaluated on the locked test set (`test_split.csv`, 439 images).

---

## 2. Calibration & Threshold Audit

- **Fitting Split:** `val_split.csv` (440 images) ONLY
- **Evaluation Split:** Locked `test_split.csv` (439 images)
- **Calibration Method:** Platt Scaling (Logistic Sigmoidal Recalibration)
- **Threshold Selection Rule:** Maximize F1 score on validation set subject to Sensitivity \(\ge 0.90\)
- **Selected Operating Threshold:** `0.4000`

---

## 3. Calibrated vs Uncalibrated Metrics Comparison

| Metric | Raw (Uncalibrated) | Calibrated (Platt Scaling) | Target Status |
| :--- | :---: | :---: | :---: |
| **Brier Score (Lower is better)** | `0.0654` | `0.0577` | Improved |
| **Expected Calibration Error (ECE)** | `0.0756` | `0.0364` | Improved |
| **Referable DR Sensitivity** | — | `96.09%` | Met |
| **Referable DR Specificity** | — | `92.31%` | Met |

---

## 4. Non-Contamination Safeguards
- **Zero Test Leakage Enforced:** The locked test set was NOT used for fitting Platt scaling parameters or selecting the decision threshold.
- **Model Architecture Frozen:** CNN feature extraction weights were unchanged.
