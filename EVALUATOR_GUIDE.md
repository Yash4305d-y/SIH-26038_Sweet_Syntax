# EVALUATOR GUIDE
**SIH 2026 — PS 26038**

Welcome to the **Diabetic Retinopathy Explainable AI Prototype**. This project develops a reproducible MATLAB-based AI screening prototype for diabetic retinopathy screening and referral support in rural telemedicine workflows.

## 1. What this system does

This system executes a fully integrated inference and governance pipeline:

Acquire → Retinal validation → IQA → Enhancement/preprocessing → Morphology evidence → DR grading → Referable decision → Explainability → Report → Specialist review → Referral → Follow-up → Audit

> [!CAUTION]
> **This is a screening and decision-support prototype.**
> It is NOT an autonomous diagnosis system, it is NOT clinically validated for field deployment, it is NOT FDA/medical-device approved, and the morphology modules provide *heuristic candidate evidence*, NOT clinically validated lesion detection.

---

## 2. Before you start

**Prerequisites:**
- **Python 3.8+**
- **MATLAB R2023b or newer** (Requires Deep Learning Toolbox, Image Processing Toolbox, Computer Vision Toolbox)
- **Simulink & SimEvents** (Required only to view the Digital Twin simulations)
- A modern web browser

Install Python requirements:
```bash
pip install -r dashboard/requirements.txt
```

---

## 3. Start the system

Open a terminal in the root `D:\SIH-26038` directory and run:

```bash
python dashboard/server.py
```

This starts the Python backend server. You should see Flask output indicating the server is running on `http://127.0.0.1:5000`.

---

## 4. 10-minute demonstration

| What evaluator wants | Where to go |
| -------------------- | ----------- |
| Run product          | `http://127.0.0.1:5000` |
| Screening demo       | `http://127.0.0.1:5000` -> Upload New Image |
| PDF                  | Layer 1 Report -> Click "Print Report" / "Download PDF" |
| Specialist review    | `http://127.0.0.1:5000/cases.html` |
| Audit trail          | `http://127.0.0.1:5000/cases.html` -> Select Case -> Scroll to Traceability Audit |
| Grad-CAM             | Shown in Layer 1 Report and Specialist Portal (`dashboard/gradcam_output`) |
| Morphology           | Shown in Layer 1 Report and Specialist Portal |
| Adaptation           | `http://127.0.0.1:5000/adaptation.html` |
| Simulink             | Open `DR_DigitalTwin_Day2.slx` in MATLAB Simulink |
| Validation metrics   | `outputs/evaluation/` directory |
| Tests                | Run `python -m unittest discover tests` or `testDRInference` in MATLAB |

**Step-by-step walkthrough:**
1. **Launch**: Run `python dashboard/server.py`.
2. **Open dashboard**: Navigate to `http://127.0.0.1:5000`.
3. **Load sample fundus**: Select a sample image from `data/raw/train_images/` or `messidor-2/preprocess/`.
4. **Run screening**: Click to analyze. The first run takes longer as the ResNet-50 model is loaded into memory via the MATLAB subprocess.
5. **Inspect result**: View the AI Grade and referable probability in the Layer 1 report.
6. **Open Grad-CAM**: The visual explanation is rendered directly on the report screen.
7. **Open morphology evidence**: The extracted features (vessels, exudates, neovascularization candidates, etc.) are listed below the image.
8. **Generate PDF**: Use the browser's native print function to generate a 2-page report (the UI is structured for standard print layouts).
9. **Open Specialist Portal**: Click "Specialist Review" or navigate to `http://127.0.0.1:5000/cases.html`.
10. **Submit specialist review**: Select the generated case on the left, assign a manual specialist grade, and submit.
11. **Inspect Layer 3 audit**: Scroll down in the case view to see the complete immutable traceability audit log, tracking versions, IQA, calibration, and adaptation configuration.

---

## 5. Safety demonstrations

The system is fortified with rigorous safety gates. Test them explicitly:

### Non-fundus rejection
- **Input**: `dashboard/img/oculaai_logo.png`
- **Expected**: The system blocks execution and reports `Rejected / not suitable for retinal screening`.

### Poor-quality image
- **Input**: Any severely blurred image.
- **Expected**: The system reports an `IQA failure` with recapture guidance, blocking any downstream DR result generation.

### Normal screening
- **Input**: A valid fundus image (e.g., `data/raw/train_images/1ae8c165fd53.png`).
- **Expected**: Full pipeline execution to a successful screening result.

---

## 6. Technical evidence

The system preserves all provenance. As an evaluator, you can inspect:
- **5-class DR probabilities & referable probability**: Visible in the Specialist Portal audit trail.
- **Calibration**: Handled natively; calibration version is tracked in the audit trail.
- **Grad-CAM & Morphology**: Preserved individually per case and visible in both Layer 1 and Layer 2.
- **Model / Calibration Version**: Fully immutable and tracked in the Layer 3 Audit.
- **Specialist Review & Agreement**: Specialist Portal tracks manual grades and automatically calculates Agreement (e.g., AGREE/DISAGREE) against the locked baseline.
- **Referral / Follow-up**: The state machine preserves transitions like `REFERRED` and `SEEN`.

---

## 7. Controlled adaptation

Navigate to `http://127.0.0.1:5000/adaptation.html`.

The project evaluated a domain-shift candidate on the IDRiD dataset via Platt scaling. The pipeline is:
Baseline → Candidate evaluation → Held-out validation → Mechanical decision → ROLLBACK

> [!IMPORTANT]
> The experimental candidate was **not promoted**. The system strictly executes the locked baseline. Any patient case processed by the system correctly reflects its state as `Baseline locked` in the audit trace, safely separating experimental evaluation from screening workflows.

---

## 8. Simulink/Digital Twin

Open `DR_DigitalTwin_Day2.slx` in MATLAB Simulink.

You can inspect three key scenarios:
1. **30-day verification run (AI-assisted)**
2. **330-day district-scale run (AI-assisted, 100,000 patients/year)**
3. **330-day manual baseline comparison**

The exact simulation telemetry (workload, queues, reviewer utilization) is saved in:
- `modules/simulink_telemed/results/results_30day.mat`
- `modules/simulink_telemed/results/results_365day.mat`

> [!NOTE]
> This simulation is a **digital twin model** designed for district-scale capacity planning and time-saved analysis. It is a synthetic simulation, not real-world field deployment data.

---

## 9. Reproducibility

**MATLAB inference tests:**
```matlab
matlab -batch "cd('D:\SIH-26038'); addpath(genpath('D:\SIH-26038\modules')); testMLIntegrationContract; testDRInference;"
```

**Morphology tests:**
```matlab
matlab -batch "cd('D:\SIH-26038'); addpath(genpath('D:\SIH-26038\modules')); run('tests/test_morphology_integration.m');"
```

**Python case-management suite:**
```bash
python -m unittest tests.test_case_management
```

**Adaptation evaluation:**
```bash
python -m unittest tests.test_sprint3_adaptation
```

---

## 10. Known limitations

- **Grade 3/4 Recall Limitation**: The baseline model exhibits lower sensitivity on specific severe cases.
- **Messidor Domain Shift**: Generalization is limited when evaluating on the external Messidor-2 distribution without fine-tuning.
- **Morphology Capabilities**: The morphology algorithms provide *heuristic candidate evidence* solely for interpretability, not clinically validated independent lesion detection.
- **Neovascularization**: The neovascularization module relies on a branch-point density heuristic, which represents candidate evidence rather than clinical detection.
- **Explainability**: Grad-CAM serves as mathematical explanation evidence (saliency), not medical validation.
- **Human-in-Loop Timing**: The 8.359-second specialist review observation is an engineering/familiarization metric, not a claim of clinical specialist validation.
- **Simulations**: Simulink outputs are theoretical district-scale models, not field deployment evidence.
