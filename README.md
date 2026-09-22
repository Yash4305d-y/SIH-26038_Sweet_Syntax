# Explainable AI for Diabetic Retinopathy Screening in Rural India

> **SIH 2026 — Problem Statement 26038 / PS 38**
> **Team: Sweet Syntax**
>
> A MATLAB-based, explainable and quality-aware diabetic retinopathy screening prototype designed for rural telemedicine and human-in-the-loop referral workflows.

---

## 🚀 What is this project?

Diabetic Retinopathy (DR) is a diabetes-related retinal disease that can lead to vision impairment and blindness if it is not detected and managed appropriately.

This project develops an **integrated retinal screening prototype** that combines:

* Retinal image validation
* Image Quality Assessment (IQA)
* Image enhancement and preprocessing
* DR severity grading from **Grade 0–4**
* Referable-DR screening
* Probability calibration
* Grad-CAM explainability
* Retinal morphology candidate evidence
* Domain-shift monitoring
* Specialist review and referral workflow
* Case-level audit and traceability
* Controlled adaptation experiments
* District-scale Simulink/Digital Twin simulation

The system is designed as a **screening and decision-support prototype** rather than an autonomous clinical diagnostic system.

---

# ⚡ Quick Start

If you only want to run the working prototype locally, start here.

## 1. Requirements

You need:

* **Python 3.8+**
* **MATLAB R2023b or newer**
* MATLAB toolboxes used by the project, including:

  * Deep Learning Toolbox
  * Image Processing Toolbox
  * Computer Vision Toolbox
* A modern web browser

Simulink/SimEvents are additionally required if you want to inspect or reproduce the Digital Twin simulations.

> **Important:** The repository does not include the original retinal datasets. Dataset images are excluded from version control. To run a normal screening inference, provide a valid retinal/fundus image.

---

## 2. Clone the repository

```bash
git clone https://github.com/Yash4305d-y/SIH-26038_Sweet_Syntax.git
cd SIH-26038_Sweet_Syntax
```

If you already have the repository, simply open a terminal in the project root.

---

## 3. Install Python dependencies

```bash
pip install -r dashboard/requirements.txt
```

The current dashboard requires Flask.

---

## 4. Verify MATLAB

Open MATLAB once and make sure the required toolboxes are available.

From the MATLAB Command Window:

```matlab
ver
```

The project expects the required MATLAB toolboxes to be installed and licensed.

---

## 5. Start the application

From the project root:

```bash
python dashboard/server.py
```

The local dashboard runs at:

```text
http://127.0.0.1:5050
```

Open that address in your browser.

### How inference works

The web dashboard is the interface.

MATLAB remains the authoritative inference backend:

```text
Browser
   │
   ▼
Flask Dashboard
   │
   ▼
Retinal Validation
   │
   ▼
IQA / Preprocessing
   │
   ▼
Morphology Evidence
   │
   ▼
MATLAB ML Inference
   │
   ▼
Locked ResNet-50
   │
   ├──► DR Grade 0–4
   ├──► Class Probabilities
   ├──► Referable Probability
   ├──► Calibrated Decision
   └──► Grad-CAM
   │
   ▼
Domain-Shift Monitor
   │
   ▼
Case / Report / Specialist Workflow
```

The system **fails closed** if the validated MATLAB inference backend is unavailable. Mock inference is not part of the real screening workflow.

The Domain-Shift Monitor is an independent distribution-monitoring signal. It does **not** modify the model prediction, calibrated probability, referral decision, or Grad-CAM.

---

# 🖥️ Using the Application

## Step 1 — Upload a fundus image

Open:

```text
http://127.0.0.1:5050
```

Choose **Upload New Image** and provide a retinal fundus image.

> A sample retinal image is intentionally not committed to the repository because the underlying datasets are excluded from version control.

---

## Step 2 — Run screening

The system processes the image through the integrated pipeline:

```text
Image
  ↓
Retinal suitability check
  ↓
Image Quality Assessment
  ↓
Enhancement / preprocessing
  ↓
Morphology evidence
  ↓
DR grading
  ↓
Referable-DR decision
  ↓
Calibration / referral decision
  ↓
Grad-CAM
  ↓
Domain-Shift Monitor
  ↓
Screening report
```

The first inference may take longer because MATLAB needs to initialize and load the locked model.

---

## Step 3 — Inspect the result

The Layer 1 report provides the screening-oriented information:

* Case ID
* Screening result
* DR grade
* Referable probability
* Referral recommendation
* Next action
* Retinal image
* Explainability evidence
* Referral/follow-up information where available

The Specialist Review portal additionally exposes the Domain-Shift Monitor when available.

---

# 🛡️ Safety Gates

The prototype deliberately prevents unsafe downstream execution.

### Non-retinal image

Provide a clearly non-retinal image.

Expected behavior:

```text
Non-retinal image
      ↓
Retinal suitability gate
      ↓
REJECTED
      ↓
No DR result
```

The system must not send a scenery/photo/non-fundus image to the DR model.

---

### Poor-quality image

Provide a severely blurred or otherwise ungradeable retinal image.

Expected behavior:

```text
Fundus image
     ↓
IQA
     ↓
FAIL
     ↓
Recapture guidance
     ↓
No downstream DR result
```

---

### New image

Uploading a new image clears stale results from the previous analysis.

This prevents an old prediction from being displayed for a new case.

---

# 🧠 Core AI Pipeline

## Five-class DR grading

The model predicts five severity levels:

| Grade | Meaning                 |
| ----: | ----------------------- |
| **0** | No Diabetic Retinopathy |
| **1** | Mild DR                 |
| **2** | Moderate DR             |
| **3** | Severe DR               |
| **4** | Proliferative DR        |

For screening:

```text
Grade 0 + Grade 1 → Non-referable
Grade 2 + Grade 3 + Grade 4 → Referable
```

Therefore:

```text
P(referable) = P(Grade 2) + P(Grade 3) + P(Grade 4)
```

---

# 🧬 Model

The authoritative five-class model is a **ResNet-50 transfer-learning model** implemented in MATLAB.

### Locked model

```text
models/baseline_resnet50_smoketest.mat
```

The MATLAB network is stored as:

```text
net
```

and is a `dlnetwork`.

### Input

```text
224 × 224 × 3
```

### Training configuration

| Parameter     | Value         |
| ------------- | ------------- |
| Architecture  | ResNet-50     |
| Input         | 224 × 224 × 3 |
| Optimizer     | Adam          |
| Learning rate | 1e-4          |
| Batch size    | 16            |
| Loss          | Cross-Entropy |
| Epochs        | 5             |
| Model state   | **LOCKED**    |

The baseline model remains the authoritative model for the integrated system.

---

# 📊 APTOS 2019 Evaluation

APTOS 2019 is the primary development and evaluation dataset.

The fixed split contains:

| Split      | Images |
| ---------- | -----: |
| Training   |  2,051 |
| Validation |    440 |
| Test       |    439 |

The test set is kept fixed for the authoritative evaluation.

---

## Five-Class Results

| Metric       |     Result |
| ------------ | ---------: |
| **Accuracy** | **82.92%** |
| **Macro-F1** | **0.6358** |
| **QWK**      | **0.8713** |

### Per-class performance

| Grade | Precision |     Recall |     F1 |
| ----: | --------: | ---------: | -----: |
|     0 |    0.9635 | **0.9814** | 0.9724 |
|     1 |    0.7857 | **0.4889** | 0.6027 |
|     2 |    0.6786 | **0.9421** | 0.7889 |
|     3 |    0.6667 | **0.2609** | 0.3750 |
|     4 |    0.7333 | **0.3143** | 0.4400 |

### Important limitation

The model does **not** perform equally well across all five grades.

In particular:

```text
Grade 3 Recall = 26.09%
Grade 4 Recall = 31.43%
```

This limitation is explicitly reported rather than hidden behind aggregate accuracy.

---

# 🎯 Referable-DR Screening

For screening, Grades 2–4 are treated as referable:

```text
0, 1 → Non-referable
2, 3, 4 → Referable
```

The screening probability is:

```text
P(referable) = P2 + P3 + P4
```

---

## APTOS Referable-DR Results

Before post-hoc calibration:

| Metric      |     Result |
| ----------- | ---------: |
| Accuracy    | **93.85%** |
| Sensitivity | **96.09%** |
| Specificity | **92.31%** |
| Precision   | **89.58%** |
| F1          | **92.72%** |
| ROC-AUC     | **0.9816** |

---

# 📐 Probability Calibration

Raw neural-network probabilities are not automatically reliable probabilities.

The project therefore uses **Platt scaling** as post-hoc calibration.

### Calibration protocol

```text
APTOS training
      ↓
APTOS validation
      ↓
Fit calibration
      ↓
Freeze calibration
      ↓
APTOS test
```

The APTOS test set is not used to fit calibration.

Messidor-2 is also not used for calibration or threshold tuning.

---

# 🔒 Frozen Referral Threshold

The operating threshold was selected on the validation set using:

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
Calibrated P(referable) >= 0.22
        ↓
     REFERABLE

Calibrated P(referable) < 0.22
        ↓
  NON-REFERABLE
```

This is a validated prototype operating point, **not a claim of a clinically optimal threshold**.

---

# 📈 Calibrated APTOS Results

| Metric      |     Result |
| ----------- | ---------: |
| Accuracy    | **93.17%** |
| Sensitivity | **98.88%** |
| Specificity | **89.23%** |
| Precision   | **86.34%** |
| NPV         | **99.15%** |
| F1          | **92.19%** |
| ROC-AUC     | **0.9816** |

### Calibration metrics

| Metric      |      Raw |   Calibrated |
| ----------- | -------: | -----------: |
| Brier Score | 0.049931 | **0.048506** |
| ECE         | 0.036375 | **0.030670** |

Calibration changes probability behavior and the screening operating point; it does not change the learned feature representation of the ResNet-50.

---

# 🔥 Explainability — Grad-CAM

Grad-CAM is integrated into the inference pipeline.

The selected layer is:

```text
res5c_branch2c
```

The output provides a spatial heatmap showing regions that contributed to the model prediction.

### Verification

The complete APTOS test set was checked:

```text
Test images:       439
Grad-CAM outputs:  439
Prediction errors: 0
Missing outputs:   0
```

This verifies **pipeline consistency** between the authoritative prediction path and Grad-CAM generation.

It does **not** establish clinical validity of the explanations.

Clinical validation of explanation quality would require independent expert annotation/evaluation.

---

# 🔬 Retinal Morphology Evidence

The integrated pipeline also extracts candidate retinal structure/lesion evidence.

Current components include:

| Component          | Method / Output                                  |
| ------------------ | ------------------------------------------------ |
| Optic disc         | Brightness/region-based localization             |
| Fovea              | Optic-disc-relative heuristic localization       |
| Vessels            | MATLAB `fibermetric` + cleanup                   |
| Exudates           | Top-hat + threshold-based candidates             |
| Microaneurysms     | Dark candidate extraction                        |
| Hemorrhage         | Dark candidate extraction                        |
| Neovascularization | Vessel skeleton + branch-point density heuristic |

These outputs are preserved independently from the CNN prediction.

### Important limitation

The morphology modules provide **candidate evidence for interpretability and system integration**.

They are **not claimed to be independently clinically validated lesion detectors**.

In particular, neovascularization is implemented as a heuristic candidate mechanism rather than a clinically validated detector.

---

# 🌍 External Validation — Messidor-2

Messidor-2 is used strictly as an external evaluation dataset.

```text
APTOS
 ├── Training
 ├── Validation
 └── Test

Messidor-2
 └── External evaluation only
```

The external dataset is not used for model training, model selection, calibration fitting, or threshold tuning.

---

## Five-Class Results

| Metric   |     Result |
| -------- | ---------: |
| Accuracy | **59.98%** |
| Macro-F1 | **0.2581** |
| QWK      | **0.3231** |

## Referable-DR Results

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

### What does this tell us?

The external results demonstrate a significant **domain-generalization limitation**.

The model shows a strong tendency toward Grade 0 predictions on Messidor-2.

This is intentionally reported rather than hidden through external-dataset tuning.

---

# 🔎 Domain-Shift Analysis

An image-representation audit found measurable differences between APTOS and Messidor-2.

| Property     |       APTOS |  Messidor-2 |
| ------------ | ----------: | ----------: |
| Dimensions   |    Variable |   512 × 512 |
| Aspect ratio | 1.28 ± 0.19 | 1.00 ± 0.00 |
| Fill         | 0.90 ± 0.12 | 0.94 ± 0.01 |
| Dark border  | 0.24 ± 0.12 | 0.26 ± 0.01 |

These observations are consistent with domain differences.

They do **not** establish that any single preprocessing difference caused the external performance drop.

---

# 🛰️ Runtime Domain-Shift Monitor

The system includes an independent runtime **domain-shift monitor**.

The monitor compares the image's internal ResNet-50 representation against a frozen **APTOS training-domain reference profile**.

### Feature representation

```text
Feature layer = avg_pool
Feature size  = 2048 dimensions
Reference     = APTOS training set
```

The monitor uses the same 224 × 224 preprocessing as the locked inference pipeline and performs a read-only feature extraction pass.

The locked ResNet-50 weights are not modified.

### Runtime statuses

```text
WITHIN_REFERENCE
POTENTIAL_SHIFT
HIGH_MISMATCH
UNAVAILABLE
```

#### WITHIN_REFERENCE

The input representation is within the APTOS reference distribution.

#### POTENTIAL_SHIFT

The input representation differs from the APTOS reference distribution.

This is a **distribution-monitoring signal** and does not indicate that the prediction is incorrect.

#### HIGH_MISMATCH

The input representation is substantially outside the APTOS reference distribution.

This does not determine prediction correctness. Specialist review should be considered when interpreting such a result.

#### UNAVAILABLE

The monitor could not be executed.

The DR inference result is still preserved, but the domain-shift signal is marked unavailable.

### Threshold selection

The monitor thresholds were selected from the **APTOS validation distribution**:

```text
95th percentile → POTENTIAL_SHIFT
99th percentile → HIGH_MISMATCH
```

The observed thresholds are approximately:

```text
Potential Shift = 242.68
High Mismatch   = 278.21
```

These thresholds are **engineering distribution-monitoring thresholds**, not clinically validated thresholds.

They were not tuned on:

```text
APTOS test
Messidor-2
IDRiD
```

### Important interpretation

The Domain-Shift Monitor is **not**:

```text
Prediction confidence
Probability of correctness
Probability of domain shift
Clinical risk score
```

It does not modify:

```text
Predicted Grade
Class Probabilities
Referable Probability
Referable Decision
Calibration
Grad-CAM
IQA result
```

The monitor is intentionally kept separate from the authoritative prediction path.

### Reliability evidence

The current analysis found that representation mismatch is detectable, but the available evidence is **mixed and insufficient to establish that domain distance consistently predicts individual model error across datasets**.

Therefore, the monitor is presented as:

```text
Distribution monitoring
        +
Deployment-awareness evidence
```

rather than as a prediction-correctness estimator.

APTOS is the current reference domain.

Messidor-2 and IDRiD are external stress-test domains and should not be described as representative Indian deployment data.

Representative Indian field data would be required to characterize actual deployment-domain shift.

---

# 👨‍⚕️ Human-in-the-Loop Workflow

The project separates AI output from specialist review.

```text
AI Screening
     │
     ▼
AI Grade / Probability
     │
     ▼
Explainability + Evidence
     │
     ▼
Domain-Shift Signal
     │
     ▼
Specialist Review
     │
     ▼
Specialist Grade
     │
     ▼
Agreement / Referral / Follow-up
```

The specialist grade is stored separately from the AI grade.

The AI prediction and probability are not overwritten by specialist review.

---

# 🗂️ Case Management

The integrated dashboard provides case-level traceability.

Open:

```text
http://127.0.0.1:5050/cases.html
```

The Specialist Portal supports:

* Case queue
* AI grade
* Referable probability
* IQA status
* Grad-CAM
* Morphology evidence
* Domain-Shift Monitor
* Model version
* Calibration version
* Specialist grade
* AI/specialist agreement
* Referral state
* Follow-up state
* Audit information

The case state machine prevents invalid workflow transitions.

Example:

```text
NON_REFERABLE
      ↓
NOT_REFERRED

REFERABLE
      ↓
REFERRED
      ↓
SEEN / LOST_TO_FOLLOWUP
      ↓
COMPLETED
```

---

# 📋 Three-Layer Reporting

The project separates information according to its intended audience.

## Layer 1 — Screening Report

Designed for the screening operator.

Contains:

* Case information
* Screening result
* DR grade
* Referable probability
* Referral recommendation
* Next action
* Relevant visual evidence

The report can be printed as a compact PDF.

---

## Layer 2 — Specialist Review

Available through:

```text
/cases.html
```

Provides technical information required for specialist review, including the Domain-Shift Monitor when available.

---

## Layer 3 — Audit / Traceability

Preserves information such as:

* AI grade
* AI probability
* Model version
* Calibration version
* IQA status
* Grad-CAM status/reference
* Morphology evidence
* Domain-Shift Monitor status
* Specialist grade
* Agreement
* Referral state
* Follow-up state
* Adaptation state

Historical cases without optional information are represented as not recorded rather than fabricated.

---

# 🔄 Controlled Adaptation

The project also contains a separate experimental adaptation workflow.

Open:

```text
http://127.0.0.1:5050/adaptation.html
```

The experiment evaluates calibration adaptation using verified IDRiD data while keeping the ResNet-50 weights frozen.

The workflow is:

```text
Locked Baseline
      ↓
Candidate Calibration
      ↓
Held-out Evaluation
      ↓
Mechanical Decision
      ↓
PROMOTE / ROLLBACK
```

### Final decision

```text
ROLLBACK
```

The experimental candidate **was not promoted**.

The production/screening workflow continues to use the locked baseline.

This keeps experimental adaptation evidence separate from actual patient-case inference.

---

# 📊 Simulink / Digital Twin

The project includes a district-scale telemedicine simulation using Simulink/SimEvents.

Main model:

```text
modules/simulink_telemed/model/DR_DigitalTwin_Day2.slx
```

The simulation models factors such as:

* Patient arrival rate
* Image-quality failures
* Retry behavior
* AI processing time
* Network delay
* Specialist review
* Reviewer capacity
* Queue length
* Workload
* Utilization

### Scenarios

The saved experiments include:

```text
30-day AI-assisted scenario
330-day AI-assisted scenario
330-day manual-review comparison
```

Saved results:

```text
modules/simulink_telemed/results/results_30day.mat
modules/simulink_telemed/results/results_365day.mat
modules/simulink_telemed/results/day2_experiment_results.mat
```

### District-scale design

The simulation uses a nominal design target of:

```text
100,000 patients/year
```

The 330-day stochastic simulation produced:

```text
90,411 realized arrivals
```

This is **simulation telemetry**, not evidence that 90,411 real patients were screened.

The Digital Twin is a capacity-planning model, not field deployment data.

---

# 🧪 Reproducibility & Testing

The project contains automated tests for the major components.

## MATLAB inference

From the project root:

```bash
matlab -batch "cd('D:\SIH-26038'); addpath(genpath('D:\SIH-26038\modules')); testMLIntegrationContract; testDRInference;"
```

This verifies:

* Model loading
* Input validation
* Five-class prediction
* Probability validity
* Referable probability
* Calibration
* Frozen 0.22 threshold
* Grad-CAM
* Baseline prediction consistency
* Documentation
* No training/model modification

---

## Domain-Shift Monitor

The runtime monitor has dedicated verification coverage.

The monitor is tested for:

* Valid runtime execution
* APTOS reference loading
* Threshold loading
* Status classification
* Contract serialization
* Failure-safe behavior
* Independence from DR prediction
* Preservation of the locked baseline

The monitor is designed so that an unavailable monitoring signal does not block the authoritative DR inference result.

---

## Morphology integration

```bash
matlab -batch "cd('D:\SIH-26038'); addpath(genpath('D:\SIH-26038\modules')); run('tests/test_morphology_integration.m');"
```

---

## Core case-management tests

```bash
python -m unittest tests.test_case_management
```

The integrated case-management suite contains:

```text
20 tests
```

and has been verified successfully.

---

## Full Python test suite

```bash
python -m unittest discover tests
```

The repository contains additional legacy/data-dependent validation scripts.

Some may require optional dependencies such as OpenCV or datasets that are intentionally excluded from the repository.

These environment/data warnings are documented in:

```text
TEST_REPORT.md
```

They should not be interpreted as product-logic failures.

---

# 📁 Repository Structure

The current repository is organized around the integrated system:

```text
SIH-26038_Sweet_Syntax/
│
├── README.md
├── QUICK_START.md
├── EVALUATOR_GUIDE.md
├── SYSTEM_ARCHITECTURE.md
├── VALIDATION_REPORT.md
├── TEST_REPORT.md
├── REQUIREMENTS_TRACEABILITY.md
│
├── dashboard/
│   ├── server.py
│   ├── index.html
│   ├── cases.html
│   ├── adaptation.html
│   ├── requirements.txt
│   ├── js/
│   ├── css/
│   ├── data/
│   ├── gradcam_output/
│   └── uploads/
│
├── models/
│   └── baseline_resnet50_smoketest.mat
│
├── modules/
│   ├── dl_pipeline/
│   │   ├── inference/
│   │   ├── domain_shift/
│   │   └── ...
│   │
│   ├── image_processing/
│   └── simulink_telemed/
│
├── outputs/
│   └── evaluation/
│       ├── domain_shift/
│       ├── referable_dr/
│       ├── ml_master/
│       └── model_evidence_package.json
│
├── tests/
│
└── .gitignore
```

Large datasets and generated runtime files are intentionally excluded from version control where appropriate.

---

# 📚 Important Documentation

If you are evaluating or understanding the project, these files are the best starting points.

| Document                                                       | Purpose                                  |
| -------------------------------------------------------------- | ---------------------------------------- |
| [`QUICK_START.md`](QUICK_START.md)                             | Start the application quickly            |
| [`EVALUATOR_GUIDE.md`](EVALUATOR_GUIDE.md)                     | Complete evaluator walkthrough           |
| [`SYSTEM_ARCHITECTURE.md`](SYSTEM_ARCHITECTURE.md)             | Understand the complete architecture     |
| [`VALIDATION_REPORT.md`](VALIDATION_REPORT.md)                 | Authoritative validation metrics         |
| [`TEST_REPORT.md`](TEST_REPORT.md)                             | Regression and verification results      |
| [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) | PS requirement → implementation/evidence |
| `outputs/evaluation/`                                          | Machine-readable evidence                |
| `outputs/evaluation/domain_shift/`                             | Domain-shift evidence and thresholds     |
| `modules/simulink_telemed/`                                    | Digital Twin implementation              |
| `tests/`                                                       | Automated verification                   |

---

# 🔐 Safety & Responsible Positioning

This project intentionally avoids presenting the AI as an autonomous diagnostic authority.

The intended concept is:

```text
Screen
  ↓
Explain
  ↓
Monitor
  ↓
Refer
  ↓
Human Review
  ↓
Follow-up
  ↓
Audit
```

The system is designed to assist screening and referral prioritization.

It is **not**:

* A clinically validated autonomous diagnostic system
* FDA/medical-device approved software
* A replacement for qualified ophthalmologists
* Evidence of prospective clinical deployment
* A guarantee of performance across all cameras, populations or clinical environments

---

# ⚠️ Known Limitations

## 1. Severe-grade recall

The five-class model has limited recall for:

```text
Grade 3 = 26.09%
Grade 4 = 31.43%
```

This is an important limitation.

---

## 2. External domain generalization

Messidor-2 performance is substantially lower than APTOS.

This demonstrates that performance on one retinal dataset cannot automatically be generalized to other imaging distributions.

---

## 3. Runtime domain monitoring

The Domain-Shift Monitor detects representation differences relative to the APTOS reference distribution.

Current evidence does **not** establish that domain distance consistently predicts individual model failure.

The monitor should therefore be interpreted as a **distribution-monitoring signal**, not a prediction-confidence or correctness estimator.

---

## 4. Morphology

Morphology modules are heuristic candidate-evidence mechanisms.

They are not independently clinically validated lesion detectors.

---

## 5. Neovascularization

The current implementation uses vessel skeletonization and branch-point density to generate candidate evidence.

It should not be described as clinically validated neovascularization detection.

---

## 6. Grad-CAM

Grad-CAM demonstrates model attention but does not prove clinical correctness of the highlighted region.

---

## 7. Human-in-the-loop timing

An observed review duration of approximately **8.359 seconds** exists in the engineering evidence.

This was an engineering/familiarization observation, not specialist clinical validation.

---

## 8. Digital Twin

Simulink results are synthetic capacity-planning simulations.

They are not real-world deployment measurements.

---

## 9. Dataset availability

The original retinal datasets are not included in this repository.

They must be obtained separately according to their respective dataset terms if full dataset reproduction is required.

---

# 🧭 Why this project is different

The goal is not simply:

```text
Image → CNN → Prediction
```

The project instead builds a complete screening workflow:

```text
                 ┌───────────────────┐
                 │   Fundus Image     │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ Retinal Validation│
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │       IQA         │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ Preprocessing     │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ ResNet-50         │
                 │ DR Grade 0–4      │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ Calibration       │
                 │ + Referral        │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ Grad-CAM          │
                 │ + Evidence        │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ Domain-Shift      │
                 │ Monitor           │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ Screening Report  │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ Specialist Review │
                 └─────────┬─────────┘
                           ▼
                 ┌───────────────────┐
                 │ Referral /        │
                 │ Follow-up / Audit │
                 └───────────────────┘
```

This architecture explicitly separates:

* **prediction**
* **probability**
* **explanation**
* **morphology evidence**
* **domain monitoring**
* **human review**
* **workflow state**
* **auditability**
* **experimental adaptation**

---

# 📌 Results at a Glance

### APTOS — Five-Class

```text
Accuracy     = 82.92%
Macro-F1     = 0.6358
QWK          = 0.8713
```

### APTOS — Referable DR

```text
Sensitivity  = 98.88%  (calibrated)
Specificity  = 89.23%  (calibrated)
ROC-AUC      = 0.9816
```

### Calibration

```text
Method       = Platt Scaling
Threshold    = 0.22
```

### Grad-CAM

```text
Test images       = 439
Generated outputs = 439
Mismatches        = 0
Missing outputs   = 0
```

### Domain-Shift Monitor

```text
Reference       = APTOS train
Feature layer   = avg_pool
Feature size    = 2048-D

Statuses:
WITHIN_REFERENCE
POTENTIAL_SHIFT
HIGH_MISMATCH
UNAVAILABLE
```

The monitor is an independent distribution signal and does not modify DR predictions or Referable Probability.

### Messidor-2

```text
5-Class Accuracy  = 59.98%
5-Class Macro-F1  = 0.2581
5-Class QWK       = 0.3231

Referable Sensitivity = 29.32%
Referable Specificity = 97.05%
Referable AUC         = 0.7669
```

The external results are retained as an explicit demonstration of the system's domain-generalization limitation.

---

# 🏁 Current Project Status

| Component               | Status                 |
| ----------------------- | ---------------------- |
| MATLAB ML inference     | ✅ Verified             |
| Locked ResNet-50        | 🔒 Frozen              |
| Five-class DR grading   | ✅ Implemented          |
| Referable-DR screening  | ✅ Verified             |
| Probability calibration | ✅ Verified             |
| Grad-CAM                | ✅ Verified             |
| Retinal validation gate | ✅ Implemented          |
| IQA fail-safe           | ✅ Verified             |
| Morphology evidence     | ✅ Integrated           |
| Domain-Shift Monitor    | ✅ Integrated           |
| Case management         | ✅ Verified             |
| Specialist review       | ✅ Implemented          |
| Layer 1 report          | ✅ Implemented          |
| Layer 3 audit           | ✅ Implemented          |
| Controlled adaptation   | ✅ Evaluated — ROLLBACK |
| Simulink Digital Twin   | ✅ Verified             |
| External validation     | ✅ Completed            |
| Regression testing      | ✅ Completed            |
| Evaluator documentation | ✅ Completed            |

### Final ML State

```text
MODEL       = ResNet-50
MODEL STATE = LOCKED
THRESHOLD   = 0.22
CALIBRATION = Platt Scaling
```

The final integrated system is **frozen and integration-ready**.

---

# 🔬 Reproducibility Philosophy

The project prioritizes:

```text
Reproducibility
      +
Transparent Evaluation
      +
Explicit Limitations
      +
Human Oversight
```

over unsupported performance claims.

The system deliberately preserves:

* Fixed evaluation splits
* Frozen model parameters
* Frozen calibration
* Frozen referral threshold
* External validation
* Domain-shift evidence
* Prediction traceability
* Explainability outputs
* Case-level audit information
* Reproducible simulation results
* Explicit experimental rollback decisions

---

# 📖 For Evaluators

If you have only a few minutes:

### 1. Read

```text
QUICK_START.md
```

### 2. Run

```bash
pip install -r dashboard/requirements.txt
python dashboard/server.py
```

### 3. Open

```text
http://127.0.0.1:5050
```

### 4. Demonstrate

```text
Valid fundus
    ↓
IQA
    ↓
DR Grade
    ↓
Referable decision
    ↓
Grad-CAM
    ↓
Domain-Shift Monitor
    ↓
Report
```

### 5. Test safety

```text
Non-fundus → Rejected
Poor-quality fundus → IQA failure
New image → Previous result cleared
```

### 6. Inspect the technical evidence

```text
/cases.html
```

and:

```text
/adaptation.html
```

### 7. Inspect domain-shift evidence

```text
outputs/evaluation/domain_shift/
```

This contains the frozen APTOS reference profile, validation-derived thresholds, external evaluation results, and domain-shift report.

### 8. Reproduce technical validation

See:

```text
VALIDATION_REPORT.md
TEST_REPORT.md
REQUIREMENTS_TRACEABILITY.md
```

---

# 🎯 Project Goal

The long-term objective is to develop a **quality-aware, explainable and deployment-aware diabetic-retinopathy screening workflow** that can support telemedicine-based screening and referral while explicitly communicating uncertainty, distribution differences, and known limitations.

> **The goal is not to build an AI that always says it is right.**
>
> **The goal is to build a system that measures its performance, exposes its limitations, explains its predictions, monitors its operating distribution, preserves human oversight, and avoids blindly trusting predictions outside its validated operating conditions.**

---

## Team Sweet Syntax

**SIH 2026 — Problem Statement 26038**

**Explainable AI for Diabetic Retinopathy Screening in Rural India**
