SIH 2026 — Updated Technical Master Plan
North Star

Closed-Loop, Deployment-Aware DR Screening

Screen → Explain → Refer → Follow → Verify → Controlled Adaptation

The current ResNet-50 remains the official baseline. Any model-improvement work is experimental until independently evaluated.

👤 TECH MEMBER 1 
System + Explainability + Care Loop Lead
1. Retinal → AI → Decision Pipeline

Maintain the complete inference flow:

Image → Retinal validation → IQA → DR inference → Referable assessment → Explanation → Report

Ensure:

Invalid/non-retinal images never reach DR inference.
IQA failures stop the pipeline.
Old results are cleared when a new image is uploaded.
Async requests cannot overwrite results for a newer image.
Existing ML inference contract remains stable.
2. Three-Layer Patient Report
Layer 1 — Patient / Health-worker

Simple, understandable information:

DR result
Referral recommendation
What the result means
What to do next
Referral ID if applicable
Follow-up status
Simple confidence wording

Avoid raw ML metrics.

Layer 2 — Specialist Review

Fast clinical-review information:

AI DR grade
Referable probability
Confidence
IQA status
Original retinal image
Grad-CAM overlay
Per-class probabilities
Specialist verified grade
Specialist sign-off

Grad-CAM wording:

“Areas the AI focused on while making this prediction.”

Not:

“These areas prove the disease.”

Layer 3 — Case Audit

Keep this case-specific, not a giant ML report:

Case ID
Model/version
Calibration version
AI prediction
probabilities
IQA result
explanation metadata
timestamp
referral information
specialist verification
follow-up status
3. Standalone Model Evidence Package

Do not put the entire evaluation suite inside every patient's PDF.

Create one separate Model Evidence Package containing:

Dataset and splits
Model architecture/version
Accuracy
Macro-F1
QWK
Per-class performance
Confusion matrix
Referable-DR evaluation
Calibration metrics
Messidor-2 external validation
IDRiD experiment, when completed
Limitations
Experimental model comparisons
Final model selection rationale

The individual patient report can reference the relevant model/version and evidence package.

4. Unified Case + Referral Data Model

This is the single source of truth shared by the report, referral tracker, specialist review, and AI adaptation system.

Case ID
Referral ID
AI Grade
AI Referable Probability
Calibration Version
Specialist Grade
Agreement
Follow-up Status
Timestamp
Important rules

Case ID

Exists for every screening case.
Referral ID exists only when referral is generated.

Calibration Version

Records exactly which calibration version produced the probability/result.

Specialist Grade

Empty until specialist review.

Agreement

Computed automatically from AI grade vs specialist grade.
Never manually entered.

Follow-up Status

Use explicit states such as:

Not Referred
Referred
Seen
Lost to Follow-up
Completed

Member 1 can refine the exact labels during implementation, but Lost to Follow-up must be an explicit state.

5. Closed Referral / Care Loop

For a referable case:

Referable
    ↓
Case ID + Referral ID
    ↓
Patient guidance
    ↓
Specialist review
    ↓
Specialist Grade
    ↓
Agreement automatically calculated
    ↓
Follow-up
    ↓
Outcome

The prototype may use synthetic/demo records.

Do not present demo records as real clinical outcomes.

6. Controlled AI Adaptation Demo

Member 1 build the product/UI side.

Member 3 owns the statistical experiment.

Member 1 responsibility:

Display current calibration version
Display verified-case count
Display candidate calibration
Display validation results
Display PASS/FAIL
Display Promote/Rollback result
Integrate an accepted calibration version into the pipeline
Maintain version history

Member 1 do not decide whether the candidate is statistically good.

👤 TECH MEMBER 2 — ML Lead
Model Accuracy + Training

This member owns improving the model itself.

1. Preserve Baseline

Current:

ResNet-50 — Baseline V1

Keep it untouched.

Record its current official metrics:

Accuracy: 82.92%
Macro-F1: 0.6358
QWK: 0.8713
2. Model Experiments

Investigate:

EfficientNet transfer learning
Transfer-learning configurations
Class-weighted loss
Learning-rate tuning
Batch-size experiments
Controlled augmentation
Resolution/preprocessing experiments
Other justified architectures

Every experiment gets a version/ID.

3. Model Evaluation

Candidates should be evaluated on:

Accuracy
Macro-F1
QWK
Grade 1 recall
Grade 3 recall
Grade 4 recall
Referable sensitivity
Referable specificity

The goal is not simply maximizing accuracy.

A model that goes from 83% → 85% while becoming worse at severe DR detection is not automatically an improvement.

4. Final Model Decision
Baseline V1
     ↓
Candidate experiment
     ↓
Validation
     ↓
Candidate shortlist
     ↓
Locked test evaluation
     ↓
Overall evidence
     ↓
Keep baseline OR promote candidate

No model replacement based on a single metric.

👤 TECH MEMBER 3 — ML Evaluation + Data/Calibration Lead
Model Evaluation Scientist / Validation Owner

This member is responsible for determining whether experiments actually hold up.

1. Dataset Analysis
APTOS class distribution
Minority-class analysis
Split verification
Preprocessing consistency
Data-quality analysis
Candidate failure patterns
2. Error Analysis

For important models:

Grade 0–4 confusion
Grade 3/4 failures
False positives
False negatives
Referable/non-referable errors
Recurring failure patterns

This feeds back to Member 2's model experiments.

3. External Validation
Messidor-2

Keep completely untouched.

Use only for independent external evaluation.

No:

calibration fitting
threshold tuning
model selection
adaptation fitting

This preserves the credibility of the existing external-validation result.

IDRiD

Use separately for the controlled adaptation experiment.

4. Controlled Calibration Experiment

Member 3 explicitly owns this entire statistical pipeline.

Step 1 — Prepare IDRiD

Create:

IDRiD
 ├── Calibration/Fit subset
 └── Held-out evaluation subset

Use a predefined minimum such as:

N ≥ 50 verified cases for candidate fitting

The exact final sample size should be documented before the experiment.

Step 2 — Fit Candidate

Member 3:

Fits the candidate Platt calibration
Keeps ResNet weights frozen
Uses only the fit subset
Produces a new calibration version

Example:

Calibration V1 → Calibration V2
Step 3 — Evaluate

Evaluate V1 vs V2 on the untouched held-out subset.

Measure:

Sensitivity
Specificity
Brier score
ECE
F1
Other predefined safety metrics
Step 4 — Automatic Promotion Gate

Predefine the criteria before seeing the result.

Example:

Promote only if held-out sensitivity remains ≥ 0.95 and Brier/ECE are maintained or improved.

Otherwise:

Rollback / retain current calibration.

Member 3 produces the actual:

PROMOTE / ROLLBACK verdict

Member 1 only displays and integrates that verdict.

5. Important Learning Principle

The system does not learn from its own predictions.

Instead:

AI prediction
      ↓
Specialist verification
      ↓
Verified outcome
      ↓
Enough verified cases
      ↓
Candidate calibration
      ↓
Held-out validation
      ↓
Promote / Rollback

The ResNet itself remains frozen for this adaptation experiment.

6. Experiment Record

Every ML experiment should record:

Experiment ID
Dataset
Data split
Model version
Calibration version
Training configuration
Validation metrics
Test metrics
External evaluation
Decision
Reason

This prevents “which model produced this number?” problems during judging.

🔗 Three-Member Architecture
                    OFFICIAL BASELINE
                      ResNet-50 V1
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼
      MEMBER 2                       MEMBER 3
    MODEL TRAINING               EVALUATION / DATA
             │                           │
      Improve model              Prove/measure it
      architectures              Error analysis
      loss/augmentation           External validation
             │                    Calibration
             └──────────┬────────────────┘
                        │
                        ▼
                 VALIDATED MODEL
                        │
                        ▼
                   MEMBER 1
               SYSTEM INTEGRATION
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
       REPORT       CARE LOOP    ADAPTATION UI
          │             │             │
          └─────────────┼─────────────┘
                        ▼
                    FINAL DEMO
🗓️ Execution Plan
Sprint 1 — Lock the foundation
Member 1
Finalize 3-layer report structure
Finalize unified data model
Case ID + Referral ID
Define follow-up states
Stabilize inference/gating
Member 2
Freeze ResNet-50 baseline
Set up experiment framework
Begin model experiments
Member 3
Validate dataset/splits
Establish evaluation scripts
Begin error analysis
Prepare IDRiD fit/held-out split
Sprint 2 — Parallel development
Member 1

Report + Care Loop

Member 2

Model experiments

Member 3

Error analysis + candidate evaluation

Sprint 3 — Critical dependency sprint
Member 1
Specialist report layer
Referral tracking
Verified-grade workflow
Member 2
Shortlist promising model candidates
Member 3
Complete IDRiD fit/held-out split
Run first candidate-calibration experiment
Calculate before/after results
Apply predefined promotion criteria
Produce first PROMOTE/ROLLBACK verdict

This is important: Sprint 3 must produce actual adaptation numbers.

Sprint 4 — Integration
Member 1
Build adaptation dashboard/demo
Integrate real calibration experiment results
Finish PDF layout
Connect report + referral + specialist record
Member 2
Finalize model candidate if one genuinely improves the evidence
Member 3
Finalize model comparison
Finalize calibration evaluation
Finalize external validation
Produce Model Evidence Package
Final System
                    RETINAL IMAGE
                         ↓
                Retinal Validation
                         ↓
                        IQA
                         ↓
                  DR Assessment
                         ↓
          ┌──────────────┴──────────────┐
          ↓                             ↓
    Non-referable                    Referable
          ↓                             ↓
     Case recorded                Referral ID
                                        ↓
                                 Specialist Review
                                        ↓
                                Specialist Grade
                                        ↓
                               Agreement computed
                                        ↓
                              Follow-up / Outcome
                                        ↓
                              Verified outcomes
                                        ↓
                         Controlled calibration
                                        ↓
                              Held-out validation
                                   ↙        ↘
                              PROMOTE      ROLLBACK
What We Are Not Claiming
❌ AI learns from its own predictions
❌ CNN automatically retrains after every patient
❌ Messidor-2 is used for tuning
❌ Synthetic referrals are real clinical evidence
❌ Live ABHA integration
❌ FDA compliance
❌ Clinical validation
❌ Autonomous diagnosis
❌ Model replacement because of one improved metric
❌ OOD/embedding monitoring as a currently validated feature
The final USP

“Our system doesn't stop at detecting diabetic retinopathy. It connects explainable AI screening to specialist referral and follow-up, records verified outcomes, and provides a controlled pathway for future calibration updates—validated on held-out data rather than allowing the AI to learn from its own predictions.”

This gives the three technical members very clean ownership:

Member 2 → make the model better.
Member 3 → prove whether it's actually better and validate adaptation.
Member → turn the validated AI into a complete screening-and-care system.