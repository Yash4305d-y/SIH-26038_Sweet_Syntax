# MATLAB Technical Research — SIH 26038
## Explainable AI for Diabetic Retinopathy Screening in Rural India

> **Consolidated research document**
>
> This document is the consolidated union of three independently prepared MATLAB research documents. Repeated material has been merged, unique technical details have been retained, and conflicting claims have been explicitly resolved or flagged rather than silently discarded.
>
> **Target release:** MATLAB R2025a or later is recommended for the current APIs described here. Exact function/toolbox availability should be checked against the team's installed release before implementation.
>
> **Primary role of MATLAB:** fundus-image quality assessment, preprocessing, AI training/inference, explainability, validation, reporting, and integration with Simulink for operational/telemedicine simulation.
>
> **Important scope rule:** this is a screening prototype, not a clinically validated diagnostic device. Lesion-level detectors, confidence calibration, and operational values must not be presented as clinically validated unless independently trained, tested, and validated.

---

# 1. Purpose

The objective of Smart India Hackathon Problem Statement 26038 is to develop an automated, explainable, and tele-operable Diabetic Retinopathy (DR) screening workflow suitable for Primary Health Centers (PHCs) and Community Health Centers (CHCs) in rural India.

The proposed MATLAB-based system should:

- Accept fundus photographs from a screening point.
- Reject ungradable images before expensive downstream processing or network transmission.
- Enhance and standardize acceptable fundus images.
- Perform automated DR screening and severity estimation.
- Generate visual evidence using explainable AI.
- Produce a clinician-reviewable report.
- Route referable or uncertain cases toward ophthalmologist review.
- Model acquisition, processing, network, queueing, and reviewer bottlenecks using Simulink/SimEvents.
- Support an eventual edge/telemedicine deployment story without overclaiming clinical readiness.

## 1.1 Why MATLAB is appropriate

MATLAB is particularly suitable because this project combines two different engineering problems:

1. **Image analysis and AI**
2. **Operational/system simulation**

MATLAB provides a unified environment for:

- Image enhancement and morphology.
- Retinal structure analysis.
- Deep-learning training and inference.
- Native Grad-CAM explainability.
- Statistical validation.
- Automated reporting.
- Simulink-based operational modeling.

The three research sources consistently identify MATLAB's strongest project-specific advantages as:

- A coherent image-processing and deep-learning workflow.
- Native, documented explainability through `gradCAM`.
- A direct bridge between algorithmic processing and Simulink system simulation.
- Reduced environment/package fragmentation compared with a multi-library Python stack.
- Strong support for classical image processing that can complement deep learning.

## 1.2 MATLAB versus Python

Python remains useful and may be preferable for:

- Accessing large open-source model repositories.
- Reusing PyTorch-first research implementations.
- External pretrained models that have no convenient MATLAB equivalent.
- Data utilities and state-of-the-art research code.

MATLAB is stronger for this specific SIH workflow when the team wants:

- One environment for image processing, AI, validation, and simulation.
- Native `gradCAM`.
- Integrated visualization and engineering workflows.
- Simulink/SimEvents operational modeling.
- A presentation-ready engineering model rather than only a model-training notebook.

MATLAB is weaker where the ecosystem is Python-first, especially:

- Large public DR datasets and their community tooling.
- Published DR baselines implemented only in PyTorch.
- Some state-of-the-art lesion-level segmentation architectures.
- Rapid access to the broader open-source AI ecosystem.

**Project decision:** use MATLAB as the primary system-development environment, while allowing Python/external models or datasets when they materially reduce implementation risk.

---

# 2. MATLAB Role in Our System

| System Stage | MATLAB Role | Main Capability / Functions | Toolbox | Built-in vs Custom | Priority |
|---|---|---|---|---|---|
| Image Input | Read and manage fundus images | `imread`, `imageDatastore`, `imfinfo`, optionally `dicomread` | Image Processing / MATLAB | Built-in | Essential |
| Image Quality Assessment | Blur, exposure, FOV and gradability assessment | `brisque`, `niqe`, `piqe`, Laplacian/gradient metrics, `imhist`, `regionprops` | Image Processing | Mixed | Essential |
| Enhancement | CLAHE, denoising, normalization and cropping | `adapthisteq`, `imgaussfilt`, `medfilt2`, `imguidedfilter`, `imadjust`, `imresize` | Image Processing | Built-in + tuning | Essential |
| Retinal ROI | Isolate circular retinal field | Thresholding, `bwareafilt`, `regionprops`, morphology | Image Processing | Custom pipeline | Essential |
| Optic Disc | Locate disc | `imfindcircles`, brightness, morphology, vessel-convergence heuristics | Image Processing / Computer Vision | Custom | Recommended |
| Fovea | Estimate foveal location | Anatomical offset heuristic or trained model | Image Processing / Deep Learning | Custom | Optional |
| Vessel Analysis | Enhance or segment retinal vessels | `fibermetric`, morphology, `unet`, `semanticseg` | Image Processing / Computer Vision / Deep Learning | Classical or trained | Recommended |
| Microaneurysm Detection | Generate and classify tiny dark candidates | `imbothat`, `regionprops`, high-resolution CNN/segmenter | Image Processing / Deep Learning | Custom | Difficult |
| Exudate Detection | Detect bright lesions | `imtophat`, Lab/green-channel thresholding, U-Net | Image Processing / Computer Vision / Deep Learning | Custom/trained | Recommended |
| Hemorrhage Detection | Detect dark irregular lesions | `imbothat`, morphology, U-Net/detector | Image Processing / Deep Learning | Custom/trained | Difficult |
| Neovascularization | Identify abnormal vascular proliferation | Vessel density/tortuosity or dedicated model | Image Processing / Deep Learning | Custom | Research-level |
| DR Classification | Binary referable-DR and 5-class grading | `imagePretrainedNetwork`, `trainnet`, `dlnetwork`, `minibatchpredict` | Deep Learning | Requires training/fine-tuning | Essential |
| Explainability | Generate class-specific evidence maps | `gradCAM`, optionally `occlusionSensitivity`, `imageLIME` | Deep Learning | Built-in | Essential |
| Confidence | Score and calibrate predictions | Softmax, `rocmetrics`, custom calibration / `fitglm` | Deep Learning / Statistics & ML | Mixed | Recommended |
| Validation | Evaluate screening performance | `confusionmat`, `confusionchart`, `rocmetrics`, `auc`, `perfcurve`, `cvpartition` | Statistics & ML | Built-in | Essential |
| Reporting | Generate annotated patient report | `exportgraphics`, `imoverlay`, `insertShape`, `jsonencode`, `writetable`, Report Generator | MATLAB / Computer Vision / Report Generator | Mixed | Recommended |
| Human Review | Display results for clinician review | App Designer, MATLAB UI | MATLAB | Custom | Recommended |
| Operations Simulation | Model arrival, processing, bandwidth and review queues | Simulink, MATLAB Function blocks, Stateflow, SimEvents | Simulink / SimEvents | Custom model | Essential/Recommended |

## 2.1 Core responsibility split

### MATLAB

MATLAB should own the **algorithmic core**:

```text
Fundus Image
    ↓
Image Quality Assessment
    ↓
Enhancement / Standardization
    ↓
Optional Anatomical / Lesion Analysis
    ↓
DR Classification
    ↓
Grad-CAM / Evidence
    ↓
Confidence / Thresholding
    ↓
Clinical Report
```

### Simulink

Simulink should own the **operational/system layer**:

```text
Patient Arrival
    ↓
Fundus Capture
    ↓
Local IQA
    ├── Ungradable → Recapture
    └── Gradable
          ↓
      Processing
          ↓
    Network Transfer
          ↓
    AI / Triage
          ↓
  Ophthalmologist Queue
          ↓
   Review / Referral
```

Simulink should not be used to unnecessarily reimplement the entire image-processing pipeline.

---

# 3. Required Toolboxes

## 3.1 Image Processing Toolbox

**Decision: Essential**

Image Processing Toolbox is the foundation of the fundus pipeline.

It supports:

- Image input.
- Color-channel extraction.
- CLAHE.
- Denoising.
- Morphology.
- Thresholding.
- Connected components.
- Region measurement.
- Geometric normalization.
- Retinal-field masking.
- Basic DICOM read/write workflows.

### Important functions

| Function | Purpose | DR Application | Limitation |
|---|---|---|---|
| `imread` | Read images | Fundus input | Dataset-specific label handling may still be required |
| `imageDatastore` | Manage image collections | Training/inference datasets | Custom labels may require helper functions |
| `imfinfo` | Read image metadata | Image/session metadata | Does not perform clinical interpretation |
| `adapthisteq` | CLAHE | Fundus contrast enhancement | Must be applied to an appropriate 2-D channel; aggressive settings can amplify artifacts |
| `imgaussfilt` | Gaussian smoothing | Denoising | Can blur fine lesions |
| `medfilt2` | Median filtering | Sensor/salt-and-pepper noise suppression | Large kernels can remove tiny lesions |
| `imguidedfilter` | Edge-preserving smoothing | Reduce noise while preserving vessels | Requires parameter tuning |
| `imadjust` | Intensity/gamma adjustment | Exposure normalization | Camera-specific tuning required |
| `imhist` | Histogram analysis | Exposure/illumination checks | Thresholds are dataset/camera dependent |
| `imbinarize` | Binarization | ROI/candidate masks | Global thresholding can fail under uneven illumination |
| `adaptthresh` | Adaptive thresholding | Non-uniform illumination | Still requires parameter tuning |
| `imfill` | Fill binary holes | Retinal/FOV masks | Depends on mask quality |
| `bwareafilt` | Filter connected components by area | Remove small noise / select candidate sizes | Area thresholds are dataset dependent |
| `bwconncomp` | Connected-component analysis | Lesion candidate generation | Depends on reliable segmentation |
| `regionprops` | Measure shape/geometry | Area, centroid, eccentricity, bounding box, etc. | Measurement only; it does not detect lesions itself |
| `imerode` / `imdilate` | Morphology | Mask cleanup | Structuring-element choice matters |
| `imopen` / `imclose` | Morphological cleanup | Lesion/ROI processing | Can remove genuine structures if overused |
| `imtophat` | Bright-feature extraction | Exudate candidates | Bright optic disc can cause false positives |
| `imbothat` | Dark-feature extraction | Microaneurysm/hemorrhage candidates | Vessels and shadows can produce false positives |
| `fibermetric` | Hessian/Frangi vesselness enhancement | Retinal vessel enhancement | Enhancement only; thresholding/segmentation is separate |
| `imfindcircles` | Circular Hough transform | Optic-disc candidate localization | Sensitive to parameter tuning and bright lesions |
| `imresize` | Resize images | Standardize network input | Interpolation can affect small lesions |
| `imcrop` | Crop image | Retinal/network ROI | Incorrect crop can remove pathology |
| `imrotate` | Geometric augmentation/normalization | Training augmentation | Excessive rotation may be inappropriate for some pipelines |
| `rgb2gray` | Convert to grayscale | Quality metrics and classical CV | Loses color information |
| `rgb2lab` / `lab2rgb` | CIE Lab processing | Exudate/color-based analysis and luminance enhancement | Conversion must be handled consistently |
| `psnr`, `ssim`, `immse` | Reference-based quality measures | Compare preprocessing/enhancement methods | Not suitable as standalone no-reference gradability measures |
| `dicomread` | Read DICOM | Clinical camera/PACS integration | Basic DICOM handling does not equal full PACS integration |

### Key implementation rule

Do not describe Image Processing Toolbox as a ready-made diabetic-retinopathy detector. It provides generic image-processing primitives from which the team must construct custom retinal algorithms.

---

## 3.2 Computer Vision Toolbox

**Decision: Strongly Recommended**

Computer Vision Toolbox is important for:

- Semantic segmentation workflows.
- Object detection.
- Annotation.
- Bounding-box operations.
- Segmentation evaluation.
- Deep-learning-era computer-vision functions.

### Current API considerations

The consolidated sources highlight an important version issue:

- `unet` is the current U-Net creation route described in the research.
- Older `unetLayers` APIs have been removed in the newer workflow described by the sources.
- The older `deeplabv3plusLayers` convenience API is also described as removed.
- Therefore, do not build the MVP around removed APIs without checking the exact MATLAB release.

### Relevant capabilities

| Capability | Application | Status |
|---|---|---|
| `unet` | Vessel, exudate, hemorrhage or optic-disc segmentation | Recommended |
| `semanticseg` | Segmentation inference | Built-in workflow |
| `evaluateSemanticSegmentation` | Pixel-level segmentation evaluation | Useful for validation |
| `yolov4ObjectDetector` | Bounding-box lesion/optic-disc detection | Optional |
| Image Labeler | Manual annotation | Useful if annotations are required |
| Medical Image Labeler | Medical annotation workflows | Optional |
| `bboxOverlapRatio` | Bounding-box IoU | Useful for object-detection evaluation |
| `imregister` / geometric registration | Longitudinal/multimodal alignment | Low priority for single-image MVP |

### Toolbox boundary

Conventional preprocessing such as CLAHE, cropping, denoising and color normalization belongs primarily to **Image Processing Toolbox**.

Computer Vision Toolbox becomes more important when the team uses:

- U-Net.
- Object detectors.
- Annotation tools.
- Segmentation evaluation.
- Bounding-box workflows.

---

## 3.3 Deep Learning Toolbox

**Decision: Essential**

Deep Learning Toolbox is the central AI toolbox.

It supports:

- Transfer learning.
- Fine-tuning pretrained networks.
- `dlnetwork`.
- `trainnet`.
- `trainingOptions`.
- Minibatched inference.
- Semantic segmentation workflows.
- Grad-CAM.
- Occlusion sensitivity.
- LIME-style image explanations.
- GPU execution when the required hardware/toolboxes are available.

### Core functions

| Function | Purpose | Project Use |
|---|---|---|
| `imagePretrainedNetwork` | Load supported pretrained models | Transfer learning |
| `trainnet` | Modern network training | DR classifier/segmenter training |
| `trainingOptions` | Configure training | Optimizer, learning rate, validation, execution environment |
| `dlnetwork` | Flexible neural-network representation | Custom training and XAI workflows |
| `minibatchpredict` | Batch inference | Large test/inference datasets |
| `gradCAM` | Gradient-based visual explanation | Primary XAI method |
| `occlusionSensitivity` | Perturbation-based explanation | Secondary XAI method |
| `imageLIME` | Local image explanation | Optional XAI comparison |
| `activations` | Inspect intermediate features | Model debugging/analysis |

### Training responsibility

The team must still implement:

- Dataset curation.
- Patient-level train/validation/test separation where possible.
- Label reconciliation.
- Class balancing.
- Data augmentation.
- Loss-function selection.
- Threshold selection.
- Clinical error analysis.
- External/held-out evaluation.

MATLAB does not make these clinical-validation tasks automatic.

---

# 4. Model Architecture Assessment

## 4.1 Recommended classification models

| Architecture | MATLAB Support | DR Grading | Edge Suitability | Recommendation |
|---|---|---|---|---|
| **ResNet-101** | Supported in the official DR example described by the research | Strong; directly evidenced by MathWorks' DR example | Heavy | Proven reference model |
| **ResNet-50** | Supported | Strong baseline | Moderate | Recommended baseline |
| **ResNet-18** | Supported | Good lightweight baseline | Good | Recommended when compute is limited |
| **EfficientNet-B0** | Supported | Good accuracy/compute tradeoff | Very good | Strong practical choice |
| **EfficientNet-B1–B7** | Not treated as first-class supported names in the consolidated research | Potentially useful but import may be required | Varies | Do not assume direct support |
| **MobileNet-v2** | Supported | Reasonable | Excellent | Strong edge/low-power candidate |
| **DenseNet-201** | Supported | Reasonable | Heavy | Optional comparison |

### Important conclusion

The research sources contain two slightly different recommendations:

- **ResNet-101** is the strongest evidence-backed reference because MathWorks' official DR example uses it.
- **EfficientNet-B0 / ResNet-18 / MobileNet-v2** are more attractive for a resource-constrained rural deployment story.

Therefore:

> **Recommended implementation strategy:** reproduce a proven ResNet-based path first if the team needs the lowest technical risk; evaluate EfficientNet-B0 or ResNet-18 as the practical MVP/edge model.

---

# 5. Segmentation and Detection Architectures

## 5.1 U-Net

**Recommendation: Primary segmentation architecture**

Use U-Net for:

- Retinal vessel segmentation.
- Exudate segmentation.
- Hemorrhage segmentation.
- Potential optic-disc segmentation.

Advantages:

- Preserves spatial detail through skip connections.
- Well suited to pixel-level segmentation.
- Straightforward MATLAB workflow.
- More realistic for an SIH prototype than building a complex custom segmentation architecture.

Limitations:

- Requires pixel-level annotations.
- Full high-resolution images can consume substantial GPU memory.
- Patch/tiling strategies may be required.

## 5.2 DeepLab v3+

DeepLab v3+ appears in some source material as an advanced segmentation option.

However, the consolidated research explicitly flags the older `deeplabv3plusLayers` convenience API as removed in the newer workflow.

**Decision:** do not make DeepLab v3+ the MVP dependency. Use U-Net unless the team has verified a current implementation path for its exact MATLAB release.

## 5.3 YOLO v4

`yolov4ObjectDetector` can be used when lesions are represented as bounding boxes rather than pixel masks.

Useful for:

- Lesion localization.
- Optic-disc detection.
- A separate object-detection demonstration.

Limitations:

- Requires bounding-box annotations.
- Tiny lesions such as microaneurysms are difficult for ordinary detection pipelines.
- It is not a replacement for the whole-image DR classifier.

---

# 6. Medical Imaging Toolbox

**Decision: Optional for the SIH 2-D fundus-photo MVP**

The core project is based on 2-D RGB fundus photographs, commonly stored as JPEG/PNG/TIFF.

The consolidated research identifies Medical Imaging Toolbox as more relevant to:

- Advanced DICOM workflows.
- PACS interoperability.
- NIfTI/NRRD workflows.
- 3-D/volumetric medical imaging.
- OCT or other future volumetric retinal imaging.
- Advanced medical annotation/registration.

Basic DICOM support is already available through Image Processing Toolbox according to the research.

### When Medical Imaging Toolbox becomes relevant

Use it if the project later needs:

- Clinical fundus-camera DICOM integration.
- PACS connectivity.
- Advanced medical-image workflows.
- OCT/volumetric retinal imaging.

### Important distinction

The fact that a MathWorks DR example appears under Medical Imaging Toolbox documentation does **not** by itself mean that Medical Imaging Toolbox is a functional dependency of the 2-D DR classifier.

---

# 7. Statistics and Machine Learning Toolbox

**Decision: Strongly Recommended**

This toolbox provides the statistical layer required for credible evaluation.

## 7.1 Relevant functions

| Function | Use |
|---|---|
| `confusionmat` | Compute confusion matrices |
| `confusionchart` | Visualize classification errors |
| `rocmetrics` | ROC/operating-point metrics |
| `auc` | Area under ROC/related curves |
| `perfcurve` | ROC/precision-recall analysis |
| `cvpartition` | Train/test/cross-validation partitioning |
| `fitcsvm` | Classical SVM baseline |
| `fitctree` | Tree-based baseline |
| `fitcensemble` | Ensemble baseline |
| `fitclinear` | Linear/logistic-style baseline |
| `fitglm` | Logistic calibration/custom statistical models |

## 7.2 Metrics to report

For binary referable-DR screening:

- Sensitivity.
- Specificity.
- PPV.
- NPV.
- F1 score.
- ROC-AUC.
- Confusion matrix.
- Operating threshold.

For 5-class grading:

- Per-class precision/PPV.
- Per-class recall/sensitivity where meaningful.
- F1 score.
- Confusion matrix.
- Macro/weighted summaries where appropriate.

### Important caution

Do not claim that a model is clinically safe merely because its accuracy is high.

A screening system should emphasize:

> **Sensitivity, calibration, false-negative analysis, image quality, and external/generalization behavior.**

---

# 8. Simulink and SimEvents

## 8.1 Purpose

Simulink should represent the **operational digital model** of rural tele-screening.

It can model:

- Patient arrival rates.
- Image acquisition.
- Image-quality rejection.
- Recapture loops.
- AI processing time.
- Network delays.
- Bandwidth limitations.
- Packet loss/delay assumptions.
- Ophthalmologist capacity.
- Review queues.
- Priority routing.
- Throughput.
- Latency.
- Queue length.
- Resource utilization.
- Multiple rural centers feeding a district-level review hub.

## 8.2 Plain Simulink versus SimEvents

### Plain Simulink

Plain Simulink can model:

- Rate-based processing.
- Delays.
- Signal flow.
- State transitions.
- Coarse throughput models.
- Stateflow-based accept/reject/recapture logic.
- Approximate queue behavior.

### SimEvents

SimEvents is a separate add-on and is preferable when the team needs true discrete-event behavior.

Typical blocks include:

- Entity Generator.
- Entity Queue.
- Entity Server.
- Entity Terminator.
- Resource Pool.
- Resource Acquirer.
- Resource Releaser.

This allows each patient/image to be treated as an individual entity moving through the system.

## 8.3 Recommended SimEvents mapping

| Real-world process | SimEvents model |
|---|---|
| Fundus image/patient arrival | Entity Generator |
| AI-processing backlog | Entity Queue |
| IQA + AI processing | Entity Server |
| Network delay | Entity Server or explicit delay |
| Ophthalmologist review backlog | Entity Queue |
| Limited ophthalmologist availability | Resource Pool + Acquirer/Releaser |
| Ungradable image | Routing back to recapture queue |
| Multiple PHCs | Multiple Entity Generators feeding shared resources |
| District review hub | Shared queue/server/resource structure |

## 8.4 Measured rather than assumed service times

A major design recommendation from the research is:

> **Measure actual MATLAB pipeline execution time and feed those measurements into the Simulink/SimEvents model instead of inventing a processing-time number.**

This makes the simulation defensible.

## 8.5 Network assumptions

The research documents example rural uplink scenarios such as:

- 2G/4G connectivity.
- Approximately 64–256 kbps in an illustrative constrained scenario.
- Variable latency.
- Packet loss/delay.

These values should be treated as **simulation assumptions**, not measured field performance, unless the team has real field measurements.

---

# 9. Image Quality Assessment (IQA)

## 9.1 Why IQA comes first

An ungradable fundus image should not be:

- Sent unnecessarily over a constrained network.
- Passed into the classifier.
- Presented as a valid negative result.
- Allowed to consume ophthalmologist review capacity without a quality check.

Therefore:

```text
Capture
  ↓
IQA
  ├── Ungradable → Recapture
  └── Gradable → Continue
```

## 9.2 Recommended composite IQA

Use multiple signals instead of one metric.

| Quality Aspect | Method | Output |
|---|---|---|
| Blur/focus | Variance of Laplacian / gradient energy | Sharpness score |
| Exposure | Luminance histogram | Under/overexposure flags |
| Saturation | Near-black/near-white pixel fraction | Exposure flag |
| FOV | Circular retinal mask and ROI coverage | FOV score |
| Overall gradability | Weighted rule or lightweight classifier | Accept/reject |

## 9.3 BRISQUE / NIQE / PIQE

MATLAB provides:

- `brisque`
- `niqe`
- `piqe`

These are useful no-reference image-quality metrics.

However, the consolidated research highlights a critical limitation:

> Their default statistical assumptions are based on natural-image statistics rather than fundus-specific clinical gradability.

Therefore, do not treat their raw scores as a clinically validated fundus gradability classifier.

A stronger approach is:

```text
BRISQUE / NIQE / PIQE
        +
Blur metric
        +
Exposure metric
        +
FOV metric
        ↓
Hybrid gradability decision
```

If enough labeled fundus-quality data are available, a custom quality model can be trained using the relevant MATLAB fitting functionality.

## 9.4 Example classical focus metric

A simple custom focus score can be:

\[
\text{FocusScore} = \operatorname{var}(\nabla^2 I_G)
\]

where \(I_G\) is the green channel.

A MATLAB implementation can use a Laplacian filter through `imfilter`.

## 9.5 Exposure checks

The research contains illustrative thresholds such as:

- More than 30% of retinal-field pixels below intensity 15 → possible underexposure.
- More than 5% above intensity 245 → possible overexposure.

These are **engineering starting points only** and must be validated against the actual camera/dataset.

## 9.6 FOV completeness

Possible method:

```text
Fundus RGB
   ↓
Retinal-field threshold
   ↓
Fill holes
   ↓
Largest connected component
   ↓
Circularity + area ratio
   ↓
FOV adequacy
```

---

# 10. Image Enhancement and Standardization

## 10.1 Recommended sequence

1. Read RGB fundus image.
2. Preserve original image for reporting.
3. Isolate retinal field.
4. Extract green channel and/or convert to Lab.
5. Apply CLAHE.
6. Apply denoising only if required.
7. Normalize color/intensity.
8. Crop/resize to network input.
9. Apply exactly the same preprocessing during inference that was used during training.

## 10.2 CLAHE

`adapthisteq` is the primary enhancement function.

Typical use:

```matlab
I_green = I(:,:,2);
I_clahe = adapthisteq(I_green);
```

One source provides an example using:

```matlab
I_clahe = adapthisteq(I_green, ...
    'ClipLimit', 0.02, ...
    'Distribution', 'rayleigh');
```

Another source notes that MathWorks' own DR example used a particular CLAHE configuration as part of its training-data preparation.

**Decision:** use the official example's preprocessing as a reproducible starting point, then tune and validate on the team's dataset.

### CLAHE limitation

Too much local contrast enhancement can:

- Amplify sensor noise.
- Strengthen choroidal texture.
- Change lesion appearance.
- Create train/inference distribution mismatch.

## 10.3 Denoising

Possible options:

- `imgaussfilt`
- `medfilt2`
- `wiener2`
- `imguidedfilter`
- `imbilatfilt`

Use denoising only when justified by the image-quality characteristics.

Do not blindly apply a strong filter because tiny lesions can be weakened or removed.

## 10.4 Illumination normalization

A custom approach can estimate low-frequency background illumination using:

- Large-kernel Gaussian filtering.
- Large morphological opening.
- Median/background estimation.

Then subtract or normalize against the estimated background.

There is no single universal built-in "fundus illumination normalization" function.

## 10.5 Color normalization

Possible methods:

- Per-channel mean/std normalization.
- Lab luminance processing.
- Consistent camera-specific normalization.

Again, the same preprocessing must be used during training and inference.

---

# 11. Retinal Vessel Segmentation

Vessel analysis is useful for:

- Anatomical structure understanding.
- Optic-disc localization.
- Separating vessel-like structures from lesion candidates.
- Producing interpretable structural evidence.

## 11.1 Classical approach

```text
Green Channel
    ↓
Top-Hat / Contrast Enhancement
    ↓
Hessian Vesselness (`fibermetric`)
    ↓
Threshold
    ↓
Morphological Cleanup
    ↓
Vessel Mask
```

`fibermetric` is a vesselness **enhancement** operation. It does not automatically produce the final binary vessel segmentation.

## 11.2 Deep-learning approach

```text
Fundus / patches
    ↓
U-Net
    ↓
Pixel probabilities
    ↓
Threshold / class assignment
    ↓
Vessel mask
```

Potential datasets mentioned in the research include:

- DRIVE.
- STARE.
- CHASE_DB1.

These are external datasets and require appropriate licensing/usage checks.

## 11.3 Comparison

| Method | Strength | Limitation | Recommendation |
|---|---|---|---|
| `fibermetric` + threshold | Fast, deterministic, interpretable | Thin/pathological vessels may be missed | MVP baseline |
| Matched filtering | Simple classical method | Scale/orientation tuning | Baseline |
| Morphology | No training required | Can fragment vessels | Supporting method |
| U-Net | Better spatial segmentation potential | Requires masks and training | Recommended if data/time permit |
| DeepLab-type approach | Multi-scale context | Higher implementation complexity/API considerations | Advanced/future |

### MVP decision

Implement the classical vessel-enhancement baseline first. Add U-Net only if annotated vessel data and training time are available.

---

# 12. Optic Disc and Fovea Localization

## 12.1 Optic disc

The optic disc is typically a bright anatomical region with strong vessel convergence.

A classical pipeline can use:

```text
Fundus
  ↓
Brightness candidate detection
  ↓
`imfindcircles`
  ↓
Candidate filtering
  ↓
Brightness + anatomical-position + vessel-convergence checks
  ↓
Optic-disc center/radius
```

Example building blocks:

- `imextendedmax`
- `imfindcircles`
- `regionprops`
- Vessel mask information.

### Important limitation

`imfindcircles` alone is not reliable because:

- The optic disc may not be perfectly circular.
- Bright exudates can resemble the disc.
- Peripapillary artifacts can obscure the disc.
- Severe disease can distort appearance.

Therefore, use multiple cues.

## 12.2 Fovea

There is no verified dedicated built-in MATLAB function in the consolidated research for fovea localization.

A classical approximation is:

- Start from optic-disc center.
- Move approximately along the temporal horizontal direction.
- Search for a darker foveal region.
- Use an anatomical offset as a starting prior.

One source describes the fovea as approximately 2.5 disc diameters temporally from the optic disc, slightly below the horizontal median.

**Important:** this is a heuristic, not a guaranteed localization rule.

### Recommended priority

- Optic disc localization → moderate-risk optional enhancement.
- Fovea localization → higher-risk optional research feature.

---

# 13. Lesion Detection

MATLAB does not provide a clinically validated one-call detector for:

- Microaneurysms.
- Exudates.
- Hemorrhages.
- Neovascularization.

All lesion detectors must therefore be treated as **custom algorithms or trained models**.

## 13.1 Microaneurysms

Classical approach:

```text
Green Channel
   ↓
CLAHE
   ↓
Bottom-Hat / morphological candidate generation
   ↓
Connected components
   ↓
Area + circularity + shape filtering
   ↓
Candidate regions
```

Potential functions:

- `imbothat`
- `bwconncomp`
- `regionprops`
- `imregionalmin`
- `bwareafilt`

A hybrid strategy is attractive:

```text
Classical candidate proposal
          ↓
Small CNN / high-resolution classifier
          ↓
False-positive rejection
```

### Major limitation

Microaneurysms are tiny and can be confused with:

- Vessel junctions.
- Noise.
- Imaging artifacts.
- Choroidal structures.

The sources discuss very small lesion scales, including values below approximately 125 µm and, in one preprocessing discussion, lesions below approximately 15 µm as vulnerable to excessive smoothing.

**Decision:** standalone high-precision/sub-pixel microaneurysm detection is research-level for the MVP.

## 13.2 Hard exudates

Classical method:

```text
RGB
 ↓
Lab / green-channel representation
 ↓
Bright-feature extraction
 ↓
Optic-disc masking
 ↓
Threshold
 ↓
Morphological cleanup
```

Useful functions:

- `rgb2lab`
- `imtophat`
- `imbinarize`
- `adaptthresh`
- `regionprops`

Exudates are relatively high contrast, making a classical MVP demonstration realistic.

## 13.3 Hemorrhages

Possible classical approach:

- Green-channel processing.
- Bottom-hat filtering.
- Dark-region candidate extraction.
- Shape/area filtering.
- Vessel masking.

Deep-learning alternative:

- U-Net segmentation.
- Object detection.

Because hemorrhages vary substantially in shape and size, a trained model may be more robust than rigid morphological rules.

## 13.4 Neovascularization

Possible features:

- Vessel density.
- Tortuosity.
- Branching.
- Disc-region vessel patterns.
- Peripheral abnormal vessel structures.

However, robust standalone neovascularization detection from 2-D fundus photographs is difficult.

**Recommended MVP treatment:** allow the global DR classifier to capture proliferative disease and explicitly label standalone NVD/NVE detection as future research.

---

# 14. DR Severity Classification

## 14.1 Clinical 5-class structure

The research uses the International Clinical Diabetic Retinopathy (ICDR) severity scale:

| Grade | Category |
|---:|---|
| 0 | No DR |
| 1 | Mild DR |
| 2 | Moderate DR |
| 3 | Severe NPDR |
| 4 | Proliferative DR |

The research describes Grade 3 using the severe-NPDR 4-2-1 rule and Grade 4 as proliferative disease involving neovascularization and/or vitreous/preretinal hemorrhage.

## 14.2 Binary referable DR

For screening, collapse the severity grades into:

```text
Grade 0–1 → Non-referable
Grade 2–4 → Referable
```

This makes the operational decision:

> **Does this patient need ophthalmologist referral?**

## 14.3 Recommended classification strategy

Use:

### Primary output

**Binary referable-DR screening**

Optimized around a predefined high-sensitivity threshold.

### Secondary output

**5-class ICDR severity distribution**

Used for richer reporting and triage.

## 14.4 Why binary screening should be primary

The research sources emphasize that:

- Binary screening is operationally more actionable.
- Five-class grading is harder.
- Middle severity classes can suffer from class imbalance.
- A screening system should prioritize avoiding missed referable disease.

A sensitivity target of approximately **90% or higher** appears in the research as an engineering/clinical target and is associated with cited clinical literature. It must be treated as a target to validate, **not as an achieved performance claim**.

## 14.5 Class imbalance

Possible strategies:

- Class-weighted loss.
- Focal loss.
- Balanced mini-batches.
- Data augmentation.
- Careful patient-level splitting.

The MathWorks DR example described in the sources uses focal cross-entropy to address class imbalance.

## 14.6 Transfer learning

Recommended workflow:

```text
Pretrained network
      ↓
Replace/adapt classification head
      ↓
Patient-level train/validation/test split
      ↓
Class balancing + augmentation
      ↓
Fine-tuning with `trainnet`
      ↓
Validation
      ↓
Threshold selection
      ↓
Held-out test
```

---

# 15. Explainable AI

## 15.1 Primary method: Grad-CAM

`gradCAM` is the strongest native XAI capability identified across the three sources.

Conceptually:

```text
Network
  ↓
Target class score
  ↓
Gradients with respect to feature maps
  ↓
Gradient weighting
  ↓
Weighted activation map
  ↓
ReLU
  ↓
Upsampling
  ↓
Overlay on fundus
```

Grad-CAM should be presented as:

> **Model attention/evidence visualization**

not:

> **Proof that a particular lesion caused the diagnosis.**

## 15.2 Secondary XAI methods

The research also identifies:

- `occlusionSensitivity`
- `imageLIME`
- `activations`

These can be used to compare explanations or debug model behavior.

## 15.3 Lesion-level evidence

Grad-CAM is coarse.

For true lesion-level evidence:

```text
Classifier Grad-CAM
       +
Lesion segmentation/masks
       +
Anatomical masks
       ↓
Integrated evidence view
```

This integration is custom engineering.

## 15.4 Confidence versus explainability

A high confidence score is not itself an explanation.

The report should keep separate:

- Prediction.
- Confidence/probability.
- XAI heatmap.
- Image-quality score.
- Optional lesion evidence.

---

# 16. Confidence Calibration and Uncertainty

## 16.1 Raw confidence

Softmax probabilities can be reported as model scores, but they should not automatically be interpreted as clinically calibrated risk.

## 16.2 Calibration

Possible custom approach:

```text
Validation logits
      ↓
Calibration model
      ↓
Calibrated probability
      ↓
Threshold selection
```

A logistic model can be fitted using functions such as `fitglm` where appropriate.

## 16.3 Important limitation

The consolidated research explicitly states that it did **not** verify a single built-in MATLAB function that automatically produces a complete deep-learning reliability diagram/calibration workflow.

Therefore:

- Reliability diagrams → custom.
- Temperature scaling → custom.
- Deep ensembles → custom.
- Monte-Carlo dropout uncertainty → custom.
- Calibrated risk → must be validated.

## 16.4 Recommended MVP

Use:

- Raw model score.
- ROC/threshold analysis.
- Optional Platt/logistic calibration if validation data are sufficient.

Do not claim clinical uncertainty estimation unless it has actually been implemented and validated.

---

# 17. Automated Clinical Reporting

A useful report should contain:

1. Anonymous patient/session identifier.
2. Original fundus image.
3. Enhanced fundus image.
4. Image-quality/gradability decision.
5. Reasons for rejection if ungradable.
6. Referable-DR decision.
7. Predicted 5-class grade.
8. Confidence/model score.
9. Grad-CAM overlay.
10. Optional optic-disc/fovea markers.
11. Optional lesion masks.
12. Referral recommendation.
13. Human-review disclaimer.
14. Machine-readable JSON/CSV result.

## 17.1 Lightweight implementation

Without Report Generator:

- `imshow`
- `imagesc`
- `tiledlayout`
- `exportgraphics`
- `imoverlay`
- `insertShape`
- `insertObjectAnnotation`
- `writetable`
- `jsonencode`

## 17.2 Report Generator

MATLAB Report Generator is useful for:

- Template-based PDF.
- Word.
- HTML.
- More formal report automation.

It is a separate licensed product.

### MVP decision

A single-page automated report generated from a MATLAB figure is sufficient for the prototype if Report Generator is unavailable.

---

# 18. Recommended End-to-End Workflow

## 18.1 Conceptual pipeline

```text
                         RURAL SCREENING POINT
                                  │
                                  ▼
                         [Fundus Capture]
                                  │
                                  ▼
                     [1. Image Quality Gate]
                       │                    │
                  Ungradable             Gradable
                       │                    │
                       ▼                    ▼
                [Recapture Loop]     [2. Enhancement]
                                           │
                                           ▼
                                  [3. Standardization]
                                           │
                          ┌────────────────┴────────────────┐
                          ▼                                 ▼
                [Optional Structure]              [4. DR Classifier]
                 - Optic Disc                      - Binary Referable DR
                 - Fovea                           - 5-Class ICDR
                 - Vessels
                          │                                 │
                          └────────────────┬────────────────┘
                                           ▼
                              [5. Explainability]
                                  - Grad-CAM
                                  - Optional XAI
                                           │
                                           ▼
                              [6. Confidence/Threshold]
                                           │
                                           ▼
                              [7. Automated Report]
                                           │
                                           ▼
                              [8. Human Review]
                                           │
                                           ▼
                               Referral / Screening
                                           │
                                           ▼
                         [Simulink Operational Model]
```

## 18.2 MATLAB implementation pipeline

| Stage | Input | MATLAB Method | Output |
|---|---|---|---|
| 1. Acquisition | JPEG/PNG/DICOM | `imread` / `dicomread` | RGB image |
| 2. Retinal ROI | RGB | Threshold + connected components | Retina mask |
| 3. IQA | Raw/ROI | Blur + exposure + FOV + optional BRISQUE/NIQE/PIQE | Gradability decision |
| 4. Enhancement | Gradable image | CLAHE + optional denoise | Enhanced image |
| 5. Normalization | Enhanced image | Crop/resize/color normalization | Network tensor |
| 6. Optional structure | Enhanced image | OD/vessel/fovea methods | Structural evidence |
| 7. DR classifier | Tensor | Transfer-learned CNN | Class probabilities |
| 8. XAI | Image + model | `gradCAM` | Heatmap |
| 9. Calibration | Validation/model scores | ROC + optional custom calibration | Calibrated/thresholded risk |
| 10. Report | All outputs | Graphics + export/JSON | Clinical-review report |
| 11. Operations | Timing/rates | Simulink/SimEvents | Throughput/latency/queue results |

---

# 19. MATLAB Function Inventory

| Function / Workflow | Toolbox | Purpose | Application | Priority |
|---|---|---|---|---|
| `imread` | Image Processing / MATLAB | Read image | Fundus input | Essential |
| `imageDatastore` | MATLAB/Image Processing workflow | Dataset management | Training | Essential |
| `imfinfo` | MATLAB | Metadata | Input/session handling | Recommended |
| `dicomread` | Image Processing | Read DICOM | Clinical integration | Optional |
| `adapthisteq` | Image Processing | CLAHE | Enhancement | Essential |
| `imadjust` | Image Processing | Intensity/gamma | Normalization | Recommended |
| `imgaussfilt` | Image Processing | Gaussian denoise | Preprocessing | Recommended |
| `medfilt2` | Image Processing | Median denoise | Preprocessing | Recommended |
| `wiener2` | Image Processing | Adaptive denoise | Optional preprocessing | Optional |
| `imguidedfilter` | Image Processing | Edge-preserving smoothing | Vessel/structure preservation | Recommended |
| `imbilatfilt` | Image Processing | Bilateral filtering | Edge-preserving denoise | Optional |
| `imfindcircles` | Image Processing | Circular Hough | Optic disc candidate | Recommended |
| `imextendedmax` | Image Processing | Regional maxima | Bright-region candidates | Optional |
| `fibermetric` | Image Processing | Vesselness enhancement | Retinal vessels | Recommended |
| `imtophat` | Image Processing | Bright-feature extraction | Exudate candidates | Recommended |
| `imbothat` | Image Processing | Dark-feature extraction | MA/hemorrhage candidates | Recommended |
| `imbinarize` | Image Processing | Binarization | ROI/candidates | Recommended |
| `adaptthresh` | Image Processing | Adaptive threshold | Uneven illumination | Recommended |
| `bwconncomp` | Image Processing | Components | Lesion candidates | Recommended |
| `bwareafilt` | Image Processing | Area filtering | Candidate cleanup | Recommended |
| `regionprops` | Image Processing | Shape measurements | Lesion/ROI analysis | Essential |
| `imopen` / `imclose` | Image Processing | Morphology | Cleanup | Recommended |
| `imerode` / `imdilate` | Image Processing | Morphology | Mask processing | Recommended |
| `rgb2lab` / `lab2rgb` | Image Processing | Lab conversion | Exudates/luminance | Recommended |
| `rgb2gray` | Image Processing | Grayscale | IQA/classical CV | Recommended |
| `imresize` | Image Processing | Resize | Network input | Essential |
| `imcrop` | Image Processing | Crop | ROI normalization | Essential |
| `psnr` / `ssim` / `immse` | Image Processing | Reference quality | Enhancement comparison | Optional |
| `brisque` | Image Processing | No-reference quality | IQA | Optional/Recommended |
| `niqe` | Image Processing | No-reference quality | IQA | Optional/Recommended |
| `piqe` | Image Processing | No-reference quality | IQA | Optional/Recommended |
| `fitbrisque` / `fitniqe` | Image Processing | Custom quality model fitting | Fundus-specific IQA | Advanced |
| `unet` | Computer Vision | U-Net architecture | Segmentation | Recommended |
| `semanticseg` | Computer Vision | Segmentation inference | Vessel/lesion masks | Recommended |
| `evaluateSemanticSegmentation` | Computer Vision | Segmentation metrics | Validation | Recommended |
| `yolov4ObjectDetector` | Computer Vision | Object detection | Lesion/OD detection | Optional |
| `bboxOverlapRatio` | Computer Vision | IoU | Detection evaluation | Optional |
| `imagePretrainedNetwork` | Deep Learning | Load pretrained model | Transfer learning | Essential |
| `trainnet` | Deep Learning | Train network | DR classification | Essential |
| `trainingOptions` | Deep Learning | Training configuration | Optimization | Essential |
| `dlnetwork` | Deep Learning | Flexible network | Custom workflows/XAI | Essential |
| `minibatchpredict` | Deep Learning | Batch inference | Testing/deployment | Essential |
| `gradCAM` | Deep Learning | XAI | Evidence heatmap | Essential |
| `occlusionSensitivity` | Deep Learning | XAI | Secondary explanation | Optional |
| `imageLIME` | Deep Learning | Local XAI | Secondary explanation | Optional |
| `activations` | Deep Learning | Feature visualization | Debugging | Optional |
| `confusionmat` | Statistics & ML | Confusion matrix | Validation | Essential |
| `confusionchart` | Statistics & ML | Matrix visualization | Validation | Essential |
| `rocmetrics` | Statistics & ML / Deep Learning | ROC and metrics | Screening evaluation | Essential |
| `auc` | Statistics & ML | AUC | Validation | Essential |
| `perfcurve` | Statistics & ML | ROC/PR analysis | Validation | Essential |
| `cvpartition` | Statistics & ML | Data partitioning | Cross-validation | Recommended |
| `fitcsvm` | Statistics & ML | SVM | Classical baseline | Optional |
| `fitctree` | Statistics & ML | Decision tree | Baseline | Optional |
| `fitcensemble` | Statistics & ML | Ensemble classifier | Baseline | Optional |
| `fitclinear` | Statistics & ML | Linear/logistic model | Calibration/classical ML | Optional |
| `fitglm` | Statistics & ML | GLM fitting | Calibration | Recommended |
| `exportgraphics` | MATLAB | Export figures | PDF/PNG report | Recommended |
| `imoverlay` | Image Processing | Overlay masks | Reporting | Recommended |
| `insertShape` | Computer Vision | Draw annotations | Reporting | Optional |
| `insertObjectAnnotation` | Computer Vision | Draw labels/boxes | Reporting | Optional |
| `writetable` | MATLAB | Write tables | CSV/Excel-style output | Recommended |
| `jsonencode` | MATLAB | JSON serialization | System integration | Recommended |
| MATLAB Function Block | Simulink | Run MATLAB code | Pipeline integration | Recommended |
| Stateflow | Simulink | State logic | Accept/reject/recapture | Recommended |
| SimEvents blocks | SimEvents | Discrete-event model | Queueing/telemedicine | Recommended if licensed |

---

# 20. Toolbox → System Component Mapping

| System Component | Image Processing | Computer Vision | Deep Learning | Medical Imaging | Statistics & ML | Simulink |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Image Input | ✓ | | | Optional | | |
| Image Quality Assessment | ✓ | | Optional | | ✓ | |
| Retinal ROI | ✓ | | | | | |
| CLAHE Enhancement | ✓ | | | | | |
| Optic Disc Localization | ✓ | ✓ | Optional | | | |
| Fovea Localization | ✓ | Optional | Optional | | | |
| Classical Vessel Enhancement | ✓ | | | | | |
| U-Net Vessel Segmentation | | ✓ | ✓ | | | |
| Classical Lesion Detection | ✓ | | | | Optional | |
| DL Lesion Segmentation | | ✓ | ✓ | | | |
| DR Severity Classification | | | ✓ | | ✓ | |
| Explainability | | | ✓ | | | |
| Confidence Calibration | | | ✓ | | ✓ | |
| Statistical Validation | | | | | ✓ | |
| Automated Report | ✓ | Optional | | | | |
| Human Review UI | | Optional | | | | |
| Workflow Simulation | | | | | | ✓ |

---

# 21. Required, Recommended and Optional Stack

## 21.1 Core MVP stack

The consolidated sources support the following practical core:

1. MATLAB.
2. Image Processing Toolbox.
3. Deep Learning Toolbox.
4. Statistics and Machine Learning Toolbox.
5. Simulink if the operational simulation is part of the demonstrated system.

## 21.2 Strongly recommended

- Computer Vision Toolbox.
- Parallel Computing Toolbox when GPU acceleration is available.

## 21.3 Optional

- SimEvents — for true discrete-event queueing.
- MATLAB Report Generator — for polished report automation.
- MATLAB Compiler — for packaged demo deployment.
- App Designer — useful for the reviewer interface and available as a MATLAB UI-development route.
- Medical Imaging Toolbox — only when advanced clinical DICOM/PACS or volumetric imaging is required.
- MATLAB Coder — only if a later embedded C/C++ deployment commitment exists.
- Optimization Toolbox — not required for the core MVP.

---

# 22. Parallel Computing Toolbox and GPU Acceleration

Parallel Computing Toolbox is particularly valuable for:

- CNN training.
- Batch inference.
- Grad-CAM generation.
- Large image preprocessing.
- Experimentation during the hackathon.

The sources indicate that compatible workflows can fall back to CPU execution when GPU acceleration is unavailable.

### Decision

```text
GPU available
    → Use Parallel Computing Toolbox
    → Faster training/inference
    → Faster experimentation

GPU unavailable
    → CPU fallback
    → Reduce model/input size
    → Use lighter architecture
```

Do not make a specific GPU compute capability a hard project requirement unless the exact hardware and MATLAB release have been tested.

---

# 23. Implementation Feasibility

| Component | Complexity | Reason |
|---|:---:|---|
| Image Input | 🟢 Straightforward | Standard image I/O |
| Image Quality Assessment | 🟢 Straightforward–🟡 Moderate | Metrics are easy; clinically meaningful thresholds require validation |
| CLAHE Enhancement | 🟢 Straightforward | Native `adapthisteq` |
| Retinal ROI | 🟢 Straightforward | Classical segmentation |
| Optic Disc Localization | 🟡 Moderate | Hough detection needs fallback logic |
| Fovea Localization | 🟠 Difficult | No dedicated verified built-in function |
| Classical Vessel Enhancement | 🟢–🟡 Moderate | `fibermetric` is available; thresholding needs tuning |
| Vessel U-Net | 🟡 Moderate | Requires masks/training |
| Hard Exudate Detection | 🟡 Moderate | Bright lesions are comparatively suitable for classical methods |
| Hemorrhage Detection | 🟠 Difficult | Shape/contrast variation |
| Microaneurysm Detection | 🟠 Difficult | Tiny lesions and false positives |
| Neovascularization Detection | 🔴 Research-Level | Fine chaotic vessel detection |
| DR Classification | 🟡 Moderate | Transfer learning is well supported |
| Grad-CAM | 🟢 Straightforward | Native function |
| Confidence Calibration | 🟡 Moderate | Custom calibration + clean validation |
| Automated PDF/figure report | 🟢 Straightforward | Figure composition and export |
| Human-review UI | 🟡 Moderate | App/UI integration |
| Simulink workflow | 🟡 Moderate | Requires operational model design |
| SimEvents queue model | 🟡 Moderate | Purpose-built blocks simplify discrete events |

---

# 24. Recommended MVP for SIH 26038

## 24.1 MUST IMPLEMENT

```text
1. Automated Image Quality Gate
   - Blur/focus
   - Exposure
   - FOV/gradability

2. Image Enhancement
   - Green-channel/Lab processing
   - CLAHE
   - Standardized preprocessing

3. Transfer-Learning DR Classifier
   - Binary referable DR as primary output
   - 5-class ICDR as secondary output

4. Explainability
   - Grad-CAM heatmap

5. Automated Report
   - Original image
   - Enhanced image
   - DR result
   - Confidence/model score
   - Grad-CAM
   - Quality status

6. Operational Simulation
   - Acquisition
   - Recapture
   - Processing
   - Network delay
   - Review queue
```

## 24.2 SHOULD IMPLEMENT

```text
1. Optic-disc localization
2. Classical hard-exudate masking
3. Classical vessel enhancement
4. Confidence calibration
5. App Designer reviewer interface
6. SimEvents discrete-event queueing if licensed
```

## 24.3 CAN SIMULATE / DEMO

```text
1. Live fundus-camera interface
2. Cloud infrastructure
3. Multiple PHC centers
4. District-level review hub
5. Bandwidth scenarios
6. Reviewer-capacity scenarios
7. Recapture-rate scenarios
```

## 24.4 FUTURE / RESEARCH

```text
1. High-precision microaneurysm detector
2. Standalone NVD/NVE detector
3. Full lesion segmentation
4. Longitudinal progression tracking
5. Advanced uncertainty estimation
6. PACS/DICOM integration
7. Embedded edge deployment
```

---

# 25. Recommended Final Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                 RURAL SCREENING POINT                       │
│                                                             │
│  Fundus Camera                                               │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────────┐                                    │
│  │ MATLAB Image Input  │                                    │
│  └──────────┬──────────┘                                    │
│             ▼                                               │
│  ┌─────────────────────┐                                    │
│  │ Local IQA           │                                    │
│  │ Blur / Exposure/FOV │                                    │
│  └───────┬─────────────┘                                    │
│          │                                                  │
│     ┌────┴────┐                                             │
│     │         │                                             │
│ Ungradable  Gradable                                        │
│     │         │                                             │
│     ▼         ▼                                             │
│ Recapture  Enhancement                                      │
│             │                                               │
│             ▼                                               │
│     ┌───────────────────────┐                               │
│     │ DR Deep-Learning Core │                               │
│     │ EfficientNet-B0 /     │                               │
│     │ ResNet baseline       │                               │
│     └──────────┬────────────┘                               │
│                │                                             │
│        ┌───────┴─────────┐                                   │
│        ▼                 ▼                                   │
│  Binary Referable    5-Class ICDR                            │
│        │                 │                                   │
│        └────────┬────────┘                                   │
│                 ▼                                             │
│       ┌──────────────────┐                                   │
│       │ Grad-CAM / XAI   │                                   │
│       └────────┬─────────┘                                   │
│                ▼                                             │
│       ┌──────────────────┐                                   │
│       │ Confidence /     │                                   │
│       │ Threshold Layer  │                                   │
│       └────────┬─────────┘                                   │
│                ▼                                             │
│       ┌──────────────────┐                                   │
│       │ Clinical Report  │                                   │
│       └────────┬─────────┘                                   │
│                ▼                                             │
│       Ophthalmologist Review                                 │
└─────────────────────────────────────────────────────────────┘

                    OPERATIONAL LAYER
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    SIMULINK / SIMEVENTS                      │
│                                                             │
│ Patient Arrival                                             │
│      ↓                                                      │
│ Capture Queue                                               │
│      ↓                                                      │
│ IQA / Recapture                                             │
│      ↓                                                      │
│ AI Processing                                               │
│      ↓                                                      │
│ Bandwidth / Network Delay                                   │
│      ↓                                                      │
│ Referral Queue                                              │
│      ↓                                                      │
│ Ophthalmologist Resource Pool                               │
│      ↓                                                      │
│ Throughput / Latency / Queue / Utilization                  │
└─────────────────────────────────────────────────────────────┘
```

---

# 26. MATLAB vs Python — Final Decision Matrix

| Criterion | MATLAB | Python | Project Decision |
|---|---|---|---|
| Image Processing | Integrated, documented toolboxes | Broad open-source ecosystem | MATLAB preferred for core pipeline |
| Classical CV | Strong built-in support | Strong OpenCV/scikit ecosystem | Both viable |
| DR Deep Learning | Strong verified workflow | Larger research ecosystem | MATLAB primary; Python fallback |
| State-of-the-art research code | Smaller ecosystem | Stronger | Python advantage |
| Native XAI | `gradCAM` | Multiple libraries | MATLAB advantage for controlled prototype |
| Statistical validation | Strong integrated toolbox | Strong libraries | MATLAB convenient |
| Workflow simulation | Simulink/SimEvents | Requires separate simulation tools | MATLAB advantage |
| Edge deployment | Requires careful licensing/runtime planning | More flexible open-source options | Python advantage |
| Environment consistency | High | Package/driver management required | MATLAB advantage |
| Hackathon integration | Strong single-environment story | More components | MATLAB advantage |

### Final decision

> **Use MATLAB as the primary development and demonstration environment. Use Python selectively when an external model, dataset utility, or research implementation materially reduces risk.**

---

# 27. Limitations and Operational Risks

## 27.1 Licensing

Potential issues:

- MATLAB desktop licensing.
- Toolbox availability.
- SimEvents licensing.
- Report Generator licensing.
- Parallel Computing Toolbox licensing.

**Mitigation:** verify all licenses before committing to the final demo.

## 27.2 Runtime/deployment footprint

A remote PHC deployment may not be suitable for a full MATLAB desktop installation.

Possible later strategies:

- MATLAB Compiler.
- MATLAB Runtime.
- ONNX export where supported and appropriate.
- C/C++ code generation only if specifically required.

These are deployment-stage decisions, not MVP requirements.

## 27.3 Dataset shift

A model trained on curated datasets may perform worse on:

- Low-cost cameras.
- Different illumination.
- Different patient populations.
- Poorly focused images.
- Compression artifacts.
- Unusual retinal pigmentation.
- Different camera color responses.

**Mitigation:** prioritize IQA and validate preprocessing across realistic capture conditions.

## 27.4 Dataset leakage

Do not allow images from the same patient to appear across train and test sets when patient identity is available.

Use patient-level splitting whenever possible.

## 27.5 Clinical overclaiming

Do not say:

- "Clinically validated" without clinical validation.
- "Diagnosis" when the system is only screening.
- "Grad-CAM proves the lesion caused the prediction."
- "Confidence equals probability of disease" without calibration.
- "90% sensitivity achieved" unless the team's measured held-out results support it.

## 27.6 Simulation assumptions

Operational numbers such as:

- Patient arrival rate.
- Bandwidth.
- Network delay.
- Reviewer capacity.
- Processing time.

must be labeled as:

- Measured,
- sourced,
- or assumed simulation parameters.

Do not present assumptions as field measurements.

---

# 28. Important API and Research Conflict Resolution

The three source documents were broadly consistent but contained several differences. These have been retained as explicit decisions rather than silently ignored.

## 28.1 MATLAB release

The sources mention R2023b, R2024a, and R2025a.

**Consolidated decision:**

- R2025a or later is the recommended target for the current API workflow.
- The minimum release depends on which functions are actually used.
- The team should verify its installed release before coding.

## 28.2 Medical Imaging Toolbox

Some material initially places Medical Imaging Toolbox in the expected stack.

Other research explicitly distinguishes documentation placement from functional dependency.

**Consolidated decision:**

> Medical Imaging Toolbox is optional for the core 2-D fundus-image MVP. Use it for advanced DICOM/PACS or volumetric imaging requirements.

## 28.3 U-Net API

Some source material uses `unetLayers`.

The more recent research explicitly flags the older API as removed and recommends `unet`.

**Consolidated decision:**

> Use the current `unet` workflow after checking the installed MATLAB release. Do not start a new implementation around a removed API.

## 28.4 DeepLab v3+

Some material lists DeepLab v3+ as a segmentation possibility.

The more recent research flags the older `deeplabv3plusLayers` convenience API as removed.

**Consolidated decision:**

> U-Net is the MVP segmentation choice. DeepLab is an advanced option only after verifying the current implementation route.

## 28.5 EfficientNet variants

Some material mentions EfficientNet-B0/B2.

The more detailed source states that B0 is the directly supported first-class name and that larger variants should not be assumed to work without import effort.

**Consolidated decision:**

> Use EfficientNet-B0 unless a larger variant has been explicitly verified for the installed MATLAB release.

## 28.6 Confidence calibration

Some material presents Platt scaling as available through MATLAB statistical functions.

The more detailed research correctly frames the complete calibration workflow as a custom combination of model outputs and statistical fitting.

**Consolidated decision:**

> Calibration is possible, but it is a custom pipeline rather than a single "calibrate my deep model" built-in function.

## 28.7 Simulink versus SimEvents

Some material treats Simulink as the queueing engine.

The detailed research distinguishes:

- Plain Simulink → coarse/rate/state-based workflow modeling.
- SimEvents → true discrete-event queueing.

**Consolidated decision:**

> Simulink is the required system-simulation environment; SimEvents is a recommended add-on when true entity-based queueing is required and licensed.

---

# 29. What the Team Should Actually Build

For a fast, defensible SIH implementation, prioritize:

```text
PHASE 1 — Guaranteed Core
──────────────────────────
✓ Dataset ingestion
✓ Patient-level split
✓ IQA
✓ CLAHE / preprocessing
✓ Binary referable-DR classifier
✓ Grad-CAM
✓ Validation metrics
✓ Automated report

PHASE 2 — Differentiation
─────────────────────────
✓ 5-class ICDR output
✓ Optic-disc localization
✓ Classical exudate evidence
✓ Vessel enhancement
✓ Confidence calibration
✓ Reviewer UI

PHASE 3 — System Engineering
─────────────────────────────
✓ Simulink operational model
✓ Network-delay scenarios
✓ Queueing
✓ Ophthalmologist resource capacity
✓ Multi-PHC simulation

PHASE 4 — Research Extensions
─────────────────────────────
○ U-Net vessel/lesion segmentation
○ High-resolution microaneurysm detector
○ NVD/NVE detection
○ Longitudinal tracking
○ DICOM/PACS integration
○ Edge deployment
```

---

# 30. Final Technical Recommendation

## Recommended environment

- **MATLAB:** R2025a or later preferred.
- **Core:** MATLAB + Image Processing Toolbox + Deep Learning Toolbox + Statistics and Machine Learning Toolbox.
- **System simulation:** Simulink.
- **Strong recommendation:** Computer Vision Toolbox.
- **GPU:** Parallel Computing Toolbox when compatible GPU hardware is available.
- **Discrete-event simulation:** SimEvents if licensed.
- **Reporting:** Report Generator only if a polished template-based report is required.
- **Medical Imaging Toolbox:** only for advanced clinical imaging/DICOM/PACS requirements.

## Recommended model strategy

### Primary

**Binary referable-DR classifier**

### Secondary

**5-class ICDR severity model**

### Initial backbone

Choose between:

- **ResNet-50** for a robust baseline.
- **ResNet-18** for lower compute.
- **EfficientNet-B0** for a compact edge-oriented design.

If the team wants maximum alignment with the MathWorks example, reproduce the documented ResNet-101 workflow first, then optimize down to a lighter architecture.

## Recommended XAI

**Grad-CAM**

with optional:

- Occlusion sensitivity.
- Image LIME.
- Lesion-mask integration.

## Recommended system simulation

```text
Patient Arrival
   ↓
Fundus Capture
   ↓
IQA
   ├── Reject → Recapture
   └── Accept
         ↓
      AI Pipeline
         ↓
   Network Transfer
         ↓
   Referral Queue
         ↓
Ophthalmologist Review
```

## Final architecture principle

> **Keep the primary DR decision model simple, measurable, and defensible. Use classical image processing and XAI to make the system interpretable, and use Simulink to demonstrate that the proposed rural tele-screening workflow can be analyzed as an end-to-end engineering system.**

---

# 31. References

## MATLAB / MathWorks capability sources

1. **MathWorks.** *Multilabel Diabetic Retinopathy Fundus Image Classification Using Deep Learning.*  
   https://www.mathworks.com/help/medical-imaging/ug/multilabel-diabetic-retinopathy-fundus-image-classification-using-deep-learning.html

2. **MathWorks.** *adapthisteq — Contrast-limited adaptive histogram equalization.*  
   https://www.mathworks.com/help/images/ref/adapthisteq.html

3. **MathWorks.** *fibermetric — Enhance elongated or tubular structures using Frangi vesselness filter.*  
   https://www.mathworks.com/help/images/ref/fibermetric.html

4. **MathWorks.** *imfindcircles — Find circles using circular Hough transform.*  
   https://www.mathworks.com/help/images/ref/imfindcircles.html

5. **MathWorks.** *Medical Imaging Toolbox.*  
   https://www.mathworks.com/products/medical-imaging.html

6. **MathWorks.** *Pretrained Deep Neural Networks.*  
   https://www.mathworks.com/help/deeplearning/ug/pretrained-convolutional-neural-networks.html

7. **MathWorks.** *unet — Create U-Net convolutional neural network for semantic segmentation.*  
   https://www.mathworks.com/help/vision/ref/unet.html

8. **MathWorks.** *unetLayers — Removed U-Net layers API.*  
   https://in.mathworks.com/help/vision/ref/unetlayers.html

9. **MathWorks.** *deeplabv3plusLayers — Removed DeepLab v3+ convenience API.*  
   https://www.mathworks.com/help/vision/ref/deeplabv3pluslayers.html

10. **MathWorks.** *yolov4ObjectDetector.*  
    https://www.mathworks.com/help/vision/ref/yolov4objectdetector.html

11. **MathWorks.** *gradCAM — Explain network predictions using Grad-CAM.*  
    https://www.mathworks.com/help/deeplearning/ref/gradcam.html

12. **MathWorks.** *occlusionSensitivity — Explain network predictions by occluding the inputs.*  
    https://la.mathworks.com/help/deeplearning/ref/occlusionsensitivity.html

13. **MathWorks.** *ROC metrics / AUC.*  
    https://www.mathworks.com/help/stats/rocmetrics.auc.html

14. **MathWorks.** *confusionmat.*  
    https://www.mathworks.com/help/stats/confusionmat.html

15. **MathWorks.** *BRISQUE / NIQE / PIQE image-quality metrics.*  
    https://www.mathworks.com/help/images/ref/brisque.html  
    https://www.mathworks.com/help/images/ref/niqe.html  
    https://www.mathworks.com/help/images/ref/piqe.html

16. **MathWorks.** *fitbrisque — Fit custom BRISQUE image-quality model.*  
    https://www.mathworks.com/help/images/ref/fitbrisque.html

17. **MathWorks.** *MATLAB Report Generator.*  
    https://www.mathworks.com/products/matlab-report-generator.html

18. **MathWorks.** *SimEvents.*  
    https://www.mathworks.com/products/simevents.html

19. **MathWorks.** *Create a Discrete-Event Model.*  
    https://www.mathworks.com/help/simevents/gs/create-a-discrete-event-model.html

20. **MathWorks.** *Simulation of a Medical Device.*  
    https://www.mathworks.com/help/simevents/examples/simulation-of-a-medical-device.html

21. **MathWorks Answers.** *EfficientNet model support in MATLAB's Deep Learning Toolbox.*  
    https://ww2.mathworks.cn/matlabcentral/answers/2176306-efficientnet-model-support-in-matlab-s-deep-learning-toolbox

## Clinical / academic references

22. Wilkinson, C. P., Ferris, F. L., Klein, R. E., Lee, P. P., Agardh, C. D., Davis, M., et al. (2003). *Proposed international clinical diabetic retinopathy and diabetic macular edema disease severity scales.* Ophthalmology, 110(9), 1677–1682.

23. Gulshan, V., Peng, L., Coram, M., Stumpe, M. C., Wu, D., Narayanaswamy, A., et al. (2016). *Development and validation of a deep learning algorithm for detection of diabetic retinopathy in retinal fundus photographs.* JAMA, 316(22), 2402–2410.

24. Selvaraju, R. R., Cogswell, M., Das, A., Vedaldi, A., Parikh, D., & Batra, D. (2017). *Grad-CAM: Visual explanations from deep networks via gradient-based localization.* IEEE ICCV, 618–626.

25. Platt, J. (1999). *Probabilistic outputs for support vector machines and comparisons to regularized likelihood methods.* Advances in Large Margin Classifiers.

26. Abdullah, M., Fraz, M. M., & Barman, S. A. (2016). *Localization and segmentation of optic disc in retinal images using circular Hough transform and grow-cut algorithm.* PeerJ.  
    https://pmc.ncbi.nlm.nih.gov/articles/PMC4867714/

27. Alyoubi, W. L., Abulkhair, M. F., & Shalash, W. M. (2021). *Diabetic Retinopathy Fundus Image Classification and Lesions Localization System Using Deep Learning.* Sensors, 21(11), 3704.  
    https://doi.org/10.3390/s21113704

28. Li, T., Gao, Y., Wang, K., Guo, S., Liu, H., & Kang, H. (2019). *Diagnostic Assessment of Deep Learning Algorithms for Diabetic Retinopathy Screening.* Information Sciences, 501, 511–522.  
    https://doi.org/10.1016/j.ins.2019.06.011

---

# 32. Consolidation Quality-Control Checklist

- [x] Three supplied MATLAB research documents were treated as source material.
- [x] Major sections from all three sources were consolidated into one consistent structure.
- [x] Duplicate sections and repeated tables were merged rather than blindly concatenated.
- [x] Unique MATLAB functions from the sources were retained in the function inventory.
- [x] Image-processing methods were retained.
- [x] IQA methods were retained.
- [x] Classical and deep-learning vessel methods were retained.
- [x] Optic-disc and fovea methods were retained.
- [x] Microaneurysm, exudate, hemorrhage and neovascularization strategies were retained.
- [x] 5-class ICDR and binary referable-DR strategies were retained.
- [x] Grad-CAM, occlusion sensitivity and LIME were retained.
- [x] Confidence calibration limitations were retained.
- [x] Automated reporting methods were retained.
- [x] Simulink and SimEvents distinctions were retained.
- [x] Queue/resource/network simulation concepts were retained.
- [x] Optional toolbox recommendations were consolidated.
- [x] MATLAB-versus-Python tradeoffs were retained.
- [x] Implementation-feasibility ratings were retained.
- [x] MVP scope was retained.
- [x] Limitations and deployment risks were retained.
- [x] The conflicting MATLAB-release claims were explicitly reconciled.
- [x] The Medical Imaging Toolbox dependency conflict was explicitly reconciled.
- [x] The `unetLayers`/`unet` API conflict was explicitly reconciled.
- [x] The DeepLab v3+ API conflict was explicitly reconciled.
- [x] EfficientNet variant uncertainty was explicitly retained.
- [x] Simulink versus SimEvents licensing distinction was retained.
- [x] Simulation assumptions are explicitly labeled as assumptions where appropriate.
- [x] Clinical claims are separated from engineering recommendations.
- [x] No model performance number is presented as an achieved result for the project.
- [x] The final recommendation is actionable for an SIH student development team.

---

# 33. Source Coverage Note

This file intentionally does **not** preserve three separate copies of the same research. Instead, it preserves the **union of substantive technical information** from the three inputs and places it under a single coherent architecture.

Where one source contained a more detailed explanation than the others, that detail was retained.

Where sources disagreed, the disagreement is documented in **Section 28 — Important API and Research Conflict Resolution** rather than silently deleting one source's position.

This makes the document suitable as the team's consolidated technical research baseline while keeping implementation uncertainty visible.
