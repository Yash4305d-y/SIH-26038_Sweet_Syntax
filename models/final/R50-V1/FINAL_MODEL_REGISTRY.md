# FINAL MODEL REGISTRY

## What model was frozen?
**Model:** ResNet-50
**ID:** R50-V1
**Checkpoint:** `models/final/R50-V1/r50_v1_best.mat`

## Why was it selected?
R50-V1 was explicitly selected and locked by the project lead during the Sprint 3 and Sprint 4 final model freeze checkpoint. The selection basis acknowledges that the baseline framework is structurally complete and inference-ready for integration. 

**CRITICAL SMOKE-TEST LIMITATION:** The available 32-image smoke-test dataset was too small to provide reliable comparative model-performance evidence, and all experiments exhibited complete class collapse under the short smoke-test training setup. Therefore, R50-V1 was not selected based on statistically significant superiority in accuracy or clinical effectiveness, but as the verified baseline to fulfill the final integration contract for UI and Simulink handoff.

## What dataset/split was used?
- **Dataset:** APTOS 2019 (Local mock)
- **Split:** Local smoke-test split (`data/splits/test_split.csv`) containing 32 images.

## What preprocessing is required?
- The model strictly requires input images to be resized to `[224, 224, 3]`.
- This is natively handled in the inference contract via `imresize`. No external manual normalization (e.g., Z-scoring) is required beyond the default datastore preprocessing pipeline.

## What are the classes?
The inference contract strictly maps outputs to:
- `0`: No DR (Grade 0)
- `1`: Mild DR (Grade 1)
- `2`: Moderate DR (Grade 2)
- `3`: Severe DR (Grade 3)
- `4`: Proliferative DR (Grade 4)

## How does inference work?
Inference is executed via `modules/dl_pipeline/inference/runDRInference.m`. The pipeline takes a single raw retinal image (path or array), resizes it to 224x224x3, and loads the frozen `r50_v1_best.mat` checkpoint to extract 5-class categorical probabilities. It calculates referable probability (P2+P3+P4), calibrates it via Platt scaling, and generates a Grad-CAM heatmap via the ResNet-50 `res5c_branch2c` feature layer.

## What limitations remain?
- Severe class collapse to Grade 0 due to limited local data.
- The model is entirely unproven on external data (Messidor-2) and has not undergone held-out performance tuning.
- The system is a prototype interface model and is not clinically safe for real-world diagnostic use without complete retraining on a full-scale dataset.
