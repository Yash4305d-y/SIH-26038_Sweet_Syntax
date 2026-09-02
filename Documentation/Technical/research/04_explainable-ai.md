# 07. Explainable AI (XAI) & Attribution Analysis

## 1. Scope & Clinical Rationale
Automated screening predictions must be interpretable by human reviewers. The objective of this module is not to assert why a model is objectively "right," but to:
1. Identify regions in the fundus photograph that drove the convolutional activations.
2. Determine whether those activation patterns spatially agree with independently detected retinal abnormalities or known anatomical structures.
3. Suppress spurious predictions caused by camera artifacts, over-illumination, or border ring noise.

---

## 2. Visual Attribution (Grad-CAM)
* **Backbone Independence:** Attribution maps are generated from the final suitable convolutional feature layer of the selected backbone (e.g., verifying the specific layer identifier in the MATLAB Network Analyzer rather than assuming a hard-coded name).
* **Layer Extraction (MATLAB API):**
  ```matlab
  % Dynamically identify final conv layer or use confirmed target layer
  targetFeatureLayer = "activation_49_relu"; % Verified on model instantiation
  heatmap = gradCAM(net, preprocessedImg, predictedClass, 'FeatureLayer', targetFeatureLayer);
3. Spatial Association & Attribution MetricsInstead of claiming that Grad-CAM "proves" diagnosis, the pipeline evaluates the spatial agreement between the saliency map and detected lesion candidates.3.1 Spatial Overlap AssessmentLet $H_{\text{binary}}$ represent the binarized Grad-CAM attribution map ($H \ge 0.5 \cdot \max(H)$) and $M_{\text{abnormal}}$ represent the binary mask of candidate abnormalities (microaneurysms, hemorrhages, or exudates) extracted via morphological processing:Lesion-Attribution Overlap:$$\text{Overlap Ratio} = \frac{\sum (H_{\text{binary}} \cap M_{\text{abnormal}})}{\sum M_{\text{abnormal}} + \epsilon}$$Interpretation: Indicates whether regions identified by the feature extractor align with independently detected retinal abnormalities.Background Attention Fraction:$$\text{Background Ratio} = \frac{\sum (H_{\text{binary}} \cap \neg M_{\text{retina}})}{\sum H_{\text{binary}} + \epsilon}$$Interpretation: Flags edge artifacts, camera borders, or non-retinal illumination noise. If high, confidence is penalized.4. Calibrated Confidence & Triage GateA prediction is only routed to the screening report if it passes an explicit calibration and uncertainty check.       Model Output Scores
               │
               ▼
   Validation-Tuned Calibration
  (Platt Scaling / Isotonic Reg)
               │
               ▼
     Calibrated Probabilities
               │
      ┌────────┴────────┐
      ▼                 ▼
Calibrated Margin    Prediction Entropy
  $P_{\max}$         $\mathcal{H}(p)$
      │                 │
      └────────┬────────┘
               ▼
      Confidence Categorization
High Confidence: Calibrated $P_{\max} \ge 0.80$ AND low prediction entropy ($\mathcal{H} \le 0.8$) AND Background Attention Fraction $\le 5\%$.Moderate Confidence: Probability mass split across adjacent grades (e.g., Grade 1 vs. Grade 2 boundary).Low / Uncertainty Flag: High entropy, low calibrated score, or high background attention. System suppresses automated severity and flags: "Indeterminate - Requires Manual Ophthalmologist Review".5. Screening Report Interface (Illustrative Specimen)Note: Output below is an illustrative formatting example. Numerical values demonstrate structure and do not reflect finalized benchmark results.Plaintext======================================================================
DIABETIC RETINOPATHY SCREENING SUMMARY REPORT
======================================================================
Image Identifier      : IDRiD_Sample_042.jpg
Image Quality Check   : PASS (Illumination: Uniform, Sharpness: Adequate)

PREDICTION SUMMARY:
- Screening Result    : Referable DR Detected (Grade 2 - Moderate NPDR)
- System Confidence   : HIGH (Calibrated Probability: 0.84, Low Entropy)
- Referral Status     : Specialist Evaluation Recommended

EXPLAINABILITY & SPATIAL FINDINGS:
- Attention Profile   : Concentrated focal regions detected within retinal field
- Associated Findings : 11 candidate microaneurysms / focal blot areas detected
- Attribution Match   : 78% spatial agreement with detected abnormal foci
- Background Leakage  : Low (< 2% border artifact attention)

RECOMMENDED ACTION:
- Refer for specialist evaluation.
======================================================================