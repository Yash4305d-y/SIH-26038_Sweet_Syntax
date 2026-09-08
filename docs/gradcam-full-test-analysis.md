# Grad-CAM Final Test Set Analysis

## Overview
This document summarizes the final, definitive generation of Grad-CAM explainability heatmaps for the **entire 439-image test set** using the Baseline ResNet-50 network for the SIH PS 26038 Diabetic Retinopathy screening project.

**Important Disclaimer**: This analysis focuses on the technical generation and qualitative observation of Grad-CAM heatmaps. **These observations do not constitute clinically validated findings** and the methodology itself does not prove clinical validity. The goal is to provide explainability prototypes for subsequent human review.

## Authoritative Evaluation
The explicit standard for model evaluation remains the **authoritative evaluation result**: `predictions.mat` / `baseline_test_predictions.csv`. 
The Grad-CAM script acts solely as an explainability pipeline; it does not overwrite or alter the baseline benchmarking metrics.

## Configuration & Processing
- **Model Used**: Baseline ResNet-50 (`D:\SIH-26038\models\baseline_resnet50_smoketest.mat`)
- **Target Layer**: `res5c_branch2c`
- **Total Images Processed**: 439 images
- **Preprocessing Pipeline (Synchronized)**: Original retinal images are processed dynamically via `augmentedImageDatastore([224 224])`. This perfectly synchronizes the interpolation and scaling behavior with the exact pipeline executed during the original Baseline evaluation.
- **Prediction Verification Result**: **100% Match**. Before generating heatmaps, every newly processed inference prediction was explicitly verified against `baseline_test_predictions.csv`.
- **Number of Mismatches**: 0 mismatches. (The 7 prior mismatches were successfully eliminated after diagnosing the preprocessing discrepancy).
- **Number of Grad-CAM Overlays Generated**: 439

## Outputs and Statistics
- **Output Location**: All final Grad-CAM overlays are stored logically in `outputs/gradcam/final/`, separated by `/correct` and `/wrong` subdirectories and further by `class_X`.
- **Machine-Readable Summary**: Detailed statistics are saved in `outputs/gradcam/final/gradcam_results.csv`, and split into:
  - `gradcam_correct.csv`
  - `gradcam_misclassified.csv`
  - `gradcam_class_X.csv` (for each DR grade)
- **Extracted Explanatory Statistics**: 
  - **Mean Activation**: The average normalized intensity of the heatmap.
  - **Max Activation**: The peak intensity (scaled to 1.0).
  - **Activated Area Percentage**: The percentage of pixels with normalized activation > 0.3. High percentages may indicate **diffuse attention**, where the network failed to localize specific features.
  - **Centroid Distance**: The Euclidean distance of the heatmap's "center of mass" from the image center (112, 112). Large distances strongly suggest **potential artifact sensitivity** (e.g., the network focusing on peripheral lighting, borders, or text rather than the central retina).

## Qualitative Observations (Representative Categories)
Based on qualitative sampling (see `outputs/gradcam/final/representative_contact_sheet.png`):
1. **High-Confidence Correct Predictions**: For true Grade 0 and advanced DR cases, the model frequently shows focused activation in plausible retinal regions (macula, optic disc vicinity, or visible exudates/hemorrhages).
2. **High-Confidence Misclassifications & Potential Artifact Sensitivity**: Several highly confident misclassifications appear to anchor their attention inappropriately near the circular border of the fundus crop, highlighting peripheral artifacts or camera lens reflections.
3. **Diffuse Attention**: In ambiguous classifications, the network sometimes exhibits unusually diffuse attention, scattering low-intensity activations sporadically across the image rather than finding a definitive lesion.

## Limitations
- **Resolution Constraint**: ResNet-50 operates at `224x224`. Fine microaneurysms that are visible in the original high-resolution APTOS images may be lost during resizing, causing Grad-CAM to highlight broad regions instead of pinpointing exact microlesions.
- **Model Capability**: This is the unweighted Baseline ResNet-50 (smoke test). Its internal feature representations might not be as robust or cleanly separated as those in the optimized/weighted models.
- **Explainability vs Causality**: Grad-CAM highlights what regions activated the final convolutional layer the most; it does not explicitly explain *why* the network considers those regions indicative of a specific DR grade.
