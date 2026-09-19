# Sprint 3: Final Candidate Evaluation

## 1. Candidate Identity
- **Candidate:** Baseline ResNet-50 (R50-V1)
- **Checkpoint:** `models/r50_v1_best.mat`

## 2. Dataset and Evaluation Split
- **Dataset:** APTOS 2019 (Local Smoke-Test Subset)
- **Evaluation Split:** `test_split` (Defined in `data/splits/test_split.csv`)
- **Sample Count:** 32 images

## 3. Preprocessing
- Resize to 224x224x3 via standard `augmentedImageDatastore`.
- No runtime external augmentation.
- No explicit normalization applied (default datastore behavior).

## 4. Overall Metrics
- **Accuracy:** 0.4062
- **Macro Precision:** 0.0813
- **Macro Recall:** 0.2000
- **Macro F1:** 0.1156
- **Weighted Precision:** 0.1650
- **Weighted Recall:** 0.4062
- **Weighted F1:** 0.2347

## 5. Per-Class Metrics
| Grade | Precision | Recall | F1 | Support |
|---|---:|---:|---:|---:|
| Grade 0 | 0.4062 | 1.0000 | 0.5778 | 13 |
| Grade 1 | 0.0000 | 0.0000 | 0.0000 | 3 |
| Grade 2 | 0.0000 | 0.0000 | 0.0000 | 10 |
| Grade 3 | 0.0000 | 0.0000 | 0.0000 | 2 |
| Grade 4 | 0.0000 | 0.0000 | 0.0000 | 4 |

## 6. Confusion Matrix
Available in `results/r50_v1_confusion_matrix.png`.

## 7. Error Analysis
- **Measurable Patterns:** Predictions are entirely concentrated in a single class (Grade 0). All minority and pathological classes (Grades 1 through 4) have 0% recall. The model failed to differentiate any severity levels beyond the majority class.

## 8. Baseline Comparison
- **Comparison:** N/A (The Final Candidate is identical to the R50-V1 Baseline).

## 9. Inference Compatibility
- **Status:** **FAIL**
- **Details:** The inference script (`modules/dl_pipeline/inference/runDRInference.m`) improperly hardcodes the loading of `effnet_e02_best.mat` rather than the locked candidate (`r50_v1_best.mat`). Furthermore, it attempts to extract Grad-CAM features from `res5c_branch2c` (a ResNet layer), which will crash when run on an EfficientNet architecture. The script must be updated to correctly point to the R50-V1 model.

## 10. Limitations
- Severe class collapse to the majority class due to the constraints of the 32-image smoke-test dataset and the 5-epoch training duration.

## 11. Missing Evidence
- Performance validation on a full-scale clinical dataset.
- Messidor-2 external validation results (Member 3 responsibility).
- Held-out candidate calibration and Referable-DR tuning (Member 3 responsibility).

## 12. Handoff Information
- This evaluation serves as the factual evidence package for Member 3. Member 3 is responsible for completing the first real adaptation experiment (calibration, held-out evaluation, promotion rule logic, and PROMOTE/ROLLBACK decisions) before Member 1 builds the final adaptation dashboard.
