# Member 3 — Sprint 2 Error Analysis Report

## 1. Executive Summary
This report analyzes the error distribution of the official **ResNet-50 Baseline V1** model on the locked APTOS 2019 test split (439 images).

---

## 2. Binary Referable DR Performance (Target: Sens > 90%, Spec > 85%)

- **Referable Sensitivity (Recall):** 96.09% (172/179)
- **Referable Specificity:** 92.31% (240/260)
- **False Positives (Referable FP):** 20 images
- **False Negatives (Referable FN):** 7 images

---

## 3. Per-Grade Multiclass Performance Breakdown

| Grade | Description | True Count | Predicted Count | Recall (Sensitivity) | Precision | F1 Score |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: |
| 0 | No DR | 215 | 219 | 98.14% | 96.35% | 0.9724 |
| 1 | Mild DR | 45 | 28 | 48.89% | 78.57% | 0.6027 |
| 2 | Moderate DR | 121 | 168 | 94.21% | 67.86% | 0.7889 |
| 3 | Severe DR | 23 | 9 | 26.09% | 66.67% | 0.3750 |
| 4 | Proliferative DR | 35 | 15 | 31.43% | 73.33% | 0.4400 |

---

## 4. Empirical Error Analysis: Observed Facts vs Possible Explanations

### Grade 0 (No DR)
- **OBSERVED FACT:** Grade 0 specificity is strong, but a small subset of non-referable images receive mild/moderate predictions.
- **POSSIBLE EXPLANATION:** Normal vascular variations or dark background pigmentation artifacts mimicking subtle microaneurysms.

### Grade 1 (Mild DR)
- **OBSERVED FACT:** Grade 1 recall is lower than Grade 0/2. Mild DR cases are frequently confused with Grade 0 (No DR) or Grade 2 (Moderate DR).
- **POSSIBLE EXPLANATION:** Mild DR is characterized solely by isolated microaneurysms; at standard 224x224 input resolution, microaneurysms (<3 pixels across) can be smoothed out by spatial downsampling and Gaussian filtering.

### Grade 2 (Moderate DR)
- **OBSERVED FACT:** Grade 2 represents the referable boundary. Grade 2 recall is solid, correctly triggering referable status.
- **POSSIBLE EXPLANATION:** Exudates and hemorrhages in Grade 2 provide prominent high-contrast features that the ResNet-50 backbone latches onto.

### Grade 3 / Grade 4 (Severe / Proliferative DR)
- **OBSERVED FACT:** Grade 3 and Grade 4 samples are relatively rare in the dataset (class imbalance).
- **POSSIBLE EXPLANATION:** Class imbalance during cross-entropy training causes the unweighted baseline to favor majority classes (Grade 0 and Grade 2).

---

## 5. Non-Contamination Safeguard Confirmation
- **RULE ENFORCED:** The locked test set (439 images) was analyzed strictly for final evaluation and error analysis. Zero hyperparameter tuning or model retraining was performed on the locked test set.
