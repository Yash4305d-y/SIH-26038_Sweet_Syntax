# System Architecture
**SIH 2026 — PS 26038**

This document outlines the technical architecture of the Explainable AI prototype for DR screening.

## Core Architecture

```text
Frontend (Dashboard / Layer 1 / Layer 2 / Layer 3)
   ↓
Backend (Python Flask `server.py`)
   ↓
Case State Machine (`CaseManager`)
   ↓
MATLAB Subprocess Execution
   ├── Retinal Validation (Non-fundus Gate)
   ├── Image Quality Assessment (IQA Gate)
   ├── Enhancement / Preprocessing
   ├── ResNet-50 Inference (Locked Baseline)
   ├── Platt Scaling Calibration
   ├── Grad-CAM Generation
   └── Morphology Evidence Extraction
   ↓
Case Persistence (`cases.json`)
   ↓
Specialist Portal (Layer 2)
   ↓
Referral / Follow-up Logic
   ↓
Layer 3 Audit Traceability
```

## Secondary Governance & Evidence Components

These modules operate independently of the primary patient screening workflow to ensure the locked baseline is never unintentionally compromised by experimental or theoretical evaluations.

```text
Controlled Adaptation (IDRiD Domain Shift)
   ├── Baseline
   ├── Candidate evaluation
   ├── Held-out validation
   ├── Mechanical decision
   └── ROLLBACK
```
*Note: The Controlled Adaptation dashboard reads directly from the external `adaptation_handoff_package.json`, isolated completely from the core screening `cases.json`.*

```text
Simulink Digital Twin
   ├── 30-day AI-assisted simulation
   ├── 330-day district-scale AI simulation
   └── 330-day manual baseline
```
*Note: Simulink execution exists purely for resource capacity planning and time-saved analysis. Results are pre-generated as telemetry `.mat` files and are NOT executed at inference runtime.*
