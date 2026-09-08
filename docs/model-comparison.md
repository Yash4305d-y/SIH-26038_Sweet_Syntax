# APTOS Model Comparison

## 1. Objective
Perform a formal comparison of the four existing APTOS 5-class ResNet-50 models to determine the recommended model based on evaluation metrics. The primary focus is QWK (since grading is ordinal), followed by Macro-F1 and Accuracy, while evaluating minority-class sensitivity.

## 2. Models Compared
- Baseline ResNet-50
- Mild Weighted ResNet-50
- Medium Weighted ResNet-50
- Strong Weighted ResNet-50

### Exact Class Weights
Mild: `[0.4977; 1.0908; 0.6628; 1.5174; 1.2314]`

Strong: `[0.3334; 1.0818; 0.5124; 1.7749; 1.2975]`

*(Medium weighted falls structurally in between)*

## 3. Dataset/Evaluation Setup
- **Dataset:** APTOS 2019 Blindness Detection test set
- **Image Count:** 439 images
- **Classes:** 0 (No DR) to 4 (Proliferative DR)

## 4. Controlled Variables
All models share the same architecture (ResNet-50), train/val/test splits, pre-processing routines, non-weighted hyperparameters, and evaluate identically on the exact same unseen test samples. No Messidor-2 data was used.

## 5. Metrics
Accuracy, Macro-F1, Quadratic Weighted Kappa (QWK), Macro Precision, Macro Recall, and per-class Precision/Recall/F1.

## 6. Results Table
| Model | Accuracy | Macro Precision | Macro Recall | Macro F1 | QWK |
|---|---|---|---|---|---|
| Baseline | 0.8292 | 0.7656 | 0.5975 | 0.6358 | 0.8713 |
| Mild Weighted | 0.8018 | 0.6864 | 0.6535 | 0.6519 | 0.8406 |
| Medium Weighted | 0.7745 | 0.6071 | 0.6161 | 0.6019 | 0.8220 |
| Strong Weighted | 0.7699 | 0.6317 | 0.6816 | 0.6475 | 0.8647 |

## 7. Per-Class Analysis
| Model | C0 F1 | C1 F1 | C2 F1 | C3 F1 | C4 F1 |
|---|---|---|---|---|---|
| Baseline | 0.9724 | 0.6027 | 0.7889 | 0.3750 | 0.4400 |
| Mild Weighted | 0.9548 | 0.6306 | 0.7273 | 0.4118 | 0.5352 |
| Medium Weighted | 0.9517 | 0.5591 | 0.7113 | 0.4912 | 0.2963 |
| Strong Weighted | 0.9314 | 0.5614 | 0.7257 | 0.4583 | 0.5610 |

## 8. Weighting Tradeoff
As weighting increases from Baseline -> Mild -> Medium -> Strong, the model trades aggregate Accuracy and QWK for minority class representation (specifically Grades 1, 3, and 4).
- The Baseline has the highest Accuracy (0.8292) and QWK (0.8713), representing the most fundamentally stable ordinal grading.
- The Mild Weighted model boosts Macro-F1 to 0.6519 (best overall) by improving minority grade recall, but begins to sacrifice QWK.
- The Strong Weighted model severely degrades Accuracy (0.7699) but maximizes minority sensitivity.
The loss in structural ordinal stability (QWK) is generally not justified by the gains in uncalibrated minority recall for an automated diagnostic tool unless explicitly gating a highly sensitive screening pipeline.

## 9. Model Ranking
| Criteria | Rank 1 | Rank 2 | Rank 3 | Rank 4 |
|---|---|---|---|---|
| Accuracy | Baseline | Mild Weighted | Medium Weighted | Strong Weighted |
| Macro-F1 | Mild Weighted | Strong Weighted | Baseline | Medium Weighted |
| QWK | Baseline | Strong Weighted | Mild Weighted | Medium Weighted |
| Macro Recall | Strong Weighted | Mild Weighted | Medium Weighted | Baseline |
| Grade 1 Recall | Mild Weighted | Strong Weighted | Medium Weighted | Baseline |
| Grade 3 Recall | Medium Weighted | Strong Weighted | Mild Weighted | Baseline |
| Grade 4 Recall | Strong Weighted | Mild Weighted | Baseline | Medium Weighted |

## 10. Final Selection
- **A. Best overall ordinal grading model:** Baseline
- **B. Best macro-F1 model:** Mild Weighted
- **C. Best minority-class sensitivity profile:** Strong Weighted
- **D. Recommended final model for SIH:** **Baseline ResNet-50**

The **Baseline ResNet-50** is recommended because it maximizes QWK (0.8713) and Accuracy (0.8292). While class weighting successfully investigated the minority-class tradeoffs, the Baseline provides the strongest, most stable fundamental grading capability for the target problem space.

## 11. Limitations
This controlled comparison strictly measures performance on the APTOS internal evaluation set. It does not measure or reflect external validity (domain shift) on external datasets like Messidor-2.

## 12. Reproducibility Information
All original `.mat` results files are strictly preserved in their respective directories. Evaluation outputs are statically reproduced using `compareModels.m` without modifying network weights.
