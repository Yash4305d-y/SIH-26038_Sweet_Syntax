# ML Final Results

## 1. Final Model
**Baseline ResNet-50**

## 2. Training Configuration
- **Dataset:** APTOS 2019
- **Split:** 70% train / 15% validation / 15% test
- **Input:** 224x224 RGB
- **Optimizer:** Adam
- **Initial learning rate:** 1e-4
- **MiniBatchSize:** 16
- **MaxEpochs:** 5
- **Loss:** crossentropy
- **Class weighting:** NONE
- **Training augmentation:** NONE

*(Note: An offline augmentation experiment was separately evaluated but rejected).*

## 3. 5-Class APTOS Results
- **Test Set:** 439 images
- **Accuracy:** 0.8292
- **Macro-F1:** 0.6358
- **QWK:** 0.8713

**Per-Class Results:**
- **Class 0:** Precision 0.9635, Recall 0.9814, F1 0.9724
- **Class 1:** Precision 0.7857, Recall 0.4889, F1 0.6027
- **Class 2:** Precision 0.6786, Recall 0.9421, F1 0.7889
- **Class 3:** Precision 0.6667, Recall 0.2609, F1 0.3750
- **Class 4:** Precision 0.7333, Recall 0.3143, F1 0.4400

## 4. Model Selection Experiments
- **Baseline ResNet-50:** Accuracy 0.8292, Macro-F1 0.6358, QWK 0.8713
- **Mild weighted:** Accuracy 0.8018, Macro-F1 0.6519, QWK 0.8406 (REJECTED)
- **Medium weighted:** Accuracy 0.7745, Macro-F1 0.6019, QWK 0.8220 (REJECTED)
- **Strong weighted:** Accuracy 0.7699, Macro-F1 0.6475, QWK 0.8647 (REJECTED)
- **Geometry-normalized:** Accuracy 0.8068, Macro-F1 0.5976, QWK 0.8546 (REJECTED)
- **Offline conservative augmentation:** Accuracy 0.8136, Macro-F1 0.6367, QWK 0.8581 (REJECTED)

## 5. Grad-CAM Verification
- **Total images verified:** 439/439
- Grad-CAM provides spatial attention visualization for model interpretability. It should not be interpreted as proof that the model detected a specific clinical lesion.

## 6. Referable-DR Evaluation
- **Raw threshold:** 0.5
- **Accuracy:** 0.9385
- **Sensitivity:** 0.9609
- **Specificity:** 0.9231
- **Precision:** 0.8958
- **F1:** 0.9272
- **ROC-AUC:** 0.9816

## 7. Calibration
Calibration improved probability calibration according to the reported Brier/ECE results and changed the operating threshold.
- **Test N:** 439
- **Frozen Threshold:** 0.22
- **Test Accuracy:** 0.9317
- **Test Sensitivity:** 0.9888
- **Test Specificity:** 0.8923
- **Test F1:** 0.9219
- **Raw Brier:** 0.049931 -> **Calibrated Brier:** 0.048506
- **Raw ECE:** 0.036375 -> **Calibrated ECE:** 0.030670

## 8. Messidor-2 External Validation
- **Images/Labels:** 1744 / 1744
- **5-class QWK:** 0.3231
- **Binary Referable ROC-AUC:** 0.7669
Messidor-2 demonstrates substantial external-domain performance degradation and representation mismatch. The representation mismatch is a plausible contributor to the observed generalization gap, but this audit does not establish causality. No Messidor-2 tuning was performed.

## 9. Limitations
This is a research/prototype screening system. It is not a clinical diagnostic system. External generalization is currently substantially weaker than APTOS internal performance. Messidor-2 results are retained and reported rather than hidden.

## 10. Final ML Architecture
The final architecture integrates the raw ResNet-50 5-class probability outputs, derives a referable-DR aggregate probability, scales it using Platt Scaling, and thresholds it at a frozen value of 0.22 to maximize sensitivity while preserving acceptable specificity.

## 11. Handoff to Other Roles
Role 1 formally delegates integration to Role 2 (Quality Gates) and Role 3/4 (Simulink/Telemedicine Integration) per the ML Handoff Contract.

## 12. Final Decision
**BASELINE RESNET-50 LOCKED.**
R50-V1 is locked for the next prototype integration stages, including Simulink handoff and UI integration. 

**Important Note:** The 32-image smoke-test results must not be presented as evidence that R50-V1 outperforms the other candidates. All controlled experiments experienced class collapse because of the extremely limited smoke-test dataset and short training duration. R50-V1 is selected as the representative baseline to fulfill the integration contract. All experiment artifacts and evaluation results have been preserved.
