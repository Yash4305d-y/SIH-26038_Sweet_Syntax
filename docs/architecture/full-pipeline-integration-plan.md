# SIH 26038 — Full Pipeline Integration Plan

## 1. Purpose

This document defines how the completed SIH 26038 components connect into one end-to-end diabetic-retinopathy screening pipeline.

The purpose is to establish clear interfaces between roles and prevent:

* duplicated preprocessing
* inconsistent image dimensions
* accidental ML retraining
* changes to the frozen calibration threshold
* duplicated lesion analysis
* incorrect interpretation of Grad-CAM
* direct modification of the locked ML model

The Role 1 ML inference interface is the authoritative interface for ML prediction.

---

# 2. End-to-End Architecture

```text
                    RETINAL IMAGE
                          │
                          ▼
              ┌───────────────────────┐
              │       ROLE 2          │
              │ Image Quality /       │
              │ Retinal CV Analysis   │
              └───────────┬───────────┘
                          │
                          │ Quality / CV outputs
                          ▼
              ┌───────────────────────┐
              │       ROLE 1          │
              │ Frozen ML Inference   │
              │ ResNet-50             │
              └───────────┬───────────┘
                          │
             ┌────────────┼─────────────┐
             │            │             │
             ▼            ▼             ▼
        5-class       Referable     Grad-CAM
        probabilities    DR           explanation
             │          decision          │
             │            │               │
             └────────────┼───────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   INTEGRATION LAYER   │
              │ Combine validated     │
              │ outputs from roles    │
              └───────────┬───────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │       ROLE 3          │
              │ Simulink / SimEvents  │
              │ Telemedicine Workflow │
              └───────────┬───────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │       ROLE 4          │
              │ App / Demonstration   │
              │ Interface             │
              └───────────────────────┘
```

---

# 3. Role Responsibilities

## Role 1 — ML Architect

Status: **FROZEN**

Role 1 owns:

* ResNet-50 inference
* five-class DR grading
* class probabilities
* referable-DR probability
* Platt calibration
* frozen referable threshold
* confidence
* Grad-CAM
* ML evaluation outputs
* ML inference contract

Authoritative function:

```matlab
result = runDRInference(image);
```

Role 1 must NOT:

* change the trained model
* retrain
* change preprocessing
* change calibration
* change threshold
* implement image-quality assessment
* implement lesion segmentation
* implement Simulink workflow
* implement the final UI

---

# 4. Role 2 → Integration Layer

Role 2 is responsible for image-quality and retinal-image/CV processing defined in the master plan.

Role 2 may produce information such as:

```text
Image quality status
Quality score
Usable / unusable decision
Retinal structure information
Lesion-related CV measurements
```

However:

**Role 2 must not silently replace the preprocessing used by Role 1.**

If Role 2 creates an enhanced image for visualization or CV analysis, that does not automatically mean the enhanced image should be sent into the frozen ML model.

The original Role 1 preprocessing convention remains authoritative for ML inference.

---

# 5. Role 2 → Role 1 Boundary

The safest initial integration is:

```text
Original retinal image
        │
        ├──────────────► Role 2 CV analysis
        │
        └──────────────► Role 1 ML inference
```

This prevents Role 2 preprocessing from changing the ML model's input distribution.

If the team later wants Role 2 preprocessing to feed the ML model, that must be treated as a **new controlled ML experiment**, not an integration change.

For the current SIH build:

**Do not do this.**

---

# 6. Role 1 Output Contract

The integration layer must consume the output of:

```matlab
runDRInference()
```

The exact field names documented in:

```text
docs/ml-integration-contract.md
```

are authoritative.

Conceptually, the ML result contains:

```text
Predicted Grade
Class Probabilities
Referable Probability
Calibrated Probability
Referable Status
Confidence
Grad-CAM
Model Name
Success / Error information
```

The integration layer must not recreate these values independently.

---

# 7. Five-Class Prediction

The ML output represents:

```text
0 → No DR
1 → Mild
2 → Moderate
3 → Severe
4 → Proliferative DR
```

The predicted grade must come directly from Role 1.

Do not calculate a new five-class prediction in Role 4 or Role 3.

---

# 8. Referable DR Decision

The SIH-defined mapping is:

```text
Grade 0 + Grade 1 → Non-referable

Grade 2 + Grade 3 + Grade 4 → Referable
```

Role 1 calculates:

```text
Referable Probability = P2 + P3 + P4
```

Calibration is performed using the frozen validation-fitted calibration.

The frozen decision threshold is:

```text
Calibrated Referable Probability >= 0.22
    → Referable

Calibrated Referable Probability < 0.22
    → Non-referable
```

No other component should independently calculate a different threshold.

---

# 9. Explainability

Role 1 provides Grad-CAM.

Conceptual flow:

```text
Image
  │
  ▼
ResNet-50
  │
  ├── Prediction
  │
  └── Grad-CAM
          │
          ▼
     Heatmap / overlay
```

The Grad-CAM output should be displayed as an **explanation of model attention**.

It must NOT be described as:

```text
"Proof that the model detected a lesion."
```

Use language such as:

```text
"Model attention visualization"
```

or:

```text
"Regions contributing to the model's prediction."
```

---

# 10. Integration Layer

The integration layer is the central handoff point.

It should combine outputs without modifying their meaning.

Conceptually:

```text
                ┌───────────────┐
                │    Role 2     │
                │ Quality / CV  │
                └───────┬───────┘
                        │
                        ▼
               ┌─────────────────┐
               │ Integration     │
               │ Result Object   │
               └────────┬────────┘
                        ▲
                        │
                ┌───────┴───────┐
                │    Role 1      │
                │ Frozen ML      │
                └───────────────┘
```

The integration object should preserve the original Role 1 result rather than copying values into differently named variables unless required by the system.

---

# 11. Suggested Unified Result

A conceptual final screening result can contain:

```text
screeningResult
│
├── input
│   └── image information
│
├── quality
│   └── Role 2 quality information
│
├── ml
│   ├── predictedGrade
│   ├── classProbabilities
│   ├── referableProbability
│   ├── calibratedProbability
│   ├── referableStatus
│   ├── confidence
│   └── gradCAM
│
├── cv
│   └── Role 2 retinal / lesion measurements
│
└── metadata
    ├── modelName
    ├── timestamp
    └── processing status
```

This is a **conceptual integration structure**.

The exact Role 1 field names must always follow:

```text
docs/ml-integration-contract.md
```

---

# 12. Role 3 — Simulink / SimEvents

Role 3 should NOT reproduce the ML model.

Instead, Role 3 consumes measured or defined screening parameters from the ML/integration layer.

Possible inputs include:

```text
Images screened
ML processing time
Quality rejection rate
Referable cases
Non-referable cases
Referral rate
Queue arrivals
Service time
```

The purpose is to simulate the telemedicine screening workflow.

Conceptually:

```text
Retinal screening
       │
       ▼
Quality gate
       │
       ▼
ML screening
       │
       ├── Non-referable
       │
       └── Referable
               │
               ▼
          Referral flow
               │
               ▼
       Telemedicine workflow
```

Role 3 should use **measured ML parameters where available**, rather than inventing performance numbers.

---

# 13. Role 4 — Application / UI

Role 4 should consume the integration result.

The UI should display, as appropriate:

```text
DR Grade
Referable / Non-referable
Probability
Confidence
Grad-CAM visualization
Image-quality status
Relevant CV findings
```

Role 4 must NOT:

* load the model independently
* implement its own prediction logic
* implement another threshold
* recalculate referable probability
* modify calibration
* preprocess images differently for ML
* claim clinical diagnosis

The UI is a consumer of the integration interface.

---

# 14. Error Handling

If Role 1 returns:

```text
success = false
```

the integration layer must not fabricate a prediction.

Instead:

```text
ML inference failed
        │
        ▼
Stop/flag screening result
        │
        ▼
Display appropriate error/status
```

Similarly, if Role 2 declares an image unusable according to its own validated quality criteria, the system should preserve that quality decision rather than pretending that a successful ML prediction means the image was clinically suitable.

---

# 15. Data Ownership

| Data                           | Owner             |
| ------------------------------ | ----------------- |
| ML model                       | Role 1            |
| ML preprocessing               | Role 1            |
| 5-class prediction             | Role 1            |
| Class probabilities            | Role 1            |
| Referable probability          | Role 1            |
| Calibration                    | Role 1            |
| 0.22 threshold                 | Role 1            |
| Confidence                     | Role 1            |
| Grad-CAM                       | Role 1            |
| Image quality                  | Role 2            |
| Classical CV / lesion analysis | Role 2            |
| Telemedicine simulation        | Role 3            |
| UI / application               | Role 4            |
| Cross-role result assembly     | Integration layer |

---

# 16. Critical Rules

## Rule 1 — One ML Source of Truth

All ML predictions must originate from:

```matlab
runDRInference()
```

Do not duplicate the model elsewhere.

## Rule 2 — Frozen Threshold

```text
0.22
```

is frozen.

Do not create a second threshold.

## Rule 3 — No Silent Preprocessing Changes

Do not add:

* CLAHE
* circular masking
* cropping
* arbitrary resizing
* color normalization
* enhancement
* lesion-based preprocessing

to the Role 1 path unless it becomes a formally controlled ML experiment.

## Rule 4 — External Validation Remains External

Messidor-2 remains an external evaluation dataset.

Do not tune the system against Messidor-2.

## Rule 5 — Grad-CAM Is Explanatory

Grad-CAM indicates model attention and should not be represented as ground-truth lesion localization.

## Rule 6 — No Clinical Diagnosis Claim

The system is a screening/prototype system.

Do not label the output as a definitive medical diagnosis.

---

# 17. Final End-to-End Flow

The intended final demonstration is:

```text
                    RETINAL IMAGE
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
        ROLE 2                     ROLE 1
     Quality / CV             Frozen ResNet-50
             │                       │
             │              ┌────────┼─────────┐
             │              │        │         │
             │              ▼        ▼         ▼
             │            Grade   Referable  Grad-CAM
             │                       │
             └───────────┬───────────┘
                         │
                         ▼
                  INTEGRATION RESULT
                         │
                 ┌───────┴────────┐
                 │                │
                 ▼                ▼
              ROLE 3            ROLE 4
             Simulink            UI
             Workflow         Demonstration
```

This architecture keeps each role independent while providing a clear path from retinal image → screening result → telemedicine workflow → demonstration interface.

---

# 18. Integration Readiness

Role 1 currently satisfies the required ML integration prerequisites:

```text
Frozen model                  PASS
Inference function            PASS
5-class prediction            PASS
Referable DR                  PASS
Calibration                   PASS
Frozen threshold              PASS
Confidence                    PASS
Grad-CAM                      PASS
Integration contract          PASS
Machine-readable export       PASS
```

Therefore:

**ROLE 1 IS READY FOR SYSTEM INTEGRATION.**

No additional ML training is required for the current integration phase.
