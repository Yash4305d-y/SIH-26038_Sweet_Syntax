# Grad-CAM Explainability Prototype

## Overview
This document describes the first prototype implementation of Grad-CAM explainability for the SIH PS 26038 Diabetic Retinopathy screening project.

**Disclaimer**: This is currently an explainability prototype used to visualize the network's spatial attention. It is not yet clinically validated.

## Network Configuration
- **Model Used**: Baseline ResNet-50 (`D:\SIH-26038\models\baseline_resnet50_smoketest.mat`)
- **Target Layer**: `res5c_branch2c` (The final convolutional layer, identified safely by direct dlnetwork inspection)
- **Output Class Count**: 5 DR Classes

## Image Preprocessing
- **Preprocessing Pipeline**: The retinal images are loaded and resized strictly to `224x224x3`. This perfectly mirrors the exact preprocessing used during Baseline evaluation (via `augmentedImageDatastore`). No normalization, CLAHE, or morphological augmentations are introduced in this phase to guarantee that the Grad-CAM outputs map exactly to the inference conditions.

## Image Selection Strategy
Instead of blindly processing all 439 test images, a focused, representative subset was selected from `baseline_test_predictions.csv`:
- One correctly classified example from each of the 5 DR classes (if available).
- Up to 3 misclassified examples to observe the network's attention when it makes an error.

## Prediction Verification
Before extracting Grad-CAM heatmaps, each selected image is passed through the network in a standard forward pass (`predict`). The resulting predicted class is explicitly verified against the stored prediction in `predictions.mat` (or in this case, `baseline_test_predictions.csv`).
If there is a mismatch (e.g., due to an inconsistent preprocessing step), the script halts immediately with an error rather than generating invalid heatmaps.

## Grad-CAM Method
The prototype utilizes MATLAB's built-in `gradCAM` functionality compatible with modern `dlnetwork` architectures (R2023a+). 
- The image is cast to a formatted `dlarray` (`'SSC'`).
- The `gradCAM` algorithm computes the gradients of the target class score with respect to the feature map activations of the target layer (`res5c_branch2c`).
- The gradients are globally average-pooled to compute importance weights.
- The feature maps are linearly combined using these weights, and a ReLU is applied to isolate positive influence.
- The resulting heatmap is resized to `224x224`, normalized, colored using a `jet` colormap, and overlaid onto the original image at 50% opacity.

## Outputs
All generated overlays and summaries are stored in:
`D:\SIH-26038\results\gradcam\prototype\`

Outputs include:
1. **Overlay Images**: Named informatively as `<image_id>_GT<true>_Pred<pred>_<correct/wrong>.png`
2. **Contact Sheet**: `contact_sheet.png` (A single collage image for rapid review of all selected prototypes)
3. **Summary Table**: `prototype_summary.csv` (Contains image filenames, ground truth, prediction, confidence score, and target layer)
