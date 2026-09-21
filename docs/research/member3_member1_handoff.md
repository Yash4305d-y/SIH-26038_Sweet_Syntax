> [!WARNING]
> **Historical Document** — superseded by current integrated implementation. The claims, limitations, and paths below represent historical research/member handoff and do NOT reflect the final integrated product state.

# Member 3 → Member 1 Handoff Contract

**Project**: SIH 2026 Problem Statement 26038 — Explainable AI for Diabetic Retinopathy Screening in Rural India  
**Author**: Member 3 — Dataset + Image Processing + Evaluation Lead  
**Target Consumer**: Member 1 — System Architecture, UI/Dashboard & Pipeline Lead  
**Status**: All Upstream Member 3 Handoff Artifacts **READY FOR CONSUMPTION**  

---

## Executive Handoff Summary

Member 3 has completed, validated, and frozen all machine-readable evidence, IQA gate contracts, feature extraction schemas, and domain adaptation packages required for Member 1's UI, Dashboard, and Pipeline integration.

---

## Upstream Handoff Artifact Matrix

| Artifact / Interface | Path / Location | Member 3 Status | Member 1 Consumer Feature | Readiness | Notes / Contract Details |
|---|---|---|---|---|---|
| **IQA Gate Contract** | `check_image_quality.m`, `check_illumination.m`, `check_fov.m` | **COMPLETE** | Retinal Gate & Quality Feedback | **READY** | Returns `status: "PASS"/"FAIL"`, focus score, illumination, FOV ratio, and recapture guidance. |
| **Structured Retinal Features** | [structured_retinal_features_schema.json](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/outputs/evaluation/structured_retinal_features_schema.json) | **COMPLETE** | Patient Report & Case Audit Screen | **READY** | Standardized JSON schema for IQA, CLAHE, vessel density, optic disc/fovea coordinates, and lesion candidate counts. |
| **Adaptation Handoff Package** | `outputs/evaluation/adaptation_handoff_package.json` | **COMPLETE** | Member 1 Adaptation Dashboard | **READY** | Contains real IDRiD split ($40/41$), Platt parameters ($A=5.4270, B=-1.8918, \tau=0.37$), and `decision: ROLLBACK`. |
| **Master Evidence Package** | [model_evidence_package.json](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/outputs/evaluation/model_evidence_package.json) | **COMPLETE** | System Evidence & Validation Screen | **READY** | Consolidated metrics across APTOS ($N=439$), Messidor-2 ($N=1,744$), and IDRiD ($N=81$) with provenance. |
| **Simulink Operational Parameters** | `docs/research/simulink_parameter_handoff.md` | **COMPLETE** | Simulink Operational Queue Model | **READY** | Empirical pipeline latency ($450$ ms), image sizes, IQA rejection rates, and 100k+ workload math. |

---

## Action Items for Member 1

1. **Dashboard Binding**:
   - Bind the Adaptation Dashboard directly to `outputs/evaluation/adaptation_handoff_package.json`.
   - Render the explicit `ROLLBACK` decision banner with rejection rationale (Specificity $64.29\% < 85\%$).
2. **IQA Rejection Handling**:
   - Ensure images returning `IQA: FAIL` bypass DR inference and display Member 3's actionable recapture guidance.
3. **Structured Report Rendering**:
   - Populate patient report panels using the schema defined in `structured_retinal_features_schema.json`.
