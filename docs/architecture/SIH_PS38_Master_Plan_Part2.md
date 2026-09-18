# SIH 2026 — Technical Master Plan

## PS 26038 — Explainable AI for Diabetic Retinopathy Screening in Rural India

**Organization:** MathWorks
**Environment:** MATLAB / Simulink
**Primary Dataset:** APTOS 2019
**External Validation:** Messidor-2
**Adaptation Experiment:** IDRiD
**North Star:** Closed-Loop, Deployment-Aware DR Screening

---

# 0. NORTH STAR

## Screen → Explain → Refer → Follow → Verify → Controlled Adaptation

The system must not stop at:

> **Image → AI prediction**

It should demonstrate a complete deployment-aware screening workflow:

```text
Acquire
   ↓
Validate retinal image
   ↓
Assess image quality
   ↓
Enhance / preprocess
   ↓
Extract retinal structures + lesion evidence
   ↓
DR severity grading (0–4)
   ↓
Referable DR decision
   ↓
Calibrated confidence
   ↓
Explain prediction
   ↓
Generate patient / specialist / audit report
   ↓
Referral when required
   ↓
Specialist review
   ↓
Verified clinical grade
   ↓
Follow-up tracking
   ↓
Controlled calibration update
   ↓
Held-out validation
   ↓
PROMOTE / ROLLBACK
```

The system must remain **safe-by-design**:

* A poor-quality image must not silently receive a DR diagnosis.
* A non-fundus image must not reach the DR model.
* A new image must clear previous results.
* A failed quality gate must stop downstream DR inference.
* The CNN must not learn from its own predictions.
* Calibration updates must use verified labels.
* No update is promoted without held-out validation.
* The locked baseline remains available for rollback.

---

# 1. OFFICIAL SIH REQUIREMENT COVERAGE

This is the master checklist.

Every requirement must eventually satisfy:

> **Implementation + Demonstrable Output + Validation Evidence**

| SIH requirement              | Owner               | Prototype location      | Required evidence                                         |
| ---------------------------- | ------------------- | ----------------------- | --------------------------------------------------------- |
| Image-quality assessment     | Member 3 / Role 2   | Preprocessing/IQA layer | IQA metrics + failure examples                            |
| Focus assessment             | Role 2              | IQA                     | Focus score + threshold validation                        |
| Illumination assessment      | Role 2              | IQA                     | Illumination metrics/examples                             |
| FOV assessment               | Role 2              | IQA                     | FOV validity + failure examples                           |
| Image enhancement            | Role 2              | Preprocessing           | CLAHE / normalization / denoising comparison              |
| Ungradable rejection         | Role 2 + Member 1   | IQA gate                | FAIL state + reason + recapture                           |
| Retinal structures           | Role 2              | Image-processing layer  | Vessel/disc/fovea outputs                                 |
| Vessel segmentation          | Role 2              | Structure extraction    | Masks + validation                                        |
| Optic-disc localization      | Role 2              | Structure extraction    | Localization output + validation                          |
| Fovea localization           | Role 2              | Structure extraction    | Localization output + validation                          |
| Microaneurysm candidates     | Role 2              | Lesion extraction       | Candidate maps + validation                               |
| Exudate extraction           | Role 2              | Lesion extraction       | Candidate/segmentation output                             |
| Hemorrhage detection         | Role 2              | Lesion extraction       | Candidate/classification output                           |
| Neovascularization           | Role 2              | Lesion analysis         | Demonstrable method/output if supported by available data |
| Structured retinal features  | Role 2              | Feature extraction      | Machine-readable feature output                           |
| DR grade 0–4                 | Member 2 / ML       | DR inference            | Locked test metrics                                       |
| Referable DR                 | Member 2 + Member 3 | Binary decision         | Sensitivity/specificity                                   |
| Explainability               | Member 1            | Grad-CAM                | Verified Grad-CAM outputs                                 |
| Lesion-level evidence        | Role 2 + Member 1   | Evidence layer          | Lesion/structure + model evidence                         |
| Calibrated confidence        | Member 3            | Calibration             | Brier/ECE/calibration metrics                             |
| Annotated reports            | Member 1            | Reporting               | Working 3-layer report                                    |
| Human-in-loop                | Member 1            | Specialist review       | Timed review workflow                                     |
| Simulink deployment model    | Simulink owner      | Simulink                | Throughput/capacity simulation                            |
| 100k+ patients/year scenario | Simulink owner      | Simulink                | Capacity evidence                                         |
| External validation          | Member 3            | Evaluation              | Frozen Messidor-2 results                                 |
| Benchmark comparison         | Member 3            | Evidence package        | Reproducible comparison                                   |
| Integrated pipeline          | All                 | End-to-end              | Full demonstration                                        |
| Controlled adaptation        | Member 3 + Member 1 | Calibration dashboard   | Real before/after + PROMOTE/ROLLBACK                      |

---

# 2. EXISTING PROTOTYPE — DO NOT REBUILD IT

The current prototype already contains major validated components.

The strategy is:

> **Extend the existing prototype around the locked ML inference contract instead of rewriting the working ML system.**

Current important components:

```text
src/runDRInference.m
src/runDRInferenceBatch.m
src/testDRInference.m

src/testMLIntegrationContract.m
src/exportDRInferenceContractJSON.m

docs/ml-inference-interface.md
docs/ml-integration-contract.md
docs/ml-handoff-contract.md
docs/ml-simulink-handoff.md

outputs/evaluation/ml_master/
outputs/gradcam/final/
outputs/gradcam/selected_cases/
```

The existing ResNet-50 remains:

> **Official Baseline V1**

Do not replace it merely because another experiment obtains a better single metric.

---

# 3. FINAL SYSTEM ARCHITECTURE

```text
                         FUNDUS IMAGE
                              │
                              ▼
                  ┌──────────────────────┐
                  │ RETINAL VALIDATION   │
                  │ Is this a fundus?    │
                  └──────────┬───────────┘
                             │
                   ┌─────────┴─────────┐
                   │                   │
                NOT FUNDUS            FUNDUS
                   │                   │
                   ▼                   ▼
              REJECT + STOP           IQA
                                       │
                             ┌─────────┴─────────┐
                             │                   │
                           FAIL                 PASS
                             │                   │
                             ▼                   ▼
                       RECAPTURE          PREPROCESSING
                       GUIDANCE            CLAHE
                                           Normalization
                                           Denoising
                                               │
                                               ▼
                                  ┌────────────────────────┐
                                  │ ROLE 2 IMAGE ANALYSIS  │
                                  │                        │
                                  │ Structures:            │
                                  │ • vessels              │
                                  │ • optic disc           │
                                  │ • fovea                │
                                  │                        │
                                  │ Lesions:               │
                                  │ • MA                    │
                                  │ • exudates             │
                                  │ • hemorrhages          │
                                  │ • NV where supported  │
                                  └───────────┬────────────┘
                                              │
                                              ▼
                                  STRUCTURED FEATURES
                                              │
                                              ▼
                                  ┌──────────────────────┐
                                  │    DR INFERENCE      │
                                  │      ResNet-50        │
                                  │       Grade 0–4       │
                                  └───────────┬──────────┘
                                              │
                             ┌────────────────┴───────────────┐
                             │                                │
                             ▼                                ▼
                     REFERABLE DR                       GRAD-CAM
                     + Calibration                      + Evidence
                             │                                │
                             └────────────────┬───────────────┘
                                              ▼
                                   CONFIDENCE-AWARE RESULT
                                              │
                                              ▼
                                      THREE-LAYER REPORT
                                              │
                    ┌─────────────────────────┼──────────────────────┐
                    │                         │                      │
                    ▼                         ▼                      ▼
             PATIENT / HEALTH           SPECIALIST              CASE AUDIT
                 WORKER                  REVIEW
                    │                         │                      │
                    └─────────────────────────┼──────────────────────┘
                                              ▼
                                      REFERRAL IF NEEDED
                                              │
                                              ▼
                                      SPECIALIST GRADE
                                              │
                                              ▼
                                          AGREEMENT
                                              │
                                              ▼
                                      FOLLOW-UP STATUS
                                              │
                                              ▼
                                    VERIFIED OUTCOMES
                                              │
                                              ▼
                                  CONTROLLED CALIBRATION
                                              │
                                              ▼
                                    HELD-OUT VALIDATION
                                              │
                                  ┌───────────┴───────────┐
                                  ▼                       ▼
                               PROMOTE                  ROLLBACK
```

---

# 4. GATE 0 — RETINAL IMAGE VALIDATION

## Purpose

Before IQA or DR inference, determine whether the uploaded image is actually suitable for retinal screening.

### Required states

```text
INPUT_RECEIVED
      ↓
RETINAL_GATE
      ↓
 ┌────┴─────┐
 │          │
PASS      NOT_FUNDUS
 │          │
 ▼          ▼
IQA       REJECT
```

If `NOT_FUNDUS`:

* show rejection
* explain that a retinal/fundus image is required
* provide upload/capture guidance
* STOP
* do not run DR inference
* do not show a DR grade
* do not show referable probability
* do not show Grad-CAM
* do not generate a normal DR report

### Important implementation rule

There must be **one authoritative gate immediately before actual DR inference**.

Conceptually:

```matlab
if retinalStatus ~= "PASS"
    % Do not call DR inference
    return
end

result = runDRInference(...)
```

The gate must not be merely a UI decoration.

---

# 5. ROLE 2 — IMAGE QUALITY ASSESSMENT

Role 2 owns the image-quality foundation.

## Required checks

### Focus

Determine whether the image is sufficiently sharp for downstream analysis.

### Illumination

Detect severe brightness/non-uniform illumination problems.

### Field of View

Check whether enough retinal field is visible.

### Other quality failure cases

Examples:

* severe blur
* excessive darkness
* excessive brightness
* insufficient retinal area
* strong artifacts
* unusable acquisition

---

# 6. IQA FAILURE WORKFLOW

When IQA fails:

```text
Image
 ↓
IQA
 ↓
FAIL
 ↓
Specific reason
 ↓
Actionable recapture guidance
 ↓
Retake / Upload New Image
```

Example:

```text
Image quality insufficient.

Reason:
Severe blur detected.

Action:
Please capture another retinal image with the camera
held steady and the retina centered.
```

The UI must distinguish:

### IQA failure

Image is unusable.

from:

### System error

File/model/integration problem.

These are not the same state.

---

# 7. PREPROCESSING

Role 2 owns:

* CLAHE
* illumination normalization
* denoising
* other validated preprocessing required by the image-processing pipeline

Each preprocessing operation should have:

```text
Input
 ↓
Processing
 ↓
Output
 ↓
Validation
```

Do not claim:

> "CLAHE improves the model"

unless an experiment actually demonstrates that.

Instead:

> "CLAHE was evaluated as an image-enhancement operation."

If it improves downstream performance, document the actual result.

---

# 8. RETINAL STRUCTURE EXTRACTION

Role 2 provides structured retinal information.

## Structures

### Blood vessels

Output:

```text
Fundus image
    ↓
Vessel extraction
    ↓
Vessel mask
```

Validation should include available quantitative metrics and visual examples.

### Optic disc

Output:

```text
Fundus
 ↓
Optic disc localization
 ↓
Coordinates / region
```

### Fovea

Output:

```text
Fundus
 ↓
Fovea localization
 ↓
Coordinates / region
```

The exact method used by Role 2 should be documented rather than inventing a method after the fact.

---

# 9. LESION ANALYSIS

Role 2 provides lesion candidates/evidence.

Required PS-aligned categories include:

* microaneurysms
* exudates
* hemorrhages
* neovascularization where the available data/method supports it

Pipeline:

```text
Fundus
 ↓
Candidate generation
 ↓
Candidate filtering
 ↓
Lesion regions/features
 ↓
Structured output
```

For each lesion module document:

1. Method
2. Input
3. Output
4. Dataset/annotations used
5. Metric if ground truth exists
6. Representative examples
7. Failure cases
8. Limitations

### Critical distinction

Do not call Grad-CAM a lesion detector.

There are two different evidence channels:

```text
ROLE 2
Explicit image-processing evidence
       ↓
Lesion / structure candidates


ROLE 1 / ML
Model explanation
       ↓
Grad-CAM regions contributing to prediction
```

They can be shown together, but they must not be represented as the same thing.

---

# 10. STRUCTURED RETINAL FEATURE OUTPUT

Role 2 should export machine-readable information rather than only images.

Example conceptual structure:

```text
CaseID

IQA
 ├─ focus
 ├─ illumination
 ├─ FOV
 └─ status

Structures
 ├─ vessel features
 ├─ optic disc features
 └─ fovea features

Lesions
 ├─ microaneurysm candidates
 ├─ exudate candidates
 ├─ hemorrhage candidates
 └─ neovascularization evidence

Preprocessing
 ├─ CLAHE
 ├─ normalization
 └─ denoising
```

This creates a clean interface between Role 2 and the ML/system layers.

---

# 11. DR CLASSIFICATION — OFFICIAL BASELINE V1

The current ResNet-50 remains the official baseline.

### Task

Five-class DR grading:

```text
0 = No DR
1 = Mild
2 = Moderate
3 = Severe
4 = Proliferative
```

### Locked APTOS split

```text
Train = 2051
Validation = 440
Test = 439
```

The test set remains locked.

### Current baseline evidence

```text
Accuracy = 82.92%
Macro-F1 = 0.6358
QWK = 0.8713
```

These remain the official baseline values.

The classifier should not be replaced simply because an experimental model wins one metric.

---

# 12. MODEL IMPROVEMENT TRACK

Member 2 can independently experiment with:

* EfficientNet transfer learning
* alternative transfer-learning configurations
* class-weighted loss
* learning-rate changes
* batch-size changes
* controlled augmentation
* preprocessing/resolution experiments
* other justified architectures

Every experiment gets:

```text
Experiment ID
Dataset
Split
Architecture
Preprocessing
Augmentation
Loss
Optimizer
Learning rate
Epochs
Batch size

Accuracy
Macro-F1
QWK
Grade 1 recall
Grade 3 recall
Grade 4 recall
Referable sensitivity
Referable specificity

Decision
Reason
```

### Rule

The baseline remains available as rollback.

A candidate model only becomes the new official model after independent evaluation and integration testing.

---

# 13. REFERABLE DR

Define:

```text
Non-referable = Grade 0 + Grade 1

Referable = Grade 2 + Grade 3 + Grade 4
```

The SIH requirement is:

```text
Sensitivity > 90%
Specificity > 85%
```

Current calibrated APTOS test result:

```text
Sensitivity = 98.88%
Specificity = 89.23%
```

This satisfies the numerical target **on the APTOS test set**.

Do not describe this as clinical validation.

Correct wording:

> "Our locked APTOS evaluation meets the numerical referable-DR sensitivity and specificity targets specified by the problem statement; this is dataset evaluation, not clinical validation."

---

# 14. CALIBRATED CONFIDENCE

Current calibration:

* Platt scaling
* fitted using validation data
* threshold selected using validation data
* test remains untouched

Current evidence includes:

```text
Brier score
ECE
ROC-AUC
Sensitivity
Specificity
Precision
NPV
F1
```

Calibration changes the probability behavior.

It does not retrain the ResNet feature representation.

---

# 15. GRAD-CAM

Current implementation:

```text
ResNet-50
 ↓
res5c_branch2c
 ↓
Grad-CAM
```

Input preprocessing was corrected to match the actual inference pipeline.

Final verification:

```text
Test cases = 439
Prediction mismatches = 0
Missing outputs = 0
```

This is strong engineering evidence for preprocessing consistency.

But:

> Grad-CAM demonstrates where the model focused; it does not by itself prove that the highlighted region is a clinically correct lesion.

Therefore combine:

```text
CNN prediction
+
Grad-CAM
+
Role 2 retinal/lesion evidence
+
Specialist review
```

rather than claiming Grad-CAM alone validates clinical reasoning.

---

# 16. THREE-LAYER REPORT

Do not put all ML metrics into the patient report.

The report must have three audiences.

## Layer 1 — Patient / Health Worker

Show:

* Case ID
* screening result
* simple DR interpretation
* referral recommendation
* basic confidence wording
* what the patient should do next
* Referral ID if applicable
* follow-up status

Avoid:

* macro-F1
* QWK
* confusion matrix
* raw calibration curves
* technical model details

---

## Layer 2 — Specialist Review

Show:

* Case ID
* AI DR grade 0–4
* referable probability
* calibrated confidence
* IQA status
* original fundus image
* Grad-CAM
* retinal structure/lesion evidence where available
* per-class probabilities
* specialist verified grade
* agreement
* specialist sign-off

Grad-CAM caption:

> "Areas the AI focused on while making this prediction."

Do not write:

> "This heatmap proves the disease is located here."

---

## Layer 3 — Case Audit

Show:

* Case ID
* model version
* calibration version
* AI grade
* AI probabilities
* IQA result
* explanation metadata
* timestamp
* referral information
* specialist verification
* agreement
* follow-up status

Do not put aggregate model evidence into every patient PDF.

---

# 17. MODEL EVIDENCE PACKAGE

Create a separate technical evidence package for judges and auditors.

Contents:

```text
1. Dataset
2. Dataset split
3. Preprocessing
4. Model architecture
5. Training configuration
6. Baseline metrics
7. Confusion matrix
8. Per-class metrics
9. Referable DR evaluation
10. Calibration
11. Grad-CAM verification
12. Role 2 image-processing validation
13. Error analysis
14. Messidor-2 external validation
15. Model comparison
16. IDRiD adaptation experiment
17. Limitations
18. Final model selection
19. Reproducibility information
```

This prevents the patient report from becoming a research paper.

---

# 18. HUMAN-IN-THE-LOOP

The system must support:

```text
AI result
   ↓
Specialist review
   ↓
Specialist verified grade
   ↓
Agreement
```

Agreement must be calculated automatically:

```text
AI Grade == Specialist Grade
```

Do not allow a user to manually type "Agreement = Yes."

The system calculates it.

---

# 19. THE <30 SECOND HUMAN-IN-LOOP REQUIREMENT

The official PS specifically mentions ophthalmologist validation under 30 seconds.

Therefore the final prototype needs a demonstrable workflow:

```text
Open case
 ↓
See original image
 ↓
See AI grade
 ↓
See referable probability
 ↓
See Grad-CAM
 ↓
See retinal/lesion evidence
 ↓
Enter specialist grade
 ↓
Submit
```

Measure the workflow time.

Do not merely say:

> "Our interface is fast."

Produce evidence.

Example:

```text
Specialist review workflow
Target: <30 seconds
Measured demo: ___ seconds
Number of trials: ___
```

Only fill this with actual measurements.

---

# 20. REFERRAL CARE LOOP

For referable cases:

```text
AI identifies referable DR
        ↓
Referral ID generated
        ↓
Patient guidance
        ↓
Specialist review
        ↓
Specialist grade
        ↓
Agreement calculated
        ↓
Follow-up
        ↓
Outcome recorded
```

For non-referable cases:

```text
AI identifies non-referable
        ↓
Result logged
        ↓
No referral generated
        ↓
Monitor / routine follow-up according to workflow
```

Do not imply that "non-referable" means "no risk."

---

# 21. UNIFIED CASE DATA MODEL

Use one source of truth.

```text
Case ID
Referral ID
AI Grade
AI Referable Probability
Calibration Version
Specialist Grade
Agreement
Follow-up Status
Timestamp
```

Definitions:

### Case ID

Exists for every screening.

### Referral ID

Exists only when referral is generated.

### Specialist Grade

Blank until specialist review.

### Agreement

Automatically calculated.

### Follow-up Status

Explicit states:

```text
Not Referred
Referred
Seen
Lost to Follow-up
Completed
```

This same data model powers:

* report
* specialist review
* referral tracker
* adaptation
* audit

---

# 22. CONTROLLED ADAPTATION

This is NOT:

> "The AI learns from its predictions."

It is:

> **The system can use specialist-verified outcomes to evaluate a candidate calibration update under a predefined validation gate.**

Current CNN weights remain frozen.

---

# 23. IDRiD ADAPTATION EXPERIMENT

Member 3 owns the statistical experiment.

### Step 1

Prepare an IDRiD subset.

### Step 2

Split into:

```text
Calibration-fit subset
        +
Held-out validation subset
```

The held-out subset must remain untouched during calibration fitting.

### Step 3

Take the current calibration.

### Step 4

Fit candidate Platt calibration using verified labels.

### Step 5

Evaluate both current and candidate calibration on held-out data.

### Step 6

Apply a pre-defined promotion rule.

Conceptual example:

```text
Sensitivity >= 0.95
AND
Brier/ECE does not materially degrade
```

The exact rule must be fixed before examining the final result.

### Step 7

Return:

```text
PROMOTE
```

or:

```text
ROLLBACK
```

The UI must display the actual result.

No fake/demo numbers.

---

# 24. ADAPTATION UI

Member 1 owns the interface.

Display:

```text
Current Calibration
        ↓
Verified Case Count
        ↓
Candidate Calibration
        ↓
Held-out Results
        ↓
Promotion Criteria
        ↓
PROMOTE / ROLLBACK
        ↓
Calibration Version History
```

Member 3 decides whether the candidate passes statistically.

Member 1 visualizes and integrates the result.

---

# 25. IMPORTANT ADAPTATION SAFETY RULE

Never do:

```text
AI prediction
 ↓
AI prediction
 ↓
AI prediction
 ↓
AI learns from its own output
```

Do:

```text
AI prediction
      +
Specialist verified outcome
      ↓
Candidate calibration
      ↓
Held-out validation
      ↓
PROMOTE / ROLLBACK
```

The ResNet weights remain frozen for this experiment.

---

# 26. FOLLOW-UP BIAS

A real deployment may have:

```text
Patients who return
+
Patients who do not return
```

If calibration uses only returning patients, the sample may not represent the entire screened population.

Therefore document:

> "Outcome-driven recalibration must account for follow-up selection bias before deployment."

Do not claim the current prototype has solved this statistically unless an actual method is implemented and validated.

---

# 27. MESSIDOR-2 EXTERNAL VALIDATION

Messidor-2 remains:

> **Frozen external validation**

Do not tune the model or calibration on Messidor-2 if it is being presented as external validation.

Current evidence demonstrates domain-shift limitations.

The correct interpretation is:

> The APTOS-trained system does not necessarily generalize equally across datasets/acquisition domains.

Do not claim resizing alone caused the performance drop.

---

# 28. DOMAIN-SHIFT EVIDENCE

Document measurable representation differences such as:

* image dimensions
* aspect ratio
* retinal fill
* dark-border characteristics
* RGB statistics

Correct language:

> "The observed acquisition and representation differences are consistent with domain shift; these measurements do not establish that any single factor caused the performance degradation."

---

# 29. SIMULINK / DISTRICT-SCALE DEPLOYMENT

The system must not stop at a MATLAB classifier.

Simulink should model:

```text
Patient acquisition
      ↓
Image arrival
      ↓
IQA / processing
      ↓
AI inference
      ↓
Referral decision
      ↓
Specialist review queue
      ↓
Review capacity
      ↓
Throughput
```

Parameters should include, where available:

* acquisition rate
* processing time
* bandwidth
* inference throughput
* specialist review capacity
* queue behavior
* referral volume
* operating hours
* annual patient volume

---

# 30. 100,000+ PATIENTS/YEAR SCENARIO

The final Simulink demonstration should show whether the proposed workflow can model a district-scale scenario involving:

> **100,000+ patients/year**

Do not simply display "100,000" on a slide.

Show the relationship between:

```text
Patients/year
↓
Images/day
↓
Processing throughput
↓
Referral percentage
↓
Specialist workload
↓
Review capacity
↓
Queue / delay
```

Use realistic assumptions and clearly label them as assumptions.

---

# 31. OFFLINE / RURAL DEPLOYMENT

Do not claim:

> "Fully offline mobile deployment"

unless actually demonstrated.

Instead, architecture can be described as:

> "Designed with deployment constraints relevant to rural screening, with the processing pipeline structured so that deployment components can be adapted to constrained environments."

The current MATLAB/dlnetwork/web prototype is not automatically an Android/iOS offline medical application.

---

# 32. DATASET STRATEGY

## APTOS

Primary training/evaluation dataset.

Used for:

* model training
* validation
* locked test evaluation
* referable DR
* calibration evaluation

---

## IDRiD

Used separately for:

* retinal structure/lesion-related experiments where appropriate
* controlled calibration adaptation experiment
* verified-label simulation

Do not mix its results into the APTOS test result.

---

## Messidor-2

Used as:

> **External frozen validation**

Do not use it for tuning.

---

# 33. MODEL / DATA SPLIT RULES

Never contaminate the locked test set.

Correct:

```text
TRAIN
  ↓
MODEL FITTING

VALIDATION
  ↓
Hyperparameter / threshold / calibration decisions

TEST
  ↓
Final locked evaluation
```

External dataset:

```text
MESSIDOR-2
  ↓
Frozen external validation
```

Adaptation:

```text
IDRiD
  ↓
Fit subset
  +
Held-out subset
```

---

# 34. ERROR ANALYSIS

Member 3 should maintain an explicit error analysis.

Analyze:

### Grade 0

False positives.

### Grade 1

Especially important because baseline recall is weaker.

### Grade 2

Referable boundary behavior.

### Grade 3 / 4

Low baseline recall requires investigation.

### Binary referable errors

```text
False negative
False positive
```

Look for recurring factors:

* image quality
* acquisition characteristics
* class imbalance
* lesion visibility
* domain shift
* preprocessing
* model confusion

Do not claim causation without evidence.

---

# 35. MODEL SELECTION RULE

Never select a new model because:

> "Accuracy increased."

Use multiple dimensions:

```text
Five-class performance
+
Macro-F1
+
QWK
+
Grade 1 recall
+
Grade 3 recall
+
Grade 4 recall
+
Referable sensitivity
+
Referable specificity
+
Calibration
+
External behavior
+
Inference compatibility
```

The final decision must be documented.

---

# 36. SCIENTIFIC EVIDENCE VS DEMO EVIDENCE

Keep these completely separate.

## Scientific evidence

* APTOS locked test
* Messidor-2 external validation
* IDRiD controlled experiment
* Role 2 validation
* model comparison
* calibration metrics

## Prototype workflow evidence

* synthetic referral records
* UI interaction
* simulated specialist review
* demonstration follow-up
* adaptation dashboard

A synthetic demo patient must never be presented as evidence that the model improved.

---

# 37. THREE TYPES OF "VALIDATION"

Use precise language.

### Engineering validation

Does the software behave correctly?

Examples:

* zero stale prediction
* correct gate behavior
* correct model output
* correct PDF
* correct referral state

### Dataset validation

Does the method perform on a dataset?

Examples:

* accuracy
* sensitivity
* specificity
* F1
* QWK
* Brier
* ECE

### Clinical validation

Does the system demonstrate clinical usefulness with appropriate expert evaluation?

This requires evidence beyond dataset metrics.

Do not call APTOS test performance "clinical validation."

---

# 38. MASTER TEST SUITE

Before final freeze, test:

## Gate tests

```text
Valid fundus → continues
Non-fundus → stops
IQA fail → stops
IQA pass → continues
```

## State tests

```text
New image clears old result
Old async result cannot overwrite new image
Failed case cannot produce DR result
```

## ML tests

```text
Inference contract
Expected input
Expected output
Prediction consistency
```

## Explainability tests

```text
Grad-CAM generated
Correct image/model preprocessing
No prediction mismatch
```

## Report tests

```text
Patient layer
Specialist layer
Audit layer
```

## Referral tests

```text
Referable → Referral ID
Non-referable → No referral
Specialist grade → Agreement
Follow-up status → correctly stored
```

## Adaptation tests

```text
Candidate calibration
Held-out validation
PROMOTE
ROLLBACK
Version history
```

## Simulink tests

```text
Input rate
Processing
Queue
Review capacity
Annual throughput
```

---

# 39. REPORT GENERATION

The PDF should be rebuilt only after the three-layer content is finalized.

Required layout behavior:

* natural A4 flow
* consistent margins
* headings stay with content
* graphs do not split awkwardly
* Grad-CAM/image pairs stay together
* confusion matrices stay together
* captions stay with figures
* intelligent table breaks
* page numbers
* no artificial blank pages
* no excessive whitespace
* clean cover
* readable specialist section

Do not solve pagination by inserting arbitrary whitespace.

---

# 40. FINAL DOCUMENTATION PACKAGE

The repository should contain:

```text
docs/
├── sih-requirements-matrix.md
├── system-architecture.md
├── role2-image-processing.md
├── iq-a-validation.md
├── retinal-structures.md
├── lesion-analysis.md
├── ml-final-results.md
├── referable-dr-evaluation.md
├── referable-dr-calibration.md
├── messidor2-representation-audit.md
├── gradcam-validation.md
├── specialist-review.md
├── referral-care-loop.md
├── controlled-adaptation.md
├── ml-inference-interface.md
├── ml-integration-contract.md
├── ml-handoff-contract.md
├── ml-simulink-handoff.md
├── simulink-deployment-model.md
├── model-evidence-package.md
└── limitations.md
```

---

# 41. MACHINE-READABLE RESULTS

Maintain:

```text
outputs/evaluation/
├── ml_master/
├── role2/
├── calibration/
├── external_validation/
├── model_comparison/
├── gradcam/
└── simulink/
```

Every important result should have:

* CSV
* MAT/appropriate MATLAB artifact
* summary text
* experiment ID
* dataset
* split
* version

This makes the project reproducible and judge-defensible.

---

# 42. THREE TECHNICAL MEMBERS

# MEMBER 1 — SYSTEM + EXPLAINABILITY + CARE LOOP LEAD

### Owns

1. Retinal validation integration
2. IQA gate integration
3. DR inference integration
4. Grad-CAM
5. Three-layer reporting
6. Specialist review UI
7. Case/referral data model
8. Referral workflow
9. Follow-up workflow
10. Verified specialist grade
11. Agreement calculation
12. Controlled adaptation dashboard
13. Calibration version integration
14. PDF generation
15. Integration tests
16. End-to-end demo

### Does NOT own

* statistical promotion decision
* inventing calibration results
* replacing the locked ML baseline without evaluation

---

# MEMBER 2 — ML MODEL / TRAINING LEAD

### Owns

1. ResNet-50 baseline
2. EfficientNet experiments
3. Transfer learning
4. Class imbalance experiments
5. Weighted loss
6. LR/batch/augmentation experiments
7. Model comparison
8. Final candidate model
9. DR Grade 0–4
10. Model inference compatibility

### Rule

Every candidate must preserve the inference contract.

---

# MEMBER 3 — DATASET + IMAGE PROCESSING + EVALUATION LEAD

### Owns

1. Dataset research
2. Dataset documentation
3. Role 2 image processing
4. IQA
5. Enhancement
6. Retinal structure extraction
7. Lesion analysis
8. Feature extraction
9. Error analysis
10. Calibration evaluation
11. Messidor-2 external validation
12. IDRiD adaptation experiment
13. Statistical promotion/rollback decision
14. Model Evidence Package
15. Benchmark comparison
16. Experiment records

---

# 43. SPRINT PLAN

# SPRINT 1 — REQUIREMENT COVERAGE + FOUNDATION

## Member 1

* Freeze system architecture
* Implement authoritative retinal gate
* Connect IQA PASS/FAIL state
* Ensure failed images cannot reach DR inference
* Finalize unified data model
* Begin three-layer report structure

## Member 2

* Freeze ResNet-50 V1
* Establish experiment framework
* Begin controlled candidate experiments

## Member 3

* Audit Role 2 implementation
* Verify every IQA component
* Verify structure/lesion outputs
* Document validation evidence
* Confirm dataset splits
* Prepare IDRiD fit/held-out split

### Sprint 1 exit condition

Every SIH requirement has:

```text
Owner
Implementation location
Evidence required
Status
```

---

# SPRINT 2 — IMAGE PROCESSING + ML + CARE LOOP

## Member 1

* Finish report architecture
* Referral workflow
* Specialist review screen
* Case audit
* Follow-up states

## Member 2

* Model experiments
* Controlled evaluation
* Candidate shortlist

## Member 3

* Role 2 validation
* Error analysis
* Calibration evaluation
* External validation documentation

### Exit condition

The complete pipeline can run:

```text
Image
→ Validation
→ IQA
→ Processing
→ DR
→ Referable
→ Explanation
→ Report
```

---

# SPRINT 3 — EVIDENCE + ADAPTATION

## Member 1

* Specialist review
* Verified grade
* Agreement
* Referral/follow-up integration

## Member 2

* Final candidate model evaluation

## Member 3

* Complete IDRiD split
* Run candidate calibration
* Evaluate held-out set
* Apply promotion rule
* Produce actual PROMOTE/ROLLBACK
* Complete Messidor-2 evidence
* Complete model comparison

### Critical dependency

Member 3 must finish the first real adaptation experiment **before** Member 1 builds the final adaptation dashboard around it.

No placeholder numbers.

---

# SPRINT 4 — FINAL INTEGRATION

## Member 1

* Adaptation dashboard
* Final report
* PDF pagination
* Specialist workflow
* End-to-end integration

## Member 2

* Final model freeze

## Member 3

* Final Evidence Package
* Final Role 2 validation
* Calibration documentation
* External validation
* Benchmark evidence

---

# FINAL INTEGRATION

The complete demonstration must be:

```text
RAW FUNDUS
   ↓
RETINAL VALIDATION
   ↓
IQA
   ↓
PREPROCESSING
   ↓
STRUCTURES + LESIONS
   ↓
DR GRADE 0–4
   ↓
REFERABLE DR
   ↓
CALIBRATED CONFIDENCE
   ↓
GRAD-CAM
   ↓
REPORT
   ↓
REFERRAL
   ↓
SPECIALIST REVIEW
   ↓
VERIFIED GRADE
   ↓
AGREEMENT
   ↓
FOLLOW-UP
   ↓
VERIFIED OUTCOMES
   ↓
CONTROLLED CALIBRATION
   ↓
HELD-OUT VALIDATION
   ↓
PROMOTE / ROLLBACK
```

Parallel deployment demonstration:

```text
COMPLETE PIPELINE
       ↓
SIMULINK
       ↓
Acquisition
       ↓
Bandwidth
       ↓
Processing
       ↓
Referral load
       ↓
Specialist capacity
       ↓
100k+ patients/year scenario
```

---

# 44. FINAL SIH DEMO STRUCTURE

The final demonstration should follow the same order as the actual PS.

## Demo 1 — Bad image

Show:

```text
Image
→ IQA FAIL
→ reason
→ recapture guidance
```

Proves:

> The system does not blindly diagnose poor-quality images.

---

## Demo 2 — Valid image

Show:

```text
Fundus
→ IQA PASS
→ preprocessing
→ structures/lesions
→ DR Grade
→ referable probability
→ Grad-CAM
```

---

## Demo 3 — Specialist review

Show:

```text
AI result
→ specialist evidence
→ specialist grade
→ agreement
```

Demonstrate the review workflow time.

---

## Demo 4 — Referral

Show:

```text
Referable
→ Referral ID
→ patient guidance
→ follow-up
```

---

## Demo 5 — Adaptation

Show actual experiment:

```text
Verified cases
→ candidate calibration
→ held-out evaluation
→ criteria
→ PROMOTE / ROLLBACK
```

---

## Demo 6 — Simulink

Show:

```text
District workload
→ acquisition
→ processing
→ referral
→ specialist capacity
→ annual throughput
```

---

# 45. WHAT THE JUDGES SHOULD BE ABLE TO SEE

At the end, the judges should be able to answer "yes" to these questions:

### Image quality

> Can the system reject an unusable retinal image and explain what to do?

### Retinal analysis

> Can the system extract meaningful retinal structures and lesion candidates?

### DR grading

> Can the system grade DR from 0–4?

### Referable screening

> Does the locked APTOS evaluation meet the stated numerical referable-DR targets?

### Explainability

> Can we see where the model focused?

### Confidence

> Are its probabilities calibrated and evaluated?

### Human-in-loop

> Can a specialist review and verify the result efficiently?

### Reporting

> Can different users receive the appropriate level of information?

### Referral

> Does a positive screening result create a traceable referral?

### Follow-up

> Can the system track what happened afterward?

### Adaptation

> Can verified outcomes be used in a controlled calibration process?

### Safety

> Can an update be rejected and rolled back?

### Deployment

> Can the workflow be modeled at district scale in Simulink?

### Evidence

> Can the team show actual validation rather than only architecture diagrams?

---

# 46. FINAL RULES

## Rule 1 — Never hide a limitation

If Messidor performance is poor:

> Show it.

If Grade 3/4 recall is weak:

> Show it.

If lesion detection has limited validation:

> Say so.

If clinical validation has not happened:

> Do not call it clinical validation.

---

## Rule 2 — Never fake evidence

No:

* fake specialist results
* fake adaptation numbers
* fake patient outcomes
* fake validation metrics
* fake benchmark superiority
* fake clinical validation

Synthetic data is allowed for demonstrating the workflow, but it must be labeled as synthetic/prototype data.

---

## Rule 3 — Never confuse the evidence types

```text
Grad-CAM ≠ lesion segmentation

APTOS test ≠ clinical validation

Messidor ≠ tuning dataset

Synthetic referral ≠ clinical outcome

Calibration ≠ retraining

Architecture ≠ validated implementation
```

---

# 47. FINAL PROJECT POSITIONING

The project should be presented as:

> **A quality-gated, explainable and deployment-aware diabetic retinopathy screening prototype that connects retinal image assessment, structured retinal evidence, 0–4 DR grading, calibrated referable-DR screening, specialist review, referral/follow-up tracking, and controlled calibration updates, with district-scale workflow modeling in Simulink.**

Do not call it:

* FDA-approved
* clinically validated
* production-ready medical device
* autonomous diagnosis
* continuously self-learning AI

unless the corresponding evidence actually exists.

---

# 48. THE CORE USP

## Closed-Loop, Deployment-Aware DR Screening

The system does not end at:

> **"The model predicted Grade 2."**

It continues:

```text
Screen
 ↓
Explain
 ↓
Refer
 ↓
Follow
 ↓
Verify
 ↓
Controlled Adaptation
 ↓
Validate
```

The important part is that the adaptation mechanism does **not** allow the AI to teach itself.

Instead:

```text
AI prediction
      +
Specialist-verified outcome
      ↓
Candidate calibration
      ↓
Held-out validation
      ↓
PROMOTE / ROLLBACK
```

---

# 49. FINAL OWNERSHIP SUMMARY

| Area                   |       Member 1 |       Member 2 |                  Member 3 |
| ---------------------- | -------------: | -------------: | ------------------------: |
| System integration     |       **Lead** |        Support |                   Support |
| Retinal gate           |       **Lead** |              — |               IQA support |
| IQA                    |    Integration |              — |                  **Lead** |
| Enhancement            |    Integration |              — |                  **Lead** |
| Structures             |    Integration |              — |                  **Lead** |
| Lesions                |    Integration |              — |                  **Lead** |
| DR model               |    Integration |       **Lead** |                Evaluation |
| Referable DR           |    Integration |          Model |            **Evaluation** |
| Calibration            | UI/integration |              — |      **Statistical lead** |
| Grad-CAM               |       **Lead** |  Model support |                Validation |
| Specialist review      |       **Lead** |              — | Clinical/evidence support |
| Referral               |       **Lead** |              — |              Data support |
| Follow-up              |       **Lead** |              — |              Data support |
| Adaptation UI          |       **Lead** |              — |       **Experiment lead** |
| Model experiments      |        Support |       **Lead** |                Evaluation |
| External validation    |              — |        Support |                  **Lead** |
| Error analysis         |        Support |        Support |                  **Lead** |
| Simulink integration   |    Integration |   Model timing |    Data/parameter support |
| Final evidence package |        Support | Model evidence |                  **Lead** |
| Final integration      |       **Lead** |          Model |                Evaluation |

---

# 50. DEFINITION OF DONE

The project is **not finished** when every module has been coded.

It is finished when:

```text
EVERY SIH REQUIREMENT
        ↓
IMPLEMENTED
        ↓
DEMONSTRABLE
        ↓
VALIDATED
        ↓
DOCUMENTED
        ↓
INTEGRATED
```

And the final repository can answer:

> **What did we build?**

> **Why did we build it?**

> **What data was used?**

> **How was it evaluated?**

> **What are the actual numbers?**

> **What are the limitations?**

> **What happens when the image is bad?**

> **What happens when the model is uncertain?**

> **What happens when the patient is referred?**

> **What happens after specialist verification?**

> **How can a calibration update be accepted or rejected?**

> **How does the system scale to district-level deployment?**

That is the final standard for SIH26038.
