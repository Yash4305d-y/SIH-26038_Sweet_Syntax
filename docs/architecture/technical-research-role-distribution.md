## 👤Divyanshu  — Computer Vision & Dataset Research

### Files

* `01_dataset-research.md`
* `02_image-processing.md`

### Responsibilities

* Find and compare suitable diabetic retinopathy datasets
* Dataset classes, labels, size, quality and accessibility
* Dataset licensing/access restrictions
* Retinal image preprocessing
* Image enhancement and normalization
* Segmentation and augmentation techniques
* Identify challenges with retinal images

### Main Question

**“What data do we have, and how do we prepare it for the AI system?”**

---

## 👤 Kyush — MATLAB, Simulink & System Research

### Files

* `03_matlab-technical-research.md`
* `04_simulink-telemedicine.md`
* `05_existing-solutions-gap.md`

### Responsibilities

* MATLAB toolboxes required by the problem statement
* What each toolbox contributes to the system
* MATLAB implementation possibilities
* Simulink telemedicine workflow
* Screening pipeline simulation
* Throughput, latency and bottleneck modelling
* Existing complete DR screening solutions
* Identify technical gaps and possible system-level differentiation

### Main Question

**“How do we build and simulate the complete system around the AI model?”**

---

## 👤 Yash — ML & Explainable AI — YOU

### Files

* `06_ml-model-research.md`
* `07_explainable-ai.md`
* `08_ml-evaluation.md`

### Responsibilities

* Existing DR classification approaches
* CNN and transfer-learning approaches
* Model architecture options
* Training strategies
* Class imbalance
* Evaluation metrics
* Sensitivity, specificity, F1, AUC, etc.
* Grad-CAM and other XAI methods
* Heatmaps / lesion-region visualization
* Explainability limitations
* Decide the most suitable ML approach after research

### Main Question

**“What AI model should we build, how should it be trained, and how do we prove and explain its predictions?”**

PS 26038 — BASIC TECHNICAL STRUCTURE

                RETINAL IMAGE
                      |
                      v
          1. IMAGE QUALITY CHECK
             - Blur
             - Illumination
             - Field of View
                      |
               +------+------+
               |             |
             FAIL           PASS
               |             |
               v             v
        Recapture       2. PREPROCESSING
        Guidance          - CLAHE
                           - Denoising
                           - Normalization
                               |
                               v
                    3. RETINAL ANALYSIS
                       - Blood vessels
                       - Optic disc
                       - Fovea
                       - Lesions
                               |
                               v
                    4. DR CLASSIFICATION
                       - CNN
                       - Grade 0–4
                       - Referable / Not
                               |
                               v
                    5. EXPLAINABILITY
                       - Grad-CAM
                       - Lesion evidence
                       - Confidence
                               |
                               v
                    6. SCREENING REPORT
                       - DR Grade
                       - Evidence
                       - Confidence
                       - Referral
                               |
                               v
                    7. HUMAN REVIEW
                       Ophthalmologist


              SEPARATE SIMULINK MODEL
                       |
                       v
              Patient/Image Arrival
                       |
                       v
                 AI Processing
                       |
                       v
                  Review Queue
                       |
                       v
                Ophthalmologist
                       |
                       v
              Throughput / Waiting /
                 Backlog Analysis


I Will update the master-plan.md after combining all are work`

FILE STRUCTURE IS READY *EDIT ONLY YOUR ASSIGNED FILES* 