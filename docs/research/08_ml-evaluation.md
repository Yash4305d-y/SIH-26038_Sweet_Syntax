# 08. ML Evaluation & Validation Protocols

## 1. Dataset Partitioning & Splitting Strategy
To evaluate real-world generalization and prevent data leakage:

* **Patient-Level Stratification:**
  - Split datasets using stratified sampling (e.g., 70% Train / 15% Validation / 15% Test as an initial split guideline, finalized upon verifying class distribution).
  - **Zero Patient Leakage:** Left and right eye images belonging to the same patient must never cross train/validation/test partitions.
  - **Augmentation Guardrail:** Augmented transformations must reside exclusively within the training partition of their source image.

### Dataset Role Breakdown
| Dataset | Subset Used | Primary Role | What It Specifically Measures |
| :--- | :--- | :--- | :--- |
| **APTOS 2019** | Full set (~3,661 images) | Primary Classifier Training & Validation | Multi-class ICDR severity classification & referable screening. |
| **DRIVE** | 40 images (test/train partitions) | Vasculature Evaluation | Vessel segmentation performance (Dice/IoU) using expert manual annotations. |
| **IDRiD** | Disease Grading set (516 images) | Secondary Validation | Indian-demographic DR severity classification agreement. |
| **IDRiD** | Lesion Segmentation subset (81 images) | Lesion & Attribution Validation | Pixel-level evaluation (Dice/IoU) of microaneurysms, hemorrhages, and exudates. |
| **Messidor-2** | Full cohort (1,748 images) | External Generalization Test | Cross-dataset performance under completely unseen camera optics. |

---

## 2. Quantitative Evaluation Metrics

### 2.1 Multi-Class Ordinal Performance
* **Quadratic Weighted Kappa (QWK):**
  - Evaluates ordinal agreement across Grades 0–4, penalizing distant misclassifications quadratically.
  - *Engineering Target:* $\text{QWK} \ge 0.80$ (subject to dataset baseline and cross-validation variance).
* **Per-Class Metrics & Macro-F1:**
  - Standard accuracy hides failure modes on rare classes. The evaluation pipeline computes:
    - Confusion Matrix (Full $5 \times 5$).
    - Per-class Precision, Recall (Sensitivity), and F1-score.
    - Special tracking on **Recall for Grades 2, 3, and 4** to ensure progressive pathologies are not missed.

### 2.2 Binary Screening Performance (Referable DR: Grade $\ge 2$)
* **Sensitivity (Recall):** $\frac{TP}{TP + FN}$ (Clinical target: $\ge 90\%$).
* **Specificity:** $\frac{TN}{TN + FP}$ (Target: $\ge 85\%$).
* **AUC-ROC:** Discriminatory power independent of cut-off (Target: $\text{AUC} \ge 0.92$).
* **Operating Threshold Selection:**
  - Do not default to a fixed $0.5$ probability threshold.
  - Select an optimal operating threshold $\tau$ on the **Validation Set** that meets the screening target ($\ge 90\%$ Sensitivity), then freeze $\tau$ before running the evaluation on the Test set and Messidor-2.

### 2.3 Model Probability Calibration
To substantiate the "Calibrated Confidence" claim, raw model probabilities $P(\text{Grade} \ge 2)$ are calibrated using Platt Scaling or Isotonic Regression on the validation set, then measured via:
* **Expected Calibration Error (ECE):** Bin-weighted difference between model confidence and actual empirical accuracy.
* **Brier Score:** Mean squared error of probabilistic forecasts.
* **Reliability Diagrams:** Visual calibration curve comparing confidence vs. accuracy across 10 deciles.

---

## 3. MATLAB Evaluation Architecture Blueprint

```matlab
function evalResults = evaluateScreeningModel(net, testDatastore, groundTruthLabels, optimalThreshold)
    % 1. Multi-Class Inference
    [predLabels, rawScores] = classify(net, testDatastore);
    
    % Confusion Matrix & Per-Class Stats
    confMat = confusionmat(groundTruthLabels, predLabels);
    evalResults.ConfusionMatrix = confMat;
    evalResults.QWK = calculateQWK(confMat);
    evalResults.PerClassRecall = diag(confMat) ./ sum(confMat, 2);
    evalResults.MacroF1 = calculateMacroF1(confMat);
    
    % 2. Referable Screening Evaluation (Grades 2-4)
    binaryGT = double(groundTruthLabels >= 2);
    probReferable = sum(rawScores(:, 3:5), 2);
    
    % 3. Apply Pre-Tuned Frozen Threshold
    binaryPred = double(probReferable >= optimalThreshold);
    
    TP = sum((binaryPred == 1) & (binaryGT == 1));
    TN = sum((binaryPred == 0) & (binaryGT == 0));
    FP = sum((binaryPred == 1) & (binaryGT == 0));
    FN = sum((binaryPred == 0) & (binaryGT == 1));
    
    evalResults.Sensitivity = TP / (TP + FN);
    evalResults.Specificity = TN / (TN + FP);
    [~, ~, ~, evalResults.AUC] = perfcurve(binaryGT, probReferable, 1);
end