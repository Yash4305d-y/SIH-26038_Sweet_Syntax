# Referable DR Benchmark Evaluation

## Overview
This document summarizes the binary "Referable vs. Non-Referable" Diabetic Retinopathy evaluation performed using the authoritative Baseline ResNet-50 predictions. 

**Important Disclaimer**: This is a research-grade benchmark evaluation designed strictly for the SIH PS 26038 technical milestone. **It does not constitute clinical validation** and cannot be used for clinical decision-making.

## Configuration & Processing
- **Model Used**: Baseline ResNet-50
- **Authoritative Source**: `results/baseline_test_predictions.csv`
- **Total Images Processed**: 439 (the fixed APTOS test set cohort)
- **Binary Mapping**: 
  - **Non-Referable (0)**: DR Grades 0 and 1
  - **Referable (1)**: DR Grades 2, 3, and 4
- **Referable Probability Calculation**: 
  The raw 5-class softmax probabilities for the Baseline network were deterministically recovered in-memory using `augmentedImageDatastore([224 224])` and `minibatchpredict`. The probability of a case being Referable was explicitly calculated as: `P(Referable) = P(Grade 2) + P(Grade 3) + P(Grade 4)`.
- **Threshold**: The default threshold of `0.5` was applied.

## Measured Metrics (at Threshold 0.5)
The detailed programmatic output is stored in `outputs/evaluation/referable_dr/referable_dr_metrics.csv`. The core evaluation metrics measured on the complete test set are:
- **Accuracy**
- **Sensitivity (Recall)**
- **Specificity**
- **Precision (PPV)**
- **Negative Predictive Value (NPV)**
- **F1 Score**
- **ROC-AUC (Area Under the Receiver Operating Characteristic Curve)**

*Note: For the exact numeric values of this run, please consult the MATLAB execution output or `referable_dr_metrics.csv`.*

## Outputs
All generated artifacts are preserved without altering the existing model or baseline metrics:
- `referable_dr_metrics.mat` and `referable_dr_metrics.csv`: The aggregated benchmark metrics.
- `referable_dr_results.csv`: A complete 439-row mapping showing the exact prediction, binary categorization, and Referable probability for each image.
- `referable_dr_confusion_matrix.png`: A visual matrix separating Non-Referable vs Referable classifications.
- `referable_dr_roc_curve.png`: The ROC curve plotting True Positive Rate vs. False Positive Rate across all thresholds.

## Limitations
- **Baseline Capabilities**: Because this relies exclusively on the smoke-tested Baseline model without class-weight optimization, the precision and sensitivity may skew toward the majority classes (e.g., Grade 0 or Grade 2) rather than capturing the nuanced boundaries between Grade 1 and Grade 2.
- **Threshold Tuning**: A fixed threshold of 0.5 was utilized. In clinical or practical deployments, this threshold is often tuned dynamically based on the ROC curve to favor sensitivity (to avoid missing Referable DR cases) over strict accuracy.
