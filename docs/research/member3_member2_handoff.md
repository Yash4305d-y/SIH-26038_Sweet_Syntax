# Member 3 → Member 2 Handoff Contract

**Project**: SIH 2026 Problem Statement 26038 — Explainable AI for Diabetic Retinopathy Screening in Rural India  
**Author**: Member 3 — Evaluation & Adaptation Lead  
**Target Consumer**: Member 2 — Machine Learning & Model Training Lead  
**Status**: Member 3 Evaluation Framework **READY FOR MEMBER 2 CANDIDATE EVALUATION**  

---

## Executive Handoff Summary

Member 3 provides the authoritative, frozen evaluation framework for evaluating model candidates produced by Member 2. The baseline model remains the **Locked ResNet-50** ($\tau=0.22$). If Member 2 provides new candidate weights, Member 3's evaluation pipeline stands ready to execute standardized 5-class, referable DR, calibration, external validation, and domain adaptation benchmarks.

---

## Evaluation Framework & Benchmark Interface

| Metric / Benchmark | Dataset / Split | Sample Size ($N$) | Locked Baseline Target | Candidate Submission Contract |
|---|---|---|---|---|
| **Primary Accuracy** | APTOS 2019 Locked Test | 439 | $82.92\%$ | 5-class logits/probabilities |
| **Macro-F1** | APTOS 2019 Locked Test | 439 | $63.58\%$ | 5-class logits/probabilities |
| **QWK** | APTOS 2019 Locked Test | 439 | $0.8713$ | 5-class logits/probabilities |
| **Referable Sensitivity** | APTOS 2019 Locked Test | 439 | $96.09\%$ | Binary probability $P_{\text{ref}} \ge \tau$ |
| **Referable Specificity** | APTOS 2019 Locked Test | 439 | $92.31\%$ | Binary probability $P_{\text{ref}} \ge \tau$ |
| **Messidor-2 ROC-AUC** | Messidor-2 Frozen External | 1,744 | $0.7669$ | Frozen model predictions |
| **IDRiD Specificity** | IDRiD Held-Out ($N=41$) | 41 | $57.14\%$ (Baseline) / $64.29\%$ (Cand) | Platt scaling calibration |

---

## Artifact Status Matrix

| Artifact / Requirement | Location | Provider | Status | Missing Dependency |
|---|---|---|---|---|
| **Locked ResNet-50 Baseline** | `models/baseline_resnet50_smoketest.mat` | Member 2 / Member 3 | **ACTIVE** | None |
| **Benchmark Comparison Matrix** | `outputs/evaluation/benchmark_comparison.csv` | Member 3 | **COMPLETE** | None (3 variants logged) |
| **Evaluation Script** | `generate_model_evidence_package.py` | Member 3 | **COMPLETE** | None |
| **Member 2 Final Weights** | `models/` | Member 2 | **PENDING MEMBER 2** | Awaiting Member 2 freeze |

---

## Submission Contract for Member 2 Model Candidates

To evaluate a new model candidate, Member 2 must provide:
1. Model weights artifact compatible with MATLAB `dlnetwork` / `minibatchpredict` or PyTorch inference bridge.
2. Exact input preprocessing requirement ($224 \times 224 \times 3$, green-channel normalization).
3. Softmax 5-class probability vector $[P_0, P_1, P_2, P_3, P_4]$ per image.
