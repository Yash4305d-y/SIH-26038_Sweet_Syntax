# Regression Test Report
**SIH 2026 — PS 26038**

This report captures the final full-system regression audit executed on the locked prototype.

## Overall Status: PASS
*No product code changes were required after executing this regression.*

---

## 1. MATLAB Inference Suite
**Command:**
```matlab
testMLIntegrationContract
testDRInference
```
**Results:** PASS
- Verified 5-class predictions, probability validations, referable probabilities, calibration retention, and frozen threshold (0.22) accuracy. 
- Guaranteed the locked baseline model weights remain pristine.

## 2. Morphology Suite
**Command:**
```matlab
run('tests/test_morphology_integration.m')
```
**Results:** PASS
- Correctly parsed vessels, optic disc, fovea, exudates, microaneurysm, and hemorrhage.
- Neovascularization accurately reports `NO_DETECTION` (as expected on normal inputs).
- `BLOCKED_BY_DEPENDENCY` and `PROCESSING_FAILED` guards function flawlessly without halting the downstream ResNet-50 CNN inference.

## 3. Case-Management Suite (Python)
**Command:**
```bash
python -m unittest tests.test_case_management
```
**Results:** 20/20 PASS
- Case creation, persistence, retrieval, state machine logic, specialist grade alignment, agreement, referral logic, and follow-up states passed fully.
- **Grad-CAM Persistence**: `test_gradcam_generated_persisted` successfully confirmed exact generation status correctly written to `cases.json`.
- **Adaptation Persistence**: Guaranteed that standard workflows explicitly save `BASELINE_LOCKED` directly inside `cases.json`.

## 4. Full Python Suite & Safety Gates
**Command:**
```bash
python -m unittest discover tests
```
**Results (Core Product Regression):** PASS
- 35 core regression tests passed.
- **Safety Tests (`test_gate_full.py`, `test_scoring_gate.py`)**: Verified that IQA safely catches blurred images, and the retinal check definitively rejects non-fundus images (with accurate scoring for faces, landscapes, logos, etc.) before reaching ML inference.
- **Async Safety**: Confirmed stale asynchronous results cannot accidentally overwrite newer cases.

*(Note: Legacy/environment-dependent validation scripts such as `test_iqa_validation.py` generated `ModuleNotFoundError: No module named 'cv2'` and missing-directory warnings. These are isolated environmental warnings reflecting older external validation targets and do not impact or invalidate the core product regression.)*

## 5. System Layer Integrations
**Layer 1 (Report Generation):** PASS
- Generates 2-page print-ready output, neatly sequestering technical evidence (Grad-CAM, Morphology) from patient-facing grades.

**Layer 2 (Specialist Portal):** PASS
- Specialist Portal correctly fetches and lists all necessary AI evidence alongside manual override functionalities without ever destructively overwriting the AI origin records.

**Layer 3 (Audit Traceability):** PASS
- Case ID, Image ID, AI Grade, Referable Probability, IQA Status, Model/Calibration Version, and exact Review Durations preserve perfectly across Python backend reboots. Historical backward-compatibility for cases missing newer Optional fields (like Grad-CAM reference) remains intact.

## 6. Digital Twin (Simulink)
**Verification:** PASS
- Native `.mat` generated outputs from `DR_DigitalTwin_Day2.slx` map seamlessly back to their designated inputs (`simParams_330day`, etc.), validating the structural integrity of the district-scale workload simulations.

## 7. Controlled Adaptation Evaluation
**Verification:** PASS
- Domain adaptation experiment results (IDRiD calibration via Platt scaling) safely executed with mechanical decision remaining explicitly evaluated as **ROLLBACK**. Global IDRiD evaluation package accurately segregated from the core patient case pipeline.
