# ML Handoff Contract

This document defines the formal contract for the ML component of the SIH-26038 pipeline. It specifies the expected inputs, outputs, decisions, and boundaries of the ML architecture for consumption by subsequent system roles (Role 2, 3, and 4).

## 1. Scope & Quality Gate Interface

**IMPORTANT:** The ML component (Role 1) does *not* own the final image-quality algorithm. The ML pipeline expects to receive a quality-gate decision from an upstream image-quality component. 

The conceptual flow is defined as:

1. **INPUT IMAGE**
2. ↓
3. **Image Quality Gate**
4. ↓
5. If unacceptable: **Reject / request better image**
6. ↓
7. If acceptable: **ResNet-50**
8. ↓
9. **5-class DR grading**
10. ↓
11. **Referable-DR probability**
12. ↓
13. **Calibration**
14. ↓
15. **Threshold decision**
16. ↓
17. **Grad-CAM / confidence outputs**

## 2. Input Specifications

- **Target Image:** Retinal fundus image
- **Expected Preprocessing:** The ML model natively expects a strictly sized **224x224 RGB** image.

## 3. Model Architecture

- **Selected Final Model:** Baseline ResNet-50 (Locked)
- **Problem Formulation:** 5-class Diabetic Retinopathy Screening

## 4. Output Contract

Upon successful inference, the ML pipeline produces the following outputs:

- `predicted_grade`: The integer representation of the primary classification.
  - Domain: `predicted_grade ∈ {0, 1, 2, 3, 4}`
- `P_grade_0`: Raw softmax probability for No DR
- `P_grade_1`: Raw softmax probability for Mild DR
- `P_grade_2`: Raw softmax probability for Moderate DR
- `P_grade_3`: Raw softmax probability for Severe DR
- `P_grade_4`: Raw softmax probability for Proliferative DR
- `referable_probability`: Sum of pathogenic probabilities.
  - Calculation: `P_grade_2 + P_grade_3 + P_grade_4`
- `calibrated_referable_probability`: The probability scaled by Platt scaling.
- `referable_threshold`: The fixed decision boundary.
  - Value: `0.22`
- `gradcam_heatmap`: Spatial attention visualization map.
- `confidence / uncertainty`: Derived confidence metrics of the prediction.
- `model_status`: Status of the inference execution (e.g., PASS/FAIL).

## 5. Decision Rules

The clinical screening decision is explicitly determined by the calibrated referable probability and the locked threshold.

- If `calibrated_referable_probability >= 0.22` → **Referable**
- If `calibrated_referable_probability < 0.22` → **Non-referable**

## 6. Clinical Disclaimer

**IMPORTANT:** This is a screening classification pipeline intended to flag patients for further evaluation. It is explicitly **not** a clinical diagnostic system. Grad-CAM provides spatial attention visualization for model interpretability; it should not be interpreted as proof that the model detected a specific clinical lesion.
