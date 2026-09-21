# QUICK START GUIDE
**SIH 2026 — PS 26038**

This guide allows an evaluator to start the Diabetic Retinopathy screening prototype in under 5 minutes.

## Prerequisites
- **Python 3.8+**
- **MATLAB R2023b+** (with Deep Learning, Image Processing, and Computer Vision Toolboxes)
- Standard modern web browser

## Install
Open a terminal in the project root (`D:\SIH-26038`) and install Python dependencies:
```bash
pip install -r dashboard/requirements.txt
```

## Start
Launch the backend server:
```bash
python dashboard/server.py
```
*Note: This starts the Python server. MATLAB will be automatically invoked in the background during inference.*

## Open
Navigate to the dashboard in your web browser:
```text
http://127.0.0.1:5000
```

## Run Sample
1. Click **Upload New Image** on the dashboard.
2. Select a sample fundus image.
*(A sample fundus image is not committed because the dataset is excluded from version control. Evaluators should provide any retinal fundus image for the normal screening workflow.)*
3. Click **Analyze**.
*(Note: The first inference may take longer as MATLAB initializes and loads the locked ResNet-50 model into memory.)*

## Expected Result
You should see:
1. **Layer 1 Report**: The AI Grade (0-4), referable probability, and referral recommendation.
2. **Explainability**: A Grad-CAM overlay showing the model's focus.
3. **Morphology Evidence**: A table of extracted candidate evidence (vessels, optic disc, fovea, exudates, microaneurysm, hemorrhage, neovascularization).

## Troubleshooting
**Problem:** Dashboard shows `Processing failed` during inference.
**Cause:** MATLAB integration failure, often due to an inactive MATLAB license or missing toolboxes.
**Fix:** Open MATLAB manually once, accept any license prompts, and verify the required toolboxes are installed.

**Problem:** `ModuleNotFoundError: No module named 'cv2'` during tests.
**Cause:** Missing `opencv-python` which is used by legacy validation scripts.
**Fix:** Run `pip install opencv-python`. This is not required for the core dashboard, only for legacy tests.
