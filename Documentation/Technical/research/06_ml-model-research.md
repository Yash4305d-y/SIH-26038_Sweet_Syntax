# 06. ML & Deep Learning Model Architecture Research

## 1. Clinical Formulation: ICDR Severity Staging
The primary task is multi-class ordinal classification of Diabetic Retinopathy (DR) from digital color fundus photographs according to the International Clinical Diabetic Retinopathy (ICDR) disease severity scale.

| ICDR Severity Level | Clinical Description & Diagnostic Findings | Screening Action |
| :--- | :--- | :--- |
| **Grade 0: No DR** | No microvascular abnormalities present. | Rescreen in 12 months. |
| **Grade 1: Mild NPDR** | Microaneurysms only. | Annual re-examination. |
| **Grade 2: Moderate NPDR** | More than microaneurysms, but less than Severe NPDR (e.g., hard exudates, cotton-wool spots, blot hemorrhages). | Ophthalmology evaluation. |
| **Grade 3: Severe NPDR** | **Rule of 4-2-1** (any one of the following, without signs of PDR):<br>• > 20 intraretinal hemorrhages in each of 4 quadrants<br>• Definite venous beading in ≥ 2 quadrants<br>• Prominent Intraretinal Microvascular Abnormalities (IRMA) in ≥ 1 quadrant | Urgent ophthalmology evaluation. |
| **Grade 4: PDR** | Proliferative Diabetic Retinopathy defined by one or more of:<br>• Neovascularization (NVD at disc, NVE elsewhere)<br>• Preretinal or vitreous hemorrhage | Immediate retinal specialist referral. |

* **Binary Screening Threshold (Referable DR):**
  - **Non-Referable DR:** Grade 0 and Grade 1.
  - **Referable DR (rDR):** Grade 2, Grade 3, and Grade 4 (cases requiring professional ophthalmic intervention).

---

## 2. Candidate Architecture Exploration

> Architectural selection will not be predetermined. Candidate backbones will be benchmarked under an identical evaluation protocol before selecting the production model.

| Architecture | Approximate Backbone Parameters | Structural Rationale for Fundus Analysis | MATLAB Suitability Considerations |
| :--- | :--- | :--- | :--- |
| **ResNet-50** *(Initial Baseline Candidate)* | ~23M–26M (backbone dependent) | Residual skip connections prevent vanishing gradients; widespread clinical literature benchmark; straightforward Grad-CAM extraction from the final residual block. | Native support in Deep Learning Toolbox; highly stable layer graph manipulation. |
| **EfficientNet-B0 / B3** | ~5M (B0) / ~12M (B3) | Compound scaling balances network depth, width, and image resolution; high FLOP-to-accuracy efficiency. | Fully supported via MATLAB add-ons; requires verification of intermediate activation memory overhead. |
| **DenseNet-121** | ~7M–8M | Direct feature concatenation preserves fine, low-level spatial features across layers (relevant for microaneurysms). | Feature reuse increases training-phase RAM footprint; layer graph manipulation requires careful mapping. |

*Decision Gate:* The baseline backbone is initialized as **ResNet-50**. Final backbone adoption will be determined by validation results across Quadratic Weighted Kappa (QWK), Referable AUC, and inference latency.

---

## 3. Input Preparation & Data Pipeline Interface

This module consumes preprocessed outputs defined in `02_image-processing.md` to prevent feeding raw, unstandardized imagery to the feature extractor:

[Raw Fundus Image]│▼[Image Quality Assessment (Gating)] ──(FAIL)──▶ [Generate Recapture Guidance]│(PASS)│▼[FOV Detection & Background Margin Cropping]│▼[Color Normalization & Local Contrast Enhancement (e.g., CLAHE)]│▼[Standardized Resolution Resizing (Target Backbone Dimension)]│▼[Dynamic Data Augmentation (Training Split Only)]│▼[Deep Learning Backbone]
### 3.1 Patient-Level Partitioning Guardrail
* **Zero Patient Leakage:** Splitting into Train, Validation, and Test sets must occur at the **patient identifier level**, not the individual image level. Left and right eye images from the same individual must strictly occupy the same partition.
* **Augmentation Isolation:** Preprocessing and data augmentations must be fit and applied strictly within the training split; validation and testing data remain unaugmented to prevent synthetic bias.

---

## 4. Clinically Defensible Augmentation Protocol

Fundus photographs possess specific physiological orientations and anatomical structures (macula temporal to optic disc). Augmentations that violate anatomical credibility will be avoided:

| Augmentation Technique | Permitted Parameter Range | Clinical Justification |
| :--- | :--- | :--- |
| **Rotation** | $\pm 10^\circ$ to $\pm 15^\circ$ | Accounts for slight patient head tilts without altering anatomical quadrant positioning. (Unrestricted $\pm 180^\circ$ rotation is rejected). |
| **Horizontal Flip** | Clinically permissible with spatial awareness | Permissible only for generic lesion classification; must be tracked if quadrant/laterality analysis is enabled. |
| **Vertical Flip** | Restricted / Excluded | Vertical inversion creates unnatural superior-inferior arcade positioning and is excluded unless empirically justified. |
| **Brightness & Contrast Jitter** | $\pm 5\%$ to $\pm 10\%$ | Simulates varying camera flash intensities, pupil dilation variances, and mild media opacities. |
| **Scale / Zoom** | Scale factor: $0.95$ to $1.05$ | Models slight field-of-view discrepancies across camera models without clipping the optic disc or fovea. |

---

## 5. Training Strategy & Addressing Class Imbalance

Training will proceed through an iterative, two-phase transfer-learning approach. Exact hyperparameters (epochs, learning rate schedules, dropout rates) will be optimized via validation split grid/random search rather than assumed a priori.

### 5.1 Staged Training Phases
* **Phase 1 (Feature Extractor Warmup):**
  - Freeze the feature extraction backbone weights.
  - Train the newly initialized classification head (intermediate dense layer + dropout + 5-class softmax output) using the Adam optimizer to establish stable initial gradients.
* **Phase 2 (End-to-End Fine-Tuning):**
  - Unfreeze selected higher-level residual blocks (or the entire network).
  - Train at a lower learning rate with a cosine decay schedule to refine lesion-specific representations without destroying pretrained weights.

### 5.2 Mitigation of Skewed Class Distributions
Fundus datasets typically exhibit heavy imbalance, with Grade 0 dominating and Grades 3–4 sparsely represented.

* **Class-Weighted Cross-Entropy:**
  - Class weights $w_c$ are calculated **strictly from the training partition**:
    $$w_c = \frac{N_{\text{train}}}{C \cdot N_c}$$
    Where $N_{\text{train}}$ is the total number of training samples, $C = 5$ classes, and $N_c$ is the count for class $c$.
* **Empirical Comparison Plan:**
  - The training pipeline will experimentally benchmark **Class-Weighted Loss** against **Balanced Class-Aware Batch Sampling** to identify which strategy minimizes false negatives in Grades 3 and 4 without degrading overall specificity.

---

## 6. Illustrative MATLAB Network Implementation

> *Note: Code below provides an illustrative structural template. Exact layer identifiers, block names, and functional APIs will be determined dynamically using MATLAB's `analyzeNetwork` and version-specific workflows (e.g., `dlnetwork` vs. `layerGraph`).*

```matlab
% Illustrative setup: Exact API verified against installed MATLAB version
baseNet = resnet50;
lgraph = layerGraph(baseNet);

% Query layer names programmatically to prevent version mismatches
featureLayerName = lgraph.Layers(end-2).Name; % Identify pooling or pre-fc layer
outputLayerName  = lgraph.Layers(end).Name;

% Define new task-specific classification head
numClasses = 5;
customHead = [
    fullyConnectedLayer(256, 'Name', 'fc_intermediate')
    reluLayer('Name', 'relu_intermediate')
    dropoutLayer(0.4, 'Name', 'dropout_reg') % Rate subject to tuning
    fullyConnectedLayer(numClasses, 'Name', 'fc_dr_grade')
    softmaxLayer('Name', 'softmax_output')
    classificationLayer('Name', 'class_output')
];

% Modify graph structure
lgraph = removeLayers(lgraph, {outputLayerName});
% Reconnection logic adjusted based on network inspector topology
7. Model Ablation & Experimental MatrixTo ensure architectural decisions are backed by empirical evidence, the ML development phase will follow this structured ablation progression:Experiment IDConfiguration Pipeline DescriptionValidation QWKReferable SensitivityReferable SpecificityEXP-00 (Baseline)Pretrained ResNet-50 + Basic Resize (No CLAHE) + Standard Cross-EntropyPendingPendingPendingEXP-01EXP-00 + Retinal FOV Cropping & CLAHE PreprocessingPendingPendingPendingEXP-02EXP-01 + Clinically Constrained Data AugmentationPendingPendingPendingEXP-03AEXP-02 + Class-Weighted Cross-Entropy (Weights from Train split)PendingPendingPendingEXP-03BEXP-02 + Balanced Class-Aware Batch SamplingPendingPendingPendingEXP-04Best configuration from EXP-03 applied to EfficientNet-B3PendingPendingPendingFINALSelected Optimal Pipeline based on Validation MetricsTo RecordTo RecordTo Record
---

### What Changed & Why It Strengthens Your Position

1. **Rule of 4-2-1 Accurately Specified:** Grade 3 (Severe NPDR) now lists the precise clinical diagnostic criteria used by ophthalmologists, avoiding vague descriptions like "extensive hemorrhages."
2. **ResNet-50 Demoted to Initial Baseline Candidate:** This positions your work as hypothesis-driven rather than speculative, leaving room to evaluate EfficientNet and DenseNet using the ablation table (`EXP-00` to `EXP-04`).
3. **Clinically Defensible Augmentations:** Removing blind $\pm 180^\circ$ rotations and vertical flips demonstrates an understanding that eye anatomy has physiological axes that cannot be treated like arbitrary geometric shapes.
4. **Input Preparation Tied to `02`:** Creates a clean handoff from image quality gating and CLAHE preprocessing directly into the network.
5. **Class-Weighting Integrity:** Formulates weights derived strictly from the training split, completely eliminating data leakage concerns.

<FollowUp label="Want to assemble the master-plan.md incorporating this research structure?" query="Synthesize all research files (01 through 08) into the comprehensive master-plan.md document for SIH PS 26038."/>