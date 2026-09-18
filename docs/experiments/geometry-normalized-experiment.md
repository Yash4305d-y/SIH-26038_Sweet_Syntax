# ML Experiment 1 — Geometry-Normalized APTOS ResNet-50

## Objective
Test whether reducing APTOS aspect-ratio variation through a 1:1 center crop improves the ResNet-50 DR classification model.

## Configuration
- **Preprocessing:** Ahead-of-time deterministic 1:1 center crop + 224x224 resize
- **Optimizer:** Adam
- **Learning Rate:** 1e-4
- **Epochs:** 5
- **Batch Size:** 16

## Results
| Metric | Baseline | Geometry Normalized | Difference |
|---|---|---|---|
| Accuracy | 0.8292 | 0.8068 | -0.0224 |
| Macro-F1 | 0.6358 | 0.5976 | -0.0382 |
| QWK | 0.8713 | 0.8546 | -0.0167 |

## Experiment Interpretation

### OBSERVATION
Compared to the baseline test evaluation, the validation accuracy changed by -0.0224, Macro-F1 by -0.0382, and QWK by -0.0167.

### HYPOTHESIS
Results do not support geometry normalization as a sufficient improvement under this experimental configuration.

### LIMITATION
This is only a 5-epoch smoke-test experiment. Do NOT claim causality from one experiment or that it solves domain shift on Messidor-2.
