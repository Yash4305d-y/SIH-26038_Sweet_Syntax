# 08. ML Evaluation & Validation Protocols

## 1. Dataset Split Strategy
To test real-world reliability and prevent data leakage:

| Dataset | Split / Purpose | What It Measures |
| :--- | :--- | :--- |
| **APTOS 2019** | 70% Train, 15% Val, 15% Internal Test | Core classifier training and multi-class accuracy across 5 DR grades. |
| **DRIVE** | 40 images (Validation only) | Accuracy and Dice score of vessel and disc segmentation. |
| **IDRiD** | 516 images + Ground-Truth Masks | Pixel-level evaluation of lesion detection and Grad-CAM alignment. |
| **Messidor-2** | 100% External Test Set | Generalization on completely unseen clinic camera hardware. |

---

## 2. Key Evaluation Metrics

### 2.1 Multi-Class Ordinal Metric
- **Quadratic Weighted Kappa (QWK):** Measures agreement between predicted and ground-truth grades while penalizing larger errors more heavily (e.g., confusing Grade 0 with Grade 4 is penalized much more than Grade 1 with Grade 2).
  - *Target:* $\text{QWK} \ge 0.80$.

### 2.2 Binary Screening Metrics (Referable DR: Grade $\ge 2$)
- **Sensitivity (Recall):** $\frac{TP}{TP + FN}$
  - *Target:* $> 90\%$ (Critical: avoid missing patients who need treatment).
- **Specificity:** $\frac{TN}{TN + FP}$
  - *Target:* $> 85\%$ (Avoid overloading clinics with false alarms).
- **AUC-ROC:** Measures separation between referable and non-referable cases across all thresholds.
  - *Target:* $> 0.92$.

### 2.3 Lesion Detection Metrics (Evaluated on IDRiD Masks)
- **Dice Similarity Coefficient (DSC):** Measures overlap between detected lesion regions and true clinical annotations.
- **Intersection over Union (IoU):** Measures spatial boundary agreement.

---

## 3. MATLAB Evaluation Template Script

```matlab
function metrics = evaluateModel(net, testData, groundTruth)
    % Run model predictions
    [predLabels, scores] = classify(net, testData);
    
    % Multi-Class Confusion Matrix
    confMat = confusionmat(groundTruth, predLabels);
    metrics.ConfusionMatrix = confMat;
    
    % Binary Mapping: Referable DR (Grades 2, 3, 4)
    binaryGT = double(groundTruth >= 2);
    binaryScores = sum(scores(:, 3:5), 2); % Cumulative prob for Grade >= 2
    
    % Calculate ROC and AUC
    [X, Y, ~, metrics.AUC] = perfcurve(binaryGT, binaryScores, 1);
    
    % Sensitivity and Specificity at 0.5 threshold
    binaryPred = double(binaryScores >= 0.5);
    TP = sum((binaryPred == 1) & (binaryGT == 1));
    TN = sum((binaryPred == 0) & (binaryGT == 0));
    FP = sum((binaryPred == 1) & (binaryGT == 0));
    FN = sum((binaryPred == 0) & (binaryGT == 1));
    
    metrics.Sensitivity = TP / (TP + FN);
    metrics.Specificity = TN / (TN + FP);
end