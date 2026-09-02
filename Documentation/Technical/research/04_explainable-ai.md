 07. Explainable AI (XAI) & Lesion-Evidence Correlation

## 1. Why Explainability Matters
In medical screening, a standalone prediction like *"Grade 2: Moderate DR (91% confidence)"* is not enough. Clinicians need to see:
1. **Where** the model is looking (to ensure it is not focusing on camera artifacts or dust).
2. **What** anatomical features caused the decision (microaneurysms, hemorrhages, or exudates).

---

## 2. Core Explainability Methods

### 2.1 Grad-CAM (Visual Attribution)
- **What it does:** Computes gradients at the final convolutional layer of ResNet-50 (`activation_49_relu`) to produce a visual heatmap showing where the model focused.
- **MATLAB API:** `gradCAM(net, preprocessedImage, predictedClass, 'FeatureLayer', 'activation_49_relu')`.

### 2.2 Lesion-Evidence Correlation (Key Differentiator)
Most standard projects stop at displaying a colorful Grad-CAM heatmap. Our pipeline connects the heatmap directly to classical morphological lesion detection:

Preprocessed Fundus Image│┌─────┴────────────────────────┐▼                              ▼ResNet-50 Grad-CAM          Morphological Filter(Heatmap $H$)               (Lesion Candidate Mask $M$)│                              │└──────────────┬───────────────┘▼Overlap / Coherence Check▼Final Evidence Summary in Report
- **Saliency Coherence Score:**
  $$\text{Coherence} = \frac{\text{Heatmap Active Region} \cap \text{Detected Lesion Mask}}{\text{Total Detected Lesion Mask}}$$
- If the heatmap strongly aligns with detected microaneurysms or hemorrhages, the report confirms high diagnostic coherence.

---

## 3. Calibrated Confidence (Knowing When to Flag for Human Review)
Instead of relying on raw Softmax scores (which can be overconfident), we combine two checks:
- **Softmax Probability Margin:** Is top-1 probability $\ge 0.75$?
- **Prediction Entropy:** Is uncertainty across all 5 classes low?

### Confidence Levels:
- **HIGH:** High probability, low entropy, clear image quality.
- **MEDIUM:** Probabilities split between two adjacent classes (e.g., Grade 1 vs. Grade 2).
- **LOW / REVIEW REQUIRED:** High entropy or poor image quality $\rightarrow$ Direct referral to ophthalmologist without an automated final grade.

---

## 4. Final Output: Structured Clinical Report
Instead of raw numbers or chatbot text, generate a clean summary:

```text
============================================================
DIABETIC RETINOPATHY SCREENING REPORT
============================================================
Image Quality Status  : PASS (Clear focus, uniform lighting)

FINDINGS:
- Predicted DR Grade  : Grade 2 (Moderate NPDR)
- Referral Required   : YES (Referable DR)
- System Confidence   : HIGH (0.84)

EVIDENCE & EXPLAINABILITY:
- Attention Region    : Temporal quadrant focus
- Morphological Match : Microaneurysm cluster detected
- Coherence Score     : 81% overlap between Grad-CAM & lesions
- Recommended Action  : Routine ophthalmology consult (30 days)
============================================================
