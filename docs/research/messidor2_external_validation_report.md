# Messidor-2 External Validation Report
**Member 3 — Sprint 2 Official Document**

## Executive Summary
This report details the external generalization performance of the frozen APTOS-trained Baseline ResNet-50 model on the **Messidor-2** benchmark dataset (N = 1744).

> [!IMPORTANT]
> **Strict Evaluation Guardrails:**
> 1. **Zero Tuning:** The model parameters were NOT fine-tuned or retrained on Messidor-2.
> 2. **Zero Threshold Fitting:** The referable DR decision threshold (\(	au = 0.22\)) derived from APTOS validation set was applied without modification.
> 3. **Zero Calibration Fitting:** Calibration parameters were not refit on Messidor-2.

---

## 1. Dataset & Metadata Integrity
- **Dataset**: Messidor-2 (External Benchmark)
- **Total Metadata Records**: 1744 (Verified via `data/metadata/messidor_data.csv`)
- **Fields**: `id_code`, `diagnosis` (0-4 DR grade), `adjudicated_dme`, `adjudicated_gradable`
- **Gradable Images**: 100% of recorded evaluation metadata rows are adjudicated.

---

## 2. Quantitative Performance Metrics

### 5-Class DR Classification
| Metric | Value | Baseline APTOS Test Comparison |
| :--- | :--- | :--- |
| **Accuracy** | 59.98% | 82.92% |
| **Macro F1-Score** | 0.2581 | 0.6358 |
| **Quadratic Weighted Kappa (QWK)** | 0.3231 | 0.8713 |

### Binary Referable DR (Grade 2+ vs Grade 0-1)
| Metric | Value |
| :--- | :--- |
| **ROC-AUC** | 0.7669 |
| **Sensitivity (Recall)** | 29.32% |
| **Specificity** | 97.05% |
| **Precision (PPV)** | 77.91% |
| **Negative Predictive Value (NPV)** | 79.45% |
| **F1-Score** | 0.4261 |
| **Raw Brier Score** | 0.193753 |
| **Expected Calibration Error (ECE)** | 0.182716 |

---

## 3. Discrepancy Analysis & Domain Shift Observation

### Observed Facts:
1. **Specificity vs Sensitivity Trade-off:** High specificity (97.05%) but lower sensitivity (29.32%) on Messidor-2 when using the fixed threshold \(	au = 0.22\).
2. **Grade 0 Bias:** The model exhibits a strong tendency to classify Messidor-2 images as Grade 0 (No DR).
3. **Domain Shift Parameters:**
   - **Image Acquisition Differences:** Messidor-2 fundus photos differ in color temperature, illumination distribution, and FOV padding compared to APTOS 2019.
   - **Pre-processing Requirements:** APTOS images were cropped and square-padded differently than Messidor-2 raw acquisitions.

---

## 4. Methodological Distinction

> [!WARNING]
> **Terminology & Integrity Definitions:**
> - **APTOS Dataset Evaluation:** Internal holdout test evaluation (locked test set, N=439).
> - **Messidor-2 External Validation:** External dataset test evaluating out-of-distribution generalization without retraining.
> - **Clinical Validation:** Prospective real-world multi-center clinical trials under IRB oversight. This study represents **External In-Silico Validation**, NOT prospective clinical validation.

---

## 5. Artifact Verification
- CSV Results: `outputs/evaluation/external_validation/messidor_external_results.csv`
- JSON Summary: `outputs/evaluation/external_validation/messidor_external_metrics.json`
- Verification Status: **PASSED**
