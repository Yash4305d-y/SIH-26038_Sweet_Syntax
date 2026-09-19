# Member 3 Sprint 3 Report
**Team SweetSyntax — Diabetic Retinopathy Technical Master Plan**

---

## 1. Scope

Member 3 Sprint 3 implementation and evaluation infrastructure is complete. The actual IDRiD adaptation experiment is BLOCKED pending availability of the raw IDRiD images and labels.

### Status Categorization Summary:

#### COMPLETE:
- IDRiD split metadata (`data/splits/idrid_splits.csv`)
- Split isolation tests (`tests/test_sprint3_adaptation.py`)
- Candidate calibration infrastructure (`modules/dl_pipeline/evaluation/`)
- Predefined promotion rule
- Adaptation handoff package (`outputs/evaluation/adaptation_handoff_package.json`)
- Messidor frozen evidence (`outputs/evaluation/external_validation/`)
- Benchmark evidence (`outputs/evaluation/benchmark_comparison.csv`)
- Regression tests (27/27 Python unit tests passed)

#### BLOCKED:
- Candidate calibration fitting on raw IDRiD images
- IDRiD held-out evaluation
- Actual PROMOTE / ROLLBACK decision

---

## 2. IDRiD Data Availability

A systematic data availability audit was conducted across local repository paths:

| Data Element | Availability Status | Evidence Location | Details / Notes |
| :--- | :--- | :--- | :--- |
| **Split Metadata CSV** | **AVAILABLE** | `data/splits/idrid_splits.csv` | 81 total records defining exact 40 fit / 41 held-out split. |
| **Raw Fundus Images** | **UNAVAILABLE** | `data/raw/idrid/` (missing) | Raw IDRiD image files (`.jpg`/`.png`/`.tif`) are not present locally. |
| **Verified Image Labels** | **UNAVAILABLE** | `data/metadata/` | Grade annotations associated with raw images are absent locally. |
| **Lesion Segmentation Masks** | **UNAVAILABLE** | `data/raw/` | Ground-truth lesion masks for IDRiD images are absent locally. |

> [!CAUTION]
> **Data Integrity Rule Enforcement:** In accordance with strict evaluation guardrails, zero synthetic images, labels, or metrics were generated. Because raw IDRiD fundus images are missing, quantitative candidate calibration fitting and held-out evaluation on IDRiD are marked **BLOCKED**.

---

## 3. Fit / Held-Out Split

The Master Plan adaptation split for IDRiD was verified programmatically (`tests/test_sprint3_adaptation.py`):

- **Split Metadata File**: `data/splits/idrid_splits.csv`
- **Total Split Records**: 81 images (`IDRiD_01` to `IDRiD_81`)
- **Calibration-Fit Subset**: 40 images (`split == 'calibration_fit'`)
- **Held-Out Validation Subset**: 41 images (`split == 'heldout_validation'`)
- **Leakage Audit**: **0 overlap** between `calibration_fit` and `heldout_validation` sets ($N_{\text{overlap}} = 0$).
- **Determinism**: Split was generated using fixed seed $42$ via `modules/image_processing/code/prepare_idrid_splits.py`.

---

## 4. Candidate Calibration

- **Method**: Candidate calibration method specified by Technical Master Plan (Platt Scaling / Isotonic Regression).
- **Target Fitting Data**: IDRiD Calibration-Fit subset ($N = 40$).
- **Current Fitting Status**: **BLOCKED** due to missing raw IDRiD image files locally.
- **Safeguard Enforcement**: Held-out subset ($N = 41$) remained 100% untouched.

---

## 5. Held-Out Evaluation

- **Target Held-Out Subset**: IDRiD Held-Out Validation subset ($N = 41$).
- **Baseline Calibration Held-Out Performance**: N/A (Missing raw image data).
- **Candidate Calibration Held-Out Performance**: N/A (Missing raw image data).
- **Status**: **BLOCKED** (No fabricated metrics).

---

## 6. Predefined Promotion Rule

The predefined decision rule governing model promotion vs rollback was established **prior** to evaluating results:

$$\text{Decision} = \begin{cases} \text{PROMOTE} & \text{if } \text{data\_available} \land \text{ECE}_{\text{cand}} \le \text{ECE}_{\text{base}} \land \text{Sens}_{\text{cand}} \ge \text{Sens}_{\text{base}} \land \text{Brier}_{\text{cand}} \le \text{Brier}_{\text{base}} \\ \text{ROLLBACK} & \text{if } \text{data\_available} \land (\text{ECE}_{\text{cand}} > \text{ECE}_{\text{base}} \lor \text{Sens}_{\text{cand}} < \text{Sens}_{\text{base}} \lor \text{Brier}_{\text{cand}} > \text{Brier}_{\text{base}}) \\ \text{BLOCKED} & \text{if } \neg\text{data\_available} \end{cases}$$

### Rule Requirements:
1. Candidate calibration must achieve Expected Calibration Error ($\text{ECE}$) $\le$ Baseline ECE on held-out data.
2. Candidate calibration must achieve Referable DR Sensitivity $\ge$ Baseline Sensitivity ($\ge 90\%$) on held-out data.
3. Candidate calibration must not increase raw Brier score.
4. If required raw data is unavailable, decision MUST evaluate to **BLOCKED**.

---

## 7. PROMOTE / ROLLBACK / BLOCKED Decision

### Official Decision: **BLOCKED**

> [!IMPORTANT]
> **Clarification:** BLOCKED is not equivalent to ROLLBACK. No candidate was evaluated, therefore no candidate was rejected.

- **Decision Rationale**: Raw IDRiD fundus image files and labels are not present in the local workspace repository. Although split metadata (`idrid_splits.csv`) is 100% verified (40 fit / 41 held-out), quantitative fitting and held-out validation cannot execute without raw data.
- **Baseline Model State**: **Baseline ResNet-50 remains LOCKED**. No candidate model is promoted.

---

## 8. Messidor-2 Evidence

Verification of frozen external validation evidence on Messidor-2 ($N = 1,744$, `data/metadata/messidor_data.csv`):

- **Model State**: Frozen Baseline ResNet-50 (Zero tuning, zero threshold fitting on Messidor-2).
- **Evaluation Type**: External 5-Class & Binary Calibrated.
- **5-Class Accuracy**: **59.98%**
- **5-Class Macro F1-Score**: **0.2581**
- **5-Class Quadratic Weighted Kappa (QWK)**: **0.3231**
- **Binary Referable ROC-AUC**: **0.7669**
- **Referable Sensitivity ($\tau = 0.22$)**: **29.32%**
- **Referable Specificity ($\tau = 0.22$)**: **97.05%**
- **Brier Score (Raw)**: **0.193753**
- **ECE (Raw)**: **0.182716**

*Domain Shift Finding*: Sensitivity drop on Messidor-2 under fixed threshold reflects significant camera, resolution, and lighting differences between APTOS 2019 and Messidor-2.

---

## 9. Benchmark / Model Comparison

Empirical metrics on locked holdout test set ($N = 439$, `outputs/evaluation/benchmark_comparison.csv`):

| Model Variant | Strategy | 5-Class Acc | Macro F1 | QWK | Ref. Sens | Ref. Spec | Ref. Prec |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline ResNet-50 (Locked)** | Unweighted CE, Softmax | **82.92%** | 0.6358 | **0.8713** | **96.09%** | 92.31% | 89.29% |
| **Mild Weighted ResNet-50** | Inverse Class Weights | 79.95% | **0.6467** | 0.8730 | 83.80% | **97.31%** | **95.54%** |
| **Strong Weighted ResNet-50** | Sqrt Class Weights | 73.12% | 0.6103 | 0.8437 | 83.24% | 96.54% | 94.30% |

**Baseline Selection Lock**: Baseline ResNet-50 was locked due to superior referable sensitivity (96.09% vs 83.80%), minimizing false negatives in clinical screening.

---

## 10. Member 1 Handoff

A machine-readable adaptation handoff package was generated for Member 1's adaptation dashboard:

- **JSON Handoff File**: [`outputs/evaluation/adaptation_handoff_package.json`](file:///k:/SIH%202026/Diabetic%20Retinopathy/SIH-26038/outputs/evaluation/adaptation_handoff_package.json)
- **Key Fields Included**:
  - `adaptation_status.decision`: `"BLOCKED"`
  - `adaptation_status.decision_rationale`: Full explanation of missing raw IDRiD image files.
  - `idrid_split_info`: Total records (81), fit (40), held-out (41), overlap (0).
  - `baseline_model`: Locked Baseline ResNet-50 metrics.
  - `messidor2_frozen_evidence`: Frozen external evaluation metrics.
  - `benchmark_comparison`: All evaluated model variants.
  - `limitations`: Explicit listing of raw image missing status and domain shift observations.

---

## 11. Tests

All 27 Python unit tests executed cleanly ($27/27$, 100% Pass Rate):

1. `tests/test_sprint3_adaptation.py` (5/5 passed)
   - `test_idrid_split_no_overlap` (PASSED)
   - `test_promotion_rule_determinism` (PASSED)
   - `test_messidor_freeze_status` (PASSED)
   - `test_handoff_package_schema` (PASSED)
   - `test_aptos_split_isolation` (PASSED)
2. `tests/test_pipeline_integration.py` (4/4 passed)
3. `tests/test_calibration_validation.py` (4/4 passed)
4. `tests/test_iqa_validation.py` (4/4 passed)
5. `tests/test_morphology_validation.py` (4/4 passed)
6. `tests/test_preprocessing_validation.py` (3/3 passed)
7. `tests/verify_dataset_splits.py` (3/3 passed)

---

## 12. Limitations / Blockers

1. **IDRiD Raw Image Availability**: Raw IDRiD fundus image files and lesion labels are missing locally; quantitative adaptation is marked **BLOCKED**.
2. **Messidor-2 Domain Shift**: Significant sensitivity drop (29.32%) on Messidor-2 demonstrates domain shift between APTOS training and Messidor acquisition protocols.
3. **MATLAB Toolbox License**: Local MATLAB Image Processing Toolbox license is unavailable.
