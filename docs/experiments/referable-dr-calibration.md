# Referable DR Probability Calibration

## Purpose
This document outlines the evaluation and probability calibration methodology for the binary referable Diabetic Retinopathy (DR) classification task using the authoritative baseline ResNet-50 model. The goal is to obtain reliable referable DR probabilities and establish a defensible operating threshold for clinical screening.

This is an ML screening research evaluation, NOT a clinical validation.

## Dataset Split Methodology
The dataset uses the exact existing train, validation, and test splits defined by the project. The validation split (`data/splits/val_split.csv`) is used strictly for calibration and threshold selection. The fixed 439-image test split (`data/splits/test_split.csv`) is held out until the calibration mapping and threshold are frozen. It is evaluated exactly once to produce unbiased, final performance metrics.

## Calibration Strategy
### Why Validation is Used for Calibration
Probability calibration (Platt scaling via logistic regression) is fitted solely on the validation dataset to prevent data leakage and overfitting. Using test data to fit calibration parameters would invalidate the final test metrics.

### Why Test Set is Not Used for Threshold Selection
The test set represents unseen data. If the threshold were tuned on the test set (e.g., maximizing test F1 score), the resulting metrics would be optimistically biased. Threshold selection must occur on the validation data.

## Referable Definition
- **Non-referable**: DR grades 0 and 1
- **Referable**: DR grades 2, 3, and 4
- **Probability Calculation**: $P(\text{referable}) = P(\text{grade 2}) + P(\text{grade 3}) + P(\text{grade 4})$

## Preprocessing Path
The identical preprocessing mechanism as the baseline evaluation is enforced:
1. `imageDatastore` for loading raw images
2. `augmentedImageDatastore([224 224])` for resizing without data augmentation
3. `minibatchpredict` for obtaining final softmax probabilities

## Methodology Details
### Calibration Method
A logistic regression model (Platt scaling) is used to map the raw referable probabilities to calibrated probabilities. The mapping function is fitted to the validation data labels using a binomial distribution and a logit link function.

### Metrics Definitions
- **Brier Score**: The mean squared error between the predicted probability and the true binary label: $Brier = \frac{1}{N} \sum (p_i - y_i)^2$.
- **Expected Calibration Error (ECE)**: ECE partitions predictions into 10 equally spaced bins (0 to 1). For each bin, it calculates the absolute difference between the mean predicted probability (confidence) and the fraction of true positives (accuracy), weighted by the number of samples in the bin.

### Threshold Selection Rule
The operating threshold is selected by maximizing the F1 score on the **validation set**, subject to the constraint that **Sensitivity $\ge$ 0.95**. This provides a clinically conservative screening-oriented operating point that prioritizes catching referable cases (high sensitivity) while maintaining reasonable specificity.

## Results
### Selected Frozen Threshold
- **Selected Threshold**: 0.2200

### Validation Results
- **N**: 440
- **Raw Brier**: 0.050749
- **Calibrated Brier**: 0.051686
- **Raw ECE**: 0.026482
- **Calibrated ECE**: 0.018255

### Test Results
- **N**: 439
- **Accuracy**: 0.9317
- **Sensitivity**: 0.9888
- **Specificity**: 0.8923
- **Precision**: 0.8634
- **NPV**: 0.9915
- **F1**: 0.9219
- **ROC-AUC**: 0.9816
- **Raw Brier**: 0.049931
- **Calibrated Brier**: 0.048506
- **Raw ECE**: 0.036375
- **Calibrated ECE**: 0.030670

### Comparison with Locked Threshold=0.5 Results
Previously locked raw results (Threshold 0.5):
Accuracy = 0.9385, Sensitivity = 0.9609, Specificity = 0.9231, Precision = 0.8958, NPV = 0.9717, F1 = 0.9272, ROC-AUC = 0.9816

*Calibrated vs Baseline Comparison:*
- **ROC-AUC** remains unchanged at 0.9816 because AUC is rank-based and invariant to monotonic transformations like logistic regression scaling.
- **Brier Score** improved from 0.049931 (raw) to 0.048506 (calibrated).
- **ECE** improved from 0.036375 (raw) to 0.030670 (calibrated), demonstrating that calibrated probabilities are more reliable.
- **Sensitivity** increased from 0.9609 to 0.9888 due to the conservative threshold of 0.2200, which aligns with the goal of prioritizing screening performance.
- **NPV** increased from 0.9717 to 0.9915.
- **Specificity** decreased slightly from 0.9231 to 0.8923 as a direct tradeoff for the improved sensitivity.

## Limitations
- **Dataset Size**: The validation set size may limit the robustness of the logistic calibration.
- **Out of Distribution**: Calibration is tied to the specific domain of the training/validation data.
- **Not Clinical Validation**: This is an ML screening research evaluation, NOT a clinical validation.
