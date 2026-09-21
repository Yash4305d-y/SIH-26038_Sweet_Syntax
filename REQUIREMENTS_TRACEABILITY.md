# Requirements Traceability Matrix
**SIH 2026 — PS 26038**

This document maps Problem Statement requirements to their concrete technical implementations and corresponding verified evidence.

| PS Requirement | Implementation | Evidence | Status |
| :--- | :--- | :--- | :--- |
| IQA | Explicit Python/MATLAB scoring module blocking bad inputs | `test_iqa_validation.py`, Python Test Suite | PASS |
| Retinal validation | Non-fundus gate (image metrics scoring) | `test_gate_full.py`, Python Test Suite | PASS |
| Optic disc | `optic_disc.m` | `test_morphology_integration.m` | Implemented candidate evidence / heuristic |
| Fovea | `fovea_heuristic.m` | `test_morphology_integration.m` | Implemented candidate evidence / heuristic |
| Vessel segmentation | `vessel_extraction.m` | `test_morphology_integration.m` | Implemented candidate evidence / heuristic |
| Microaneurysm | `ma_hemorrhage_candidates.m` (Candidate extractor) | `test_morphology_integration.m` | Implemented candidate evidence / heuristic |
| Exudate | `exudate_candidates.m` (Candidate extractor) | `test_morphology_integration.m` | Implemented candidate evidence / heuristic |
| Hemorrhage | `ma_hemorrhage_candidates.m` (Candidate extractor) | `test_morphology_integration.m` | Implemented candidate evidence / heuristic |
| Neovascularization | `neovascularization_candidates.m` (Candidate evidence heuristic) | `test_morphology_integration.m` | Implemented candidate evidence / heuristic |
| DR grading | Locked ResNet-50 (`baseline_resnet50_smoketest.mat`) | MATLAB metrics | PASS |
| Referable DR | Calibrated binary decision using Platt Scaling | APTOS/Messidor metrics | PASS |
| Grad-CAM | Saliency overlay implementation | Prediction-consistency verification tests | PASS |
| Specialist review | Layer 2 Specialist Portal | `test_case_management.py` | PASS |
| Referral | Case state machine (`CaseManager`) | `test_case_management.py` | PASS |
| Follow-up | Case state machine (`CaseManager`) | `test_case_management.py` | PASS |
| Adaptation | Controlled Adaptation evaluating IDRiD shift | `adaptation_handoff_package.json` | ROLLBACK |
| Digital Twin | Simulink / SimEvents District Model | Pre-generated `.mat` scenario outputs | PASS |

*( * Note: Neovascularization and other morphology modules provide heuristic candidate evidence designed solely for explainability, NOT clinically validated automated detection.)*
