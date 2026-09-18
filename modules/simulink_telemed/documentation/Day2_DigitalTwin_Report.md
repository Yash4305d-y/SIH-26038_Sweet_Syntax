# Role 3 — Discrete-Event Digital Twin Technical Report
## PS 38 / SIH 2026: District-Scale Screening Capacity Model

### 1. Parameter Provenance Matrix

| Parameter Category | Value | Source / Methodology |
|---|---|---|
| **IQA Gate Failure Rate** | **13.68%** | **Measured (Role 2):** 58 failures / 424 benchmark fundus images (51 illumination, 7 FOV). |
| **AI Forward Pass + Grad-CAM** | **1.45 s** | **Measured (Role 1):** ResNet-50 forward inference + Grad-CAM activation mapping. |
| **Referable DR Rate (Grade >= 2)** | **43.51%** | **Measured (Role 1):** Evaluation on 439 held-out test fundus images. |
| **Low Confidence Rate (< 0.65)** | **4.78%** | **Measured (Role 1):** Grade < 2 cases with soft entropy/uncertainty flags. |
| **Overall Specialist Review Trigger** | **48.29%** | **Derived:** Union of Grade >= 2 and Low-Confidence (< 0.65) cases. |
| **AI-Assisted Review Time** | **30 s** | **System Specification:** Reviewer evaluation of pre-extracted lesion candidates. |
| **Manual Review Time Baseline** | **240 s (4 m)** | **Literature Assumption:** Standard unassisted 5-stage DR grading (3–5 min baseline). |
| **District Scale Cohort** | **100,000 pts/yr** | **Operational Baseline:** Standard Indian rural district screening target. |
| **Staffing Model** | **2 Specialists** | **Operational Baseline:** Dedicated tele-ophthalmologists at district hospital. |

### 2. Verified Level-4 Telemetry (330-Day Operational Run)

* **Patients Screened:** 90,411
* **Quality Interventions (Edge Intercept):** 12,367 images (13.7%) caught before entering CNN.
* **Specialist Workload Demand:** Reduced from 2,512.6 hours (manual) to 314.1 hours (AI-assisted).
* **Net Specialist Capacity Saved:** **2,198.5 clinical hours saved annually per district (87.5% reduction)**.
* **Specialist Utilization:** Operates at **5.95% utilization**, guaranteeing SLA < 24 hrs with zero backlog.