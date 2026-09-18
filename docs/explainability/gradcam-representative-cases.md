# Grad-CAM Representative Cases

## Overview
This document summarizes the programmatic selection of representative Grad-CAM cases from the fully verified 439-image baseline test set. These curated images highlight both the strengths (high-confidence correct localizations) and weaknesses (high-confidence misclassifications, peripheral artifacts) of the Baseline ResNet-50 model.

**Important Disclaimer**: These images are *representative visual examples* selected based on raw computational confidence and spatial metrics. **They do not constitute proof of clinical lesion localization or clinical validity.** They are strictly observational aids intended for human review to understand model failure modes.

## Selection Methodology
The cases were automatically parsed from the `gradcam_results.csv` output file using a deterministic MATLAB script (`analyzeGradCAMRepresentativeCases.m`). 
No models were modified or re-run during this selection. All 439 previously generated files were treated as immutable.

### Selection Criteria & Metrics Used
The selection relied strictly on statistics demonstrably present in the verified CSV:
1. **Confidence**: The raw softmax score of the predicted class. High confidence was heavily prioritized for both correct and incorrect predictions to ensure the examples represent the model's strongest held internal beliefs.
2. **Centroid Distance (`CentroidDist`)**: The Euclidean distance of the heatmap's "center of mass" from the center of the image. 
   - A *low* Centroid Distance implies focused attention on the central fundus.
   - A *high* Centroid Distance implies attention anchoring to peripheral features or borders (often indicative of artifacts).
3. **Correctness (`IsCorrect`)**: Whether the prediction matched the authoritative ground truth.

*(Note: "Diffuse vs. Focused" attention is difficult to classify purely through single-scalar metrics. We utilize `CentroidDist` as a proxy for artifact-attention, but human review of the generated image is necessary to definitively confirm diffuse behavior.)*

## Selected Cases
A total of **29** unique, non-altered representative Grad-CAM overlays were copied to `outputs/gradcam/selected_cases/`.

### Breakdown:
- **Top 10 High-Confidence Correct**: The 10 correct predictions with the highest overall confidence, sorted secondarily by minimal centroid distance (most central focus).
- **Top 10 High-Confidence Misclassified**: The 10 incorrect predictions where the model was most confident in its error. These are prime candidates for failure-mode analysis.
- **Best Representative per Grade**: The single highest-confidence correct prediction for each of the 5 DR grades.
- **Most Interesting Misclassification per Grade**: The highest-confidence error associated with each true DR grade, prioritized by extreme centroid distances (peripheral artifacts) where applicable.

A detailed machine-readable log of the exact selection ranks and criteria is available in `outputs/gradcam/selected_cases/representative_cases.csv`.
