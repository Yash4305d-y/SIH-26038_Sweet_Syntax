# Explainable AI for Diabetic Retinopathy Screening in Rural India

> **SIH 2026 — Problem Statement 26038 / PS 38**
> An explainable, confidence-aware AI prototype for diabetic retinopathy screening and referral support in rural telemedicine workflows.

---

## Overview

Diabetic Retinopathy (DR) is a diabetes-related retinal disease that can lead to vision impairment and blindness if not detected and managed appropriately.

This project develops a **reproducible MATLAB-based AI screening prototype** that analyzes retinal fundus images and provides:

* Five-level diabetic retinopathy grading
* Referable-DR screening
* Calibrated referral probability
* Model confidence
* Grad-CAM visual explanations
* External-domain evaluation
* A standardized ML inference interface for system integration
* Support for integration with a larger telemedicine workflow and Simulink-based simulation

The system is designed as a **screening and decision-support prototype, not an autonomous clinical diagnostic system**.

---

## Key Idea

The ML pipeline combines detailed DR grading with a separate referral decision:

```text
Retinal Fundus Image
        │
        ▼
Image Quality / Retinal Analysis
        │
        ▼
Frozen ResNet-50 ML Model
        │
        ├──► Grade 0
        ├──► Grade 1
        ├──► Grade 2
        ├──► Grade 3
        └──► Grade 4
        │
        ▼
P(Grade 2) + P(Grade 3) + P(Grade 4)
        │
        ▼
Platt Calibration
        │
        ▼
Frozen Threshold = 0.22
        │
        ▼
Referable / Non-Referable
        │
        ├──► Confidence
        ├──► Grad-CAM
        └──► Reliability / Domain-Shift Analysis
```

The final ML component is exposed through a controlled inference interface so downstream UI and simulation components do not independently recreate the prediction logic.

---

# 1. Project Objectives

The ML component is designed to:

1. Classify retinal fundus images into five DR severity levels.
2. Provide a binary **referable-DR** screening decision.
3. Handle severe class imbalance through experimentally evaluated training strategies.
4. Evaluate performance using metrics appropriate for both class imbalance and ordinal disease severity.
5. Provide calibrated referral probabilities.
6. Provide visual model explanations using Grad-CAM.
7. Evaluate generalization on an independent external dataset.
8. Expose the frozen ML pipeline through a standardized inference contract.
9. Provide ML outputs that can be consumed by the system's UI and workflow simulation.

---

# 2. DR Grading

The model predicts five classes:

| Grade | Description             |
| ----: | ----------------------- |
|     0 | No Diabetic Retinopathy |
|     1 | Mild DR                 |
|     2 | Moderate DR             |
|     3 | Severe DR               |
|     4 | Proliferative DR        |

The five-class output preserves disease severity information.

For screening, the classes are additionally grouped into:

| Screening Class | DR Grades |
| --------------- | --------- |
| Non-referable   | 0, 1      |
| Referable       | 2, 3, 4   |

Therefore:

```text
Referable Probability = P2 + P3 + P4
```

The Grade 2+ definition follows the problem-statement screening requirement used in this prototype.

---

# 3. Dataset Strategy

## Primary Dataset — APTOS 2019

APTOS 2019 is the primary labeled dataset used for model development and evaluation.

A fixed split was created:

| Split      | Images |
| ---------- | -----: |
| Training   |   2051 |
| Validation |    440 |
| Test       |    439 |

The test set contains **439 images** and is kept fixed for authoritative evaluation.

The training data is strongly imbalanced toward Grade 0, making accuracy alone insufficient for model selection.

---

## External Dataset — Messidor-2

Messidor-2 is used strictly as an **external evaluation dataset**.

* Images: **1744**
* Labels: **1744**
* No APTOS overlap identified
* Used for external generalization analysis
* Not used for training
* Not used for model selection
* Not used to tune the calibration threshold

This separation preserves the purpose of external validation.

---

# 4. Model Architecture

## ResNet-50 Transfer Learning

The final model is based on **ResNet-50** with transfer learning.

The network accepts:

```text
224 × 224 × 3
```

and produces five DR class probabilities.

The final model is stored as:

```text
models/baseline_resnet50_smoketest.mat
```

with the network stored in the MATLAB variable:

```text
net
```

The network is a MATLAB `dlnetwork`.

### Why ResNet-50?

ResNet-50 was selected because it provides:

* Mature residual architecture
* Strong transfer-learning capability
* Suitable feature extraction for image classification
* Stable MATLAB Deep Learning Toolbox support
* Compatibility with Grad-CAM
* A reproducible implementation within the MATLAB/Simulink ecosystem

The project does not claim that ResNet-50 is universally superior to every modern architecture.

---

# 5. Training Configuration

The locked baseline configuration uses:

| Parameter             | Value                                     |
| --------------------- | ----------------------------------------- |
| Architecture          | ResNet-50                                 |
| Input                 | 224 × 224 × 3                             |
| Optimizer             | Adam                                      |
| Learning Rate         | 1e-4                                      |
| Batch Size            | 16                                        |
| Loss                  | Cross-Entropy                             |
| Maximum Epochs        | 5                                         |
| Dataset Split         | Fixed APTOS split                         |
| External Augmentation | None beyond baseline resize preprocessing |

The baseline model uses the same preprocessing convention throughout authoritative evaluation and inference.

---

# 6. Model Selection

Multiple variants were investigated rather than selecting the first trained model.

Evaluated approaches included:

* Baseline ResNet-50
* Mild class-weighted training
* Medium class-weighted training
* Strong class-weighted training
* Offline augmentation
* Geometry-normalized/cropped training

## Final Selection

**Baseline ResNet-50 was locked as the final five-class model.**

The decision was based primarily on overall classification performance, with particular importance given to:

* Accuracy
* Macro-F1
* Quadratic Weighted Kappa (QWK)
* Per-class performance
* Consistency with the complete inference pipeline

The baseline achieved the highest overall **accuracy and QWK** among the compared final candidates.

Class weighting improved some minority-class metrics, but the weighted variants did not provide a better overall trade-off for the final system.

---

# 7. Final APTOS 5-Class Results

The authoritative APTOS test-set results for the locked baseline are:

| Metric   |     Result |
| -------- | ---------: |
| Accuracy | **82.92%** |
| Macro-F1 | **0.6358** |
| QWK      | **0.8713** |

### Per-Class Metrics

| Grade | Precision |     Recall |     F1 |
| ----: | --------: | ---------: | -----: |
|     0 |    0.9635 | **0.9814** | 0.9724 |
|     1 |    0.7857 | **0.4889** | 0.6027 |
|     2 |    0.6786 | **0.9421** | 0.7889 |
|     3 |    0.6667 | **0.2609** | 0.3750 |
|     4 |    0.7333 | **0.3143** | 0.4400 |

### Important Limitation

The model performs substantially better on common classes than on the rarest severe classes.

In particular:

* Grade 3 recall: **26.09%**
* Grade 4 recall: **31.43%**

This is an important limitation of the current five-class model and is not hidden by the aggregate accuracy.

The strong referable-DR performance should therefore not be interpreted as evidence that all five individual grades are equally reliable.

---

# 8. Why QWK and Macro-F1?

## Quadratic Weighted Kappa

DR grades are **ordinal**.

A prediction of Grade 4 for a true Grade 3 is less severe than predicting Grade 0 for a true Grade 3.

QWK is therefore useful because it accounts for the magnitude of disagreement between ordinal classes.

## Macro-F1

APTOS is heavily class-imbalanced.

Macro-F1 gives each class equal importance rather than allowing the dominant Grade 0 class to dominate the metric.

Therefore, the project reports both:

```text
Accuracy + Macro-F1 + QWK + Per-Class Metrics
```

rather than relying on accuracy alone.

---

# 9. Referable-DR Screening

For practical screening, the five classes are converted into a binary referral decision:

```text
Grade 0 + Grade 1 → Non-Referable
Grade 2 + Grade 3 + Grade 4 → Referable
```

The referable probability is:

```text
P(referable) = P2 + P3 + P4
```

This allows the system to retain five-level severity information while also producing a screening-oriented referral decision.

---

# 10. APTOS Referable-DR Results

Using the frozen baseline model:

| Metric      |     Result |
| ----------- | ---------: |
| Accuracy    | **93.85%** |
| Sensitivity | **96.09%** |
| Specificity | **92.31%** |
| Precision   | **89.58%** |
| F1          | **92.72%** |
| ROC-AUC     | **0.9816** |

The high sensitivity indicates that the binary referable grouping is effective on the APTOS test set.

However, this does not eliminate the five-class Grade 3/4 limitation described above.

---

# 11. Probability Calibration

Raw neural-network softmax scores are not automatically reliable probabilities.

The project therefore uses **Platt scaling** as a post-hoc calibration method.

### Calibration methodology

* Calibration fitted using the APTOS validation set
* No calibration fitting on the APTOS test set
* No calibration fitting on Messidor-2
* Calibration parameters frozen before final evaluation

The calibrated referable probability is then used for the screening decision.

---

# 12. Frozen Referral Threshold

The referral threshold was selected using the validation set.

Selection criterion:

```text
Maximize F1
subject to Sensitivity ≥ 95%
```

The resulting frozen threshold is:

```text
0.22
```

Therefore:

```text
Calibrated Referable Probability >= 0.22
        → Referable

Calibrated Referable Probability < 0.22
        → Non-Referable
```

This threshold is **not claimed to be a clinically optimal threshold**. It is the validated operating point selected for this prototype.

---

# 13. Calibrated Test Results

On the APTOS test set:

| Metric      |     Result |
| ----------- | ---------: |
| Accuracy    | **93.17%** |
| Sensitivity | **98.88%** |
| Specificity | **89.23%** |
| Precision   | **86.34%** |
| NPV         | **99.15%** |
| F1          | **92.19%** |
| ROC-AUC     | **0.9816** |

Calibration metrics also improved on the test set:

| Metric      |      Raw |   Calibrated |
| ----------- | -------: | -----------: |
| Brier Score | 0.049931 | **0.048506** |
| ECE         | 0.036375 | **0.030670** |

Calibration should therefore be interpreted as improving the behavior of the probability estimates and defining a screening operating point, rather than improving the underlying classifier itself.

---

# 14. Explainability with Grad-CAM

Grad-CAM is integrated into the final ML inference pipeline.

The selected convolutional layer is:

```text
res5c_branch2c
```

Grad-CAM generates a spatial heatmap representing regions that influenced the model's prediction.

The system uses this to provide a visual explanation alongside the predicted grade and confidence.

### Important limitation

Grad-CAM is **not treated as clinical ground truth**.

It indicates model attention, but it does not prove that the model identified a medically correct lesion.

Clinical validation of explanation quality would require expert-annotated lesion localization or equivalent validation.

---

# 15. Grad-CAM Pipeline Verification

An initial implementation exposed a preprocessing mismatch between the authoritative baseline evaluation and Grad-CAM generation.

The issue was identified and corrected.

The final Grad-CAM implementation uses the same baseline preprocessing convention:

```text
imageDatastore
      ↓
augmentedImageDatastore([224 224])
```

The complete APTOS test set was then verified.

### Verification result

```text
Total test images:       439
Grad-CAM outputs:        439
Prediction mismatches:   0
Missing outputs:         0
```

This proves **pipeline integrity**.

It does not constitute clinical validation of the Grad-CAM explanations.

---

# 16. Grad-CAM Representative Cases

A representative-case analysis was performed on the 439-image test set.

Results:

```text
Total:          439
Correct:        364
Misclassified:   75
```

A set of **29 representative cases** was selected for analysis, including examples across grades and both correct and incorrect predictions.

These cases are intended for:

* Explainability
* Error analysis
* Demonstration
* Judge presentation

They are not treated as clinical validation.

---

# 17. External Generalization — Messidor-2

The frozen APTOS-trained model was evaluated on Messidor-2 without tuning the model to the external dataset.

### Five-Class Results

| Metric   |     Result |
| -------- | ---------: |
| Accuracy | **59.98%** |
| Macro-F1 | **0.2581** |
| QWK      | **0.3231** |

### Binary Referable-DR Results

| Metric      |       Result |
| ----------- | -----------: |
| Accuracy    |   **79.30%** |
| Sensitivity |   **29.32%** |
| Specificity |   **97.05%** |
| Precision   |   **77.91%** |
| F1          |   **42.61%** |
| ROC-AUC     |   **0.7669** |
| Brier Score | **0.193753** |
| ECE         | **0.182716** |

These results demonstrate a significant **domain-generalization limitation**.

The model showed a strong tendency toward Grade 0 predictions on Messidor-2.

---

# 18. Why Messidor-2 Was Not Tuned

Messidor-2 is being used as an external validation dataset.

Therefore:

```text
APTOS → Training / Validation / Model Selection
Messidor-2 → External Evaluation
```

Tuning the model or threshold specifically for Messidor-2 would compromise the independence of the external evaluation.

The poor external performance is therefore retained as an honest limitation rather than hidden through external-dataset tuning.

---

# 19. Domain Representation Analysis

A representation audit compared APTOS test images with the processed Messidor-2 images.

Important differences included:

| Property     |                   APTOS |  Messidor-2 |
| ------------ | ----------------------: | ----------: |
| Dimensions   | Variable, high variance |   512 × 512 |
| Aspect Ratio |             1.28 ± 0.19 | 1.00 ± 0.00 |
| Fill         |             0.90 ± 0.12 | 0.94 ± 0.01 |
| Dark Border  |             0.24 ± 0.12 | 0.26 ± 0.01 |

This demonstrates a substantial representation/domain difference.

However, the project does **not** claim that any single preprocessing difference, such as resizing, is solely responsible for the Messidor-2 performance drop.

---

# 20. Domain-Shift-Aware Confidence — Future Enhancement

The external evaluation motivates an additional reliability mechanism:

> **Domain-Shift-Aware Confidence**

The idea is to distinguish:

```text
“How confident is the classifier?”
```

from:

```text
“Does this image resemble the distribution on which the classifier was validated?”
```

A possible implementation is:

1. Extract a late ResNet-50 feature embedding.
2. Estimate the APTOS training feature distribution.
3. Calculate Mahalanobis distance for a new image.
4. Compare the distance against a validated threshold.
5. Flag substantially unfamiliar images for human review.

Conceptually:

```text
High classifier confidence
+
Low domain distance
        → Higher reliability

High classifier confidence
+
High domain distance
        → Reliability warning / human review
```

### Current status

This is an **experimental enhancement**, not a claimed validated production feature.

Before integration, it must be evaluated using:

* APTOS held-out data
* Messidor-2
* Threshold analysis
* Domain-separation metrics

A successful detector would provide an additional safety mechanism against blindly trusting confident predictions on unfamiliar inputs.

---

# 21. Inference Interface

The final ML model is exposed through a standardized MATLAB inference interface.

Main components:

```text
src/runDRInference.m
src/runDRInferenceBatch.m
src/testDRInference.m
```

The interface provides:

* Five-class prediction
* Class probabilities
* Referable probability
* Calibrated probability
* Referable status
* Confidence
* Grad-CAM
* Model status
* Error information

The interface uses the frozen:

* ResNet-50 model
* Preprocessing convention
* Calibration parameters
* Referral threshold
* Grad-CAM configuration

No retraining is performed during inference.

---

# 22. ML Integration Contract

The ML component provides a standardized contract for the rest of the system.

Main documentation:

```text
docs/ml-integration-contract.md
```

The contract ensures that:

* The UI does not duplicate ML logic.
* Simulink does not independently reproduce the classifier.
* The locked model remains authoritative.
* The same preprocessing is used.
* The same calibration is used.
* The same referral threshold is used.
* Grad-CAM is generated through the established pipeline.

This creates a clean separation between:

```text
ML Intelligence
        ↓
Integration Contract
        ↓
UI / Workflow Simulation
```

---

# 23. Verification Status

The complete ML pipeline has been verified.

| Component                | Status |
| ------------------------ | ------ |
| Final Model              | ✅ PASS |
| APTOS Evaluation         | ✅ PASS |
| Model Comparison         | ✅ PASS |
| Grad-CAM                 | ✅ PASS |
| Referable-DR             | ✅ PASS |
| Calibration              | ✅ PASS |
| Messidor-2 Evaluation    | ✅ PASS |
| ML Inference Interface   | ✅ PASS |
| Integration Contract     | ✅ PASS |
| Simulink Handoff         | ✅ PASS |
| Documentation            | ✅ PASS |
| Machine-Readable Results | ✅ PASS |

### Final ML Decision

> **BASELINE RESNET-50 — LOCKED**

The ML pipeline is currently **frozen and integration-ready**.

---

# 24. System Architecture

The complete project is divided into role-based components.

```text
                         ┌─────────────────────┐
                         │   Fundus Image      │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │ Role 2              │
                         │ Image Quality / CV  │
                         └──────────┬──────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────┐
                    │ Role 1 — ML Architect        │
                    │                              │
                    │ Frozen ResNet-50             │
                    │ 5-Class DR                   │
                    │ Referable Screening          │
                    │ Calibration                  │
                    │ Confidence                   │
                    │ Grad-CAM                     │
                    └──────────────┬───────────────┘
                                   │
                                   ▼
                         ┌─────────────────────┐
                         │ Integration Layer   │
                         └─────────┬───────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
          ┌───────────────────┐         ┌───────────────────┐
          │ Role 3             │         │ Role 4             │
          │ Simulink/SimEvents │         │ MATLAB App/UI      │
          └───────────────────┘         └───────────────────┘
```

---

# 25. Technology Stack

## Machine Learning

* MATLAB
* Deep Learning Toolbox
* ResNet-50
* Transfer Learning
* Cross-Entropy Loss
* Class-Weighted Training Experiments
* Image Augmentation Experiments
* Platt Scaling
* Mahalanobis Distance — proposed domain-shift experiment

## Image / Explainability

* MATLAB Image Processing capabilities
* Grad-CAM
* `augmentedImageDatastore`

## Evaluation

* Accuracy
* Precision
* Recall
* F1
* Macro-F1
* Confusion Matrix
* QWK
* ROC-AUC
* Sensitivity
* Specificity
* Brier Score
* Expected Calibration Error

## System Integration

* MATLAB App Designer
* Simulink
* SimEvents
* MATLAB ML inference interface

---

# 26. Project Structure

```text
SIH-26038/
│
├── data/
│   ├── splits/
│   │   ├── aptos_train.csv
│   │   ├── aptos_val.csv
│   │   └── aptos_test.csv
│   └── ...
│
├── models/
│   ├── baseline_resnet50_smoketest.mat
│   └── ...
│
├── src/
│   ├── trainBaselineResNet50.m
│   ├── runDRInference.m
│   ├── runDRInferenceBatch.m
│   ├── testDRInference.m
│   ├── evaluateReferableDR.m
│   ├── calibrateReferableDR.m
│   ├── evaluateMessidor2External.m
│   ├── gradcamBaselineFull.m
│   ├── analyzeGradCAMRepresentativeCases.m
│   └── ...
│
├── outputs/
│   ├── evaluation/
│   ├── gradcam/
│   └── ...
│
├── docs/
│   ├── ml-final-results.md
│   ├── ml-inference-interface.md
│   ├── ml-integration-contract.md
│   ├── ml-handoff-contract.md
│   ├── ml-simulink-handoff.md
│   ├── referable-dr-evaluation.md
│   ├── referable-dr-calibration.md
│   └── ...
│
└── README.md
```

Large datasets, generated images, model artifacts and other large files should remain excluded from version control where appropriate.

---

# 27. Reproducibility

The project uses a fixed evaluation methodology.

Important reproducibility principles include:

* Fixed APTOS train/validation/test split
* Frozen final model
* Frozen calibration
* Frozen referral threshold
* Consistent baseline preprocessing
* Independent external evaluation
* Explicit model comparison
* Machine-readable evaluation outputs
* Automated verification scripts
* Integration contract

The project prioritizes **reproducibility and transparent evaluation over unsupported performance claims**.

---

# 28. Limitations

The current prototype has several important limitations.

### 1. Five-class minority performance

Grade 3 and Grade 4 recall remain low:

```text
Grade 3 Recall = 26.09%
Grade 4 Recall = 31.43%
```

### 2. External-domain generalization

Messidor-2 performance is significantly lower than APTOS performance.

This demonstrates that performance on one retinal dataset should not automatically be generalized to all real-world retinal images.

### 3. Dataset dependence

The final model was developed around the APTOS training distribution.

### 4. Explainability limitations

Grad-CAM provides model-attention visualization but does not establish clinical correctness.

### 5. No clinical deployment claim

The prototype has not undergone prospective clinical validation, regulatory approval, or deployment-level safety validation.

### 6. Domain-shift detection is not yet validated

The proposed Mahalanobis-based domain-shift mechanism requires further experimental validation before being presented as a finalized safety feature.

---

# 29. Safety Positioning

The project deliberately avoids presenting the AI as an autonomous diagnostic authority.

The intended workflow is:

```text
AI Screening
     │
     ├── High-confidence / validated-distribution case
     │
     └── Uncertain / potentially unfamiliar case
                     │
                     ▼
               Human Review
```

The goal is to support screening and prioritization, particularly in telemedicine settings where specialist resources may be limited.

The AI should **assist**, not replace, qualified clinical judgment.

---

# 30. Key Results at a Glance

### APTOS — Five-Class

```text
Accuracy     = 82.92%
Macro-F1     = 0.6358
QWK          = 0.8713
```

### APTOS — Referable DR

```text
Sensitivity  = 96.09%
Specificity  = 92.31%
ROC-AUC      = 0.9816
```

### Calibration

```text
Method       = Platt Scaling
Threshold    = 0.22
```

### Grad-CAM

```text
Test Images  = 439
Outputs      = 439
Mismatches   = 0
Missing      = 0
```

### Messidor-2 External Test

```text
5-Class Accuracy = 59.98%
5-Class Macro-F1 = 0.2581
5-Class QWK      = 0.3231

Referable Sensitivity = 29.32%
Referable AUC         = 0.7669
```

The external results are reported explicitly as evidence of domain-generalization limitations.

---

# 31. Core ML Contribution

The ML contribution of this project is not a claim of a novel CNN architecture.

Instead, it is the construction of an integrated, reproducible ML screening pipeline:

```text
Fixed Dataset Methodology
        ↓
Transfer-Learned ResNet-50
        ↓
5-Class DR Grading
        ↓
Model Comparison
        ↓
Referable-DR Screening
        ↓
Probability Calibration
        ↓
Confidence
        ↓
Grad-CAM Explainability
        ↓
External Domain Evaluation
        ↓
Standardized Inference Contract
```

The project additionally investigates how the system can become **domain-shift-aware**, so that high classifier confidence is not automatically treated as high reliability on unfamiliar data.

---

# 32. Responsible Claim

> **This project is a reproducible research/prototype implementation for diabetic retinopathy screening and decision support. Its reported performance is dataset-specific and should not be interpreted as evidence of clinical diagnostic accuracy across all populations, devices, or imaging conditions. External evaluation demonstrates a significant domain-generalization limitation, which motivates explicit reliability and human-review mechanisms.**

---

# 33. Status

**ML Pipeline: FROZEN**

**Final Model: ResNet-50**

**Inference Interface: READY**

**Integration Contract: VERIFIED**

**External Validation: COMPLETED**

**Grad-CAM: VERIFIED**

**Calibration: VERIFIED**

**Further ML changes should only be introduced if required by system integration or after a clearly defined, independently evaluated experiment.**

---

## Project Goal

The long-term goal is to develop a **quality-aware, explainable, confidence-aware diabetic-retinopathy screening workflow** that can assist telemedicine-based screening and referral while explicitly communicating the model's limitations and uncertainty.

> **The objective is not to make an AI that always says it is right — it is to build a system that measures its performance, exposes its limitations, and avoids blindly trusting predictions outside its validated operating conditions.**
