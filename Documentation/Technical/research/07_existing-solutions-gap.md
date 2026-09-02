# 05 --- Existing Solutions, State of the Art & Technical Gap Analysis

## SIH 26038 --- Explainable AI for Diabetic Retinopathy Screening in Rural India

> **Consolidated Union of Three Research Files**
>
> This document merges the three supplied research files on existing
> solutions, state of the art, portable/offline retinal screening, XAI,
> clinical validation, and system-level technical gaps. Overlapping
> material is consolidated into a canonical structure; unique technical
> details, caveats, comparisons, and claims are retained in the
> source-material appendix.

------------------------------------------------------------------------

# 1. Purpose

Existing-solution research is essential to prevent unsupported novelty
claims and to position SIH 26038 against capabilities already
demonstrated, clinically validated, deployed, or commercialized.

Automated diabetic-retinopathy (DR) screening is a mature area of
applied medical AI. Autonomous screening, CNN-based grading, portable
fundus imaging, offline inference, image-quality assessment,
telemedicine referral, and Grad-CAM-style explainability all have prior
evidence. Therefore, the project should **not** claim novelty merely
because it uses CNNs, detects microaneurysms, applies CLAHE, generates
Grad-CAM maps, or runs inference on a portable device.

The central research question is instead:

> **Does a documented system already integrate the particular
> combination of image-quality gating, adaptive processing, lesion-level
> evidence, DR grading, explainability, calibrated confidence, human
> review, offline/store-and-forward operation, network constraints, and
> explicit operational/resource simulation for rural Indian PHCs at
> 100,000+ patients/year scale?**

This distinction separates **feature novelty** from **system-level
differentiation**.

## 1.1 Feature Novelty vs. System-Level Differentiation

### Feature novelty

Feature novelty asks:

> "Does capability X exist anywhere?"

For nearly every individual capability in the proposed pipeline, the
answer is **yes**:

-   Image quality assessment
-   DR classification
-   5-level or multi-stage grading
-   Portable fundus imaging
-   Offline inference
-   CLAHE/enhancement
-   Grad-CAM
-   Lesion segmentation
-   Confidence/uncertainty estimation
-   Telemedicine referral
-   Store-and-forward workflows

These should therefore be treated as established techniques rather than
invented capabilities.

### System-level differentiation

System-level differentiation asks:

> "Does a system exist that integrates this particular combination of
> capabilities, validated and deployed together, for rural Indian PHCs
> and explicitly modeled at operational scale?"

The research reviewed here indicates that this is a substantially
narrower and more defensible gap.

The proposed differentiation is the coherent integration of:

1.  Classical and learned preprocessing.
2.  Deterministic IQA and recapture routing.
3.  Adaptive enhancement.
4.  DR grading.
5.  Morphological lesion evidence.
6.  Grad-CAM or related spatial attribution.
7.  Probability/confidence calibration.
8.  Human-in-the-loop review.
9.  Offline-first/local inference.
10. Opportunistic store-and-forward telemedicine.
11. Network-aware queueing.
12. Resource/capacity simulation.
13. District-scale 100,000+ patient/year scenario analysis.

------------------------------------------------------------------------

# 2. State of the Art: Existing DR AI Systems

Automated DR systems span black-box end-to-end classifiers, hybrid
lesion-guided architectures, and regulatory-cleared autonomous screening
products.

``` text
AI Screening Paradigms

1. End-to-End Deep Learning:
   Input Fundus Image
          │
          ▼
   Deep CNN / Vision Model
          │
          ▼
   DR Class / Referral Probability

2. Lesion-Guided / Hybrid:
   Input Image
       ├──────────────► Morphology / U-Net Segmentation
       │                         │
       │                         ▼
       │                  Lesion Evidence
       │
       └──────────────► CNN Feature Embeddings
                                 │
                                 ▼
                         Integrated Diagnosis
```

## 2.1 Representative Systems

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  System             Organization               Year AI / Task          Dataset / Validation     Reported Performance              Validation / Deployment    Important Limitations
  ------------------ -------------- ---------------- ------------------ ------------------------ --------------------------------- -------------------------- --------------------------------
  **LumineticsCore / Digital                    2018 Autonomous         Proprietary pivotal      \~87% sensitivity, \~90%          FDA De Novo authorized;    Specific compatible
  IDx-DR**           Diagnostics,                    CNN-based DR/DME   primary-care study;      specificity; one source also      deployed in US primary     camera/workflow;
                     USA                             referral           \~900 fully screened     reports 96.1% gradability         care                       rural-India/offline/lesion-XAI
                                                                        participants                                                                          evidence not established in
                                                                                                                                                              reviewed sources

  **EyeArt**         Eyenuk, USA                2020 Autonomous         Large                    Manufacturer-reported \~96%/88%   FDA 510(k)-cleared;        Hosted/server architecture;
                                                     deep-learning DR   clinical/retrospective   for mtmDR and \~97%/90% for vtDR; commercial/international   offline complete workflow and
                                                     screening;         validation sets; Indian  another reviewed source reports   deployment                 clinician-facing explanation not
                                                     mtmDR/vtDR         smartphone-camera        95.5%/86.5%                                                  verified in reviewed sources
                                                                        studies also exist                                                                    

  **AEYE-DS**        AEYE Health,               2022 Autonomous DR      FDA clinical evidence;   Camera/configuration-dependent;   FDA 510(k)-cleared         Connectivity, offline operation,
                     USA                             detection          compatible cameras       detailed independent figures                                 and explanation details not
                                                                        include Topcon NW400 and limited in reviewed sources                                  sufficiently documented in
                                                                        Optomed Aurora                                                                        reviewed sources

  **Google / Verily  Google /            2016 onward Deep CNN DR/STDR   EyePACS (\>130k in       One postdeployment analysis:      Large real-world Indian    Cloud-connected workflow;
  ARDA**             Verily;                         screening          reviewed source) plus    97.0% sensitivity / 96.4%         deployment; hundreds of    substantial PPV gap at scale; no
                     deployed with                                      Indian datasets          specificity for severe NPDR/PDR   thousands screened         reviewed evidence of explicit
                     Indian                                                                      and 95.9%/94.9% for STDR          cumulatively               network/resource simulation or
                     eye-hospital                                                                                                                             clinician-facing lesion XAI
                     partners                                                                                                                                 

  **Medios AI +      Remidio /            2018--2023 Lightweight        Indian community/rural   \~93.0% sensitivity / 92.5%       Offline smartphone         Proprietary hardware/model;
  Remidio Fundus on  Medios, India        literature on-device DR       cohorts                  specificity for referable DR in   inference; rural Indian    binary referable-DR focus;
  Phone**                                            screening                                   one reviewed study                field validation           lesion-level XAI/calibration not
                                                                                                                                                              established

  **SELENA+**        EyRIS /                    2018 Multi-task         Multi-ethnic cohorts;    \~90.5% sensitivity / 91.6%       Singapore national         Enterprise/cloud-oriented; no
                     Singapore Eye                   deep-learning      very large image volume  specificity in reviewed material  screening and              reviewed network-simulation
                     Research                        ensemble                                                                      international validation   integration
                     Institute                                                                                                                                

  **AIDRSS**         Academic               Recent / Deep learning with Multicentric Indian      Reported \~92% sensitivity, 88%   Research-stage; arXiv      Treat performance as a research
                     multicentric     research-stage CLAHE; 5-stage     dataset                  specificity; 100% sensitivity for status in reviewed source  claim pending independent
                     Indian study                    ICDR                                        referable DR in the paper                                    replication/peer review

  **DeepDR**         Academic                 \~2021 Integrated IQA +   \>670k total images      Lesion AUCs \~0.901--0.967;       Peer-reviewed research     Strong academic precedent for
                     research                        lesion detection + across internal/external severity AUCs \~0.943--0.972      with external datasets     integrated IQA/lesion/grading,
                     system                          severity grading   datasets in reviewed                                                                  but rural portable telemedicine
                                                                        source                                                                                deployment and operational
                                                                                                                                                              simulation not established

  **Academic U-Net / Multiple                Ongoing Lesion             IDRiD, DDR and related   Task-dependent; one reviewed      Mostly                     Edge latency, field robustness,
  ResNet XAI         research                        segmentation +     datasets                 dual-stage source reports AUC     retrospective/public       automated reporting, and
  prototypes**       groups                          classification +                            \~0.93--0.95 across 5 classes     benchmarks                 operational simulation often
                                                     XAI                                                                                                      absent

  **IDRiD / DeepDRiD Academic            2018 onward Segmentation,      Benchmark datasets       Model/task dependent              Research benchmarks        Benchmark success does not
  challenge          research                        grading, quality                                                                                         establish clinical deployment
  systems**          community                       estimation,                                                                                              
                                                     landmarks                                                                                                
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### Interpretation

Existing commercial systems are stronger than a hackathon prototype in
regulatory maturity and clinical validation. Academic systems may be
stronger in lesion segmentation or XAI experimentation. The project
should therefore frame its contribution as **integration and operational
engineering**, not superior clinical accuracy.

------------------------------------------------------------------------

# 3. Existing Portable-Camera Solutions

Portable and smartphone-based fundus cameras address the hardware-access
problem but introduce focus, illumination, pupil, field-of-view,
corneal-reflection, eyelid/eyelash, and operator-variation challenges.

``` text
Tabletop Camera:
Fixed Position → Stable Illumination → Controlled Field → Higher First-Pass Quality

Handheld / Smartphone:
Handheld Motion → Reflection / Vignetting → Pupil Drift → Blur / Artifacts
```

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Solution          Camera / Form Factor              AI               Offline                   Connectivity       IQA             Validation /      Primary Limitations
                                                                                                                                    Rural Evidence    
  ----------------- --------------------------------- ---------------- ------------------------- ------------------ --------------- ----------------- ----------------------
  **Remidio         Smartphone-attached handheld      On-device Medios **Yes** for inference     Not required for   Quality         Peer-reviewed     Proprietary ecosystem;
  Fundus-on-Phone   non-mydriatic camera              AI                                         immediate          notification /  Indian            binary focus; image
  (FOP) + Medios                                                                                 inference;         filtering       community/rural   quality affected by
  AI**                                                                                           optional           reported; exact studies; rural    cataract, small pupils
                                                                                                 upload/follow-up   standalone IQA  outreach camps    and media opacity
                                                                                                                    architecture                      
                                                                                                                    not fully                         
                                                                                                                    documented                        

  **Peek Retina**   Smartphone clip-on adapter        Peek             Not confirmed for DR AI   Cloud storage      Specific        Low-resource      DR diagnostic accuracy
                                                      vision-testing                             referenced in      automated DR    deployments       in reviewed comparison
                                                      software;                                  reviewed material  IQA not         including         lower than leading
                                                      DR-specific AI                                                confirmed       multiple LMIC     dedicated systems;
                                                      not confirmed as                                                              settings          field of view/device
                                                      core feature in                                                                                 differences matter
                                                      reviewed                                                                                        
                                                      material                                                                                        

  **Forus 3nethra   Portable/handheld/semi-portable   FH-POISE /       Not independently         Wi-Fi /            Not             Indian outreach   AI-specific claims for
  family**          non-mydriatic cameras             third-party AI   confirmed                 telemedicine       independently   and rural         newer models rely
                                                      depending on                               connectivity       confirmed       programs; KIDROP  substantially on
                                                      model                                      emphasized by      beyond product  demonstrates      manufacturer material
                                                                                                 manufacturer       material        field portability 
                                                                                                                                    for ROP, not DR   

  **Optomed         Handheld non-mydriatic camera     Partner AI such  Configuration-dependent / Cellular/Wi-Fi     Built-in        Clinical and      Cost, connectivity,
  Aurora + partner                                    as AEYE-DS in    not fully verified        workflows          quality         mobile screening  small-pupil/artifact
  AI**                                                reviewed                                                      verification    use               sensitivity
                                                      material                                                      described                         

  **Volk VistaView  Handheld portable camera          Partner/cloud    Partial; acquisition can  Wi-Fi/4G for       Basic image     Community         Manual recentering and
  / iNview                                            integration      be offline but grading    remote AI          review          screening pilots  cloud dependence
  ecosystem**                                                          may be cloud-dependent                                                         
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 3.1 Image Quality as a Deployment Constraint

Image quality is not a new research problem, but it is a first-order
deployment problem.

Common rural handheld issues include:

-   Poor focus / motion blur
-   Uneven illumination
-   Vignetting
-   Pupil drift
-   Corneal reflections
-   Eyelid/eyelash obstruction
-   Media opacity
-   Missing macular/optic-disc field
-   Small pupil diameter
-   Camera-specific artifacts

A particularly useful field observation in the supplied research is:

> A rural Remidio FOP study reported **197 gradable images out of 250
> captured cases**, implying approximately a **21% ungradable rate in
> that particular study**.

This should be treated as a sourced example, **not a universal
constant**. It is appropriate as a scenario parameter or
sensitivity-analysis range in the companion Simulink model.

------------------------------------------------------------------------

# 4. Existing Offline Solutions

A critical distinction is required between **offline AI inference** and
an **offline complete clinical workflow**.

## 4.1 Offline AI Inference

Offline inference means the AI model can execute locally without an
active internet connection.

This is already demonstrated by Medios AI on Remidio smartphone
hardware.

``` text
Offline AI Inference

Camera → Local IQA → Local AI → Local Result
                         │
                         └── no continuous internet required
```

## 4.2 Offline Complete Clinical Workflow

A genuinely offline-first clinical workflow additionally needs:

-   Patient registration
-   Local data persistence
-   IQA
-   AI inference
-   Explainability generation
-   Report persistence
-   Confidence/calibration
-   Referral logic
-   Secure local queue
-   Retry logic
-   Store-and-forward synchronization
-   Clinician review
-   Referral tracking
-   Eventual EHR/telemedicine integration

``` text
Offline-First Complete Workflow

Camera
  ↓
Local IQA
  ↓
Local AI
  ↓
XAI + Confidence
  ↓
Local Encrypted Store
  ↓
Priority / Retry Queue
  ↓
Opportunistic Network Uplink
  ↓
Central Doctor Review
```

The supplied research supports offline **inference** strongly, but does
not establish that a reviewed commercial system already provides the
entire offline clinical workflow above with integrated XAI, calibration,
network-aware routing, and capacity simulation.

## 4.3 Existing Offline/Connectivity Patterns

  -----------------------------------------------------------------------
  Pattern                 What It Demonstrates    Remaining Limitation
  ----------------------- ----------------------- -----------------------
  **Medios + FOP**        Offline smartphone AI   Complete asynchronous
                          inference               review/referral
                                                  workflow not fully
                                                  documented

  **Store-and-forward     Capture and review can  Still requires eventual
  teleophthalmology**     be separated in time    transmission

  **Local workstation     No-cloud inference      Usually lack robust
  prototypes**                                    synchronization,
                                                  network retry,
                                                  encryption, and
                                                  operational routing

  **Hosted                Centralized review and  Vulnerable to
  tele-ophthalmology      queueing                connectivity failure;
  clouds**                                        not equivalent to
                                                  offline inference

  **Commercial            Immediate autonomous    Offline capability is
  point-of-care systems** screening               not consistently
                                                  established in the
                                                  reviewed public
                                                  documentation
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 5. Existing Explainable-AI Approaches

  -------------------------------------------------------------------------------------------------------------
  XAI Method        What It Explains       Strength                  Limitation             Clinical Usefulness
  ----------------- ---------------------- ------------------------- ---------------------- -------------------
  **Grad-CAM**      Coarse                 Fast, intuitive,          Coarse resolution; may Moderate as a
                    class-discriminative   architecture-compatible   highlight general      sanity-check
                    spatial regions                                  structures rather than 
                                                                     lesions                

  **Grad-CAM++**    More detailed          Potentially better        Still constrained by   Moderate / research
                    activation regions /   localization              feature-map            
                    multiple instances                               resolution;            
                                                                     DR-specific            
                                                                     quantitative evidence  
                                                                     limited                

  **HiResCAM**      Alternative            Emerging method intended  Newer; DR-specific     Emerging
                    high-resolution class  to improve faithfulness   superiority remains an 
                    attribution                                      active research        
                                                                     question               

  **Integrated      Pixel attribution      Axiomatically grounded    Computationally        Limited--moderate
  Gradients**       relative to a baseline                           expensive; noisy maps  

  **Saliency /      High-frequency input   Simple single-pass        Often highlights       Low
  Guided Backprop** sensitivity            attribution               normal vessels/edges   

  **Occlusion       Change in prediction   Model-agnostic and        Computationally        Useful for
  maps**            when regions are       intuitive                 expensive              retrospective
                    masked                                                                  validation

  **LIME / SHAP**   Contribution of        Model-agnostic; SHAP has  Superpixels/features   Limited--moderate
                    perturbed              formal game-theoretic     may not map cleanly to 
                    regions/features       basis                     lesions; expensive for 
                                                                     high-resolution images 

  **Attention       Internal attention     Can provide global        Attention is not       Research-level
  maps**            allocation             context                   automatically an       
                                                                     explanation            

  **U-Net / lesion  Explicit lesion        Closest to clinical       Requires dense         High potential
  segmentation**    regions                structural evidence       annotations and        
                                                                     compute                

  **Morphological   Candidate              Deterministic, fast,      Sensitive to noise and High when paired
  overlays**        lesions/anomalies      interpretable             parameter tuning       with CNN evidence

  **Uncertainty /   Reliability of         Supports abstention and   Calibration itself     High when well
  calibration       prediction             human review              must be validated      calibrated
  visualization**                                                                           
  -------------------------------------------------------------------------------------------------------------

## 5.1 Why Heatmaps Alone Are Insufficient

The supplied research strongly supports a critical interpretation:

> **A heatmap alone should not be presented as complete clinical
> explainability.**

A Grad-CAM map may show where a model's activation is concentrated, but
it does not prove:

-   that the highlighted pixels are a true lesion;
-   which lesion type caused the prediction;
-   that the model used medically valid reasoning;
-   that the probability is calibrated;
-   that the explanation improves clinician decisions.

One reviewed quantitative study using IDRiD lesion ground truth reported
only moderate spatial agreement for CNN/heatmap explanations, with the
best combination around **0.51** on its explainability-consistency
measure and lower values for other combinations.

Therefore, stronger XAI should combine:

1.  **Coarse spatial attention** --- Grad-CAM/related map.
2.  **Structural evidence** --- lesion proposal/mask.
3.  **Quantification** --- area, radius, location, proximity to fovea
    where feasible.
4.  **Prediction reliability** --- calibrated probability.
5.  **Human-readable summary** --- a concise rationale for review.

------------------------------------------------------------------------

# 6. Confidence, Calibration and Human-in-the-Loop Review

Raw softmax probability should not automatically be described as
clinical confidence.

The reviewed research identifies:

-   Monte Carlo Dropout
-   Bayesian CNNs
-   Deep ensembles
-   Entropy-based uncertainty
-   Temperature scaling
-   Platt scaling

as relevant approaches.

A calibrated confidence layer is particularly useful for
human-in-the-loop screening:

``` text
AI Prediction
     │
     ├── High confidence + low risk
     │        └── Routine workflow
     │
     ├── High confidence + high risk
     │        └── Priority referral
     │
     └── Low confidence / uncertain
              └── Mandatory human review
```

The research also notes that calibration quality itself must be
measured; uncertainty estimates can misdirect referral effort when
poorly calibrated.

------------------------------------------------------------------------

# 7. Comprehensive Capability Comparison

**Legend:** ✓ = demonstrated; △ = partially demonstrated / limited
evidence; ✗ = not demonstrated in reviewed evidence; ? = insufficient
public evidence.

  ---------------------------------------------------------------------------------------------------------------------------------------------
  Capability              LumineticsCore               EyeArt     AEYE-DS        Google/Verily ARDA      Remidio + Medios   DeepDR /   Proposed
                                                                                                                            Academic SIH System
  ------------------ ------------------- -------------------- ----------- ------------------------- --------------------- ---------- ----------
  DR screening                         ✓                    ✓           ✓                         ✓                     ✓          ✓  ✓ planned

  5-level grading                      △ △/✓ depending output           ?                         ?                     △ ✓ research  ✓ planned
                                                   definition                                                                        

  Referable DR                         ✓                    ✓           ✓                         ✓                     ✓          ✓  ✓ planned

  Image quality                        ✓            ✓ claimed           ?                         ?                   △/✓          ✓  ✓ planned
  assessment                                                                                                                         

  Adaptive                             ?                    ?           ?                         ?                     ?          ?  ✓ planned
  enhancement                                                                                                                        

  Vessel/structure                     ?                    ?           ?                         ?                     ?       ✓ in  ✓ planned
  analysis                                                                                                                  research 

  Lesion detection                     ?                    ?           ?                         ?                     ?          ✓  ✓ planned

  Portable camera      ✗/camera-specific                    △           ✓                         ?                     ✓          △  ✓ planned

  Offline AI                           ?                    ?           ?          ✗/cloud-oriented                     ✓    ✓ on PC  ✓ planned
  inference                                                                                                                          

  Explainability                       ?                    ?           ?                         ?                     ? ✓ research  ✓ planned

  Lesion-level                         ?                    ?           ?                         ?                     ?          ✓  ✓ planned
  evidence                                                                                                                           

  Confidence                           ?                    ?           ?                         ?                     ? △ research  ✓ planned
  calibration                                                                                                                        

  Automated report                     ✓                    ✓           ✓                         ✓                     ✓          △  ✓ planned

  Human-in-loop                        △ ✓ workflow-dependent           △                     ✓ for ✓ referral/validation          △  ✓ planned
                                                                            monitoring/adjudication                                  

  Telemedicine                         △                    ✓   ✓/claimed                         ✓                   △/✓          △  ✓ planned

  Rural deployment               Limited      Limited/claimed     Limited                         ✓                     ✓          ✗     Target

  Network-aware                        ✗                    ✗           ✗                         ✗                     ✗          ✗  ✓ planned
  workflow                                                                                                                           

  Resource                             ✗                    ✗           ✗                         ✗                     ✗          ✗  ✓ planned
  simulation                                                                                                                         

  Predictive                           ✗                    ✗           ✗                         ✗                     ✗          ✗  ✓ planned
  scalability model                                                                                                                  

  100,000+ annual                      ✗                    ✗           ✗                         ✗                     ✗          ✗  ✓ planned
  simulation                                                                                                                         
  ---------------------------------------------------------------------------------------------------------------------------------------------

### Critical interpretation

The project must not interpret this table as proving superiority.

For example:

-   ARDA has already operated at hundreds of thousands of patients
    cumulatively in India.
-   Medios has already demonstrated offline portable AI inference.
-   DeepDR already demonstrates integrated IQA + lesion detection +
    grading academically.
-   Commercial systems have much stronger regulatory and clinical
    evidence.

The project's differentiation is the **specific integration of
explainability/confidence with an explicit operational model of the same
screening pipeline**.

------------------------------------------------------------------------

# 8. What Existing Systems Already Solve

## 8.1 Mature / Well-Established

Do **not** claim novelty for:

-   Automated DR classification.
-   Referable DR detection.
-   CNN/transfer learning on retinal images.
-   Portable fundus imaging.
-   Smartphone-based screening.
-   Offline on-device inference.
-   Image-quality assessment.
-   Telemedicine retinal screening.
-   Store-and-forward workflows.
-   Automated reports/referral outputs.
-   Grad-CAM-style heatmaps.

## 8.2 Demonstrated but Limited / Fragmented

-   Integrated IQA + lesion detection + grading.
-   Lesion segmentation in research systems.
-   Human-AI hybrid review.
-   Confidence calibration.
-   Quantitative XAI validation against lesion annotations.
-   Rural deployments at varying scales.
-   AI + structured teleophthalmology pathways.

## 8.3 Emerging

-   Lesion-level evidence explicitly linked to grading.
-   Calibrated uncertainty-guided referral.
-   Clinician-validated explanation interfaces.
-   Multimodal/natural-language clinical explanations.
-   Vision-foundation-model-based XAI and calibration.
-   Network-aware AI triage policies.

## 8.4 Research-Level / Operationally Unresolved

-   Robust multi-vendor handheld-camera normalization.
-   Reliable microaneurysm-level detection across devices/sites.
-   Integrated multi-tier explainability.
-   Full offline clinical workflow with asynchronous review.
-   AI-pipeline-specific network/queue simulation.
-   District resource allocation under intermittent connectivity.
-   Explicit pre-deployment capacity simulation for 100,000+ annual
    screenings.

------------------------------------------------------------------------

# 9. What Existing Systems Do Not Solve Together

The strongest gap is not the absence of individual components. It is the
limited evidence for a **single reproducible system integrating them**.

## 9.1 Combination A --- Portable Imaging + IQA + Automated Grading

**Existing evidence:** Strong.

Remidio/Medios and DeepDR cover substantial parts of this combination.

**Remaining gap:** Small. This combination itself should not be claimed
as novel.

## 9.2 Combination B --- Offline Inference + Explainability + Clinical Review

**Existing evidence:** Partial.

Offline inference is strongly demonstrated by Medios. Explainability is
abundant in academic literature. Human review is common in clinical
workflows.

**Remaining gap:** Moderate-to-significant because the reviewed sources
did not identify a documented offline field system that simultaneously
exposes lesion-level/Grad-CAM explanation to the field
operator/reviewer.

## 9.3 Combination C --- Lesion Evidence + Calibrated Confidence + Human Review

**Existing evidence:** Each element exists academically.

**Remaining gap:** Significant because the reviewed sources did not
identify one documented system that structures human review around both
explicit lesion evidence and calibrated confidence simultaneously.

## 9.4 Combination D --- AI Screening + Telemedicine + Network Constraints + Resource Modeling

**Existing evidence:** AI + telemedicine is well established. Healthcare
discrete-event simulation is also an established methodology.

**Remaining gap:** Significant because the reviewed DR simulation
literature does not appear to model the **short-horizon AI pipeline
itself**---camera queues, AI compute queues, transmission bandwidth,
network retries, and doctor-review queues---using the specific
Simulink/SimEvents architecture proposed here.

## 9.5 Combination E --- Image-Level AI + Clinical Explainability + Operational Scalability

ARDA demonstrates AI + very large real-world scale. Academic work
demonstrates AI + explainability.

The reviewed research did not find a system explicitly modeling the
**operational scalability of an explainable AI screening pipeline
itself**.

This is arguably the clearest system-level differentiation.

------------------------------------------------------------------------

# 10. Proposed Technical Gap

The proposed project should be positioned as:

> **A reproducible, modular MATLAB/Simulink reference architecture
> coupling an explainable, confidence-aware DR-screening pipeline with
> an explicit operational-scalability simulation under rural network and
> resource constraints.**

It should **not** be positioned as:

-   the first DR AI;
-   the first portable DR AI;
-   the first offline DR AI;
-   the first Grad-CAM DR system;
-   a clinically superior replacement for regulatory-cleared systems;
-   a system that eliminates ophthalmologists.

## 10.1 Proposed Pipeline

``` text
┌──────────────────────────────────────────────────────────────────────────────┐
│ LAYER 1 — INPUT NORMALIZATION & QUALITY GATING                              │
│                                                                              │
│ Focus / blur metrics → exposure / histogram checks → field/structure checks │
│                         ↓                                                    │
│              PASS ────────────────► Continue                                 │
│              FAIL ───────────────► Operator Recapture                       │
├──────────────────────────────────────────────────────────────────────────────┤
│ LAYER 2 — ADAPTIVE PROCESSING                                                │
│                                                                              │
│ Green-channel processing → CLAHE → vignette/background normalization         │
├──────────────────────────────────────────────────────────────────────────────┤
│ LAYER 3 — DUAL-STREAM DIAGNOSTIC ENGINE                                      │
│                                                                              │
│ Stream A: Morphological lesion candidates                                   │
│ Stream B: Deep classifier (e.g., EfficientNet / selected backbone)          │
│                                                                              │
│                    ↓                                                        │
│              DR grade / referable risk                                      │
├──────────────────────────────────────────────────────────────────────────────┤
│ LAYER 4 — MULTI-TIER EXPLAINABILITY & CALIBRATION                            │
│                                                                              │
│ Grad-CAM + lesion overlays + quantitative evidence + calibrated probability │
├──────────────────────────────────────────────────────────────────────────────┤
│ LAYER 5 — HUMAN REVIEW / TELEMEDICINE                                        │
│                                                                              │
│ Risk + uncertainty → priority routing → local queue → store-and-forward     │
├──────────────────────────────────────────────────────────────────────────────┤
│ LAYER 6 — OPERATIONAL DIGITAL TWIN                                           │
│                                                                              │
│ Simulink / SimEvents: patient arrivals + resources + queues + network +      │
│ compute + doctor review + throughput + latency + 100,000+ scenario          │
└──────────────────────────────────────────────────────────────────────────────┘
```

## 10.2 Proposed Gap-to-Implementation Matrix

  --------------------------------------------------------------------------
  Proposed Gap      Existing State    Why It Matters   Prototype Feasibility
  ----------------- ----------------- ---------------- ---------------------
  IQA-driven        IQA exists, but   Prevents poor                     High
  routing +         deployment        images from      
  enhancement +     implementations   reaching         
  recapture         vary              downstream AI    

  Lesion overlays + Components        Gives clinicians       High / research
  Grad-CAM +        largely exist     multiple                     prototype
  calibrated        separately        evidence types   
  confidence                                           

  Offline-first     Offline inference Handles                           High
  inference +       demonstrated;     intermittent PHC 
  deferred review   complete workflow connectivity     
                    less documented                    

  Network-aware     Limited evidence  Prevents                          High
  queue/capacity    in DR products    operational      
  simulation                          bottlenecks from 
                                      being hidden     

  District-scale    Large deployments Supports                          High
  100k+ scenario    exist, but        staffing,        
  planning          predictive        bandwidth,       
                    simulation is     camera and       
                    different         compute          
                                      decisions        

  Reproducible      Commercial        Provides                          High
  MATLAB/Simulink   systems are       transparent      
  implementation    proprietary;      engineering      
                    research is       artifact for SIH 
                    fragmented                         
  --------------------------------------------------------------------------

------------------------------------------------------------------------

# 11. Rural India Relevance

The reviewed evidence shows that several rural-India requirements are
already addressed individually:

  -----------------------------------------------------------------------
  Requirement             Existing Evidence       Remaining Opportunity
  ----------------------- ----------------------- -----------------------
  Rural PHCs              ARDA, Remidio and Forus Integrate operational
                          programs                modeling rather than
                                                  claim rural deployment
                                                  itself as new

  Low ophthalmologist     Central motivation for  Explicitly model
  availability            Indian screening        specialist queues and
                          programs                capacity

  Portable cameras        Remidio, Forus, Peek    Multi-vendor
                          and others              normalization and
                                                  transparent IQA

  Poor/intermittent       Medios offline          Network-aware
  internet                inference;              end-to-end workflow
                          store-and-forward       simulation
                          telemedicine            

  Variable image quality  Real field attrition    IQA + recapture +
                          demonstrated            enhancement integration

  Limited computing       Smartphone edge AI      Reproducible local
                          demonstrated            inference and capacity
                                                  model

  Store-and-forward       Long-established in     Combine with
  telemedicine            India                   risk-prioritized local
                                                  queues

  Local-language          Not publicly documented Potential integration
  reporting               in reviewed systems     target; requires
                                                  explicit validation

  Large-scale screening   ARDA and other programs Predictive
                          demonstrate actual      pre-deployment
                          scale                   simulation is the
                                                  differentiator
  -----------------------------------------------------------------------

### Important caution

Existing systems should not be dismissed simply because they use cloud
or proprietary hardware. The evidence shows that several commercial and
Indian systems have substantial real-world clinical maturity. The honest
claim is that the proposed architecture is **designed for rural
operational constraints and explicitly evaluates them**, not that
existing products cannot operate in rural settings.

------------------------------------------------------------------------

# 12. Clinical Validation Lessons

Dataset performance alone is insufficient for a deployment claim.

Important lessons from the supplied research:

### 12.1 Dataset size and diversity

The evidence ranges from small field studies to DeepDR-scale datasets
with hundreds of thousands of images. Large datasets support stronger
generalization claims but do not guarantee field performance.

### 12.2 External validation

External datasets are important because performance can differ
substantially across populations, cameras and acquisition environments.

### 12.3 Prospective / multicenter validation

Prospective multicenter validation is more rigorous than retrospective
benchmark evaluation. A hackathon prototype cannot reproduce
regulatory-grade evidence within the project timeline.

### 12.4 Definition of referable DR matters

Sensitivity and specificity cannot be compared blindly across systems
because "referable DR" can correspond to different thresholds and
reference standards.

### 12.5 Gradability matters

The approximately 197/250 gradable-image result from one Remidio field
study demonstrates that image-quality attrition can materially affect
real-world throughput and performance.

### 12.6 Positive predictive value matters

High sensitivity and specificity on curated data do not automatically
translate into high PPV in a population with lower disease prevalence.
The reviewed ARDA postdeployment material is particularly important
because it illustrates that observed PPV can be substantially lower than
sensitivity/specificity.

### 12.7 Operational throughput matters

A clinical AI system can be accurate yet operationally ineffective if:

-   camera queues are too long;
-   recapture rates are high;
-   compute resources saturate;
-   bandwidth is insufficient;
-   transmission retries accumulate;
-   specialist review capacity is exceeded.

This is the reason for integrating the SimEvents operational model.

------------------------------------------------------------------------

# 13. Anti-Hallucination / Evidence Discipline

A critical feature of this document is distinguishing verified evidence
from manufacturer claims and from project assumptions.

  -----------------------------------------------------------------------
  System / Evidence       High-Confidence Finding Claim Requiring Caution
  ----------------------- ----------------------- -----------------------
  LumineticsCore          FDA-authorized          Do not infer
                          autonomous DR/DME       rural-India/offline
                          screening and pivotal   capabilities not
                          clinical evidence       documented

  EyeArt                  FDA-cleared autonomous  Do not assume complete
                          screening               offline inference from
                                                  point-of-care language

  AEYE-DS                 FDA-cleared DR          Detailed offline/XAI
                          screening;              workflow not
                          portable-camera         established here
                          compatibility reported  

  ARDA                    Large-scale Indian      Do not equate observed
                          deployment and          scale with predictive
                          postdeployment          simulation
                          performance evidence    

  Medios + FOP            Offline smartphone AI   Do not claim full
                          and Indian field        offline clinical
                          validation              workflow unless
                                                  demonstrated

  Forus 3nethra/FH-POISE  Camera portability and  Do not present
                          field programs;         manufacturer AI
                          AI-specific newer-model performance as
                          claims often            independently validated
                          manufacturer-sourced    

  AIDRSS                  Research-stage          Treat as research
                          multicentric study and  claims pending
                          reported metrics        independent replication

  DeepDR                  Peer-reviewed           Do not imply rural
                          integrated IQA +        deployment or
                          lesion + grading        operational simulation
                          research                without evidence

  Grad-CAM                Established XAI         Do not claim heatmaps
                          technique               are lesion-proof or
                                                  causal explanations

  Project 100k simulation Proposed simulation     Do not present as
                          target                  achieved deployment
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 14. Novelty Stress Test

## Claim 1

**"We are the first to apply deep learning to diabetic retinopathy."**

**Verdict: FALSE.**

Deep-learning DR screening has been established for years.

## Claim 2

**"Our use of Grad-CAM makes our AI uniquely explainable."**

**Verdict: INSUFFICIENT.**

Grad-CAM is widely used, and coarse heatmaps do not provide lesion-level
proof.

## Claim 3

**"Our offline deployment capability is completely novel."**

**Verdict: FALSE.**

Medios AI already demonstrates offline smartphone inference.

## Claim 4

**"We combine edge IQA, multi-tier explainability, confidence
calibration and a Simulink/SimEvents digital twin to model
district-scale screening feasibility for 100,000+ patients."**

**Verdict: STRONGEST DEFENSIBLE DIFFERENTIATION.**

This claim is about a specific system integration and operational
simulation rather than a novel neural architecture.

------------------------------------------------------------------------

# 15. Recommended Positioning Strategy

## 15.1 Conservative Claim

> "We propose a prototype pipeline that integrates image-quality-aware
> DR screening, lesion-level explainability, and confidence-based human
> review with an explicit MATLAB/Simulink discrete-event simulation of
> the telemedicine workflow's network and resource constraints at a
> 100,000+ patient/year design scale. Each individual AI capability
> draws on established, published techniques; the contribution is the
> integration and accompanying operational-scalability simulation, not a
> claim of superior diagnostic accuracy over existing regulatory-cleared
> or field-deployed systems."

## 15.2 Strong but Defensible Claim

> "Existing DR-screening systems have separately demonstrated offline AI
> inference, integrated IQA/lesion/grading pipelines, explainable
> heatmaps, uncertainty-aware referral research, telemedicine workflows,
> and large-scale Indian deployment. We did not find, in the reviewed
> sources, a system that combines lesion-level evidence, calibrated
> confidence and explainability into a single human-review workflow
> while also explicitly simulating the operational scalability of that
> same AI pipeline under rural network, compute, queue and
> specialist-resource constraints. Our contribution is this reproducible
> system-level integration, evaluated as a prototype."

## 15.3 Claims to Avoid

-   ❌ "We developed a completely novel AI algorithm that outperforms
    all commercial systems."
-   ❌ "Our Grad-CAM solves the black-box problem."
-   ❌ "No other system can screen DR offline."
-   ❌ "Our rural deployment is unprecedented."
-   ❌ "We have already validated 100,000 patients."
-   ❌ "Our simulation proves clinical effectiveness."
-   ❌ "Our AI eliminates ophthalmologists."

------------------------------------------------------------------------

# 16. Strongest Technical Differentiation

The most defensible differentiation identified across the three supplied
research files is:

> **An explainable, confidence-aware DR screening pipeline coupled to an
> explicit, purpose-built discrete-event simulation of that same
> pipeline's operational scalability under rural network and resource
> constraints, at a 100,000+ patient/year design scale.**

This is stronger than claiming novelty for any individual algorithm.

The distinction is important:

``` text
Existing Mature Fields

Clinical DR AI ───────────────────────► Mature
Portable / Offline AI ───────────────► Demonstrated
XAI / Lesion Segmentation ───────────► Strong Research Base
Telemedicine ────────────────────────► Established
Healthcare DES / Operations Research ► Established

                         ↓

              Proposed Integration Gap

Explainable AI
      +
Calibrated Confidence
      +
Offline / Store-and-Forward
      +
Network Constraints
      +
Compute / Camera / Doctor Queues
      +
Simulink / SimEvents
      +
100,000+ Patient Design Scenario
```

------------------------------------------------------------------------

# 17. Implementation Boundaries for SIH

The project should demonstrate a **prototype and simulation**, not claim
regulatory readiness.

### Recommended demonstration scope

1.  Acquire representative fundus images.
2.  Run deterministic IQA.
3.  Trigger recapture or rejection for poor images.
4.  Apply enhancement.
5.  Run DR classifier.
6.  Generate lesion candidates.
7.  Generate Grad-CAM.
8.  Calibrate confidence on held-out data.
9.  Produce an interpretable triage report.
10. Simulate patient arrivals and queues in SimEvents.
11. Simulate network latency/bandwidth/retries.
12. Simulate specialist review capacity.
13. Run 100,000+ annual scenarios.
14. Perform sensitivity analysis on:

-   image quality;
-   patient arrivals;
-   doctor review time;
-   network bandwidth;
-   network failure;
-   camera/operator capacity;
-   AI service time;
-   recapture probability.

### What the simulation proves

It can demonstrate:

-   throughput;
-   queue behavior;
-   resource utilization;
-   expected latency;
-   backlog;
-   sensitivity to network/resource constraints;
-   capacity requirements.

### What it does not prove

It does **not** prove:

-   clinical efficacy;
-   regulatory compliance;
-   diagnostic equivalence to FDA-cleared systems;
-   real-world population-level performance;
-   actual 100,000-patient deployment.

------------------------------------------------------------------------

# 18. Final Gap Statement

> **The individual building blocks of the proposed DR screening system
> are not novel. The defensible gap lies in their system-level
> integration: a reproducible, modular, explainability- and
> confidence-aware screening pipeline designed for rural Indian PHCs,
> coupled directly to a Simulink/SimEvents operational digital twin that
> models image-quality failures, recapture, AI compute, network
> constraints, transmission queues, specialist review, resource
> utilization, throughput and 100,000+ patient/year capacity.**

This framing is technically safer, more credible, and better aligned
with the actual evidence than claiming a new DR algorithm.

------------------------------------------------------------------------

# 19. Source-Union Appendix

The following appendix preserves the supplied research material that
contains source-specific wording, alternate comparison tables,
additional systems, detailed caveats, references, and unique claims. It
is retained so the consolidation does not silently discard substantive
research.

------------------------------------------------------------------------

# Appendix 1: Retained Material from `05_existing-solutions-gap.md`

# Existing Solutions & Technical Gap Research --- SIH 26038

## 1. Purpose

Existing-solution research prevents unsupported novelty claims and
positions the SIH prototype against capabilities already demonstrated,
deployed, clinically validated, or commercialized. Automated
diabetic-retinopathy (DR) screening, portable retinal imaging, offline
inference, image-quality feedback, telemedicine, and heatmap-based
explainability are not individually new capabilities.
\[cite:137\]\[cite:139\]\[cite:179\]

The objective is to distinguish **feature novelty** from **system-level
differentiation**. A feature can be mature---such as referable-DR
classification---while a useful system-level gap may remain in how image
quality, AI confidence, explainability, clinician review, unreliable
networks, and resource capacity are integrated and evaluated for rural
primary healthcare centres (PHCs).

This research asks: **which capabilities are established, which are
partially integrated, and which end-to-end combinations have limited
public evidence---especially for rural India and operational scale?**

## 2. Existing DR AI Systems

### Representative Systems

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  System                  Organization           Year AI Approach       DR Task                 Dataset /        Reported            Clinical          Limitations
                                                                                                Validation       Performance         Validation /      
                                                                                                                                     Deployment        
  ----------------------- -------------- ------------ ----------------- ----------------------- ---------------- ------------------- ----------------- --------------------------------------------------
  **LumineticsCore /      Digital         FDA De Novo Proprietary       More-than-mild DR and   Prospective      Sensitivity 87.2%,  FDA-cleared       Uses specified camera/workflow; public evidence
  IDx-DR**                Diagnostics,           2018 autonomous AI;    macular-edema-related   primary-care     specificity 90.7%,  autonomous AI;    does not establish offline rural-India workflow or
                          USA                         image-quality     referral criteria       study, 900 fully gradability 96.1%   deployed in US    lesion-level XAI \[cite:139\]
                                                      guidance                                  screened         in pivotal study    primary-care      
                                                                                                participants                         settings          

  **EyeArt**              Eyenuk, USA             FDA Proprietary       More-than-mild DR and   Large            Company reports 96% FDA-cleared;      Cloud/hosting architecture reported; offline
                                            clearance autonomous        vision-threatening DR   retrospective    sensitivity/88%     point-of-care and complete workflow and explanation mechanism not
                                                 2020 retinal-image AI                          and clinical     specificity for     telemedicine      publicly verified \[cite:156\]\[cite:158\]
                                                                                                implementation   mtmDR and 97%/90%   deployments       
                                                                                                evidence         for vtDR                              

  **AEYE-DS**             AEYE Health,            FDA Proprietary       More-than-mild DR       FDA clinical     Manufacturer        FDA-cleared DR    Connectivity, explanation, and offline workflow
                          USA               clearance autonomous AI                             studies;         reports             screening;        details not publicly documented
                                                 2022                                           compatible with  camera-specific     portable          \[cite:151\]\[cite:157\]\[cite:162\]
                                                                                                Topcon NW400 and performance ranges  handheld-camera   
                                                                                                Optomed Aurora                       offering claimed  

  **Medios AI + Remidio   Remidio           Published Offline           Referable DR, any DR,   Community and    Referable DR        Offline           Public evidence for calibrated confidence,
  Fundus on Phone**       Innovative       2018--2023 smartphone/edge   sight-threatening DR    rural India      sensitivity 93.0%,  smartphone        lesion-level explanation, network-aware capacity
                          Solutions,                  AI                                        studies;         specificity 92.5%   workflow          simulation is limited
                          India                                                                 specialist       in reported study   demonstrated in   \[cite:137\]\[cite:179\]\[cite:189\]\[cite:198\]
                                                                                                consensus in                         India; rural      
                                                                                                reported                             camps reported    
                                                                                                validation                                             

  **Google/Verily DR      Google Health   2016 onward Deep CNN          Referable DR screening  Retrospective    High                Strong research   Dataset performance alone does not demonstrate
  research models**       / Verily                    retinal-image                             datasets and     study-dependent     evidence;         offline PHC workflow or lesion evidence
                          research                    classification                            selected         performance         deployment        
                          groups                                                                prospective      reported            details vary by   
                                                                                                studies                              program           

  **IDRiD challenge       Academic        2018 onward Segmentation,     Lesions, optic          IDRiD research   Task-dependent      Research          Dataset size and benchmark design do not establish
  systems**               research                    classification,   disc/fovea, DR/DME      benchmark        research metrics    benchmark, not a  broad clinical deployment \[cite:176\]\[cite:177\]
                          community                   landmark          grading                                                      clinical product  
                                                      localization                                                                                     

  **DeepDRiD challenge    Academic        2020 onward Deep learning for DR grading and image    Challenge        Model-dependent     Research systems  Does not establish clinical deployment or complete
  systems**               research                    grading and       quality                 benchmark                                              telemedicine workflow \[cite:165\]
                          community                   quality                                                                                          
                                                      estimation                                                                                       

  **Lesion-segmentation   Multiple            Ongoing U-Net, attention, MA, hemorrhage,         IDRiD, DDR,      Dataset-dependent   Mostly            Annotation-dependent; generalization remains
  research models**       academic                    multi-scale       hard/soft exudate       DIARETDB1 and                        research-only     difficult \[cite:174\]\[cite:176\]
                          groups                      segmentation      segmentation            related datasets                                       
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### LumineticsCore / IDx-DR

**Verified capability:** LumineticsCore is an FDA-cleared autonomous AI
system for DR testing. The cited review describes macula- and
disc-centred images, image-quality feedback, resubmission workflow, and
primary-care deployment. \[cite:139\]

**Clinical evidence:** Its pivotal prospective study included 900 fully
screened primary-care participants and reported 87.2% sensitivity, 90.7%
specificity, and 96.1% gradability for referable DR. \[cite:139\]

**Interpretation:** This system already demonstrates that autonomous AI,
image-quality handling, point-of-care screening, and referral workflows
are not novel. Public documentation reviewed here does not establish an
offline, portable, explainable, network-aware rural-India system with
operational capacity modelling.

### EyeArt

**Verified capability:** EyeArt is marketed by Eyenuk as an FDA-cleared
autonomous AI system for point-of-care detection of more-than-mild and
vision-threatening DR. The company states that it provides immediate
diagnostic results, image-quality feedback, multi-camera compatibility,
EHR integration, and analytics. \[cite:156\]

**Manufacturer claim:** Eyenuk reports 96% sensitivity and 88%
specificity for more-than-mild DR, plus 97% sensitivity and 90%
specificity for vision-threatening DR. \[cite:156\]

**Independent interpretation:** EyeArt is a mature comparator for
automated screening and telemedicine-compatible deployment. Its publicly
described architecture includes a local client, server, and remotely
hosted analysis engine, so complete offline inference should not be
assumed from public evidence. \[cite:158\]

### AEYE-DS

**Verified capability:** FDA documentation indicates AEYE-DS is intended
for automatic detection of more-than-mild DR in adults with diabetes who
have not previously been diagnosed with DR. \[cite:151\]\[cite:152\]

**Manufacturer claim:** AEYE Health states that its system supports
desktop and portable camera workflows, produces results at point of
care, and has defined performance ranges for compatible cameras.
\[cite:157\]\[cite:162\]

**Independent interpretation:** AEYE-DS demonstrates that portable,
autonomous, FDA-cleared DR screening exists. It reduces the
defensibility of any claim that portable-camera AI alone is a major
novelty.

### Medios AI + Remidio Fundus on Phone

**Verified capability:** In rural north India, trained Eye Mitra
Opticians used a handheld Remidio non-mydriatic Fundus on Phone camera
with offline Medios AI to screen for referable DR; the cited report
states that the system generated a report within 20 seconds of image
capture. \[cite:137\]

**Clinical deployment evidence:** The same rural implementation found
that image quality could be insufficient in people with cataract, small
pupils, corneal opacity, or other media opacity, demonstrating that
real-world image gradability remains a major operational constraint.
\[cite:137\]

**Interpretation:** Offline AI and portable camera deployment in rural
India are already demonstrated. The project should not claim first
offline portable AI DR screening for rural India.

## 3. Existing Portable-Camera Solutions

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Solution           Camera                AI                         Portable     Offline Connectivity         IQA             Clinical          Rural Deployment        Limitations
                                                                                                                                Validation                                
  ------------------ --------------------- ---------------- ------------------ ----------- -------------------- --------------- ----------------- ----------------------- --------------------------------------
  **Remidio Fundus   Smartphone-attached   Medios offline                    ✓    ✓ for AI Not required for     Quality         Published Indian  ✓ Rural Indian camps    Image quality degraded by opacity,
  on Phone +         handheld              AI                                    inference immediate inference; notification    community/rural   demonstrated            small pupils, cataract; public
  Medios**           non-mydriatic camera                                                  may be needed for    reported        studies                                   lesion/XAI details limited
                                                                                           central follow-up                                                              \[cite:137\]\[cite:179\]\[cite:189\]

  **Optomed Aurora + Portable handheld     AEYE-DS                           ✓           ? Manufacturer         ? Not fully     FDA-cleared       Primary-care/portable   Offline capability not publicly
  AEYE-DS**          camera                autonomous AI                                   describes            publicly        indication with   use claimed             verified; explanation/telemedicine
                                                                                           internet-connected   documented      compatible camera                         details limited
                                                                                           camera workflow                                                                \[cite:157\]\[cite:162\]

  **Desktop Topcon + Desktop non-mydriatic LumineticsCore                    ✗           ? Integrated clinical  ✓ Image-quality Prospective       Primary care;           Camera form factor/workflow may be
  LumineticsCore**   camera                                                                workflow; connection guidance        pivotal and       rural-specific evidence less suited to outreach \[cite:139\]
                                                                                           requirements not                     real-world        limited                 
                                                                                           fully established                    implementation                            
                                                                                           publicly                             studies                                   

  **Multi-camera     Multiple supported    EyeArt           △ camera-dependent           ? Public hosted/server ✓ Manufacturer  FDA-cleared;      Rural/remote programs   Offline inference not verified;
  EyeArt workflow**  retinal cameras                                                       architecture         claims          implementation    claimed                 product claims need independent
                                                                                                                real-time       studies exist                             confirmation \[cite:156\]\[cite:158\]
                                                                                                                quality                                                   
                                                                                                                feedback                                                  

  **Smartphone AI    Smartphone adapters   Varies: offline                   ✓           △ Varies by system     Often included  Usually pilot     Some community/outreach Research prototypes often lack
  research systems**                       or cloud CNNs                                                        but             validation        studies                 multicentre prospective evidence
                                                                                                                inconsistent                                              \[cite:179\]\[cite:181\]
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### Image-Quality Findings

Image quality is neither a new problem nor a solved deployment detail.
Automated quality assessment has long been investigated using clarity
and field definition; one published system defined adequate quality
using visibility of macular vessels and required field structures,
including optic disc and relevant retinal coverage. \[cite:180\]

Current reviews report substantial variation in how DR datasets and
studies define and report focus, illumination, field definition, and
artefacts. They also warn that an apparently well-focused and
illuminated image can still be ungradable if the macula is absent.
\[cite:187\]

**Project implication:** Explicit quality decision and recapture
workflow is justified and useful, but it is not itself novel.
Differentiation should be the integration of IQA outputs with
enhancement, routing, confidence, human review, and operational
simulation.

## 4. Existing Offline Solutions

  -------------------------------------------------------------------------------------------------------------------------------------
  System               Local AI              Cloud Required     Offline   Store-and-Forward Connectivity     Limitation
                                                              Inference                     Dependency       
  -------------------- --------------- -------------------- ----------- ------------------- ---------------- --------------------------
  **Medios + Fundus on ✓               Not for immediate AI           ✓         △ Not fully Can screen with  Complete referral workflow
  Phone**                                            result                   documented in limited/no       still requires
                                                                           reviewed sources continuous       communication and care
                                                                                            internet         coordination
                                                                                                             \[cite:137\]\[cite:179\]

  **EyeArt**           Local client         Hosted analysis           ?                   △ Likely requires  Offline autonomous
                       documented         engine documented                                 connectivity for inference not publicly
                                                                                            hosted analysis  verified \[cite:158\]
                                                                                            based on public  
                                                                                            architecture     

  **AEYE-DS**          Point-of-care     Internet-connected           ?                   ? Details vary by  Do not assume offline
                       result claimed      camera described                                 configuration    workflow from portable
                                                                                                             camera alone \[cite:157\]

  **LumineticsCore**   Local                   Not publicly           ?                   ? Clinical         Offline complete workflow
                       device/camera          resolved here                                 integration      not publicly documented
                       workflow                                                             demonstrated     \[cite:139\]

  **Smartphone         Varies                        Varies        Some      Often possible Depends on       Pilot evidence may not
  research workflow**                                         systems ✓                     implementation   establish complete
                                                                                                             clinical telemedicine
                                                                                                             system
                                                                                                             \[cite:179\]\[cite:181\]
  -------------------------------------------------------------------------------------------------------------------------------------

### Offline AI vs Offline Clinical Workflow

**Offline inference** means a local device can produce an AI screening
result without active internet connectivity.

**Offline complete workflow** also requires local storage, data
security, report persistence, retry/synchronization, clinician-review
routing, referral tracking, and eventual integration with telemedicine
or health records.

Medios/Fundus on Phone literature strongly supports offline inference in
rural India, but provides insufficient public evidence that it includes
the full network-aware, asynchronous clinician-review and
capacity-planning architecture proposed in this project.
\[cite:137\]\[cite:179\]

## 5. Existing Explainable-AI Approaches

  ------------------------------------------------------------------------------------------------------------------------------------------------
  XAI Method                  DR Application                What It Explains       Strength                Limitation             Clinical
                                                                                                                                  Usefulness
  --------------------------- ----------------------------- ---------------------- ----------------------- ---------------------- ----------------
  **Grad-CAM**                DR grade/referable DR         Regions contributing   Fast and visually       Coarse heatmap; may    Supporting
                              classification                to selected class      intuitive               not identify true      visualization,
                                                            score                                          lesions                not lesion proof

  **Grad-CAM++**              Small-lesion/classification   Higher-detail class    May improve             Still attribution, not Research support
                              research                      activation regions     localization            causal clinical        
                                                                                                           reasoning              

  **Saliency / integrated     Pixel-attribution research    Sensitivity to input   Fine-grained            Noisy/unstable;        Limited unless
  gradients**                                               pixels                 attribution possible    difficult              validated
                                                                                                           interpretation         

  **Occlusion maps**          Classifier evidence           Effect of masking      Model-agnostic,         Computationally        Useful
                              inspection                    image regions          intuitive               expensive              retrospective
                                                                                                                                  validation

  **LIME / SHAP**             Local image-prediction        Contribution of        Model-agnostic          Superpixels may not    Limited clinical
                              explanations                  perturbed                                      map to lesions         translation
                                                            superpixels/features                                                  

  **Attention maps**          Attention CNN/transformer DR  Internal attention     May provide global      Attention is not       Research-level
                              models                        allocation             context                 automatically          
                                                                                                           explanation            

  **Segmentation-based        Lesion segmentation plus      Exudate, hemorrhage,   Closer to clinical      Requires lesion        Stronger
  explanation**               grade prediction              MA masks               evidence                labels; errors         potential
                                                                                                           propagate              clinical
                                                                                                                                  usefulness

  **Uncertainty/calibration   Confidence-aware              Reliability of         Supports                Requires               Valuable for
  display**                   classification                predicted probability  abstention/escalation   calibration/external   clinician review
                                                                                                           validation             
  ------------------------------------------------------------------------------------------------------------------------------------------------

Grad-CAM, LIME, SHAP, and related approaches are common in DR-XAI
literature, but clinical validation and standardized evaluation remain
limited. \[cite:143\]\[cite:148\]

A heatmap alone should **not** be treated as meaningful clinical
explainability. It may show regions influential to a model but does not
prove that those regions are true lesions, that the model used medically
valid reasoning, or that the explanation improves clinician decisions.
\[cite:144\]

### Confidence and Calibration

Confidence should not be interpreted directly from uncalibrated softmax
probabilities. A 2025 uncertainty-aware DR study reported that
calibration materially reduced expected calibration error in its
experimental setting, reinforcing the need to evaluate reliability
rather than merely display raw confidence. \[cite:195\]

## 6. Comparison Table

Legend: **✓** demonstrated; **△** partially demonstrated or limited
evidence; **✗** not demonstrated in reviewed evidence; **?**
insufficient public evidence.

  ----------------------------------------------------------------------------------------------------------------------------------
  Capability                           LumineticsCore             EyeArt    AEYE-DS     Medios +     Academic    Our Proposed System
                                                                                       Fundus on   Lesion/XAI 
                                                                                           Phone      Systems 
  ------------------------ -------------------------- ------------------ ---------- ------------ ------------ ----------------------
  DR screening                                      ✓                  ✓          ✓            ✓            ✓              ✓ planned

  5-level grading                                   △         ✓ reported          ?            △            ✓              ✓ planned
                                                          classification                                      
                                                                   basis                                      

  Referable DR                                      ✓                  ✓          ✓            ✓            ✓              ✓ planned

  Image quality assessment                          ✓          ✓ claimed          ?            ✓            ✓              ✓ planned

  Image enhancement                                 ?                  ?          ?            △            ✓              ✓ planned

  Vessel analysis                                   ?                  ?          ?            ?            ✓              △ planned

  Lesion                                            ?                  ?          ?            ?            ✓              △ planned
  detection/segmentation                                                                                      

  Portable camera                                   ✗ △ camera-dependent          ✓            ✓            △   ✓ compatible planned

  Offline capability                                ?                  ?          ?            ✓            △          ✓ planned for
                                                                                                                inference/simulation

  Explainability                                    ?                  ?          ?            ?            ✓              ✓ planned

  Lesion-level evidence                             ?                  ?          ?            ?            ✓              △ planned

  Confidence calibration                            ?                  ?          ?            ?            △              ✓ planned

  Automated report                                  ✓                  ✓          ✓            ✓            △              ✓ planned

  Human-in-loop review     △ implementation-dependent ✓ workflow claimed          △   △ referral            △              ✓ planned
                                                                                        workflow              

  Telemedicine                                      △                  ✓  ✓ claimed            △            △              ✓ planned

  Rural deployment                                  △          △ claimed          △            ✓            △               ✓ target

  Network-aware workflow                            ?                  ?          ?            ?            ?              ✓ planned

  Resource simulation                               ?                  ?          ?            ?            ?              ✓ planned

  Scalability modeling       △ health-system analyses        ✓ analytics ✓ scalable △ deployment            ✗              ✓ planned
                                                                 claimed      claim     examples              

  100,000+ patient                                  ?                  ?          ?            ?            ✗              ✓ planned
  scenario                                                                                                    
  ----------------------------------------------------------------------------------------------------------------------------------

The proposed system is **not automatically superior**. Commercial
systems are stronger on regulatory maturity, controlled clinical
workflows, and real-world deployment. Academic systems are often
stronger on lesion segmentation and XAI experimentation.

## 7. What Existing Systems Already Solve

### Mature / Well-Established

  -----------------------------------------------------------------------
  Capability                          Evidence-Based Assessment
  ----------------------------------- -----------------------------------
  Automated DR classification         Mature in research and commercial
                                      systems

  Referable DR detection              Mature; FDA-cleared systems exist

  Autonomous point-of-care DR         Established in several commercial
  screening                           systems

  Portable fundus imaging             Established through smartphone and
                                      handheld systems

  Offline smartphone DR inference     Demonstrated in Indian community
                                      and rural settings

  Image-quality assessment /          Established research area;
  gradability                         implemented in commercial workflows

  Telemedicine retinal screening      Established before modern deep
                                      learning

  Automated reports / referral        Commercially implemented in
  outputs                             multiple systems
  -----------------------------------------------------------------------

Autonomous systems such as LumineticsCore, EyeArt, and AEYE-DS already
solve automated DR screening in real clinical settings.
\[cite:139\]\[cite:156\]\[cite:157\] Portable offline inference has also
been demonstrated through Medios with the Remidio Fundus on Phone
platform in India. \[cite:137\]\[cite:179\]

### Demonstrated but Limited

  -----------------------------------------------------------------------
  Capability                          Evidence-Based Assessment
  ----------------------------------- -----------------------------------
  5-level DR grading in deployed      Present in research and some
  systems                             commercial classification
                                      frameworks; less consistently
                                      documented as primary clinical
                                      output

  Lesion segmentation                 Strong academic research; limited
                                      routine commercial disclosure

  Human-AI hybrid review              Demonstrated in selected
                                      teleophthalmology workflows

  Confidence calibration              Active research; rarely detailed in
                                      commercial product documentation

  Rural deployment                    Demonstrated by selected pilots;
                                      wide-scale evidence varies

  Store-and-forward workflow          Established telemedicine principle;
                                      product details vary
  -----------------------------------------------------------------------

### Emerging

  -----------------------------------------------------------------------
  Capability                          Evidence-Based Assessment
  ----------------------------------- -----------------------------------
  Lesion-level evidence linked to DR  Active research; not standard
  grade                               product capability

  Calibrated uncertainty-guided       Active research; limited deployment
  referral                            evidence

  Clinician-validated explanation     Limited standardization and
  interfaces                          clinical-validation evidence

  Offline complete workflow with      Plausible and partly demonstrated,
  asynchronous review                 incompletely documented

  Network-aware AI triage policies    Limited public evidence
  -----------------------------------------------------------------------

### Research-Level

  -----------------------------------------------------------------------
  Capability                          Evidence-Based Assessment
  ----------------------------------- -----------------------------------
  Reliable microaneurysm-level        Difficult due to tiny lesions and
  detection across devices/sites      annotation variability

  Causal/clinically validated XAI     Not established by heatmaps alone

  Integrated capacity simulation from Limited public evidence
  PHC to specialist review            

  District resource allocation under  Limited public evidence
  connectivity constraints            

  End-to-end simulation for 100,000+  Limited public evidence in reviewed
  annual screenings                   systems
  -----------------------------------------------------------------------

## 8. What They Don't Solve Together

  ------------------------------------------------------------------------------------------
  Capability           Existing       Systems Found     Degree of       Remaining Gap
  Combination          Evidence                         Integration     
  -------------------- -------------- ----------------- --------------- --------------------
  Portable imaging +   Strong         Medios/Remidio;   High for        Not a novelty claim
  IQA + automated DR                  AEYE-DS;          screening       
  grading                             commercial                        
                                      systems                           

  Offline inference +  Strong         Medios + Fundus   High for        Complete
  rural India                         on Phone          initial         asynchronous
  deployment                                            screening       review/network
                                                                        workflow not fully
                                                                        documented

  AI screening +       Demonstrated   EyeScreen,        Moderate/high   Detailed
  telemedicine + human                AI-human hybrid                   network/resource
  review                              programs                          modelling limited

  Image-quality        Demonstrated   LumineticsCore;   Moderate/high   Adaptive enhancement
  feedback +                          Medios; academic                  and downstream
  recapture + referral                IQA systems                       confidence
  workflow                                                              integration limited

  DR grading +         Strong         Many academic XAI High in         Clinical explanation
  Grad-CAM/attention   research       studies           research        validation weak
  heatmaps             evidence                                         

  Lesion               Demonstrated   IDRiD/DeepDRiD    Moderate        Deployment and
  segmentation + DR    in research    challenge systems                 external validation
  grading                                                               limited

  Lesion-level         Limited        Isolated research Low             Strong candidate
  evidence +                          components                        integration gap
  calibrated                                                            
  confidence +                                                          
  clinician review                                                      

  Offline AI + XAI +   Limited public No fully          Low             Defensible prototype
  calibrated           evidence       documented                        gap
  confidence +                        comparator in                     
  store-and-forward                   reviewed sources                  
  review                                                                

  AI screening +       Limited public Telemedicine      Low             Strong operational
  network              evidence       studies, not                      simulation gap
  constraints +                       integrated DR                     
  queue/resource                      products                          
  modelling                                                             

  Rural PHC            Limited public No reviewed DR    Low             Strong
  screening +          evidence       product documents                 system-engineering
  100,000-patient                     this reproducible                 gap
  annual capacity                     model                             
  simulation                                                            
  ------------------------------------------------------------------------------------------

The gap is not that individual components are absent. The evidence
indicates limited public documentation of a **single, reproducible,
system-level architecture** connecting IQA/recapture, adaptive
processing, DR grading, evidence visualization, calibrated confidence,
human review, offline/store-and-forward operation, network constraints,
reviewer queues, and district-scale capacity analysis.

## 9. Our Technical Gap

The proposed system should be positioned as a **prototype for
integrated, explainability-aware and operations-aware DR
tele-screening**, not as the first AI DR screener, first portable DR
camera, first offline DR tool, or first XAI DR model.

  ----------------------------------------------------------------------------------------------------
  Proposed Gap                 Evidence              Existing Solutions Why It Matters  Feasible for
                                                                                        Prototype?
  ---------------------------- --------------------- ------------------ --------------- --------------
  IQA-driven routing linked to IQA exists;           LumineticsCore,    Robustness to   ✓
  enhancement, recapture, and  deployment reporting  Medios, academic   variable PHC    
  AI confidence                is variable           IQA systems        image quality   

  Lesion overlays plus         XAI and segmentation  Academic           More            △; research
  Grad-CAM plus calibrated     exist mostly          XAI/segmentation   interpretable   prototype
  confidence in clinician      separately            systems            evidence than   
  report                                                                raw class       
                                                                        output          

  Offline-first inference with Offline AI            Medios             Relevant to     ✓
  deferred/store-and-forward   demonstrated; full    demonstrates       intermittent    
  review                       workflow integration  offline inference  PHC             
                               incompletely                             connectivity    
                               documented                                               

  Network-aware queue/capacity Limited public        Telemedicine       Avoids          ✓
  simulation                   evidence in reviewed  exists, operations operational     
                               DR products           modelling rarely   failure of      
                                                     reported           clinically good 
                                                                        AI              

  District-scale 100,000+      Public                Commercial systems Supports        ✓
  scenario planning            resource-simulation   offer analytics,   staffing,       
                               architectures limited not necessarily    bandwidth,      
                                                     reproducible       camera, and     
                                                     simulation         compute         
                                                                        decisions       

  MATLAB/Simulink reproducible Commercial tools are  No reviewed system Transparent     ✓
  architecture                 proprietary; research documents this     student         
                               often isolated        exact stack        prototype and   
                                                                        scenario        
                                                                        analysis        
  ----------------------------------------------------------------------------------------------------

### Rural India Relevance

Rural India requires portable acquisition by non-specialists, management
of focus/illumination/field problems, limited ophthalmologist access,
intermittent connectivity, constrained computing, asynchronous referral,
and scalable PHC operations. Medios/Remidio studies already show offline
screening can work but also document image-quality failures due to
cataract, small pupils, and media opacity. \[cite:137\]

## 10. Our System-Level Differentiation

  ----------------------------------------------------------------------------
  Dimension         Existing          Our Differentiation    Evidence Strength
                    Solutions                                
  ----------------- ----------------- ---------------------- -----------------
  Technical AI      Strong autonomous Transparent modular    Moderate
                    screening already pipeline, not claim of 
                    exists            superior diagnosis     

  Image quality     Existing systems  Connect quality        Moderate
                    use IQA/feedback  outcome to             
                                      enhancement,           
                                      recapture, confidence, 
                                      operations routing     

  Explainability    Grad-CAM/XAI      Combine heatmap        Moderate
                    common in         caveats, lesion        
                    research          overlays where         
                                      available, calibration 
                                      outputs                

  Human review      Hybrid workflows  Explicitly model       Moderate
                    exist             capacity, routing,     
                                      priority, review       
                                      delays                 

  Offline/edge      Medios            Offline-first plus     Moderate
                    demonstrates      store-and-forward      
                    offline           review and             
                    smartphone AI     connectivity           
                                      simulation             

  Telemedicine      Mature field      Model transmission,    Moderate
                                      retry, queues,         
                                      asynchronous review    

  Operational       Commercial        Reproducible           Stronger
  planning          systems report    Simulink/SimEvents     
                    analytics;        capacity and           
                    academic workflow bottleneck model       
                    work exists                              

  Engineering       Commercial tools  MATLAB + Simulink      Moderate to
  reproducibility   are proprietary;  architecture with      strong
                    research          assumptions/scenario   
                    components        sweeps                 
                    fragmented                               
  ----------------------------------------------------------------------------

### Strongest Defensible Differentiation

> **The project is an integrated, reproducible prototype that treats DR
> AI screening as a rural healthcare-delivery system---not only as an
> image-classification task---by coupling image-quality-aware
> processing, explainability and calibrated confidence, human review,
> offline/store-and-forward telemedicine, and Simulink-based resource,
> network, and capacity simulation for district-scale deployment.**

This is system-engineering differentiation, not a claim to be the first
DR classifier, portable camera, offline AI tool, Grad-CAM DR model, or
telemedicine workflow.

## Clinical Validation Analysis

Dataset performance alone is insufficient for deployment because it does
not establish performance on new cameras, operators, rural populations,
ungradable images, cataracts, small pupils, calibration reliability,
safety at operating threshold, usefulness of explanations, follow-up
completion, or workflow feasibility.

LumineticsCore had prospective primary-care validation, while EyeArt and
AEYE-DS have regulatory and clinical evidence.
\[cite:139\]\[cite:140\]\[cite:151\] Many academic systems instead
report benchmark performance, which should not be presented as proof of
clinical readiness.

IDRiD provides masks for microaneurysms, hemorrhages, hard exudates, and
soft exudates, with optic-disc/fovea and grading tasks. It is useful for
lesion-evidence prototyping but insufficient alone for wide clinical
generalization. \[cite:176\]\[cite:177\]

## Recommended Positioning

### Conservative Claim

> Our project develops a MATLAB-based prototype for explainable DR
> screening that integrates fundus-image quality assessment, DR triage,
> clinician-review support, and telemedicine workflow simulation for
> rural primary healthcare scenarios.

### Strong but Defensible Claim

> Existing systems have demonstrated autonomous DR screening, portable
> imaging, offline inference, and telemedicine independently or in
> selected workflows. Our differentiation is a reproducible system-level
> prototype integrating IQA-driven recapture and enhancement,
> explainability with confidence calibration, human-in-the-loop review,
> offline/store-and-forward telemedicine, and Simulink-based modelling
> of bandwidth, reviewer capacity, queues, bottlenecks, and 100,000+
> annual screening scenarios.

### Claims We Should Not Make

-   "The first AI system for DR screening in rural India."
-   "The first offline portable DR screening system."
-   "The first explainable DR AI system."
-   "The first telemedicine DR workflow."
-   "The first autonomous DR screening system."
-   "Clinically diagnostic" or "ready for clinical deployment" without
    prospective validation and appropriate regulation.
-   "Grad-CAM proves the model detected the lesion."
-   "Sub-pixel microaneurysm detection" without rigorous lesion-level
    validation.
-   "Better than FDA-cleared systems" without a fair prospective
    comparison.

## References

1.  **Bahl, A., and Rao, S.** "Diabetic retinopathy screening in rural
    India with portable fundus camera and artificial intelligence using
    eye mitra opticians from Essilor India." *Eye*, 2022. DOI:
    10.1038/s41433-020-01350-8.
    https://pmc.ncbi.nlm.nih.gov/articles/PMC8727670/. Supports rural
    Indian deployment, portable Remidio Fundus on Phone camera, offline
    Medios AI, rapid report generation, and image-quality limitations.
    \[cite:137\]
2.  **Teng, C. W., et al.** "Autonomous Artificial Intelligence in
    Diabetic Retinopathy Testing---Lessons Learned on Successful Health
    System Adoption." *Ophthalmology Science*, 2026. DOI:
    10.1016/j.xops.2025.100935.
    https://pmc.ncbi.nlm.nih.gov/articles/PMC12553049/. Supports
    FDA-cleared systems, pivotal studies, implementation evidence, image
    gradability, and adoption constraints. \[cite:139\]
3.  **Eyenuk.** "EyeArt: FDA-Cleared Autonomous AI Screening for
    Diabetic Retinopathy." Official source. https://www.eyenuk.com/.
    Supports manufacturer claims about point-of-care screening,
    image-quality feedback, compatibility, and performance. \[cite:156\]
4.  **AEYE Health.** "AEYE Diagnostic Screening." Official source.
    https://www.aeyehealth.com/aeye-diagnostic-screening. Supports
    manufacturer claims about portable/desktop camera workflows and
    point-of-care screening. \[cite:157\]
5.  **U.S. Food and Drug Administration.** "AEYE-DS 510(k) Summary."
    https://www.accessdata.fda.gov/cdrh_docs/pdf24/K240058.pdf. Supports
    intended use for automatic detection of more-than-mild DR in adults
    with diabetes. \[cite:151\]
6.  **Natarajan, S., Jain, A., Krishnan, R., Rogye, A., and Sivaprasad,
    S.** "Diagnostic Accuracy of Community-Based Diabetic Retinopathy
    Screening With an Offline Artificial Intelligence System on a
    Smartphone." *JAMA Ophthalmology*, 2019.
    https://jamanetwork.com/journals/jamaophthalmology/fullarticle/2747315.
    Supports offline smartphone AI evaluation. \[cite:181\]
7.  **Rajalakshmi, R., et al.** "Smartphone imaging integrated with
    offline artificial intelligence for diabetic retinopathy
    screening." 2021. https://pmc.ncbi.nlm.nih.gov/articles/PMC8725117/.
    Supports offline smartphone AI in remote/rural contexts with
    unreliable internet. \[cite:179\]
8.  **Fleming, A. D., et al.** "Automated assessment of diabetic retinal
    image quality based on clarity and field definition." *Investigative
    Ophthalmology & Visual Science*, 2006.
    https://pubmed.ncbi.nlm.nih.gov/16505050/. Supports
    clarity/field-defined image-quality assessment. \[cite:180\]
9.  **Costa, P., et al.** "Image quality assessment of retinal fundus
    photographs for diabetic retinopathy in the machine learning era: a
    review." *Eye*, 2023.
    https://www.nature.com/articles/s41433-023-02717-3. Supports the
    importance and inconsistency of IQA criteria. \[cite:187\]
10. **DeepDRiD Challenge Authors.** "DeepDRiD: Diabetic
    Retinopathy---Grading and Image Quality Estimation Challenge." 2022.
    https://pmc.ncbi.nlm.nih.gov/articles/PMC9214346/. Supports DR
    grading and IQA benchmark research. \[cite:165\]
11. **IDRiD Grand Challenge.** "Indian Diabetic Retinopathy Image
    Dataset." 2018. https://idrid.grand-challenge.org/Data/. Supports
    lesion segmentation, optic-disc/fovea localization, and DR/DME
    grading tasks. \[cite:176\]\[cite:177\]
12. **Xu, et al.** "Advanced Segmentation of Diabetic Retinopathy
    Lesions Using Multi-Scale Attention and Lesion Perception."
    *Algorithms*, 2024. https://www.mdpi.com/1999-4893/17/4/164.
    Supports the active research status and difficulty of lesion
    segmentation. \[cite:174\]
13. **Systematic Review Authors.** "Early Detection of Diabetic
    Retinopathy Through Explainable AI: A Systematic Literature
    Review." 2025.
    https://ejournal.uin-suka.ac.id/saintek/ijid/article/view/5200.
    Supports use of Grad-CAM, LIME, and SHAP in DR-XAI literature.
    \[cite:143\]
14. **Review Authors.** "A Comprehensive Review of Explainable
    Artificial Intelligence in Computer Vision." *Sensors*, 2025.
    https://www.mdpi.com/1424-8220/25/13/4166. Supports limitations of
    attribution/attention methods and need for explanation evaluation.
    \[cite:144\]
15. **Uncertainty-Aware DR Study Authors.** "Uncertainty-aware diabetic
    retinopathy detection using deep learning enhanced by Bayesian
    approaches." *Scientific Reports*, 2025.
    https://www.nature.com/articles/s41598-024-84478-x. Supports
    calibration and expected calibration error as reliability
    considerations. \[cite:195\]

------------------------------------------------------------------------

# Appendix 2: Retained Material from `05_existing-solutions-gap (1).md`

# 05 --- Existing Solutions & Technical Gap Research

### SIH 26038 --- Explainable AI for Diabetic Retinopathy Screening in Rural India

------------------------------------------------------------------------

# 1. Purpose

**Why existing-solution research is necessary.** A hackathon or
prototype proposal is only as credible as its understanding of the field
it claims to improve. Diabetic retinopathy (DR) screening AI is one of
the most mature areas of applied medical AI --- it includes the
first-ever FDA-authorized autonomous diagnostic AI system,
multi-hundred-thousand-patient real-world deployments in India itself,
and a large academic literature on explainability and uncertainty. Any
claim of novelty made without checking this landscape first risks
re-proposing something that already exists, which would be a critical
weakness in a technical evaluation.

**Why understanding competitors/research systems matters.** It lets the
team (a) avoid wasting effort re-building a solved sub-problem, (b)
correctly calibrate which parts of the proposed system are genuinely new
versus standard practice, and (c) anticipate the most likely evaluator
pushback ("Doesn't Google/Remidio/IDx already do this?") with a
prepared, evidence-based answer.

**What this research is intended to establish.** A factual account of:
which capabilities in the proposed pipeline are already mature and
widely deployed; which are demonstrated only in research settings; which
combinations of capabilities have limited public evidence of
integration; and, from that, what a defensible (not merely asserted)
technical gap looks like for this specific project.

**How this research will help define the actual technical gap.** By
deliberately trying to disprove the project's uniqueness first (per the
critical research principle below), any gap that survives this scrutiny
is more likely to hold up under evaluator questioning than one arrived
at by assuming novelty from the outset.

## Feature novelty vs. system-level differentiation

-   **Feature novelty** asks: "Does capability X exist anywhere?" For
    nearly every individual capability in this project's pipeline (image
    quality assessment, DR grading, Grad-CAM explainability, offline
    inference, telemedicine referral), the answer found in this research
    is **yes** --- each exists in at least one published or deployed
    system. Claiming novelty at the level of an individual feature is
    therefore not defensible.
-   **System-level differentiation** asks: "Does a system exist that
    integrates this *particular combination* of capabilities, validated
    and deployed together, for this particular context (rural Indian
    PHCs, at 100,000+ patient/year scale, with an explicit
    resource/network/queue simulation component)?" This is a much
    narrower and more defensible question, and it is the level at which
    this document seeks to establish a gap --- not by claiming any
    single piece is unprecedented, but by evidencing that the specific
    combination is not established in the literature or in deployed
    products reviewed here.

------------------------------------------------------------------------

# 2. Existing DR AI Systems

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  System           Organization                         Year AI Approach     DR Task              Dataset             Performance               Clinical Validation        Deployment          Limitations
  ---------------- ------------------------ ---------------- --------------- -------------------- ------------------- ------------------------- -------------------------- ------------------- -------------------------
  LumineticsCore   Digital Diagnostics         2018 (De Novo CNN-based       Referable DR /       Proprietary;        87% sensitivity, 90%      FDA De Novo--authorized    Deployed in US      US-market-focused;
  (formerly        Inc. (USA)                 authorization) autonomous      diabetic macular     pivotal trial       specificity for referable (2018); pivotal clinical   primary-care        requires a specific
  IDx-DR)                                                    diagnostic      edema (DME)          dataset             DR/DME in the pivotal     trial published            settings; CMS       compatible camera (e.g.,
                                                             algorithm       detection,                               trial                                                reimbursement       Topcon TRC-NW400); not
                                                                             point-of-care, no                                                                             established         documented as
                                                                             specialist overread                                                                                               rural-India-deployed

  EyeArt           Eyenuk, Inc. (USA)              2020 (FDA CNN-based deep  More-than-mild DR    Proprietary; also   Sensitivity/specificity   FDA 510(k)-cleared on the  Deployed            Independent Indian
                                                     510(k)) learning        (mtmDR) and          evaluated on Indian reported in independent   LumineticsCore predicate   commercially (US);  validation used a
                                                                             vision-threatening   smartphone-camera   Indian smartphone-fundus                             also evaluated (not different camera (Remidio
                                                                             DR detection         images in academic  validation studies                                   necessarily         FOP) than its primary
                                                                                                  studies             (values vary by study;                               deployed) in India  regulatory clearance
                                                                                                                      see Section 3)                                       via                 pathway
                                                                                                                                                                           smartphone-camera   
                                                                                                                                                                           studies             

  AEYE-DS          AEYE Health, Inc. (USA)         2022 (FDA Deep learning   DR detection,        Not publicly        Not publicly documented   FDA 510(k)-cleared         Not publicly        Limited independent
                                                     510(k))                 cleared via 510(k)   documented in       in sources reviewed                                  documented as       published detail found in
                                                                             on the               sources reviewed                                                         India-deployed      this research
                                                                             LumineticsCore                                                                                                    
                                                                             predicate                                                                                                         

  Google/Verily    Google LLC / Verily Life    Deployed from Deep learning   Referable DR and     EyePACS (\>130,000  Postdeployment            CE-marked; postdeployment  Deployed at 45--61+ Positive predictive value
  ARDA (Automated  Sciences, deployed with             2018; trained on      sight-threatening DR images) + Indian    (real-world) study: 97.0% clinical performance       sites across Tamil  markedly lower than
  Retinal Disease  Aravind Eye Hospitals      postdeployment \>130,000       (STDR) detection     hospital datasets   sensitivity / 96.4%       published in JAMA          Nadu and other      sensitivity/specificity
  Assessment)      (India) and Sankara        study covering EyePACS images                                           specificity for severe    Ophthalmology-affiliated   parts of Southern   (PPV \~50--68%),
                   Nethralaya                  Jan 2019--Jul plus additional                                          NPDR or PDR; 95.9%        research; large real-world India; screened     reflecting the reality
                                                        2023 Indian hospital                                          sensitivity / 94.9%       sample (\~4,537 patients   over                that high sensitivity at
                                                             datasets                                                 specificity for STDR      in the reported            250,000--600,000+   scale increases false
                                                                                                                                                cross-sectional analysis,  patients            referrals; postdeployment
                                                                                                                                                drawn from \>600,000       cumulatively per    performance can drift
                                                                                                                                                patients screened          different reports   from initial validation,
                                                                                                                                                cumulatively)                                  which is why the authors
                                                                                                                                                                                               explicitly recommend
                                                                                                                                                                                               ongoing monitoring

  AIDRSS           Academic multicentric       Recent (arXiv Deep learning   5-stage ICDR grading Multicentric Indian 92% overall sensitivity,  Multicentric validation    Research-stage as   As an arXiv preprint,
  (AI-Driven       study, India                    preprint) (\~50 million   (DR0--DR4)           population dataset  88% specificity, 100%     reported in the paper; not documented; not     this has not been
  Diabetic                                                   trainable                                                sensitivity for referable confirmed as               confirmed as a      confirmed as
  Retinopathy                                                parameters)                                              DR (DR3/DR4) in the       regulatory-cleared or      large-scale field   peer-reviewed at the time
  Screening                                                  with CLAHE                                               reported study            long-term deployed         deployment          of this research; treat
  System)                                                    preprocessing                                                                                                                     performance figures as
                                                             for image                                                                                                                         claimed rather than
                                                             enhancement                                                                                                                       independently replicated

  DeepDR           Academic research system           \~2021 Deep learning   Image quality        466,247 training    AUCs of 0.901--0.967 for  Peer-reviewed (published   Research system;    Demonstrates a genuinely
                   (Shanghai Jiao Tong                       system          assessment + lesion  images from 121,342 individual lesion         research); large internal  not confirmed in    integrated
                   University--affiliated                    integrating     detection            patients; evaluated detection; AUCs of        and external validation    this research as a  IQA+lesion+grading
                   research, per the                         real-time image (microaneurysms,     on a local set of   0.943--0.972 for DR       sets                       commercially        pipeline in a single
                   published paper)                          quality         cotton-wool spots,   200,136 images and  severity grading                                     deployed product    system --- directly
                                                             assessment,     hard exudates,       three external                                                                               relevant as a precedent
                                                             lesion          hemorrhages) +       datasets (209,322                                                                            that partially overlaps
                                                             detection, and  4-stage DR severity  images total)                                                                                with this project's
                                                             severity        grading,                                                                                                          pipeline (see Section 8)
                                                             grading in one  trained/evaluated on                                                                                              
                                                             pipeline        \>670,000 images                                                                                                  
                                                                             total across                                                                                                      
                                                                             internal and                                                                                                      
                                                                             external datasets                                                                                                 
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### What these systems solve well vs. not

-   **LumineticsCore, EyeArt, AEYE-DS** solve *regulatory-grade
    autonomous point-of-care DR/DME detection* well, with real clinical
    trial evidence --- but they are US-market products validated
    primarily on specific fixed fundus cameras, and none of the sources
    reviewed document rural-India-specific deployment, offline/edge
    operation, or an integrated telemedicine-resource simulation
    component.
-   **Google/Verily ARDA** solves *large-scale, real-world Indian
    deployment* convincingly, with published postdeployment performance
    data at hundreds of thousands of patients --- but it is a
    cloud-connected classification service integrated into Aravind's own
    existing workflow; the reviewed sources do not document an explicit
    explainability (heatmap/lesion-evidence) layer, a
    confidence-calibration mechanism visible to the operator, or a
    published network/resource capacity simulation for its deployment at
    scale.
-   **AIDRSS** solves *multi-class ICDR grading with an enhancement
    step* and reports strong sensitivity --- but as a research-stage
    system its clinical validation, deployment, and explainability
    status are less established than the FDA-cleared or Google-deployed
    systems.
-   **DeepDR** solves *integration of IQA + lesion detection + grading
    into one pipeline* --- this is the closest academic precedent to
    this project's proposed pipeline structure, but it is a research
    system evaluated on curated datasets and is not documented as a
    rural-India, portable-camera, or telemedicine-workflow deployment,
    nor as including calibrated confidence or a resource/network
    simulation layer.

------------------------------------------------------------------------

# 3. Existing Portable-Camera Solutions

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Solution          Camera                   AI                Portable                    Offline              Connectivity           IQA                Clinical Validation          Rural Deployment  Limitations
  ----------------- ------------------------ ----------------- --------------------------- -------------------- ---------------------- ------------------ ---------------------------- ----------------- ---------------------------
  Remidio           Remidio Non-Mydriatic    Medios AI         Yes --- handheld,           Yes --- explicitly   Not required for AI    Not confirmed as a Multiple peer-reviewed       Yes ---           Field trial sample sizes
  Fundus-on-Phone   Fundus on Phone          (Remidio/Medios   smartphone-based            documented as an     inference;             standalone         validation studies (Nature   explicitly        are moderate (e.g., 250
  (FOP) + Medios AI (smartphone-attached),   Technologies,                                 offline, on-device   connectivity relevant  automated          Eye 2018 with EyeArt         validated in      persons screened, 197
                    Bangalore, India         Singapore) ---                                AI algorithm         only for optional data image-quality gate algorithm; Indian Journal of rural India field gradable); results are from
                                             offline,                                      designed for         upload/reporting       in the sources     Ophthalmology 2020/2021 with studies (Essilor  specific studies rather
                                             on-device                                     settings lacking                            reviewed (field    Medios AI) report            India "Eye Mitra" than one continuously
                                                                                           reliable                                    studies report     sensitivity/specificity for  opticians in      monitored large-scale
                                                                                           internet/compute                            "good quality      referable DR against         rural outreach    program comparable to
                                                                                                                                       images obtained in ophthalmologist grading      camps; community  ARDA's \>600,000-patient
                                                                                                                                       197 of 250 cases,"                              screening in      postdeployment dataset
                                                                                                                                       implying a quality                              Mumbai wards)     
                                                                                                                                       filtering step                                                    
                                                                                                                                       exists, but the                                                   
                                                                                                                                       mechanism is not                                                  
                                                                                                                                       detailed as a                                                     
                                                                                                                                       separate published                                                
                                                                                                                                       IQA model)                                                        

  Peek Retina (Peek Smartphone clip-on       Peek software /   Yes --- designed for        Not confirmed as     Cloud storage          Not confirmed as a Peer-reviewed validation     Deployed/tested   Sensitivity/specificity for
  Vision)           adapter                  vision-testing    minimal-training,           offline AI inference referenced in some     specific automated against standard fundus      in multiple       DR specifically are
                                             suite;            low-resource use            for DR grading in    reviewed sources, but  DR-image-quality   cameras exists (Uganda       low-resource      markedly lower than the
                                             DR-specific AI                                the sources          not confirmed as a     model in sources   cross-sectional study: 84%   settings (Kenya,  FDA-cleared or Medios AI
                                             grading not                                   reviewed; primarily  hard requirement for   reviewed           sensitivity, 79.9%           Uganda, Tanzania, figures in the sources
                                             confirmed as a                                an image-capture and basic operation                           specificity for DR vs. a     Malawi, Mali,     reviewed, and Peek's
                                             core built-in                                 vision-test tool                                               Zeiss Visucam 200 reference  Botswana,         device-comparison
                                             feature in the                                                                                               camera)                      Madagascar,       literature notes lower
                                             sources reviewed                                                                                                                          India)            diagnostic accuracy for
                                             (used primarily                                                                                                                                             smaller-field-of-view
                                             for image                                                                                                                                                   smartphone systems
                                             capture + broader                                                                                                                                           generally
                                             eye-test suite)                                                                                                                                             

  Forus Health      Proprietary              FH-POISE          Yes --- explicitly marketed Not confirmed as     Manufacturer describes Not independently  The 3nethra Neo camera has   Yes --- used in   Most detailed
  3nethra (family:  portable/handheld        ("Precision       as                          offline AI inference wireless/Wi-Fi-based   confirmed in this  independent field            large-scale       performance/AI-capability
  classic+, pico,   non-mydriatic fundus     Ocular            compact/portable/handheld   in independently     data transfer and      research beyond    documentation in the         Indian outreach   claims for the newer
  specto, neo,      camera line, Bengaluru,  Intelligence for  across the product line     verified             telemedicine           manufacturer       peer-reviewed KIDROP         (e.g., Andhra     AI-enabled models
  ultima)           India                    Systemic Diseases                             (non-manufacturer)   integration            product pages      retinopathy-of-prematurity   Pradesh Digital   (FH-POISE) come from
                                             and Eye Health")                              sources;                                                       screening program in India   Health SaaS       manufacturer product pages
                                             --- AI-assisted                               manufacturer                                                   (a different condition than  Platform reported rather than independent
                                             analysis                                      materials describe                                             DR, but the same device      by the            peer-reviewed validation in
                                             referenced in                                 Wi-Fi connectivity                                             family, demonstrating        manufacturer as   the sources reviewed here
                                             current product                               and "telemedicine                                              field-portability at scale)  covering 115      --- **this is a
                                             marketing for                                 ready" data sharing,                                                                        Community Health  manufacturer claim, not
                                             newer models                                  which suggests at                                                                           Centers and 3.5   confirmed by independent
                                             (pico, ultima)                                least partial                                                                               million eye       peer-reviewed validation**
                                                                                           connectivity                                                                                screenings over   in this research
                                                                                           dependence for some                                                                         four years);      
                                                                                           workflows                                                                                   KIDROP program    
                                                                                                                                                                                       covers            
                                                                                                                                                                                       long-distance     
                                                                                                                                                                                       rural outreach    
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Variable image quality --- a specific note relevant to this project's
requirements:** The only solution above with clearly documented
field-reported quality attrition is Remidio FOP/Medios AI, where one
published rural field study reported that only 197 of 250 captured
images were of gradable quality --- i.e., roughly a 21% real-world
ungradable rate in that specific study. This is a genuine, sourced data
point (not this project's own assumption) that can inform, but should
not be treated as a universal constant for, the "ungradable rate"
parameter used in the companion Simulink simulation document.

------------------------------------------------------------------------

# 4. Existing Offline Solutions

  -------------------------------------------------------------------------------------------------------------------------------------------------
  System              Local AI         Cloud Required      Offline Inference   Store-and-Forward         Connectivity Dependency     Limitation
  ------------------- ---------------- ------------------- ------------------- ------------------------- --------------------------- --------------
  Remidio             Yes --- runs on  No (for inference)  Yes --- this is the Not the primary design    Low --- inference itself    The
  Fundus-on-Phone +   the same                             explicit, published (real-time on-device      does not require            completeness
  Medios AI           smartphone used                      design goal and     result within \~20        connectivity; connectivity  of the
                      for image                            finding of the      seconds is reported in    is relevant mainly for      "offline
                      capture                              "Medios --- an      one field study), though  record                      clinical
                                                           offline,            nothing in the reviewed   transmission/telemedicine   workflow"
                                                           smartphone-based    sources rules out         follow-up, which is         (i.e., whether
                                                           artificial          store-and-forward use for separate from the AI step   doctor review,
                                                           intelligence" study referral/record-keeping                               referral
                                                           and its follow-ups,                                                       tracking, and
                                                           motivated                                                                 reporting also
                                                           explicitly by the                                                         work fully
                                                           observation that                                                          offline, or
                                                           cloud-based AI's                                                          only the AI
                                                           prerequisites (high                                                       inference
                                                           computational                                                             step) is not
                                                           power, reliable                                                           fully detailed
                                                           internet) are often                                                       in the sources
                                                           unavailable in                                                            reviewed
                                                           low-resource                                                              
                                                           settings                                                                  

  LumineticsCore /    Not confirmed as Not fully confirmed Not confirmed as a  Not the design pattern    Not clearly documented in   This is a
  EyeArt / AEYE-DS    offline/edge in  either way from the design goal in the  documented --- designed   the sources reviewed        genuine
  (US FDA-cleared     the sources      sources reviewed    sources reviewed    as autonomous, immediate                              information
  systems)            reviewed; these  for the core                            point-of-care diagnosis                               gap in the
                      are generally    inference step;                         rather than asynchronous                              available
                      described as     described as                            store-and-forward                                     sources, not a
                      point-of-care    "point-of-care"                                                                               confirmed
                      systems          rather than                                                                                   negative ---
                      interfacing with explicitly                                                                                    the absence of
                      an EMR, implying "offline-capable"                                                                             "offline"
                      at least                                                                                                       language in US
                      local-network                                                                                                  FDA/product
                      connectivity                                                                                                   literature
                                                                                                                                     does not prove
                                                                                                                                     these systems
                                                                                                                                     cannot run
                                                                                                                                     offline, only
                                                                                                                                     that offline
                                                                                                                                     operation is
                                                                                                                                     not the
                                                                                                                                     emphasized
                                                                                                                                     design point

  Store-and-forward   No --- these     Yes, for the        No --- by           Yes --- this is the       High for the                This model
  teleophthalmology   programs are     grading step (a     definition,         classic and explicitly    grading/decision step;      handles poor
  (general, e.g.,     explicitly built human grader or     store-and-forward   documented pattern of     low-to-moderate for the     real-time
  Aravind, LVPEI,     around           reading center      relies on           teleophthalmology in      image-capture step itself   connectivity
  Mumbai KSF          transmitting     reviews transmitted transmission and    India cited in multiple                               by decoupling
  programs)           images to a      images, not         later review, not   reviewed sources                                      capture from
                      remote reading   necessarily in real local inference                                                           review in
                      center for       time)                                                                                         time, but
                      asynchronous                                                                                                   still
                      grading, not                                                                                                   ultimately
                      on-device AI                                                                                                   depends on
                      classification                                                                                                 eventual data
                                                                                                                                     transmission
                                                                                                                                     --- it does
                                                                                                                                     not remove the
                                                                                                                                     network
                                                                                                                                     dependency, it
                                                                                                                                     only relaxes
                                                                                                                                     its latency
                                                                                                                                     requirement
  -------------------------------------------------------------------------------------------------------------------------------------------------

## Offline AI inference vs. offline complete clinical workflow

These are **not the same**, and conflating them would be a significant
overstatement of what has been demonstrated:

-   **Offline AI inference** (Remidio/Medios AI) means the
    classification algorithm itself runs on a local device without
    needing to reach a server. This is well documented and independently
    validated in the peer-reviewed sources above.
-   **Offline complete clinical workflow** would additionally require
    that registration, quality assessment, explainability generation,
    reporting, referral logic, and doctor review all function without
    connectivity (at least until a later synchronization point). The
    sources reviewed for this research document offline *inference*
    clearly, but do **not** provide equally strong evidence of a fully
    offline *end-to-end* clinical workflow including asynchronous doctor
    review and referral tracking --- the doctor-review and
    referral-tracking parts of the pipeline, in the systems reviewed,
    still appear to depend on eventual connectivity (store-and-forward)
    or in-person follow-up rather than being demonstrated as fully
    offline-capable themselves.

------------------------------------------------------------------------

# 5. Existing Explainable-AI Approaches

  --------------------------------------------------------------------------------------------------------------------------------------
  XAI Method               DR Application        What It Explains         Strength            Limitation          Clinical Usefulness
  ------------------------ --------------------- ------------------------ ------------------- ------------------- ----------------------
  Grad-CAM                 Most widely used XAI  Class-discriminative     Requires no         A rigorous          Moderate --- useful as
                           method applied to DR  spatial heatmap showing  architecture change quantitative study  a coarse sanity-check
                           CNN classifiers in    which image regions most or retraining;      (using the IDRiD    and communication aid
                           the academic          influenced the predicted applicable to any   dataset's           for clinicians, but
                           literature reviewed   class, computed from     CNN; widely         pixel-level lesion  the quantitative
                           (multiple 2024--2026  gradients flowing into   reported to         annotations as      evidence indicates it
                           papers)               the last convolutional   visually align with ground truth) found should not be treated
                                                 layer                    lesion locations    that even the       as reliably
                                                                          such as             best-performing     lesion-precise on its
                                                                          microaneurysms,     model/method        own
                                                                          hemorrhages, and    combination         
                                                                          exudates in         (VGG16+Grad-CAM)    
                                                                          qualitative         achieved an         
                                                                          comparisons         "Explainability     
                                                                                              Consistency Score"  
                                                                                              of only about 0.51  
                                                                                              out of a possible   
                                                                                              1.0 for overall DR  
                                                                                              lesion              
                                                                                              localization, with  
                                                                                              a range of          
                                                                                              0.21--0.51 across   
                                                                                              all combinations    
                                                                                              tested ---          
                                                                                              indicating          
                                                                                              Grad-CAM's spatial  
                                                                                              correspondence to   
                                                                                              actual lesions is   
                                                                                              real but far from   
                                                                                              precise             

  HiResCAM                 Emerging comparative  Similar                  Evaluated alongside Newer and less      Emerging --- same
                           alternative to        class-activation-style   Grad-CAM against    widely adopted in   category of usefulness
                           Grad-CAM in recent    spatial attribution,     expert-annotated    DR-specific         as Grad-CAM, with
                           (2026) DR             computed differently to  lesion masks using  literature than     ongoing quantitative
                           explainability        (per its proposing       Dice, IoU, and      Grad-CAM;           comparison
                           research              research) more           Pointing Game       comparative         
                                                 faithfully reflect the   metrics in recent   advantage over      
                                                 model's actual decision  foundation-model DR Grad-CAM for DR     
                                                 process                  research            specifically is     
                                                                                              still an active     
                                                                                              research question   
                                                                                              in the sources      
                                                                                              reviewed            

  Grad-CAM++               Referenced            Similar heatmap concept, Not specifically    Limited DR-specific Not independently
                           generically in XAI    intended to better       benchmarked against quantitative        assessed for DR in
                           surveys as an         handle multiple          DR lesion ground    evidence located    this research beyond
                           extension of Grad-CAM instances of the same    truth in the                            general XAI literature
                                                 class in one image       sources found                           
                                                                          during this                             
                                                                          research                                

  SHAP                     Applied in DR         Attributes prediction    Provides a more     Computationally     Moderate --- more
                           research as a         contribution to specific formally grounded   more expensive;     established for
                           complementary         features (pixels, or     (game-theoretic)    pixel-level SHAP    tabular/clinical
                           feature-attribution   clinical variables when  attribution than    maps for            fusion tasks than as a
                           method, sometimes     tabular data is fused    raw activation      high-resolution     primary
                           alongside Grad-CAM    in)                      maps; useful when   fundus images are   lesion-localization
                           for imaging and/or                             combining           less commonly       tool for fundus images
                           alongside                                      image-derived and   reported than       alone
                           clinical/tabular data                          non-image clinical  Grad-CAM in the     
                                                                          variables           sources reviewed    

  LIME                     Referenced in general Local                    Model-agnostic      Not found as a      Limited direct
                           medical-imaging XAI   surrogate-model-based                        common approach     DR-specific evidence
                           literature            explanation of a single                      specifically        found
                                                 prediction                                   benchmarked for DR  
                                                                                              lesion-level        
                                                                                              evidence in the     
                                                                                              sources reviewed    
                                                                                              here                

  Lesion-level /           DeepDR (Section 2)    Directly outputs or      Potentially more    Requires            Higher --- directly
  segmentation-based       and various academic  highlights specific      clinically          lesion-level        answers "what did the
  explanation              DR segmentation       lesion types             interpretable than  annotated training  model see," which is
                           papers                (microaneurysms,         a generic heatmap,  data, which is more closer to how
                                                 hemorrhages, exudates)   since it names      expensive to obtain ophthalmologists
                                                 as a distinct model      lesion types        (e.g., IDRiD) than  reason, when lesion
                                                 output rather than an    explicitly rather   image-level         detection performance
                                                 indirect heatmap         than only marking   DR-grade labels;    itself is reliable
                                                                          "important" pixels  less commonly       
                                                                                              available at        
                                                                                              deployment scale    
                                                                                              than image-level    
                                                                                              classifiers         

  Uncertainty/confidence   Multiple recent       A numeric or visual      Directly supports a Adds computational  High, when well
  visualization (e.g.,     (2024--2026) academic indication of how        human-in-the-loop   overhead (e.g.,     calibrated --- but the
  Monte Carlo Dropout,     DR papers             confident the model is   workflow by         multiple forward    calibration itself
  Bayesian CNNs, deep                            in a given prediction,   identifying which   passes for Monte    must be validated, not
  ensembles with                                 used to flag ambiguous   cases most need     Carlo Dropout);     assumed, per the
  entropy-based flagging)                        cases for mandatory      expert attention,   calibration quality dedicated
                                                 human review             rather than         varies by method,   calibration-referral
                                                                          treating all AI     and one dedicated   study found in this
                                                                          outputs as equally  study found that    research
                                                                          trustworthy         the *degree of      
                                                                                              calibration*        
                                                                                              materially affects  
                                                                                              whether             
                                                                                              uncertainty-based   
                                                                                              referral actually   
                                                                                              improves outcomes   
                                                                                              --- poorly          
                                                                                              calibrated          
                                                                                              uncertainty         
                                                                                              estimates can       
                                                                                              misdirect referral  
                                                                                              effort              
  --------------------------------------------------------------------------------------------------------------------------------------

## Does a heatmap alone qualify as meaningful clinical explainability?

The evidence gathered here supports a **critical, not celebratory,**
answer: **not fully.** The quantitative comparison study (using
pixel-level IDRiD lesion ground truth) found that even the best
CNN+heatmap combination reached only a moderate degree of spatial
agreement with actual expert-annotated lesions, and performance varied
substantially by lesion type and by which of the ten common heatmapping
techniques was used. This means a heatmap can be visually persuasive to
a non-expert without being reliably accurate at the pixel level, and by
itself a heatmap does **not** provide: (a) a named lesion category, (b)
a calibrated confidence value, or (c) a human-readable clinical
rationale in the form clinicians actually use (e.g., "moderate NPDR due
to multiple microaneurysms and a small area of hemorrhage in the
superior temporal quadrant"). Several of the DR-XAI papers reviewed here
explicitly combine Grad-CAM-style heatmaps with either lesion-level
detection outputs or confidence/uncertainty scores specifically because
a heatmap alone is recognized in this literature as an incomplete form
of explainability, not a self-sufficient one.

------------------------------------------------------------------------

# 6. Comparison Table

Legend: ✓ = demonstrated (with source evidence above) · △ = partially
demonstrated / limited evidence · ✗ = not demonstrated in sources
reviewed · ? = insufficient public evidence to judge

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------
  Capability          LumineticsCore/EyeArt/AEYE-DS   Google/Verily ARDA      Remidio FOP + Medios AI   Forus Health 3nethra     DeepDR (academic)   Our Proposed
                      (FDA-cleared, US)               (India deployment)      (India, offline)          (+FH-POISE)                                  System
  ------------------- ------------------------------- ----------------------- ------------------------- ------------------------ ------------------- -------------
  DR screening        ✓                               ✓                       ✓                         △ (manufacturer claim    ✓                   ✓ (proposed)
                                                                                                        for AI-enabled models;                       
                                                                                                        independent validation                       
                                                                                                        not confirmed)                               

  5-level grading     △ (LumineticsCore targets a     ? (severity detail      ? (referable              ?                        ✓ (4-stage grading  ✓ (proposed)
                      referral threshold rather than  beyond                  vs. non-referable binary                           demonstrated)       
                      full 5-level output per sources STDR/severe-NPDR/PDR    output documented; full                                                
                      reviewed)                       bucketing not confirmed 5-level ICDR grading not                                               
                                                      in sources reviewed)    confirmed as Medios AI's                                               
                                                                              core output in sources                                                 
                                                                              reviewed)                                                              

  Referable DR        ✓                               ✓                       ✓                         ?                        ✓                   ✓ (proposed)

  Image quality       △ (LumineticsCore documented to ? (not detailed in      △ (quality attrition      ?                        ✓ (explicit         ✓ (proposed)
  assessment          guide the operator to retake    sources reviewed)       reported in field data;                            real-time IQA       
                      insufficient-quality images)                            explicit automated IQA                             module)             
                                                                              model not separately                                                   
                                                                              confirmed)                                                             

  Image enhancement   ?                               ?                       ?                         ?                        ? (not confirmed as ✓ (proposed)
                                                                                                                                 a distinct step in  
                                                                                                                                 sources reviewed)   

  Vessel/retinal      ?                               ?                       ?                         ?                        ?                   ✓ (proposed)
  structure analysis                                                                                                                                 

  Lesion detection    ? (marketing describes          ?                       ?                         ?                        ✓ (explicit         ✓ (proposed)
                      "analyzing images for evidence                                                                             multi-lesion-type   
                      of lesions" but explicit                                                                                   detection)          
                      lesion-level *output* to the                                                                                                   
                      clinician not confirmed)                                                                                                       

  Portable camera     ✗ (fixed/table camera           ? (camera hardware not  ✓                         ✓                        N/A (software-only  ✓ (proposed,
                      documented)                     the focus of ARDA                                                          research system)    dependent on
                                                      sources; likely uses                                                                           chosen
                                                      standard/fixed cameras                                                                         hardware)
                                                      at partner hospitals)                                                                          

  Offline capability  ✗ (not confirmed)               ✗ (cloud-based          ✓                         △ (Wi-Fi/telemedicine    N/A                 △ (proposed
                                                      classification service)                           connectivity emphasized                      ---
                                                                                                        in manufacturer                              feasibility
                                                                                                        materials; offline AI                        to be
                                                                                                        not independently                            validated)
                                                                                                        confirmed)                                   

  Explainability      ✗ (not confirmed as a           ✗ (not confirmed in     ✗ (not confirmed in       ✗ (not confirmed in      ✗ (paper focuses on ✓ (proposed)
                      clinician-facing feature in     sources reviewed)       sources reviewed)         sources reviewed)        detection/grading   
                      sources reviewed)                                                                                          performance, not    
                                                                                                                                 XAI output)         

  Lesion-level        ✗                               ✗                       ✗                         ✗                        ✓ (via its          ✓ (proposed)
  evidence                                                                                                                       lesion-detection    
                                                                                                                                 module)             

  Confidence          ?                               ?                       ?                         ?                        ?                   ✓ (proposed)
  calibration                                                                                                                                        

  Automated report    ✓ (point-of-care result         ✓ (referral output      ✓ (result generated in    △ (report generation     ?                   ✓ (proposed)
                      reported)                       reported)               \~20s per field study)    implied by                                   
                                                                                                        telemedicine-ready                           
                                                                                                        product description)                         

  Human-in-loop       △ (LumineticsCore is explicitly ✓ (Aravind's            ✓ (ophthalmologist        ✓ (telemedicine referral N/A (research       ✓ (proposed)
  review              *autonomous*, i.e., designed to postdeployment          grading used in           implied)                 system, not a       
                      avoid mandatory overread)       monitoring involves     validation studies; field                          deployed clinical   
                                                      human-graded            workflow includes                                  workflow)           
                                                      adjudication samples)   referral to a specialist)                                              

  Telemedicine        △ (point-of-care design reduces ✓ (deployed within      △ (some field studies are ✓ ("telemedicine ready"  N/A                 ✓ (proposed)
                      reliance on telemedicine        Aravind's existing      camp-based rather than    marketing; KIDROP                            
                      referral for the initial read)  telemedicine-adjacent   telemedicine-networked)   program documented as                        
                                                      hospital network)                                 travel/outreach-based)                       

  Rural deployment    ✗ (not confirmed as             ✓ (explicitly deployed  ✓ (explicitly validated   ✓ (Andhra Pradesh CHC    ✗ (research-only)   ✓ (proposed)
                      rural-India-deployed)           across rural/remote     in rural India outreach   program; KIDROP rural                        
                                                      Tamil Nadu sites)       camps)                    outreach)                                    

  Network-aware       ✗ (not documented in sources    ✗ (not documented in    ✗ (not documented ---     ✗ (not documented)       ✗ (not applicable)  ✓ (proposed)
  workflow (explicit  reviewed)                       sources reviewed)       offline design sidesteps                                               
  bandwidth/latency                                                           rather than models the                                                 
  modeling)                                                                   network problem)                                                       

  Resource simulation ✗                               ✗                       ✗                         ✗                        ✗                   ✓ (proposed)

  Scalability         △ (Medicare                     △ (postdeployment study ✗                         △ (manufacturer cites    ✗                   ✓ (proposed)
  modeling            reimbursement/adoption          reports scale reached,                            3.5 million screenings,                      
                      literature discusses scale-up   i.e., descriptive, not                            descriptive not                              
                      considerations narratively, not a predictive capacity                             predictive)                                  
                      via simulation)                 model)                                                                                         

  100,000+ patient    ? (US system scale not reported ✓ (postdeployment data  ✗ (documented field       △ (3.5 million           ✗                   △ (proposed,
  scenario            in these units in sources       covers                  studies are far smaller   screenings over 4 years                      as a
                      reviewed)                       250,000--600,000+       in scale)                 cited by manufacturer,                       *simulated*
                                                      patients cumulatively                             i.e., descriptive)                           scenario, not
                                                      --- i.e., a real system                                                                        yet an
                                                      has already operated                                                                           achieved
                                                      well beyond this                                                                               deployment)
                                                      project's 100,000/year                                                                         
                                                      target, though as an                                                                           
                                                      *observed outcome*, not                                                                        
                                                      a *predictive                                                                                  
                                                      simulation*)                                                                                   
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------

**Important reading of this table:** Our proposed system is not marked
superior on most rows relative to the strongest existing comparator for
that specific row --- e.g., Google/Verily ARDA has already *operated at*
a scale exceeding 100,000 patients/year, which is a stronger form of
evidence (an actual deployment) than this project's *planned simulation*
of the same scale. Where our system is marked ✓ and existing systems are
marked ✗ or ?, this reflects an absence of *found evidence* for that
specific capability in the specific system reviewed --- not proof that
no such system exists anywhere.

------------------------------------------------------------------------

# 7. What Existing Systems Already Solve

### Mature / well-established

-   Automated referable-DR / DR-vs-no-DR classification using deep CNNs
    (LumineticsCore, EyeArt, AEYE-DS, ARDA) --- regulatory-cleared
    and/or deployed at large scale with published
    sensitivity/specificity.
-   Portable and smartphone-based fundus imaging for rural/low-resource
    screening (Remidio FOP, Peek Retina, Forus 3nethra family) ---
    multiple peer-reviewed field validations across India and other LMIC
    settings.
-   Offline, on-device AI inference for DR screening on a
    smartphone-based camera (Remidio Medios AI) --- explicitly
    documented and independently validated in peer-reviewed Indian
    studies.
-   Grad-CAM-style visual heatmap explanation for CNN-based DR
    classifiers --- extremely well represented in the recent academic
    literature (2024--2026), to the point of being closer to a "default
    baseline XAI technique" than a novel contribution.
-   Store-and-forward teleophthalmology for DR referral in
    low-ophthalmologist-density regions --- an established practice in
    India with decades of program history (SNDRP since 2003, multiple
    state-level and NGO-run programs).
-   Large-scale, real-world Indian deployment of cloud-based
    DR-screening AI reaching hundreds of thousands of patients
    (Google/Verily ARDA at Aravind and partner sites).

### Demonstrated but limited

-   Integrated single-pipeline systems combining image-quality
    assessment, lesion detection, and multi-stage grading (DeepDR) ---
    demonstrated in a strong academic paper, but not confirmed in this
    research as translated into a rural-India-deployed,
    telemedicine-integrated, portable-camera product.
-   Quantitative evaluation of explainability accuracy against
    expert-annotated lesion ground truth --- demonstrated in at least
    one rigorous comparative study, but this remains uncommon; most
    DR-XAI papers reviewed show heatmaps qualitatively without
    quantitatively validating their pixel-level accuracy against
    annotated lesions.
-   Uncertainty/confidence-aware DR classification with referral triage
    --- demonstrated in multiple recent academic papers (Monte Carlo
    Dropout, Bayesian CNNs, calibration-referral studies), but not
    confirmed in this research as a feature of any of the widely
    deployed commercial/field systems reviewed (LumineticsCore, EyeArt,
    ARDA, Medios AI).
-   AI-enabled DR screening integrated with a structured
    teleophthalmology referral pathway and prospective outcome tracking
    (LVPEI's SMART DROP study) --- an active, registered clinical study
    (protocol published 2025) rather than a long-established, fully
    evaluated program.

### Emerging

-   Vision-foundation-model-based DR classification with joint
    calibration and explanation-localization evaluation (e.g.,
    DINOv2-based studies) --- very recent (2026) academic work, not yet
    reflected in deployed systems.
-   Multimodal/VLM-based explanation generation that produces
    natural-language, quadrant-based lesion reasoning rather than only a
    heatmap --- recent (2025--2026) research, explicitly framed by its
    own authors as addressing the limitation that heatmaps alone don't
    communicate clinical reasoning.

### Research-level

-   Formal discrete-event/operations-research simulation of DR screening
    *capacity and resource allocation* --- genuinely established as a
    research area (Brailsford, Rauner, Gutjahr, Zeppelzauer's
    discrete-event + ant-colony-optimization work; Davies et al.'s POST
    model; more recent DES work for HPV/cervical-cancer screening
    capacity planning cited as an analogous methodology) --- but this
    body of work models **screening policy and disease-progression
    scheduling** (e.g., optimal screening interval, cost-effectiveness
    of screening frequency) using generic OR/simulation tools, not an
    **AI-pipeline-and-network-aware, Simulink/SimEvents-specific model**
    of an explainable-AI telemedicine workflow. This is an important
    distinction developed further in Section 8.

------------------------------------------------------------------------

# 8. What They Don't Solve Together

### Combination A --- Portable imaging + Image quality assessment + Automated DR grading

**Existing evidence:** Strong. Remidio FOP + Medios AI (portable +
on-device grading, with field-observed quality attrition) and DeepDR
(integrated IQA + grading, though not portable-camera-specific) both
cover large parts of this combination. **Degree of integration:** High
for Remidio/Medios AI as a deployed field system; high for DeepDR as an
academic pipeline; the combination *as a single deployed rural-India
product* is well precedented. **Remaining gap:** Limited --- this
combination is close to solved by existing systems; this project's
contribution here is mainly a matter of implementation choices
(MATLAB-based, specific enhancement techniques) rather than a genuine
capability gap.

### Combination B --- Offline inference + Explainability + Clinical review

**Existing evidence:** Offline inference is well evidenced (Medios AI).
Clinical review is well evidenced (essentially every reviewed system
involves eventual human oversight in some form). Explainability
integrated *specifically with* an offline, field-deployed system is
**not evidenced** in the sources reviewed --- no source found in this
research documents Medios AI, or a comparable offline field system,
providing a Grad-CAM-style or lesion-level explanation to the field
operator or reviewing clinician. **Degree of integration:** Low ---
offline and clinical-review both exist, and explainability exists
(academically, on non-offline research systems), but the specific
three-way combination was not found integrated in one documented system.
**Remaining gap:** Moderate-to-significant --- this is a plausible,
evidence-supported gap.

### Combination C --- Lesion-level evidence + Calibrated confidence + Human-in-the-loop validation

**Existing evidence:** Each element individually has academic support
(DeepDR for lesion-level evidence; multiple Monte Carlo Dropout/Bayesian
papers for calibrated confidence; essentially all clinical DR-AI systems
for human-in-the-loop validation in some form). **Degree of
integration:** Low --- the sources reviewed did not identify one system
that outputs lesion-level evidence *and* a calibrated confidence score
*and* structures human review around both simultaneously;
uncertainty-quantification papers and lesion-detection papers in this
research were largely separate lines of work. **Remaining gap:**
Significant, and specifically well suited to an academic-style,
prototype-stage project like this one, since it does not require
large-scale field deployment to demonstrate --- it can be shown on a
held-out dataset.

### Combination D --- AI screening + Telemedicine + Network constraints + Resource modeling

**Existing evidence:** AI screening + telemedicine is well evidenced
(SMART DROP at LVPEI; Google ARDA's integration into hospital
telemedicine-adjacent networks; decades of Indian store-and-forward
teleophthalmology practice). Formal resource/capacity simulation of DR
*screening programs* is also well evidenced as a research area
(Brailsford et al.; Davies et al.'s POST model; related DES work in
cervical-cancer screening capacity planning). **Degree of integration:**
Low, specifically for the *network-constraint* piece. The DR-specific
discrete-event simulation literature reviewed here models **screening
interval, policy choice, and long-horizon disease progression** --- not
the **short-horizon, AI-pipeline-specific queue and network behavior**
(camera queues, AI-compute queues, image-transmission bandwidth
constraints, doctor-review queues) that this project's companion
Simulink/SimEvents document addresses. No source found in this research
combines an explainable AI DR-screening pipeline with an explicit
Simulink/SimEvents-style network-and-resource discrete-event simulation.
**Remaining gap:** Significant, and this is the most distinctive
combination found in this research --- it sits at the intersection of
two separately mature fields (clinical DR-AI, and healthcare
operations-research simulation) that do not appear, from the sources
reviewed, to have been combined for this specific problem.

### Combination E --- Image-level AI + Clinical explainability + Operational scalability

**Existing evidence:** Image-level AI at operational scale is well
evidenced (ARDA's 250,000--600,000+ patient postdeployment data is a
genuine, large existing example of "AI + scale"). Clinical
explainability is well evidenced academically (Section 5). The
combination of all three --- an explainable AI pipeline whose
operational scalability (throughput, latency, resource needs) has itself
been explicitly modeled/simulated --- was **not found** in any source
reviewed. **Degree of integration:** Low. **Remaining gap:** Significant
--- closely related to Combination D, and arguably the clearest
articulation of a genuine system-level gap from this research.

  ------------------------------------------------------------------------------------------------------------------------------
  Capability         Existing Evidence          Systems Found                Degree of Integration       Remaining Gap
  Combination                                                                                            
  ------------------ -------------------------- ---------------------------- --------------------------- -----------------------
  A --- Portable     Strong                     Remidio FOP/Medios AI,       High                        Small
  imaging + IQA +                               DeepDR                                                   
  Grading                                                                                                

  B --- Offline      Partial (each piece        Medios AI (offline+review),  Low                         Moderate--Significant
  inference +        separately)                academic XAI papers                                      
  Explainability +                              (explainability, but not                                 
  Clinical review                               offline)                                                 

  C --- Lesion-level Partial (each piece        DeepDR (lesion),             Low                         Significant
  evidence +         separately, academically)  uncertainty-quantification                               
  Calibrated                                    papers (confidence), general                             
  confidence +                                  clinical workflows                                       
  Human-in-loop                                 (human-in-loop)                                          

  D --- AI           Partial (AI+telemedicine   SMART DROP, ARDA,            Low (specifically for the   Significant
  screening +        strong;                    Brailsford/Davies DES        network/AI-pipeline-aware   
  Telemedicine +     DES-for-screening-policy   literature                   simulation piece)           
  Network            strong; network-aware                                                               
  constraints +      AI-pipeline simulation                                                              
  Resource modeling  absent)                                                                             

  E --- Image-level  Partial (AI+scale strong;  ARDA (scale), academic XAI   Low                         Significant
  AI +               AI+explainability strong   papers (explainability)                                  
  Explainability +   academically; all three                                                             
  Operational        together absent)                                                                    
  scalability                                                                                            
  ------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 9. Our Technical Gap

Mapping the proposed pipeline (Image Quality → Adaptive Enhancement →
Retinal/Lesion Analysis → DR Grading → Explainability → Confidence →
Human Review → Telemedicine → Network Constraints → Simulink Resource
Simulation) against the evidence above:

1.  **Already solved (individually):** Image quality assessment, DR
    grading (referable and multi-class), portable/smartphone imaging,
    offline inference, telemedicine referral, store-and-forward
    workflows, Grad-CAM-style explainability, and confidence/uncertainty
    quantification each have independent, often strong, prior evidence.
2.  **Partially solved:** Integrated pipelines combining several of the
    above (DeepDR: IQA+lesion+grading; SMART DROP:
    AI+teleophthalmology+human review) exist, but none reviewed here
    combines *all* of: IQA, enhancement, lesion-level analysis, grading,
    explainability, calibrated confidence, human review, *and*
    telemedicine in one documented, validated system.
3.  **Poorly integrated combinations:** Per Section 8, Combinations B,
    C, D, and E all show low integration evidence. Of these,
    **Combination D/E (explainable AI screening + explicit
    network/resource/queue simulation for scalability)** is the
    combination with the clearest, most defensible absence of evidence,
    because it sits between two normally separate research communities
    (clinical DR-AI and healthcare operations-research simulation) that
    this research did not find bridged.
4.  **Especially relevant to rural India:** The ophthalmologist-scarcity
    data found in this research (approximately 1 ophthalmologist per
    100,000 population nationally, with figures elsewhere citing roughly
    18 ophthalmologists per million population and each ophthalmologist
    needing to examine on the order of 3,500 people with diabetes
    annually) directly motivates why the *resource/queue* half of this
    project's pipeline --- not just the AI half --- is a genuinely
    important, India-specific problem, not a generic add-on.
5.  **Feasible for this prototype:** Given hackathon time constraints,
    the most feasible gap to actually demonstrate is not a full field
    deployment (which would take years, as the reviewed systems show)
    but a **methodologically sound, evidence-grounded simulation and
    prototype pipeline** that integrates lesion-level evidence,
    calibrated confidence, and an explicit Simulink/SimEvents
    network-and-resource model --- explicitly presented as a
    prototype/simulation contribution, not a claim of clinical
    validation or deployment-readiness equivalent to LumineticsCore or
    ARDA.

  ----------------------------------------------------------------------------------------------------------------------------------------------------
  Proposed Gap               Evidence                Existing Solutions                       Why It Matters           Feasible for Our Prototype?
  -------------------------- ----------------------- ---------------------------------------- ------------------------ -------------------------------
  Explainability             No source found         Medios AI (offline, no confirmed         Rural PHCs are exactly   Yes --- feasible to demonstrate
  (Grad-CAM/lesion-level)    combining offline AI    explainability); academic XAI papers     the setting where        on a prototype/dataset basis,
  integrated with an         with explainability     (explainability, not offline)            connectivity cannot be   though full field deployment is
  **offline**,               output to the field                                              assumed, yet             out of scope for a hackathon
  field-deployable pipeline  operator                                                         clinicians/technicians   timeline
                                                                                              there arguably need      
                                                                                              explanation *more*, not  
                                                                                              less, given less         
                                                                                              specialist backup        
                                                                                              on-site                  

  Calibrated confidence      No source found         DeepDR (lesion only); uncertainty papers Reduces over-referral (a Yes --- both are
  **combined with**          combining both in one   (confidence only)                        documented problem ---   algorithmic/evaluation-stage
  lesion-level evidence,     system                                                           ARDA's positive          capabilities, well suited to
  structuring human review                                                                    predictive value of      dataset-level demonstration
  around both                                                                                 \~51--68% implies many   
                                                                                              referrals are false      
                                                                                              positives) while still   
                                                                                              flagging genuinely       
                                                                                              uncertain cases for      
                                                                                              mandatory review         

  Explicit                   No source found;        Brailsford/Rauner/Gutjahr/Zeppelzauer,   Directly answers the SIH Yes --- this is exactly the
  Simulink/SimEvents-based   existing                Davies et al. POST model (different      problem statement's      deliverable specified in the
  network-and-resource       DES-for-DR-screening    question, same broad methodology)        explicit requirement for companion Simulink research
  simulation of the          literature addresses                                             a system-level,          document
  *specific* AI-pipeline     screening                                                        100,000+-patient         (04_simulink-telemedicine.md)
  workflow (not generic      interval/policy, not                                             simulation, which none   
  disease-progression        AI-pipeline                                                      of the clinical AI       
  screening-policy           queue/network/compute                                            systems reviewed here    
  simulation)                mechanics                                                        published (their scale   
                                                                                              claims are               
                                                                                              descriptive/observed,    
                                                                                              not                      
                                                                                              predictive/simulated)    

  Single reproducible,       Not found as a single   N/A --- this is more an                  A single, modular,       Yes --- this is an
  MATLAB-based, modular      reproducible open       engineering-integration gap than a       documented pipeline is   engineering/integration claim,
  pipeline spanning image    pipeline in the sources capability gap                           valuable for a hackathon appropriately scoped to a
  processing through         reviewed (existing                                               evaluation even where    prototype
  resource simulation        systems are either                                               each individual          
                             proprietary commercial                                           algorithmic piece is not 
                             products or separate                                             novel                    
                             academic papers                                                                           
                             addressing only one                                                                       
                             stage)                                                                                    
  ----------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# 10. Our System-Level Differentiation

  ------------------------------------------------------------------------------------------------------------
  Dimension             Existing Solutions          Our Differentiation        Evidence Strength
  --------------------- --------------------------- -------------------------- -------------------------------
  **Technical** ---     DeepDR integrates           Proposing to combine       Moderate --- each piece
  integrated pipeline,  IQA+lesion+grading (strong, lesion-level evidence +    individually well evidenced;
  image-quality-aware   but no                      calibrated confidence +    the combination's absence is
  processing,           explainability/confidence   explainability in one      evidenced by its absence across
  lesion-level          layer documented);          pipeline, explicitly       the reviewed literature, not by
  evidence,             XAI/uncertainty papers      presented to structure     a positive claim that it is
  explainability,       exist separately            human review               impossible
  confidence                                                                   
  calibration,                                                                 
  human-in-the-loop                                                            

  **Deployment** ---    Remidio/Medios AI and Forus Limited --- this project   Low for claiming deployment
  rural PHC             3nethra already             cannot claim to out-deploy superiority; the honest claim
  environment, portable substantially address       already-validated,         is architectural compatibility
  cameras, variable     portable,                   multi-year field-tested    with this class of hardware,
  image quality,        rural-India-deployable      commercial products within not proven field deployment
  intermittent          imaging with (in Medios     a hackathon timeframe      
  connectivity,         AI's case) offline                                     
  offline/edge          inference                                              
  capability                                                                   

  **Operational** ---   AI+telemedicine exists      This is the strongest and  Strong --- supported by a
  telemedicine          (SMART DROP, ARDA);         most original dimension    genuine, identified absence in
  workflow, queue       DES-for-screening-policy    found in this research --- the literature reviewed,
  modeling, doctor      exists (Brailsford,         a Simulink/SimEvents-based combined with a companion
  capacity, network     Davies); the *specific*     operational simulation     technical document
  constraints,          combination of an           specifically modeling the  (04_simulink-telemedicine.md)
  throughput, resource  AI-pipeline-aware           AI pipeline's own queues,  that shows exactly how this
  optimization,         network/queue/resource      compute, and network       would be implemented
  100,000+ patient      simulation was not found    stages (not just           
  simulation                                        disease-progression        
                                                    screening policy)          

  **Engineering** ---   Not found as a combined     A MATLAB/Simulink-based,   Moderate-to-strong as an
  MATLAB                offering among the systems  reproducible, modular      engineering/integration claim;
  implementation,       reviewed (commercial        implementation spanning    strength depends on actual
  Simulink system-level products are                both the AI pipeline and   delivery quality, not just
  simulation, modular   closed/proprietary;         the operational simulation intent
  architecture,         academic DR papers are      in one toolchain           
  reproducible          typically                                              
  evaluation            Python/PyTorch-based                                   
                        without an accompanying                                
                        operational simulation; DES                            
                        screening-policy papers use                            
                        generic OR tools like                                  
                        TreeAge or AnyLogic, not                               
                        Simulink/SimEvents)                                    
  ------------------------------------------------------------------------------------------------------------

## What is the strongest technically defensible reason that our system is different from existing solutions?

Based on the evidence gathered, the strongest defensible claim is
**not** about any single AI capability (all of which have precedent),
but about the **combination of an explainable, confidence-aware AI
screening pipeline with an explicit, purpose-built discrete-event
simulation of that same pipeline's operational scalability (queues,
network, and resource constraints) for a 100,000+ patient/year rural
Indian deployment context** --- a combination this research did not find
integrated in any single existing academic paper or deployed product.
Clinical DR-AI systems that have reached this patient scale (ARDA) did
so as an *observed outcome of deployment*, not as a *pre-deployment,
resource-aware simulated design decision*; and the DR-specific
simulation literature that does exist targets screening-policy questions
(interval, cost-effectiveness) rather than AI-pipeline queue/network
mechanics.

------------------------------------------------------------------------

# ANTI-HALLUCINATION REQUIREMENT --- Capability Classification Summary

  -------------------------------------------------------------------------------------------------------------------------
  System           Verified Capability        Claim Made by              Independent          Our Interpretation
                   (peer-reviewed /           Manufacturer/Researchers   Validation Found     
                   regulatory)                (not independently                              
                                              confirmed here)                                 
  ---------------- -------------------------- -------------------------- -------------------- -----------------------------
  LumineticsCore   Autonomous DR/DME          ---                        Pivotal trial        Verified at the
                   detection, FDA De                                     published; multiple  regulatory-trial level;
                   Novo-authorized, 87%/90%                              independent review   real-world post-market data
                   sensitivity/specificity in                            articles corroborate beyond the pivotal trial was
                   pivotal trial                                         FDA status           not reviewed in depth here

  EyeArt           FDA 510(k)-cleared for     ---                        Independent Indian   Verified as
                   mtmDR/vision-threatening                              smartphone-camera    regulatory-cleared;
                   DR                                                    validation study     performance on
                                                                         (Nature Eye, 2018)   non-primary-clearance camera
                                                                         found meaningful but hardware (smartphone) shown
                                                                         imperfect agreement  by at least one independent
                                                                         with ophthalmologist study to differ from its core
                                                                         grading              clearance context

  AEYE-DS          FDA 510(k)-cleared         ---                        Not independently    Regulatory status verified
                                                                         detailed in sources  via secondary review sources;
                                                                         reviewed beyond      primary clinical performance
                                                                         regulatory-history   data not independently
                                                                         review articles      located in this research

  Google/Verily    CE-marked; postdeployment  Google's own descriptions  Postdeployment study Strong evidence for
  ARDA             sensitivity/specificity    of ARDA's broader          is itself a form of  real-world Indian-scale
                   published in peer-reviewed capabilities beyond DR/DME independent-style    performance; note the study
                   research from the          are manufacturer           real-world           itself flags a substantial
                   deploying institution      statements not             verification,        gap between
                   (Aravind) in partnership   independently verified     published via a      sensitivity/specificity and
                   with Google                here                       peer-reviewed        positive predictive value at
                                                                         research pathway,    scale
                                                                         though it involves   
                                                                         the deploying        
                                                                         partner institution  
                                                                         rather than a fully  
                                                                         external auditor     

  Remidio Medios   Multiple independent       Manufacturer/company claim Yes --- several      High confidence in
  AI               peer-reviewed field        of being "the first"       independent          offline-inference capability
                   validations (Nature Eye    offline AI algorithm for   peer-reviewed field  and rural field usability;
                   2018 with EyeArt; Indian   this purpose (stated in a  studies              "first to market" claims are
                   Journal of Ophthalmology   peer-reviewed paper's                           researcher/manufacturer
                   2020/2021 with Medios AI)  introduction, attributed                        framing, presented here as
                                              to the researchers'                             such rather than
                                              framing, not an                                 independently adjudicated
                                              independently audited                           
                                              claim)                                          

  Forus Health     Device portability and use AI-assistance capability   Independent          **This is a manufacturer
  3nethra /        in large outreach programs (FH-POISE) and specific    peer-reviewed        claim, not independently
  FH-POISE         documented in independent  screening-volume           validation           peer-reviewed validation**,
                   peer-reviewed sources      statistics (3.5 million    specifically of      for the AI-specific
                   (KIDROP), though for       screenings, 115 CHCs) are  FH-POISE's DR-AI     (FH-POISE) capability; the
                   retinopathy of             manufacturer-sourced       performance was      camera hardware's
                   prematurity, not DR        claims from company        **not found** in     portability/field-usability
                   specifically               product pages              this research        is independently corroborated
                                                                                              via the (different-condition)
                                                                                              KIDROP literature

  AIDRSS           Reported in an arXiv       Performance figures (92%   Not confirmed as     Treat as a research claim
                   preprint                   sensitivity, 88%           independently        pending peer review, not as
                                              specificity, 100%          replicated or        an independently validated
                                              sensitivity for referable  peer-reviewed at the fact
                                              DR) are as stated by the   time of this         
                                              paper's authors            research             

  DeepDR           Peer-reviewed publication  ---                        The paper's own      High confidence as a
                   with large internal and                               external-dataset     research-stage academic
                   external validation                                   evaluation           result; not evidenced as
                   datasets                                              constitutes a form   translated into a deployed
                                                                         of built-in          product
                                                                         independent          
                                                                         validation           
  -------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

# CLINICAL VALIDATION ANALYSIS

For the major systems reviewed:

-   **Dataset size and diversity:** Ranges enormously --- from DeepDR's
    \>670,000 total images across four datasets (strong diversity) to
    some rural field studies with only 250--301 patients (Remidio FOP
    validation studies). Larger datasets generally support better
    generalization claims, but do not by themselves guarantee real-world
    performance, as the ARDA postdeployment study explicitly
    demonstrates (performance in a controlled trial can differ from
    performance observed after real-world deployment).
-   **External validation:** DeepDR reports evaluation on three external
    datasets in addition to its internal one --- a genuine strength.
    ARDA's cited training used EyePACS plus additional Indian hospital
    datasets, and its postdeployment evaluation is itself effectively an
    external, real-world validation of the originally trained model.
-   **Multi-center / prospective validation:** AIDRSS is described as
    multicentric; SMART DROP is an explicitly registered, prospective
    cohort study (not yet reporting completed results at the time of
    this research, per its 2025 protocol publication). Prospective,
    multi-center validation is the more rigorous standard, and notably
    fewer of the reviewed systems have completed (rather than merely
    designed) such studies.
-   **Sensitivity, specificity, AUC, referable-DR definition:** These
    vary across studies not only due to true performance differences but
    due to **different definitions of "referable DR"** (e.g.,
    moderate-or-worse NPDR and/or DME vs. severe NPDR/PDR only) and
    different reference standards (adjudicated grading, single-grader
    grading, OCT-based reference for DME). Direct numeric comparison
    across systems in Section 2's table should therefore be read with
    this caveat rather than as a strict leaderboard.
-   **Image quality handling:** Directly affects reported performance
    --- the Remidio field study reporting only 197/250 gradable images
    demonstrates that real-world image-quality attrition is a
    first-order factor, not a minor detail, and any performance figure
    quoted without stating the gradable-image denominator should be
    interpreted cautiously.
-   **Generalization:** ARDA's own published postdeployment analysis is
    a rare example in this space of a system explicitly checking whether
    original-trial performance holds up after real deployment --- and
    finding meaningful differences (particularly in positive predictive
    value), which is direct evidence for why dataset/trial performance
    is an insufficient basis for a deployment claim on its own.

**Why dataset performance alone is insufficient for deployment:** As the
evidence above shows, a system can perform well on a curated evaluation
dataset (dataset-level sensitivity/specificity) while still requiring
separate demonstration of: gradable-image rate under real field
conditions, positive predictive value at true population
disease-prevalence (which is typically much lower than in a curated
dataset, inflating false referrals), postdeployment performance drift,
and operational throughput under real resource constraints --- none of
which are captured by a single reported AUC or sensitivity/specificity
pair.

------------------------------------------------------------------------

# RURAL INDIA RELEVANCE

  -----------------------------------------------------------------------
  Requirement                         Addressed by existing systems?
  ----------------------------------- -----------------------------------
  Rural PHCs                          Directly addressed by Google/Verily
                                      ARDA (Tamil Nadu rural/remote
                                      sites), Remidio Medios AI (rural
                                      outreach camps), and the Forus
                                      3nethra family (Andhra Pradesh CHC
                                      program, KIDROP outreach) --- this
                                      is a genuinely well-covered
                                      requirement among existing Indian
                                      systems

  Low ophthalmologist availability    Explicitly the stated motivation
                                      for essentially every India-focused
                                      system/program reviewed (ARDA,
                                      Remidio, teleophthalmology
                                      literature); supported by sourced
                                      statistics (\~1 ophthalmologist per
                                      100,000 population nationally; \~18
                                      per million in one cited figure,
                                      implying each must examine \~3,500
                                      people with diabetes annually)

  Portable cameras                    Well addressed (Remidio FOP, Forus
                                      3nethra family, Peek Retina)

  Poor/intermittent internet          Addressed by Medios AI's
                                      offline-inference design; addressed
                                      differently (by decoupling capture
                                      from grading in time) by
                                      store-and-forward teleophthalmology
                                      programs; **not** addressed by an
                                      explicit bandwidth/network
                                      simulation in any source reviewed

  Variable image quality              Addressed in real-world field data
                                      (the Remidio 197/250 gradable-image
                                      figure) but, per this research, not
                                      addressed by a dedicated,
                                      separately published automated
                                      image-quality-gating model
                                      integrated into a field-deployed
                                      rural Indian system (DeepDR has
                                      such a model, but is not confirmed
                                      as rural-India-deployed)

  Limited computing resources         Directly addressed by Medios AI's
                                      smartphone-based on-device
                                      inference design, explicitly
                                      motivated in its own published
                                      rationale by the unavailability of
                                      high computational power and
                                      reliable internet in the target
                                      settings

  Store-and-forward telemedicine      Well established in Indian
                                      teleophthalmology practice
                                      generally (SNDRP, Mumbai KSF
                                      program, LVPEI's broader network)

  Local language / reporting          **Not publicly documented** in any
                                      source reviewed for this research,
                                      for any of the systems covered ---
                                      this is a genuine, stated evidence
                                      gap rather than an inferred one

  Large-scale screening               Directly demonstrated by ARDA
                                      (250,000--600,000+ patients
                                      cumulatively) and Forus's cited
                                      3.5-million-screening Andhra
                                      Pradesh program --- i.e.,
                                      large-scale screening itself is
                                      achieved, but (per Combination D/E
                                      in Section 8) not shown to have
                                      been pre-validated via an explicit
                                      operational simulation before or
                                      during scale-up
  -----------------------------------------------------------------------

**Caution against assuming suitability:** Several reviewed systems
(e.g., the FDA-cleared US systems) are explicitly designed for and
validated in a different context (US primary care with specific
compatible camera hardware) and are **not** documented in the sources
reviewed as validated for rural Indian PHC conditions --- their strong
regulatory/clinical evidence should not be read as evidence of
rural-India suitability without a system-specific rural validation
study, which was not found for these particular systems in this
research.

------------------------------------------------------------------------

# GAP VALIDITY CHECK --- Novelty Stress Test

1.  **Is there already a commercial system doing this?** For most
    individual pipeline stages, yes (Section 2, 3). For the full
    combination (explainable + confidence-calibrated + offline-capable +
    operationally-simulated pipeline), no commercial system doing all of
    this together was found.
2.  **Is there already a research paper doing this?** DeepDR comes
    closest for the AI-pipeline integration (IQA+lesion+grading); no
    paper found adds explainability, calibrated confidence, *and* an
    explicit Simulink/SimEvents-style operational simulation on top of
    that.
3.  **Is there already a portable system doing this?** Portable +
    offline + AI grading, yes (Medios AI). Portable + offline + AI
    grading + explainability + confidence + operational simulation, no.
4.  **Is there already an offline system doing this?** Offline AI
    inference, yes (Medios AI). Offline AI inference with published
    explainability output, not found.
5.  **Is there already an explainable system doing this?** Explainable
    DR classifiers, yes, abundantly (Section 5) --- but not shown
    deployed on offline/portable hardware, nor combined with formal
    calibrated confidence and lesion-level evidence simultaneously.
6.  **Is there already a telemedicine system doing this?** Yes,
    extensively (decades of Indian teleophthalmology practice; SMART
    DROP; ARDA's hospital-network integration) --- but not combined with
    an explicit network/resource discrete-event simulation of that same
    telemedicine pipeline.
7.  **Is there already a system combining several of these?** Yes ---
    DeepDR combines three algorithmic stages; SMART DROP combines AI
    with a structured teleophthalmology pathway and prospective
    evaluation; ARDA combines AI with massive real-world Indian scale.
    Each of these already occupies part of the space this project is
    entering.
8.  **What exactly remains different?** The **combination** of (a) an
    explainable, confidence-aware AI DR-screening pipeline **and** (b)
    an explicit, purpose-built discrete-event (Simulink/SimEvents)
    simulation of that pipeline's own operational scalability under
    rural network/resource constraints, targeted at a 100,000+
    patient/year design scenario. This specific combination was not
    found integrated in any single system or paper reviewed in this
    research.

**Is the proposed gap weak or strong?** The narrowest, most defensible
form of the gap (Combination D/E: explainable AI + operational/network
simulation, done together) is reasonably strong, precisely because it
sits at the boundary between two separately mature fields rather than
claiming novelty within either field alone. A broader claim --- e.g.,
"our AI pipeline itself is more accurate or more explainable than
existing systems" --- would be weak and is explicitly **not**
recommended, since existing systems (ARDA, DeepDR, LumineticsCore) have
far more extensive validation than a hackathon prototype can produce.

**Suggested stronger, more defensible differentiation:** Position the
project primarily as **a reproducible, MATLAB/Simulink-based reference
architecture that couples an explainable, confidence-aware DR-screening
AI pipeline with an explicit operational-scalability simulation** --- a
combination and an engineering integration this research did not find
already published or productized --- rather than as a claim of superior
AI accuracy or of proven rural deployment readiness, both of which are
already strongly contested ground occupied by well-validated existing
systems.

------------------------------------------------------------------------

# RECOMMENDED POSITIONING

### Conservative claim

"We propose a prototype pipeline that integrates image-quality-aware DR
screening, lesion-level explainability, and confidence-based human
review with an explicit MATLAB/Simulink discrete-event simulation of the
telemedicine workflow's network and resource constraints at a 100,000+
patient/year design scale. Each individual AI capability draws on
established, published techniques; the project's contribution is the
integration and the accompanying operational-scalability simulation, not
a claim of superior diagnostic accuracy over existing regulatory-cleared
or field-deployed systems."

### Strong but defensible claim

"Existing DR-screening systems have separately demonstrated offline AI
inference (Medios AI), integrated AI pipelines combining image quality,
lesion detection, and grading (DeepDR), explainable heatmap-based
reasoning (widely published Grad-CAM literature), calibrated
uncertainty-based referral triage (recent academic work), and
large-scale real-world Indian deployment (Google/Verily ARDA). We did
not find, in the sources reviewed, a system that combines lesion-level
evidence, calibrated confidence, and explainability into a single
human-review-structuring workflow, nor one whose operational scalability
for a 100,000+ patient/year rural deployment has been explicitly
validated through a purpose-built discrete-event (SimEvents/Simulink)
simulation of its own AI pipeline's queues, compute, and network
behavior --- as opposed to the disease-progression/screening-interval
simulations found in the operations-research literature, or the
after-the-fact observed scale reported by deployed systems like ARDA.
Our system-level contribution is this specific combination, evaluated as
a reproducible prototype."

### Claims we should NOT make

-   **"No existing system does automated DR screening in rural India."**
    False --- Google/Verily ARDA alone contradicts this, having screened
    over 250,000--600,000 patients across dozens of sites in rural Tamil
    Nadu.
-   **"No existing system works offline."** False --- Remidio's Medios
    AI is explicitly documented, peer-reviewed, and independently
    validated as an offline, on-device AI system for exactly this use
    case.
-   **"No existing system provides explainability for DR AI."** False
    --- Grad-CAM-based DR explainability is one of the most heavily
    published sub-areas of DR AI research found in this research.
-   **"Our AI model is more accurate than existing systems."**
    Unsupported and inadvisable --- this project has not conducted, and
    a hackathon timeline is unlikely to support, clinical-trial-grade
    validation comparable to LumineticsCore's FDA pivotal trial or
    ARDA's 600,000+-patient postdeployment study.
-   **"Our system is clinically validated / deployment-ready."**
    Unsupported --- nothing in this project's development to date
    constitutes the kind of prospective, multi-site clinical validation
    documented for the mature systems reviewed here (e.g., SMART DROP's
    registered prospective cohort design, or ARDA's postdeployment
    monitoring study).
-   **"Our system is the first to combine AI and telemedicine for DR in
    India."** False --- this combination has existed in Indian practice
    for over two decades (SNDRP since 2003) and is the explicit basis of
    ARDA's and SMART DROP's current designs.

------------------------------------------------------------------------

# REFERENCES

## Academic / peer-reviewed sources

1.  Determinants for scalable adoption of autonomous AI in the detection
    of diabetic eye disease in diverse practice types. *Frontiers in
    Digital Health*, 2023.
    https://www.frontiersin.org/journals/digital-health/articles/10.3389/fdgth.2023.1004130/full
    --- Supports: LumineticsCore/IDx-DR FDA De Novo authorization and
    background (Section 2).
2.  Autonomous Artificial Intelligence in Diabetic Retinopathy Testing
    --- Lessons Learned on Successful Health System Adoption.
    https://www.sciencedirect.com/science/article/pii/S2666914525002337
    and
    https://www.ophthalmologyscience.org/article/S2666-9145(25)00233-7/fulltext
    --- Supports: FDA-cleared systems overview (LumineticsCore, EyeArt,
    AEYE-DS) and their regulatory history (Section 2).
3.  Clinical Implementation of Autonomous Artificial Intelligence
    Systems for Diabetic Eye Exams. *Diabetes Care* / American Diabetes
    Association journals.
    https://diabetesjournals.org/clinical/article/42/1/142/153640/Clinical-Implementation-of-Autonomous-Artificial
    --- Supports: LumineticsCore pivotal trial sensitivity/specificity,
    image-quality-guided retake feature (Sections 2, 6).
4.  Performance of a Deep Learning Diabetic Retinopathy Algorithm in
    India. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11923701/ and
    https://research.google/pubs/performance-of-a-deep-learning-diabetic-retinopathy-algorithm-in-india/
    --- Supports: Google/Verily ARDA postdeployment performance, scale
    (600,000+ patients), Aravind partnership (Section 2, 6, 10).
5.  Real-World Performance of a Deep Learning Diabetic Retinopathy
    Algorithm (ARVO abstract).
    https://iovs.arvojournals.org/article.aspx?articleid=2793899 ---
    Supports: ARDA deployment scale (250,000+ patients, 61 sites)
    (Section 2).
6.  AI-Driven Diabetic Retinopathy Screening: Multicentric Validation of
    AIDRSS in India. arXiv preprint. https://arxiv.org/pdf/2501.05826
    --- Supports: AIDRSS system description and reported performance
    (Section 2), explicitly flagged as an unreplicated preprint claim
    (Anti-Hallucination section).
7.  Deep Learning Fundus Image Analysis for Diabetic Retinopathy and
    Macular Edema Grading (DeepDR). *Scientific Reports* / Nature.
    https://www.nature.com/articles/s41598-019-47181-w and
    https://pmc.ncbi.nlm.nih.gov/articles/PMC6656880/ and
    https://arxiv.org/pdf/1904.08764 --- Supports: DeepDR's integrated
    IQA+lesion+grading pipeline and performance (Sections 2, 7, 8).
8.  Diabetic retinopathy screening in rural India with portable fundus
    camera and artificial intelligence using eye mitra opticians from
    Essilor India. https://pmc.ncbi.nlm.nih.gov/articles/PMC8727670/ ---
    Supports: Remidio FOP + Medios AI rural field study, gradable-image
    rate (Sections 3, 8, Rural India Relevance).
9.  Automated diabetic retinopathy detection in smartphone-based fundus
    photography using artificial intelligence. *Eye* (Nature).
    https://www.nature.com/articles/s41433-018-0064-9 and
    https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5997766/ --- Supports:
    EyeArt evaluation on Remidio FOP smartphone images (Sections 2, 3).
10. Use of offline artificial intelligence in a smartphone-based fundus
    camera for community screening of diabetic retinopathy. *Indian
    Journal of Ophthalmology*.
    https://journals.lww.com/ijo/fulltext/2021/11000/use_of_offline_artificial_intelligence_in_a.40.aspx
    --- Supports: Medios AI offline design, Mumbai community screening
    (Sections 3, 4).
11. Medios --- An offline, smartphone-based artificial intelligence
    system for diabetic retinopathy. *Indian Journal of Ophthalmology*.
    https://journals.lww.com/ijo/fulltext/2020/68020/medios\_\_an_offline,\_smartphone_based_artificial.30.aspx
    --- Supports: Medios AI's stated rationale (lack of compute/internet
    in target settings) and offline design (Sections 4, Rural India
    Relevance).
12. Validity of smartphone-based retinal photography (PEEK-retina)
    compared to the standard ophthalmic fundus camera in diagnosing
    diabetic retinopathy in Uganda. *PLOS ONE*.
    https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0273633
    --- Supports: Peek Retina DR sensitivity/specificity (Section 3).
13. Comparison of smartphone-based retinal imaging systems for diabetic
    retinopathy detection using deep learning.
    https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7336606/ --- Supports:
    relative accuracy of Peek Retina vs. other smartphone systems
    (Section 3).
14. Screening for ROP (KIDROP programme, 3Nethra Neo camera).
    https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6157798/ --- Supports:
    Forus 3nethra Neo field-portability evidence via the KIDROP rural
    outreach program (Section 3).
15. Systematic Comparison of Heatmapping Techniques in Deep Learning in
    the Context of Diabetic Retinopathy Lesion Detection.
    https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7774113/ --- Supports:
    quantitative Explainability Consistency Score findings for Grad-CAM
    and other heatmapping techniques against IDRiD lesion ground truth
    (Section 5).
16. Uncertainty-aware diabetic retinopathy detection using deep learning
    enhanced by Bayesian approaches. *Scientific Reports*.
    https://www.nature.com/articles/s41598-024-84478-x --- Supports:
    Bayesian/MC-Dropout uncertainty quantification for DR (Section 5).
17. Role of calibration in uncertainty-based referral for deep learning.
    https://journals.sagepub.com/doi/abs/10.1177/09622802231158811 ---
    Supports: the finding that calibration quality affects whether
    uncertainty-based referral works as intended (Section 5, 9).
18. Optimizing Diabetic Retinopathy Screening at Primary Health Centres
    in India: A Cost-Effectiveness Analysis.
    https://link.springer.com/article/10.1007/s41669-025-00572-4 ---
    Supports: Ayushman Bharat PHC DR-screening context, India's
    ophthalmologist-to-population ratio figure (\~1:100,000) (Section 9,
    Rural India Relevance).
19. SMART (artificial intelligence enabled) DROP: Study protocol for
    diabetic retinopathy management. *PLOS ONE*.
    https://pmc.ncbi.nlm.nih.gov/articles/PMC12088010/ and
    https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0324382
    --- Supports: LVPEI's registered prospective AI+teleophthalmology
    pathway study, ophthalmologist-density figures (18 per million;
    \~3,500 patients/ophthalmologist/year) (Sections 2, 8, 9, 10).
20. Diabetic retinopathy screening in the public sector in India: What
    is needed? *Indian Journal of Ophthalmology*.
    https://www.ovid.com/jnls/ijo/fulltext/10.4103/ijo.ijo_1298_21\~diabetic-retinopathy-screening-in-the-public-sector-in-india
    --- Supports: history of Indian public-sector DR
    screening/teleophthalmology programs (SNDRP since 2003) (Section 4,
    Gap Validity Check).
21. Combined Discrete-event Simulation and Ant Colony Optimisation
    Approach for Selecting Optimal Screening Policies for Diabetic
    Retinopathy.
    https://link.springer.com/content/pdf/10.1007/s10287-006-0008-x.pdf
    --- Supports: existing DES-based DR screening-policy simulation
    literature, used to distinguish screening-policy simulation from
    AI-pipeline/network simulation (Sections 7, 8).
22. The evaluation of screening policies for diabetic retinopathy using
    simulation (POST model). https://pubmed.ncbi.nlm.nih.gov/12207814/
    and https://eprints.soton.ac.uk/35900 --- Supports: same distinction
    as above (Sections 7, 8).
23. Planning for resilience in screening operations using discrete event
    simulation modeling: example of HPV testing in Peru.
    https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9204370/ --- Supports:
    general precedent for DES-based screening-capacity planning as an
    established methodology in a different disease-screening context
    (Section 7).

## Regulatory / product / official sources

24. FDA permits marketing of LumineticsCore® (formerly IDx-DR). Digital
    Diagnostics.
    https://www.digitaldiagnostics.com/fda-permits-marketing-of-lumineticscore-formerly-known-as-idx-dr-for-automated-detection-of-diabetic-retinopathy-in-primary-care/
    --- Supports: FDA De Novo authorization history (Section 2).
    **Manufacturer source --- company statement, not independent peer
    review.**
25. 3nethra classic⁺, 3nethra pico, 3nethra specto, 3nethra ultima,
    3nethra neo HD FA --- Forus Health product pages.
    https://forushealth.com/3nethra-pico/,
    https://forushealth.com/3nethra-ultima/,
    https://forushealth.com/3nethra-specto/,
    https://forushealth.com/3nethra-neo-hd-fa/ --- Supports: product
    specifications, FH-POISE AI branding, Andhra Pradesh CHC
    screening-volume claim (Section 3). **Manufacturer source ---
    capability and volume claims not independently verified in this
    research.**

------------------------------------------------------------------------

# FINAL QUALITY-CONTROL CHECKLIST

-   [x] Existing academic DR systems were researched (DeepDR, AIDRSS,
    XAI/uncertainty literature).
-   [x] Existing commercial systems were researched (LumineticsCore,
    EyeArt, AEYE-DS, Google/Verily ARDA, Remidio Medios AI, Forus Health
    3nethra family).
-   [x] Portable-camera systems were researched (Remidio FOP, Peek
    Retina, Forus 3nethra family).
-   [x] Offline/on-device systems were researched (Medios AI;
    distinguished from store-and-forward teleophthalmology).
-   [x] Explainable DR AI systems were researched (Grad-CAM, HiResCAM,
    SHAP, uncertainty quantification, quantitative heatmap-accuracy
    study).
-   [x] Telemedicine systems were considered (SMART DROP, ARDA's
    hospital network, Indian public-sector teleophthalmology history).
-   [x] Rural/low-resource systems were considered (dedicated Rural
    India Relevance section).
-   [x] Major capabilities were compared objectively (Section 6
    comparison matrix with ✓/△/✗/? legend, including uncertain cells
    left as "?" rather than guessed).
-   [x] Our system was included in the comparison matrix, without being
    automatically marked superior on every row.
-   [x] Existing systems that already solve proposed features were
    identified explicitly (Section 7, "Mature/well-established").
-   [x] Feature-level novelty was separated from system-level
    differentiation (Section 1, Section 10).
-   [x] Commercial claims were not treated as independently validated
    facts (Anti-Hallucination section explicitly flags Forus Health's
    FH-POISE and screening-volume claims as manufacturer-sourced).
-   [x] Unsupported "no existing system does X" claims were avoided
    (Section 8 and "Claims we should NOT make" explicitly reject several
    such claims).
-   [x] Clinical validation was distinguished from dataset performance
    (dedicated Clinical Validation Analysis section, citing ARDA's own
    postdeployment-vs-trial gap as evidence).
-   [x] The proposed technical gap is evidence-based (Sections 8, 9
    built directly from the comparison and combination-evidence tables).
-   [x] The gap was stress-tested against existing solutions (Gap
    Validity Check section, 8-question stress test).
-   [x] Strong but defensible differentiation was identified
    (Recommended Positioning section).
-   [x] Weak/unsupported claims were explicitly rejected (Recommended
    Positioning, "Claims we should NOT make").
-   [x] References are provided, distinguishing academic/peer-reviewed
    sources from manufacturer/product sources.
-   [x] Every important claim is traceable to a specific source cited
    above; uncertain items are explicitly marked "Not publicly
    documented" or "?" rather than inferred.

------------------------------------------------------------------------

# Appendix 3: Retained Material from `05_existing-solutions-gap (2).md`

# Technical Research: Existing Solutions, State of the Art, and System-Level Technical Gap Analysis (SIH 26038)

## 1. Purpose

Researching the existing automated Diabetic Retinopathy (DR) landscape
is essential to prevent duplicating established technologies and to
establish a technically defensible project proposal for Smart India
Hackathon (SIH) Problem Statement 26038.

Over the last decade, computer vision and deep learning applied to
retinal fundus photography have progressed from academic experiments to
commercial, regulatory-cleared screening systems. Claiming that a system
is novel simply because it detects microaneurysms, grades DR using
convolutional neural networks (CNNs), or generates a Class Activation
Map (Grad-CAM) is technically inaccurate.

    +--------------------------------------------------------------------------------------------------+
    |                                    NOVELTY TAXONOMY                                              |
    +--------------------------------------------------------------------------------------------------+
    |  FEATURE NOVELTY (Often False Claims)                                                            |
    |  - "First AI to detect Diabetic Retinopathy"                    --> Solved (Abràmoff et al., 2016)|
    |  - "First use of CNNs/Transfer Learning on Retinal Images"      --> Solved (Gulshan et al., 2016) |
    |  - "First to use Grad-CAM heatmaps for explainability"          --> Solved (Multiple papers, 2017)|
    |  - "First to use CLAHE and Morphological Filtering"             --> Solved (Established, 1990s)  |
    |                                                                                                  |
    |  SYSTEM-LEVEL DIFFERENTIATION (Defensible Technical Gap)                                         |
    |  - Addressing the end-to-end breakdown between edge hardware, degraded input quality,            |
    |    black-box opacity, telecommunication constraints, and human resource bottlenecks.            |
    |  - Coupling an edge-executable, multi-stage explainable pipeline with a closed-loop               |
    |    digital twin simulation that validates district-scale feasibility (100,000+ patients/year).  |
    +--------------------------------------------------------------------------------------------------+

### Feature Novelty vs. System-Level Differentiation

-   **Feature Novelty:** Isolated algorithmic attributes (e.g., using a
    specific neural backbone, applying a particular adaptive
    thresholding parameter, or computing an ROC curve). These components
    are well-documented in open literature and standard toolboxes.
-   **System-Level Differentiation:** The coherent integration of
    heterogeneous technologies---combining classical pre-processing,
    deterministic quality gating, dual-level interpretability
    (pixel-level morphology combined with gradient activations),
    probability calibration, and operational systems engineering
    (discrete-event queue and network modeling)---to address the failure
    modes of rural healthcare deployment.

------------------------------------------------------------------------

## 2. Existing DR AI Systems

Automated screening architectures range from classical feature
extraction pipelines to deep neural networks and FDA-cleared commercial
medical devices.

    AI Screening Paradigms:
    1. End-to-End Deep Learning (Black-Box):
       Input Image ───► Deep ConvNet Backbone ───► Softmax Probabilities (Grades 0-4)
       
    2. Lesion-Guided / Hybrid Systems:
       Input Image ───┬─► Morphological / U-Net Segmentation ──► Lesion Counts/Density ─┐
                      │                                                                  ├─► Integrated Diagnosis
                      └─► Global CNN Backbone Feature Embeddings ────────────────────────┘

### Comparative Analysis of Established Systems

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  System           Organization   Year    AI Approach       DR Task              Dataset Used     Reported        Clinical         Deployment        Known Limitations
                                                                                                  Performance     Validation       Evidence          
  ---------------- -------------- ------- ----------------- -------------------- ---------------- --------------- ---------------- ----------------- --------------------
  **IDx-DR (now    Digital        2018    Biomarker-based   Referable DR (rDR:   Proprietary      Sensitivity:    Prospective,     Commercial        Locked to specific
  Digital          Diagnostics            deep learning     Moderate NPDR or     clinical trial   $87.2\%$,       multi-center FDA deployment in US  desktop fundus
  Diagnostics)**   (USA)                  ensemble          worse / DME)         datasets         Specificity:    pivotal trial    primary care      camera (Topcon
                                                                                 ($N=900$)        $90.7\%$        (NCT02963441)    clinics           NW400); cloud/local
                                                                                                  (Pivotal trial)                                    enterprise server
                                                                                                                                                     required;
                                                                                                                                                     proprietary closed
                                                                                                                                                     ecosystem.

  **EyeArt**       Eyenuk,        2020    Multi-scale deep  Referable DR and     Clinical         Sensitivity:    Prospective,     Deployed          High infrastructure
                   Inc. (USA)             convolutional     Vision-Threatening   validation sets  $95.5\%$,       multi-center     internationally   requirement;
                                          neural network    DR (vtDR)            ($N>100,000$     Specificity:    clinical         and within NHS    proprietary
                                                                                 images)          $86.5\%$        validation; FDA  screening         cloud-centric
                                                                                                                  510(k) cleared   workflows         processing; limited
                                                                                                                                                     visual
                                                                                                                                                     explainability for
                                                                                                                                                     local operators.

  **Google Health  Google Health  2016,   Modified          Referable DR (ICDR   Kaggle EyePACS   Sensitivity:    Prospective      Deployed in       Initial field
  / ARDA**         / Verily       2019    Inception-v4 /    Grade $\ge 2$)       ($N=128,175$),   $90.3\%$,       validation in    pilots across     studies showed high
                   (USA/India)            ensemble deep                          Messidor-2       Specificity:    Indian public    India and         ungradable drop
                                          CNNs                                   ($N=1,748$)      $98.1\%$        clinics          Thailand          rates due to
                                                                                                  (Messidor-2)    (Aravind,                          lighting variations;
                                                                                                                  Sankara)                           cloud connectivity
                                                                                                                                                     preferred; Grad-CAM
                                                                                                                                                     heatmaps not
                                                                                                                                                     verified for direct
                                                                                                                                                     clinical triage.

  **Medios AI**    Remidio        2020    Lightweight deep  Referable DR         Indian clinical  Sensitivity:    Prospective      Deployed on       Binary
                   Innovative             CNN optimized for (binary)             cohort           $93.0\%$,       peer-reviewed    Remidio Fundus on classification only
                   Solutions              edge deployment                        ($N=4,137$)      Specificity:    validation       Phone (FOP)       (not granular
                   (India)                                                                        $92.5\%$        against Indian   devices across    5-class ICDR);
                                                                                                  (Validation     tele-screening   India             proprietary
                                                                                                  cohort)         cohorts                            on-device model tied
                                                                                                                                                     directly to Remidio
                                                                                                                                                     smartphone hardware.

  **SELENA+**      EyRIS /        2018    Multi-task deep   Referable DR,        Multi-ethnic     Sensitivity:    Extensive global Commercial        Cloud-tethered
                   Singapore Eye          learning ensemble Glaucoma suspect,    cohorts          $90.5\%$,       external         deployment across enterprise software;
                   Research                                 AMD                  ($N=494,661$     Specificity:    validation       Singapore         optimized for
                   Institute                                                     images)          $91.6\%$        (Singapore,      National          high-end tabletop
                   (Singapore)                                                                                    Australia, UK)   Screening Program desktop cameras
                                                                                                                                                     (Canon, Topcon); no
                                                                                                                                                     network-simulation
                                                                                                                                                     integration.

  **Dual-Stage XAI Academic       2021    Multi-task U-Net  5-Class ICDR Grading IDRiD ($N=516$), AUC:            Retrospective    Laboratory        Untested on field
  Research         Literature             for lesions +                          DDR ($N=13,677$) $0.93 - 0.95$   validation on    prototype /       deployment
  Prototype**      (e.g., Yang et         ResNet-50                                               across 5        public academic  open-source code  telemetry;
                   al.)                   classifier                                              classes         benchmark        repository        processing latency
                                                                                                                  datasets                           exceeds standard
                                                                                                                                                     edge-device
                                                                                                                                                     constraints; lacks
                                                                                                                                                     automated reporting
                                                                                                                                                     and operational
                                                                                                                                                     simulation.
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------

### Summary of Strengths and Gaps in Existing AI Models

-   **What they solve well:** High diagnostic sensitivity and
    specificity on clean, well-illuminated tabletop fundus photographs
    for the binary classification of Referable Diabetic Retinopathy
    ($>90\%$ sensitivity target met).
-   **What they do not solve:** Seamless tolerance of multi-vendor
    portable camera artifacts, granular 5-class diagnostic evidence tied
    to sub-pixel lesions, and dynamic adaptation to intermittent,
    bandwidth-constrained rural telemedicine pipelines.

------------------------------------------------------------------------

## 3. Existing Portable-Camera Solutions

Portable and smartphone-based fundus cameras have emerged as low-cost
alternatives to clinical desktop systems (which often cost upwards of
\$15,000--\$30,000 USD). However, they introduce optical and field
operational challenges that affect AI screening accuracy.

    Tabletop Fundus Cameras:
    [Fixed Chinrest] ──► [Constant Illumination] ──► [45°-50° Field] ──► High First-Pass Quality

    Handheld / Smartphone Cameras:
    [Handheld Wobble] ──► [Variable Corneal Reflection] ──► [Vignetting/Pupil Drift] ──► Elevated Blur/Artifacts

### Portable and Handheld Screening Systems

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Solution /    Camera System           Coupled AI       Portable / Form Offline Capability Connectivity         Image Quality     Independent Clinical Rural         Primary Limitations
  Device                                System           Factor                             Dependencies         Assessment (IQA)  Validation           Deployment    
                                                                                                                                                        Evidence      
  ------------- ----------------------- ---------------- --------------- ------------------ -------------------- ----------------- -------------------- ------------- ---------------------
  **Remidio FOP Remidio Fundus on Phone Medios AI        Fully portable  **Yes** (Runs      None required for    Basic             Peer-reviewed        Active in     Proprietary
  (NM-FOP)**    (Smartphone optical     (On-device       (Handheld,      locally on         inference; cellular  exposure/glare    validation in Indian rural         ecosystem; binary
                adapter)                neural network)  battery         smartphone)        uplink used for      gate              clinics (Gulshan et  screening     classification
                                                         powered)                           doctor auditing                        al., Rajalakshmi et  camps and     output; limited
                                                                                                                                   al.)                 vision        lesion-specific
                                                                                                                                                        centers       explainability;
                                                                                                                                                        across India  relies on mydriasis
                                                                                                                                                                      (dilation) in dark
                                                                                                                                                                      rooms for
                                                                                                                                                                      non-cooperative
                                                                                                                                                                      patients.

  **Volk        Volk Optical (Handheld  Volk iNview /    Portable        **Partial**        Requires Wi-Fi/4G to Basic image       Evaluated in         Global        High dependency on
  VistaView**   portable fundus camera) Third-party      (Integrated     (Acquisition       transfer images to   review by         community screening  community     stable internet
                                        Cloud            handheld unit)  offline; grading   cloud AI engines     operator          pilots               screening     uplinks for automated
                                        Integration                      cloud-dependent)                                                               projects      classification;
                                                                                                                                                                      requires manual
                                                                                                                                                                      re-centering by
                                                                                                                                                                      operator.

  **Forus       Forus Health (India)    Third-party AI   Semi-portable   **No** (Standard   Operates over local  Operator-driven   Extensively          High          Not handheld;
  3Nethra       (Compact                integrations     (Requires       units require      LAN or               manual check or   validated in Indian  penetration   requires operator
  classic /     desktop/semi-portable   (Retinally,      table, compact  external PC        tele-ophthalmology   external quality  tele-ophthalmology   across Indian training for manual
  neo**         camera)                 etc.)            carrying case)  processing)        cloud                plug-in           networks (Aravind    rural vision  pupil alignment;
                                                                                                                                   Eye Care System)     centers       sensitivity drops in
                                                                                                                                                                      the presence of media
                                                                                                                                                                      opacities (e.g.,
                                                                                                                                                                      cataracts).

  **Optomed     Optomed (Finland)       Integrated       Fully portable  **Partial**        Cellular/Wi-Fi       Built-in          Validated in         Used in       High unit cost;
  Aurora**      (Handheld non-mydriatic cloud/embedded   (Handheld form  (Depending on the  uplink to hospital   non-mydriatic     European and Asian   global mobile advanced AI features
                camera)                 partner AI       factor)         coupled AI         PACS/Cloud AI        quality           clinical cohorts     screening     require subscriptions
                                        (Airdoc, EyeRIS)                 license)                                verification                           vans          and cloud
                                                                                                                                                                      integration;
                                                                                                                                                                      artifacts from small
                                                                                                                                                                      pupil diameters
                                                                                                                                                                      ($<3.5\,\text{mm}$)
                                                                                                                                                                      reduce readability.
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### Technical Analysis of Portable Camera Data

When deploying in rural Indian PHCs, non-mydriatic (undilated) handheld
captures often suffer from poor focus, eyelid/eyelash artifacts, uneven
illumination, and corneal reflections. Existing systems address this
primarily through proprietary hardware baffles or basic post-capture
exclusion. Most systems lack a modular, transparent, and multi-stage
Image Quality Assessment (IQA) module that provides actionable feedback
to the operator (such as detecting underexposure versus motion blur)
before sending the data to the neural network.

------------------------------------------------------------------------

## 4. Existing Offline Solutions

Deploying AI systems in rural environments requires operating through
intermittent or absent power and telecommunications infrastructure.

    Inference vs. Workflow Topology:

    1. Offline AI Inference Only (Common):
       Camera ──► Local PC / Edge Box (Local AI Inference) ──X (Pipeline Halts; No Specialist Review)

    2. Offline-First Complete Tele-Workflow (Rare):
       Camera ──► Local IQA ──► Local AI ──► Encrypted SQLite Store ──► Opportunistic Uplink ──► Central Doctor Triage

### Systems with Localized Processing Capabilities

  -------------------------------------------------------------------------------------------------------------------------------------
  System / Platform    Local AI          Cloud           Offline       Store-and-Forward   Connectivity          Operational
                       Processing        Dependency      Inference     Telemedicine        Dependencies          Limitations
                                                         Support       Support                                   
  -------------------- ----------------- --------------- ------------- ------------------- --------------------- ----------------------
  **Medios AI          **Yes** (Embedded Cloud not       Fully offline **Yes** (Can buffer Local operation       Strictly proprietary;
  (Remidio)**          ONNX/TFLite       required for    inference on  clinical reports    requires zero         operates exclusively
                       models on mobile  point-of-care   smartphone    locally until       connectivity; remote  on Remidio hardware;
                       hardware)         grading         edge node     cellular coverage   synchronization       does not permit
                                                                       is detected)        requires 2G/3G/4G     third-party camera
                                                                                                                 integration or
                                                                                                                 external algorithmic
                                                                                                                 inspection.

  **IDx-DR Edge Box**  **Yes**           Connects        Fully offline Limited (Designed   Ethernet/LAN access   Appliance hardware
                       (Dedicated local  periodically    operational   primarily for       for setup and         cost is high; fixed
                       appliance         for licensing,  inference     immediate           enterprise electronic clinical
                       hardware)         logging, and                  primary-care        health record (EHR)   configuration;
                                         updates                       handoff rather than sync                  requires pristine
                                                                       asynchronous                              input images from a
                                                                       telemedicine)                             designated Topcon
                                                                                                                 camera.

  **Standard           **Yes** (Local    None            Local         **No** (Research    None during local     Lacks fault-tolerant
  Open-Source          desktop GPU                       workstation   scripts do not      inference; no         asynchronous database
  Prototypes**         running                           inference     model data          built-in              synchronization, data
                       Python/PyTorch)                                 synchronization or  telecommunications    encryption, and
                                                                       transmission        routing               network-aware
                                                                       failure)                                  transmission queue
                                                                                                                 logic.

  **Commercial         **No**            **Mandatory**   **No**        **Yes** (Core       High-speed,           Completely fails in
  Tele-Ophthalmology                                     (Inference    architecture relies high-reliability      dead zones or
  Clouds (e.g.,                                          executed      on central queue    broadband uplink      high-latency rural
  Retmarker, EyeNuk                                      entirely on   buffering)          ($>2\,\text{Mbps}$)   mobile networks
  Cloud)**                                               remote cloud                                            ($<128\,\text{kbps}$
                                                         clusters)                                               or intermittent
                                                                                                                 drops).
  -------------------------------------------------------------------------------------------------------------------------------------

### Key Distinction: Offline Inference vs. Offline Clinical Workflow

-   **Offline Inference:** Executing a forward pass of a deep neural
    network on a local CPU/GPU without an active internet connection.
    *This is technically mature and straightforward to achieve via
    optimized runtimes (such as ONNX, MATLAB MEX, or TensorRT).*
-   **Offline Clinical Workflow:** The ability to complete patient
    intake, perform automated IQA, execute inference, generate a
    calibrated triage prediction, generate a localized report, and
    safely manage an encrypted local queue that opportunistically syncs
    with regional ophthalmologists when network conditions improve.
    *This integration remains a common failure point in rural
    deployments.*

------------------------------------------------------------------------

## 5. Existing Explainable-AI (XAI) Approaches in Retinal Imaging

Most published DR AI models operate as black-box predictors, outputting
only a class label and an associated softmax score. Several
interpretability techniques have been applied to address this
limitation.

    +--------------------------------------------------------------------------------------------------+
    |                                    XAI FIDELITY COMPARISON                                       |
    +--------------------------------------------------------------------------------------------------+
    |  COARSE ATTENTION (Standard Grad-CAM):                                                           |
    |  [ Retinal Vessel ] ──► ( Large, blurry heatmap blob covering vessels, macula, and background )  |
    |  Clinical Utility: Low. Merely confirms the CNN is looking at the retina, not the border.        |
    |                                                                                                  |
    |  FINE LESION EVIDENCE (Multi-Task / Classical Overlay):                                          |
    |  [ Microaneurysm Proposal ] ──► ( Distinct sub-pixel bounding box + CLAHE contrast validation )  |
    |  Clinical Utility: High. Directly correlates with clinical diagnostic criteria.                 |
    +--------------------------------------------------------------------------------------------------+

### Evaluation of XAI Methods for Retinal Screening

  ---------------------------------------------------------------------------------------------------------------
  XAI Method        Typical DR       What It Explains   Algorithmic      Primary           Clinical Usefulness
                    Application                         Strengths        Limitations       for Triage
  ----------------- ---------------- ------------------ ---------------- ----------------- ----------------------
  **Grad-CAM**      Post-hoc         Coarse spatial     Low              Low spatial       **Low to Moderate.**
                    visualization of regions that       computational    resolution        Helps identify gross
                    CNN              maximize the       overhead;        (governed by the  failure modes, but
                    classification   activation of the  natively         final             insufficient for
                    backbones        predicted class    supported across convolutional     verifying early
                    (ResNet,         layer              deep learning    feature stride,   microaneurysm
                    EfficientNet)                       toolboxes        e.g.,             pathology.
                                                                         $16\times 16$ or  
                                                                         $32\times 32$);   
                                                                         highlights        
                                                                         general quadrants 
                                                                         rather than       
                                                                         individual        
                                                                         lesions; can      
                                                                         produce           
                                                                         false-positive    
                                                                         visual artifacts  
                                                                         on lens dirt.     

  **Grad-CAM++**    Fine-grained     Weighted           Better           Still constrained **Moderate.** Better
                    classification   pixel-level        localization of  by the coarse     highlights dispersed
                    visualization    contributions,     multiple         spatial           hard exudates, but
                                     particularly for   distinct lesion  resolution of     cannot delineate fine
                                     multi-instance     clusters than    deep feature      vessel
                                     targets            standard         maps; susceptible micro-abnormalities.
                                                        Grad-CAM         to high gradient  
                                                                         noise.            

  **Integrated      Feature          Attribution of     Axiomatically    Computationally   **Low.** Pixel
  Gradients**       attribution      every input pixel  grounded         slow              attribution noise does
                    across all input to the final logit (satisfies       ($50-300\times$   not match the
                    pixels           prediction         completeness and baseline forward  morphology clinicians
                                                        implementation   pass);            use for diagnosis.
                                                        invariance)      attribution maps  
                                                                         appear noisy,     
                                                                         speckled, and     
                                                                         difficult for     
                                                                         non-engineers to  
                                                                         interpret.        

  **Saliency Maps   Edge and         Identifies         Simple to        Highlights        **Low.** Often
  (Vanilla / Guided boundary         high-frequency     compute via a    general           misleads operators by
  Backprop)**       attribution maps edges that drive   single backward  structural edges  highlighting healthy
                                     the gradient       pass             (e.g., normal     vascular boundaries.
                                     response                            retinal vessels,  
                                                                         optic disc        
                                                                         borders) rather   
                                                                         than true         
                                                                         pathology.        

  **Semantic        Lesion boundary  Pixel-level binary Directly aligns  Requires dense,   **High.** Provides
  Segmentation      extraction       masks identifying  with clinical    pixel-level       direct visual evidence
  (U-Net Masks)**   (Exudates,       specific           diagnostic       expert            that matches clinical
                    Hemorrhages)     pathological       terminology      annotations for   diagnostic rules.
                                     structures         (e.g., surface   training; high    
                                                        area of          memory and        
                                                        intraretinal     compute footprint 
                                                        hemorrhages)     on edge hardware. 

  **Morphological   Structural       Sub-pixel          Fast,            Prone to false    **High (when paired
  Extraction        extraction of    candidate          deterministic,   alarms on         with CNNs).** Grounds
  Overlays**        bright/dark      identification     and does not     background        black-box network
                    anomalies        (microaneurysms,   require complex  choroidal vessels attention in tangible
                                     vessel occlusions) deep neural      and optical noise morphological
                                                        network training if parameters are anomalies.
                                                                         poorly tuned.     
  ---------------------------------------------------------------------------------------------------------------

### Does a Heatmap Alone Constitute Clinical Explainability?

**No.** Peer-reviewed clinical literature (e.g., *Lancet Digital
Health*, *Ophthalmology Science*) indicates that uncalibrated Grad-CAM
heatmaps often fail to provide actionable clinical insight. A heatmap
that broadly highlights a large section of the retina does not tell an
ophthalmologist whether the AI triggered on a cluster of microaneurysms,
a pigmentary change, poor focus, or sensor dirt.

True clinical explainability requires combining spatial attention with
specific, verifiable evidence: \* Localizing the candidate lesion
(bounding box or morphological mask). \* Quantifying its physical
attributes (pixel radius, area, proximity to the fovea). \* Providing a
calibrated statistical confidence score for the prediction.

------------------------------------------------------------------------

## 6. Comprehensive Capability Comparison Matrix

The following matrix compares major existing research archetypes,
commercial solutions, and our proposed SIH 26038 technical architecture
across clinical, technical, and operational dimensions.

    Key:  ✓ = Fully Demonstrated & Validated   △ = Partially Addressed / Limited Evidence   ✗ = Not Demonstrated   ? = Insufficient Public Evidence

  ----------------------------------------------------------------------------------------------------
  Functional Capability     IDx-DR       Google ARDA   Medios AI      EyeArt      Academic  SIH 26038
                                                                                 U-Net XAI   Proposed
                                                                                              Design
  --------------------- -------------- --------------- ---------- -------------- ---------- ----------
  **Automated DR              ✓               ✓            ✓            ✓            ✓          ✓
  Screening**                                                                               

  **5-Class ICDR        ✗ (Binary rDR) ✓ (Multi-class) ✗ (Binary  ✗ (Binary rDR)     ✓          ✓
  Staging**                                               rDR)                              

  **Referable DR (rDR)        ✓               ✓            ✓            ✓            △          ✓
  Optimization**                                                                            

  **Modular Image             ✓               △            △            ✓            ✗          ✓
  Quality Gating                                                                            
  (IQA)**                                                                                   

  **Adaptive Image            ?               ✗            ?            ?            △          ✓
  Enhancement (CLAHE)**                                                                     

  **Retinal Vessel /          ✓          ✗ (Latent)    ✗ (Latent)       ✓            ✓          ✓
  Disc Analysis**                                                                           

  **Discrete Lesion           ✓          ✗ (Latent)    ✗ (Latent)       ✓            ✓          ✓
  Proposals**                                                                               

  **Portable / Handheld       ✗               △            ✓            △            ✗          ✓
  Camera Support**                                                                          

  **Edge / Local        △ (Appliance)     ✗ (Cloud)    ✓ (Mobile)   ✗ (Cloud)      ✓ (PC)       ✓
  Offline Inference**                                                                       

  **Grad-CAM Saliency         ✗               △            ✗            ✗            ✓          ✓
  Maps**                                                                                    

  **Fine Morphological        ✓               ✗            ✗            ✗            △          ✓
  Evidence**                                                                                

  **Probability               ?               △            ?            ?            ✗          ✓
  Calibration                                                                               
  (Platt/Temp)**                                                                            

  **Automated                 ✓               △            ✓            ✓            ✗          ✓
  Diagnostic Triage                                                                         
  Report**                                                                                  

  **Human-in-the-Loop   ✗ (Autonomous)        △            △      ✗ (Autonomous)     ✗          ✓
  Workflow Engine**                                                                         

  **Network-Aware             ✗               ✗            △            ✗            ✗          ✓
  Telemedicine Spool**                                                                      

  **Rural Operational         ✗               ✗            ✗            ✗            ✗          ✓
  Simulation**                                                                              

  **SimEvents                 ✗               ✗            ✗            ✗            ✗          ✓
  Discrete-Queue                                                                            
  Modeling**                                                                                

  **100,000+ Annual           ✗               ✗            ✗            ✗            ✗          ✓
  Scale Validation**                                                                        
  ----------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 7. What Existing Systems Already Solve

To maintain technical credibility, this project must not claim novelty
for capabilities that are already mature and commercially deployed.

    State of Technology Maturity in Retinal AI:

    [MATURE & ESTABLISHED]
    ├── Binary Referable DR Classification (Sens/Spec > 90%)
    ├── Transfer Learning using Standard CNN Backbones
    ├── Edge-Device Deep Learning Compilation (ONNX, TensorRT, TFLite)
    └── Basic Post-Hoc Saliency Heatmaps (Grad-CAM)

    [DEMONSTRATED BUT FRAGMENTED]
    ├── Dual-Stage Detection (Lesion Segmentation + Image Classification)
    ├── Offline Store-and-Forward Telemedicine Synchronization
    └── Automated PDF Clinical Triage Report Generation

    [RESEARCH-LEVEL & GENERALLY UNSOLVED]
    ├── Dynamic Adaptation to Diverse Handheld Camera Artifacts
    ├── Multi-Scale Verification Combining Coarse XAI with Sub-Pixel Morphology
    └── End-to-End Operational Telemedicine Discrete-Event Systems Modeling

### Categorized Capabilities

#### Mature and Well-Established (Do Not Claim Novelty)

-   **Automated Binary Referable DR Classification:** Classifying fundus
    images into Referable DR (Moderate NPDR or worse) versus
    Non-Referable DR has been extensively solved by systems like IDx-DR,
    EyeArt, and Google ARDA, with sensitivities and specificities
    routinely exceeding $90\%$.
-   **Transfer Learning on Retinal Benchmarks:** Fine-tuning backbones
    like ResNet, EfficientNet, and Inception on public datasets (such as
    EyePACS, Messidor, and APTOS) is standard practice.
-   **Stand-alone Grad-CAM Generation:** Visualizing class activation
    maps using standard backbones is supported natively across toolboxes
    and cannot be presented as a novel algorithmic contribution.
-   **Standalone Mobile Deployment:** Demonstrating on-device inference
    on a handheld device has already been achieved at scale by
    commercial products like Remidio Medios AI.

#### Demonstrated but Fragmented

-   **Automated Image Quality Assessment (IQA):** Exists in desktop
    cameras, but frequently breaks down on low-cost handheld devices
    when exposed to pupil drift and illumination shifts.
-   **Lesion-Level Segmentation:** Demonstrated on benchmark datasets
    using architectures like U-Net and YOLO, but rarely packaged
    alongside lightweight classifiers due to edge memory and compute
    budgets.

#### Research-Level / Operationally Unresolved

-   **Multi-Vendor Handheld Camera Normalization:** Creating
    pre-processing pipelines that maintain performance across both
    high-end tabletop and low-cost portable cameras without retraining
    models.
-   **Integrated Multi-Tier Explainability:** Combining coarse deep
    learning attention maps with sub-pixel morphological lesion
    candidates and confidence calibration to support review by
    non-specialist clinicians.
-   **Operational Systems Simulation:** Modeling how an AI screening
    pipeline interacts with queuing dynamics, intermittent cellular
    bandwidth, and limited specialist availability across an entire
    administrative district serving over 100,000 patients annually.

------------------------------------------------------------------------

## 8. What Existing Systems Do Not Solve Together (Multi-Capability Gaps)

The primary limitation of current approaches lies in the operational
divide between algorithmic screening and field implementation. Existing
solutions solve isolated sub-problems, but break down when deployed in
resource-constrained rural healthcare environments.

    Current Operational Bottlenecks in Rural Screening:

    [Algorithm-Only Research Prototypes]
    High Theoretical Accuracy ──► Fails in Field ──► (No IQA Gating, Breaks on Blurry Handheld Images)

    [Commercial Enterprise Ecosystems]
    High Diagnostic Rigor ────► Fails in Field ──► (Locked Hardware, Expensive, Cloud-Tethered)

    [Unassisted Direct-to-Doctor Tele-Screening]
    No Local AI Triage ───────► Fails in Field ──► (Bandwidth Overload, Doctor Burnout from Normal Images)

### Multi-Capability Integration Analysis

  ---------------------------------------------------------------------------------------------------------
  Capability Combination         Current State  Representative       Level of          Remaining
                                 of Evidence    Systems              Integration       Operational Gap
  ------------------------------ -------------- -------------------- ----------------- --------------------
  **Combination                  Commercial     Remidio Medios AI,   **Partial.** IQA  Lack of an open,
  A:**`<br>`{=html}Portable      handhelds      academic IQA papers  is often tightly  modular IQA and
  Handheld Imaging`<br>`{=html}+ (e.g.,                              locked to         enhancement pipeline
  Modular Pre-Capture            Remidio) run                        proprietary       that can normalize
  IQA`<br>`{=html}+ Adaptive     proprietary                         hardware or       variable-quality
  Enhancement                    IQA; academic                       treated as an     images from low-cost
                                 research                            offline research  cameras before
                                 focuses mostly                      step.             feeding them to deep
                                 on clean,                                             networks.
                                 curated                                               
                                 datasets.                                             

  **Combination                  Most models    Academic dual-stage  **Low.** Deep     Absence of an
  B:**`<br>`{=html}Fine Lesion   produce either papers (e.g.,        classifiers and   integrated
  Proposals`<br>`{=html}+ Coarse a coarse       U-Net + ResNet)      lesion segmenters explainability layer
  Grad-CAM Maps`<br>`{=html}+    heatmap                             are rarely        that combines coarse
  Calibrated Confidence Scores   (Grad-CAM) or                       integrated into a heatmaps with
                                 an                                  single            localized lesion
                                 uncalibrated                        lightweight       proposals and
                                 softmax                             pipeline.         Platt-calibrated
                                 probability.                                          risk probabilities.
                                 Lesion                                                
                                 segmentation                                          
                                 models often                                          
                                 run in                                                
                                 isolation.                                            

  **Combination                  Commercial     Commercial           **Low to          Lack of an
  C:**`<br>`{=html}Edge AI       clouds require tele-ophthalmology   Moderate.** AI    edge-coordinated
  Classification`<br>`{=html}+   reliable       web portals          inference and     system that buffers
  Network-Aware                  uplinks;                            network           data locally,
  Telemedicine`<br>`{=html}+     standalone                          transmission are  prioritizes packets
  Asynchronous Triage Queues     offline apps                        typically handled based on AI-assessed
                                 lack built-in                       by separate,      risk, and adapts
                                 tools to                            uncoordinated     transmission to
                                 manage                              software layers.  fluctuating rural
                                 transmission                                          network bandwidth.
                                 queues over                                           
                                 intermittent                                          
                                 networks.                                             

  **Combination                  Clinical       Healthcare           **Almost          **Major System
  D:**`<br>`{=html}Screening     trials report  operations research  Non-Existent.**   Gap.** No existing
  Algorithm                      diagnostic     literature (SimIO,   The AI research   screening platform
  Pipeline`<br>`{=html}+         sensitivity    discrete queuing     community and the links its
  Discrete-Event Queue           and            theory)              operational       algorithmic
  Modeling`<br>`{=html}+         specificity,                        healthcare        processing pipeline
  District Resource Sizing       but rarely                          systems           to a dynamic
  (100k+ Patients)               model                               simulation        Simulink/SimEvents
                                 operational                         community work in model to simulate
                                 systems                             isolation.        district-wide
                                 metrics                                               screening
                                 (queuing, wait                                        operations.
                                 times,                                                
                                 reviewer                                              
                                 bandwidth,                                            
                                 network                                               
                                 latency).                                             
  ---------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 9. Defining Our Technical Gap

Our technical gap does not depend on claiming an entirely new neural
network architecture. Instead, it addresses the system-level operational
challenges that cause screening workflows to fail in rural healthcare
environments like Indian PHCs.

    +───────────────────────────────────────────────────────────────────────────────────────────────────+
    |                                    PROPOSED TECHNICAL PIPELINE                                    |
    +───────────────────────────────────────────────────────────────────────────────────────────────────+
    |                                                                                                   |
    |  [Layer 1: Input Normalization & Gating]                                                          |
    |  - Variance of Laplacian Focus Gating + Histogram Dynamic Range Checking (Edge IQA)                |
    |  - Green-Channel Spatial CLAHE + Background Vignette Subtraction (Adaptive Enhancement)          |
    |                                                                                                   |
    |  [Layer 2: Dual-Stream Diagnostic Engine]                                                         |
    |  - Stream A: Morphological Sub-Pixel Extraction (Microaneurysm & Hard Exudate Bounding)           |
    |  - Stream B: Compound-Scaled Deep Classifier (EfficientNet Backbone for 5-Class ICDR)            |
    |                                                                                                   |
    |  [Layer 3: Multi-Tier Clinical Explainability & Calibration]                                      |
    |  - Spatial Heatmap Layer: Layer-Specific Grad-CAM Integration                                 |
    |  - Structural Evidence: Overlaid Morphological Lesion Delineations                       |
    |  - Statistical Calibration: Empirical Platt Scaling for Reliable Risk Probabilities        |
    |                                                                                                   |
    |  [Layer 4: Operational Systems Digital Twin (Simulink / SimEvents)]                               |
    |  - Dynamic Modeling: Non-Homogeneous Poisson Patient Arrivals & In-Clinic Queuing              |
    |  - Communications: Variable Bandwidth (64–384 kbps), Packet Drop, and Retransmission Spools     |
    |  - Human Resources: Tiered Priority Doctor Review Queues (30s Routine vs. 90s Pathological)      |
    |  - Scale Validation: Empirical Throughput Sizing for 100,000+ Patients/Year (20 PHC Model)       |
    +───────────────────────────────────────────────────────────────────────────────────────────────────+

### Detailed Evaluation of the Technical Gap

  ------------------------------------------------------------------------------
  Proposed         Existing         Why This Matters for         Prototype
  Technical Gap    Evidence & State Rural India               Feasibility (SIH
                   of the Art                                      26038)
  ---------------- ---------------- ----------------------- --------------------
  **1. Dynamic,    Most deep        In rural PHCs,            **High.** Can be
  IQA-Gated        learning         screening is run by     implemented cleanly
  Preprocessing    pipelines assume community health          in MATLAB using
  for Low-Cost     clean, centered, workers (ASHAs or ANMs)    basic gradient
  Handheld         high-contrast    using low-cost portable       metrics
  Devices**        tabletop fundus  cameras; poor-quality      (`imfilter`),
                   captures,        images must be caught    histogram parsing,
                   failing when     and retaken immediately  and green-channel
                   applied directly at the point of care.          CLAHE
                   to blurry,                                 (`adapthisteq`).
                   low-cost                                 
                   handheld inputs.                         

  **2. Dual-Level  Existing systems Rural medical officers    **High.** Can be
  Explainability   output either an and                         achieved by
  Linking Grad-CAM uncalibrated     tele-ophthalmologists        overlaying
  with             black-box        need specific visual       morphological
  Morphological    classification   evidence (such as        top-hat candidate
  Extraction**     score or a       localized                    proposals
                   coarse, broad    microaneurysms or hard      (`imbothat`,
                   Grad-CAM         exudate margins) to        `regionprops`)
                   activation       trust automated            directly onto
                   heatmap that     referral                Grad-CAM activation
                   lacks structural recommendations.               maps.
                   detail.                                  

  **3. Integrated  Existing         Clinical effectiveness    **High.** Can be
  Discrete-Event   research papers  in rural screening is         built in
  Operational      evaluate AI      determined by           MATLAB/Simulink and
  Telemedicine     purely on static operational factors:     SimEvents to model
  Simulation**     test sets        camera queues,           multi-PHC networks
                   (reporting AUC,  transmission delays        handling over
                   sensitivity, and over slow networks, and   100,000 patients
                   specificity)     tele-ophthalmologist         annually.
                   without          review bottlenecks.     
                   assessing                                
                   real-world                               
                   clinical                                 
                   workflow                                 
                   constraints.                             
  ------------------------------------------------------------------------------

------------------------------------------------------------------------

## 10. Our System-Level Differentiation

Our system is differentiated by the integration of its diagnostic
pipeline with an operational systems simulation, linking medical image
analysis with healthcare operations engineering.

                            DIFFERENTIATION COMPARISON MATRIX
                            
    Dimension                     Current Approaches               Our System Architecture
    ──────────────────────────────────────────────────────────────────────────────────────────────
    Algorithm Structure           Single-Model Black-Box     ──►   Dual-Stream (Morphology + Deep CNN)
    Image Quality Handling        Passive / Ignored Post-Hoc ──►   Point-of-Care Edge IQA Quality Gating
    Explainability Output         Coarse Heatmap Alone       ──►   Grad-CAM + Lesion Proposals + Calibration
    Telemedicine Integration      Static Batch Upload        ──►   Network-Aware Local Buffering & Prioritization
    System-Level Validation       Isolated AUC / ROC Metrics ──►   SimEvents Operational Scale Simulation
    Toolchain Integration         Fragmented Open-Source     ──►   Unified Deterministic MATLAB/Simulink Stack
    ──────────────────────────────────────────────────────────────────────────────────────────────

### Systematic Differentiation Breakdown

  ----------------------------------------------------------------------------
  Dimension        Existing          Our Proposed         Defensibility Level
                   Approaches        Differentiation      
  ---------------- ----------------- -------------------- --------------------
  **Technical &    Standalone deep   An integrated         **High.** Grounded
  Algorithmic**    learning          pipeline that pairs     in established
                   classifiers       an EfficientNet            clinical
                   trained on        classifier with         explainability
                   uncalibrated      morphological          research; avoids
                   cross-entropy     candidate                  treating
                   loss, producing   extraction,              uncalibrated
                   unverified        supported by             heatmaps as
                   Grad-CAM          Platt-scaled         definitive clinical
                   heatmaps.         confidence                  proof.
                                     calibration and      
                                     localized lesion     
                                     bounding.            

  **Rural          Cloud-dependent   A modular edge        **High.** Directly
  Operational      enterprise        architecture             reflects the
  Deployment**     screening systems designed for offline     operational
                   or standalone     inference, featuring  realities of rural
                   desktop research  local IQA gating to     Indian Primary
                   scripts that      trigger immediate     Healthcare Centres
                   assume constant   recaptures and an    (PHCs) and Community
                   electrical power  opportunistic,        Healthcare Centres
                   and high-speed    prioritized                (CHCs).
                   broadband.        store-and-forward    
                                     telemedicine buffer. 

  **Systems        Healthcare        A dynamic               **Very High.**
  Engineering &    studies that      SimEvents/Simulink    Addresses a known
  Scale**          evaluate only     digital twin that         gap in the
                   diagnostic        simulates screening  literature; combines
                   performance on    operations across a     medical image
                   static image      20-PHC district      processing directly
                   datasets,         network, validating  with discrete-event
                   omitting queuing  throughput, doctor       operational
                   dynamics, network review capacity, and     simulation.
                   constraints, and  queuing latency for  
                   staff workload    100,000+ patients    
                   modeling.         annually.            
  ----------------------------------------------------------------------------

------------------------------------------------------------------------

## 11. Novelty Stress Test

To ensure the project's technical claims are defensible under
competitive and academic scrutiny, common novelty assertions must be
critically evaluated.

    +--------------------------------------------------------------------------------------------------+
    |                                    NOVELTY STRESS TEST                                           |
    +--------------------------------------------------------------------------------------------------+
    |  CLAIM 1: "We are the first to apply deep learning to Diabetic Retinopathy."                     |
    |  VERDICT: COMPLETELY FALSE.                                                                      |
    |  EVIDENCE: Solved at scale by Gulshan et al. (JAMA 2016), Abràmoff et al. (2016), and others.    |
    |                                                                                                  |
    |  CLAIM 2: "Our use of Grad-CAM makes our AI uniquely explainable."                               |
    |  VERDICT: MEDICALLY & TECHNICALLY INSUFFICIENT.                                                  |
    |  EVIDENCE: Hundreds of papers apply Grad-CAM to fundus images; clinicians frequently criticize   |
    |            coarse heatmaps as uninformative for subtle microaneurysm detection.                  |
    |                                                                                                  |
    |  CLAIM 3: "Our offline deployment capability is entirely novel."                                 |
    |  VERDICT: DEMONSTRABLY FALSE.                                                                    |
    |  EVIDENCE: Medios AI has run on-device inference on Remidio smartphone hardware since 2018-2020. |
    |                                                                                                  |
    |  CLAIM 4: "We combine edge IQA, multi-tier explainability, and a Simulink digital twin to        |
    |            model district-scale screening feasibility for 100,000+ patients."                    |
    |  VERDICT: HIGHLY DEFENSIBLE AND TECHNICALLY SOUND.                                               |
    |  EVIDENCE: Fills an established gap between algorithmic design and operational systems           |
    |            engineering in rural telemedicine workflows.                                          |
    +--------------------------------------------------------------------------------------------------+

------------------------------------------------------------------------

## 12. Recommended Positioning Strategy

When presenting the project to hackathon judges, academic reviewers, and
clinical stakeholders, use the following messaging guidelines to
maintain technical credibility.

### Conservative Claim (Highly Defensible)

> "We present an integrated, modular MATLAB/Simulink architecture for
> diabetic retinopathy screening designed for the operational
> constraints of rural Indian primary care. The system integrates
> automated image quality gating, adaptive enhancement, deep
> classification, and confidence calibration with a SimEvents
> discrete-event simulation that models patient queuing, intermittent
> network uplinks, and remote ophthalmologist review workflows across an
> administrative district."

### Strong but Defensible Claim (Competitive Hackathon Positioning)

> "Addressing the operational gap between medical AI algorithms and
> rural healthcare deployment, our solution pairs an edge-executable,
> multi-tier explainable screening pipeline (combining Grad-CAM heatmaps
> with morphological lesion proposals) with an operational systems
> digital twin in Simulink. The simulation directly models patient flow,
> cellular bandwidth volatility, and triage queues across a 20-PHC
> network, demonstrating operational feasibility and resource allocation
> for over 100,000 patients annually."

### Claims We Must NOT Make

-   ❌ *"We developed a completely novel AI algorithm that outperforms
    all commercial systems."* (Unsupported; commercial systems have
    undergone multi-center FDA and international clinical trials).
-   ❌ *"Our use of Grad-CAM solves the AI black-box problem in
    ophthalmology."* (Inaccurate; coarse heatmaps do not provide fine
    structural lesion verification).
-   ❌ *"No other system can screen for Diabetic Retinopathy offline."*
    (Factually incorrect; on-device edge screening has been deployed
    commercially by companies like Remidio).
-   ❌ *"Our model eliminates the need for human ophthalmologists."*
    (Medically and legally unsound; clinical guidelines require
    certified human-in-the-loop verification for diagnostic referral
    pathways).

------------------------------------------------------------------------

## 13. References

1.  **Gulshan, V., Peng, L., Coram, M., Stumpe, M. C., Wu, D.,
    Narayanaswamy, A., ... & Webster, D. R.** (2016). *Development and
    validation of a deep learning algorithm for detection of diabetic
    retinopathy in retinal fundus photographs*. JAMA, 316(22),
    2402-2410.\
    *Validates:* Foundational clinical standards for automated binary
    referable DR detection using deep convolutional neural networks.
2.  **Abràmoff, M. D., Lavin, P. T., Birch, M., Shah, N., & Folk, J.
    C.** (2018). *Pivotal trial of an autonomous AI-based diagnostic
    system for detection of diabetic retinopathy in primary care
    offices*. npj Digital Medicine, 1(1), 39.\
    *Validates:* Clinical trial methodology and performance benchmarks
    for autonomous primary-care DR screening (IDx-DR).
3.  **Rajalakshmi, R., Subashini, R., Anjana, R. M., & Mohan, V.**
    (2018). *Automated diabetic retinopathy detection in
    smartphone-based fundus photography using artificial intelligence*.
    Eye, 32(6), 1138-1144.\
    *Validates:* Point-of-care, on-device mobile DR screening on Indian
    patient cohorts using smartphone-based imaging (Remidio FOP).
4.  **Selvaraju, R. R., Cogswell, M., Das, A., Vedaldi, A., Parikh, D.,
    & Batra, D.** (2017). *Grad-CAM: Visual explanations from deep
    networks via gradient-based localization*. IEEE ICCV, 618-626.\
    *Validates:* Theoretical foundation and mathematical limitations of
    gradient-weighted class activation mapping.
5.  **Ting, D. S. W., Cheung, C. Y. L., Lim, G., Tan, G. S. W.,
    Quang, N. D., Gan, A., ... & Wong, T. Y.** (2017). *Development and
    validation of a deep learning system for diabetic retinopathy and
    related eye diseases using retinal images from multiethnic
    populations with diabetes*. JAMA, 318(22), 2211-2223.\
    *Validates:* Multi-center international validation benchmarks for
    automated retinal screening (SELENA+ platform).
6.  **Ministry of Health and Family Welfare, Government of India.**
    (2022). *Indian Public Health Standards (IPHS) Guidelines for
    Primary Health Centres*. Directorate General of Health Services.\
    *Validates:* Operational staffing, patient load parameters, and
    infrastructure constraints in rural Indian Primary Healthcare
    Centres (PHCs).
7.  **MathWorks, Inc.** (2023). *SimEvents User's Guide: Model
    Discrete-Event Systems in Healthcare and Telecommunications*.
    Natick: The MathWorks, Inc.\
    *Validates:* Discrete-event queuing, server allocation, and entity
    routing mechanics for modeling healthcare operations.
8.  **Platt, J.** (1999). *Probabilistic outputs for support vector
    machines and comparisons to regularized likelihood methods*.
    Advances in Large Margin Classifiers, 10(3), 61-74.\
    *Validates:* The mathematical formulation of Platt scaling for
    logistic probability calibration.

------------------------------------------------------------------------

# 20. Consolidation Notes

-   This file is a **union-style consolidation**, not a claim that every
    numerical value from different sources is directly comparable.
-   Where the supplied files gave different performance figures or
    different descriptions of the same system, the canonical sections
    preserve the broader interpretation and the appendix retains the
    source-specific detail.
-   "Not documented in reviewed sources" is intentionally different from
    "does not exist."
-   Manufacturer claims are not treated as equivalent to independent
    peer-reviewed validation.
-   Observed deployment scale (for example, ARDA's large patient volume)
    is not equivalent to predictive capacity simulation.
-   The 100,000+ patient/year target is a **design/simulation
    scenario**, not an achieved deployment claim.
