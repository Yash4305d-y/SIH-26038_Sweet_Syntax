# SIH 2026 — PS 26038 / PS 38
# Explainable AI for Diabetic Retinopathy Screening in Rural India
## MASTER PLAN — v4 (consolidated)

---

## 0. Project North Star

Not building: *"A diabetic retinopathy classifier."*

Building: *"A quality-gated, lesion-grounded, explainable, confidence-aware retinal
screening pipeline in MATLAB — parameterizing a Simulink digital twin that proves
whether the workflow can actually operate at district scale."*

**Core positioning line for the pitch:** *"We aren't claiming to beat FDA-cleared
accuracy; we're demonstrating a reproducible prototype that links an explainable
pipeline to an explicit operational capacity simulation for rural India."* No "first,"
no priority claims — the substance carries this without needing a superlative.

---

## 1. Time Budget (5–6 week schedule)

| Week | Focus | Owner(s) | Checkpoint |
|---|---|---|---|
| 1 | Data setup (APTOS/IDRiD/Messidor-2 downloaded, split, documented); IQA gate built; SimEvents license confirmed | Role 1, Role 2, Role 3 | Quality gate runs end-to-end on sample images |
| 2 | Preprocessing pipeline finalized (deterministic); grading model training starts; morphological candidate extraction (vessels, disc, exudates) built | Role 1, Role 2 | First (even bad) held-out grading number exists |
| 3 | Grading model tuned; referable-DR binary metric evaluated; MA/hemorrhage candidates + fovea heuristic added | Role 1, Role 2 | Referable-DR sensitivity/specificity reported honestly |
| 4 | Grad-CAM wired in; evidence correlation; binary calibration; SimEvents digital twin built and parameterized with real measured values | Role 1, Role 2, Role 3 | Grad-CAM + evidence report generating; Simulink model runs with real numbers |
| 5 | App Designer UI; 3-scenario demo wired end-to-end; Messidor-2 external eval; documentation | Role 4, Role 5/6 | Full live demo runs without manual intervention |
| 6 (if available) | Rehearsal, judge Q&A drilling, pitch deck, buffer for compute fallback issues | Everyone | Dry-run in front of a non-team member |

**If time is tighter (~2–3 weeks):** compress by cutting the ablation study, the full
quantitative Grad-CAM/lesion IoU metric (keep a handful of manual qualitative examples
instead), and reduce Simulink to one scenario (AI + quality gate) instead of three.
State these explicitly as "future work" in documentation rather than pretending they
were never planned.

---

## 2. Team Role Matrix (3–4 technical, 2–3 presentation/support)

**Technical:**

- **Role 1 — ML Architect:** owns APTOS data split, ResNet-50/EfficientNet transfer
  learning, weighted cross-entropy for class imbalance, binary referable-DR calibration.
- **Role 2 — Classical CV Engineer:** owns deterministic IQA gating (blur/exposure/FOV)
  and Morphological Candidate Extraction (vessels via `fibermetric`, optic disc via
  brightest-blob + compactness check, fovea heuristic, exudates via `imtophat`,
  MA/hemorrhage candidates via `imbothat`).
- **Role 3 — Systems/Simulink Modeler:** owns the SimEvents digital twin — queues,
  bandwidth constraints, 100k-patient/year scale-up — parameterized by *measured*
  values (processing time, IQA fail rate, referable-DR distribution) passed from
  Roles 1 & 2, not invented numbers.
- **Role 4 — UI & Integration Engineer:** owns the MATLAB App Designer interface, wires
  Role 1–3's MATLAB outputs into the 3-scenario demo UI, formats the PDF/structured
  report. *(Pure MATLAB throughout — no Python bridge in the integrated pipeline.)*

**Presentation / support (2–3 members):**

- **Documentation & dataset provenance:** writes up the final report, tracks which
  numbers are measured vs. assumed vs. sourced, documents the Messidor-2 label-source
  caveat and the APTOS split methodology so the technical team doesn't have to context-
  switch out of building.
- **Pitch deck & demo narrative:** owns the pitch deck, the run-of-show script for the
  3-scenario demo, and drills the anti-hallucination guardrails (§7) with the whole team
  before judging.
- *(If a 3rd support member exists: competitor/gap analysis, and rehearsing judge Q&A
  as a "hostile judge" role-play before the real thing.)*

---

## 3. What PS 38 requires (everything must map to one of these five)

1. Image Quality Assessment & Enhancement
2. Retinal Structure / Lesion Analysis
3. DR Severity Grading (0–4, plus referable-DR binary)
4. Explainability (Grad-CAM + evidence + confidence)
5. Simulink Workflow Simulation (district-scale throughput)

---

## 4. Dataset Strategy

- **APTOS 2019 — primary grading dataset** (~3,662 images, 5-class, imbalanced —
  handle with weighted loss). **Note:** the public Kaggle test set has no released
  labels; carve your own train/val/test split (e.g. 70/15/15) from the labeled
  training set — don't look for labeled Kaggle test data, it doesn't exist.
- **IDRiD — lesion/structure ground truth + Indian-demographic fine-tuning pass.**
  516 images with image-level DR/DME grading, 81 with pixel-level lesion masks
  (microaneurysm, hard exudate, soft exudate, hemorrhage) plus optic disc/fovea
  coordinates. Too small to train a 5-class CNN from scratch on alone — use it for
  lesion evaluation ground truth and a final fine-tuning pass on the APTOS-trained model.
- **Messidor-2 — external generalization test only, never trained on.** **Document
  your label source explicitly**: the original Messidor-2 release did not ship with
  adjudicated DR grades; commonly used labels come from a separate community regrading
  effort. State exactly which label file you used and that it's a secondary source —
  this preempts a sharp provenance question.
- **Patient-level leakage control:** meaningful for IDRiD/Messidor-2 if patient IDs are
  available; APTOS's public data has no patient identifiers, so don't claim this
  control was enforced there.

---

## 5. Master Pipeline Architecture

```
                FUNDUS IMAGE
                     |
                     v
          +----------------------+
          | IMAGE QUALITY GATE   |  (deterministic: focus, illumination, FOV)
          +----------+-----------+
                     |
          +----------+----------+
          |                     |
        FAIL                   PASS
          |                     |
          v                     v
   RECAPTURE GUIDANCE      DETERMINISTIC PREPROCESSING
   (specific reason)       (CLAHE/denoise — applied to
                             every passing image, uniformly)
                                |
                    +-----------+-----------+
                    |                       |
                    v                       v
       MORPHOLOGICAL CANDIDATE       DR GRADING CNN
       EXTRACTION                    (transfer learning)
       (vessels, disc, fovea,               |
        exudates, MA/hemorrhage)            v
                    |                  Grad-CAM
                    |                       |
                    +----------+------------+
                               |
                               v
                     EVIDENCE CORRELATION
                     (attention regions vs. candidates)
                               |
                               v
                CALIBRATED CONFIDENCE (binary referable-DR)
                               |
                               v
                   REFERRAL PRIORITIZATION
                               |
                               v
                STRUCTURED SCREENING REPORT
                               |
                               v
                     HUMAN REVIEW (<30s)

                 |  measured tic/toc time,
                 |  measured IQA fail rate,
                 v  measured referable-DR distribution
        SIMULINK / SIMEVENTS DIGITAL TWIN
        (arrivals -> AI service -> review queue ->
         ophthalmologist capacity -> outcome/backlog)
```

**Digital twin framing (use this exact language with judges):** the Simulink model is
not a separate flowchart — it's parameterized directly by values measured from the
running MATLAB pipeline: `tic`/`toc` processing time, measured quality-gate fail rate,
measured referable-DR distribution feed straight into the SimEvents blocks.

---

## 6. Component Build Details

### 6.1 Image Quality Assessment (deterministic gate)
Laplacian-variance focus score, histogram-based illumination/exposure check, FOV check
via thresholding/circular boundary estimation. Output: `quality_score`,
`quality_status`, `failure_reason` (e.g. "Severe blur detected" → "Recapture with
camera stabilized"). Calibrate thresholds against real examples, don't guess.

### 6.2 Preprocessing — must be deterministic and uniform
Whatever wins your raw-vs-preprocessed experiment (CLAHE on green channel + denoising is
the standard baseline) gets applied to **every image that passes the quality gate**, no
exceptions for "borderline only." Conditional preprocessing creates a train/test domain
shift the CNN will latch onto instead of the pathology — this was the single most
important correction from the last review round.

### 6.3 Morphological Candidate Extraction (not "segmentation")
- **Vessels:** `fibermetric` (Frangi-style vesselness) — explainable, fast, MATLAB-native.
- **Optic disc:** Gaussian blur → threshold top ~1% brightest pixels → largest blob
  centroid, with a compactness check (area/perimeter² near circular) as a tiebreaker so
  a large bright exudate region in severe cases isn't mistaken for the disc. Skip
  `imfindcircles`/Hough tuning — not worth the time.
- **Fovea:** cheap geometric heuristic — darkest local region ~2.5 optic-disc-diameters
  temporal to the disc center, along the horizontal meridian. ~30 minutes of work; keep
  it, it's explicitly named in the PS.
- **Exudates (bright lesions):** `imtophat`.
- **Microaneurysms / hemorrhages (dark lesions):** `imbothat`, candidate-level only —
  document this as candidate detection, not clinical-grade confirmed lesions.
- **Neovascularization:** dropped from MVP scope entirely — a genuinely unsolved problem
  from 2D fundus photos alone; not worth the time for the judge-reward it offers.

### 6.4 DR Grading Model
Transfer learning (ResNet-50 or EfficientNet via `imagePretrainedNetwork`), fine-tuned
on APTOS then IDRiD, weighted cross-entropy for class imbalance, 5-class output (0–4)
plus a separate **referable-DR binary metric** (Level 2+, per the PS's own definition —
document it as PS-defined, not team-chosen). Report real measured sensitivity/
specificity — target >90%/>85%, but state actual numbers honestly if you land under.

### 6.5 Explainability
- **Grad-CAM** via MATLAB's built-in `gradCAM` function.
- **Evidence correlation:** cross-reference high-attention regions against 6.3's
  candidate detections ("attention overlaps 3 MA candidates and 1 hemorrhage region").
  Evaluate this at region-level, not pixel-perfect IoU — Grad-CAM's spatial resolution
  is coarse relative to fine lesion masks, and a literal pixel IoU will read
  artificially low. If you do report a number, caveat the resolution mismatch.
- **Confidence:** derive from softmax entropy or MC-dropout variance, bucketed
  High/Medium/Low/Insufficient. **Focus calibration effort on the binary referable-DR
  decision** — 5-class calibration will be statistically noisy given how few severe/PDR
  examples exist in any held-out split, and referable-DR is what the PS actually sets a
  target against anyway.
- **Language discipline:** never say "Grad-CAM proves the model saw the lesion" — say
  "Grad-CAM spatial attention broadly correlates with our morphological lesion
  candidates."

### 6.6 Simulink / SimEvents Digital Twin
- Confirm SimEvents license availability in **week 1**, not week 5 — if unavailable,
  fall back to a simpler rate/queue-length Simulink model, decided early.
- Recapture/retry loop: use SimEvents alone (`Entity Output Switch` + a retry-count
  entity attribute) — skip Stateflow, one less tool to integrate under time pressure.
- Parameterize with measured values (see §5's digital-twin framing).
- Given the time budget, prioritize **one fully-finished scenario** (AI + quality gate +
  priority review) over three half-finished ones; add the manual-baseline and
  AI-only-no-gate comparisons only if time remains.
- District-scale (100k+/year) parameters: state population, screening frequency, and
  reviewer count explicitly as assumptions — never imply they're real district data.

### 6.7 Demo Interface
MATLAB App Designer for the upload-image → view-report demo UI — native, fast to build,
keeps everything in one environment instead of reintroducing a web stack under
demo-prep pressure.

---

## 7. The Final Demo Run-of-Show (3 scenarios)

Live-demo three specific cases through the App Designer UI — not a batch script.

- **Case 1 — The Happy Path:** clear fundus image → IQA passes → CLAHE applied
  (deterministically) → CNN predicts Grade 3 → Grad-CAM overlaps morphological exudate
  candidates → high-confidence structured report generated.
- **Case 2 — The Safety Gate:** blurry, off-center image → IQA fails (Laplacian
  variance too low) → processing halts before reaching the CNN → UI displays "Recapture
  Required: Poor Focus." Proves the system won't silently hallucinate on bad input.
- **Case 3 — Human-in-the-Loop, then the Simulink Pivot:** ambiguous image → CNN
  outputs high entropy/split probabilities → system flags "Low Confidence: Force Human
  Review" → **immediately pivot into the Simulink model**: "When cases like this get
  flagged, here's how our district-scale queue absorbs the backlog without overloading
  the available ophthalmologists."

This gives the demo a clear beginning (input handling), middle (AI + explainability),
and end (system-scale proof) instead of stopping at the classifier.

---

## 8. Pitch Guardrails — Judge Q&A Survival

**If asked "why not just use an FDA-cleared system like IDx-DR?":**
*"FDA-cleared systems are excellent for controlled clinical settings. Our contribution
is an open-architecture prototype designed specifically to simulate rural operational
failure modes — intermittent bandwidth, high ungradable/recapture rates, ophthalmologist
shortages — using an explicit Simulink digital twin."*

**If asked "why not just use GPT/Gemini/Claude on the image?":**
*"General-purpose multimodal models can give a plausible-sounding interpretation, but
we're not evaluated on how convincing a generated response sounds — we're evaluated
against medical-image ground truth, with explicit quality gating, lesion-level
evidence, calibrated uncertainty, and a measurable system-throughput model. That's not
something a general chat model produces."*

**Do NOT say:**
- *"We are the first offline DR AI."* — false; Medios AI (Remidio) already holds this
  position, documented in peer-reviewed literature (Indian Journal of Ophthalmology,
  2020) as, to the researchers' knowledge, the first offline DR-screening software
  integrated with a smartphone-based fundus camera. Verified via search — don't contest
  this one if a judge raises it.
- *"Grad-CAM proves the model saw the microaneurysm."* — say instead: *"Grad-CAM
  spatial attention broadly correlates with our morphological lesion candidates."*
- *"This is clinically diagnostic-ready."* — say instead: *"This is a research-grade
  triage prototype validated on public benchmarks."*
- Any "first end-to-end..." priority claim — drop the superlative, keep the substance
  (§0's positioning line already does this correctly).

---

## 9. Compute Fallback Protocol

If GPU memory limits cause OOM errors during training or integrated inference:

1. Downgrade backbone immediately — ResNet-50 → MobileNet-v2 or ResNet-18.
2. Reduce image input resolution to strictly 224×224.
3. Drop batch size to 8 or 16.

Decide and rehearse this fallback *before* it's needed, not mid-demo.

---

## 10. Evaluation Framework

- **Level 1 — Image quality:** blur/illumination/FOV accept-reject performance against
  a small manually-labeled benchmark (document who labeled it).
- **Level 2 — Lesion/structure:** Dice/IoU per lesion type against IDRiD masks (region-
  level for Grad-CAM correlation specifically, per §6.5's resolution caveat).
- **Level 3 — DR grading:** accuracy, macro F1, quadratic weighted kappa, confusion
  matrix, and separately, referable-DR sensitivity/specificity/AUC.
- **Level 4 — System:** measured processing time, throughput, queue wait time, reviewer
  utilization from the SimEvents model.
- **Cross-dataset generalization (Messidor-2):** report referable-DR sensitivity/
  specificity/AUC on this held-out external set with the label-provenance caveat noted.
- **Baselines & ablation:** simple CNN vs. transfer learning vs. final model — full
  ablation study (raw vs. preprocessed, Grad-CAM-only vs. +evidence) is "if time
  remains," not a committed deliverable given the time budget in §1.

---

## 11. Documentation Checklist

1. Problem statement, in your own words
2. Dataset strategy with explicit split methodology and Messidor-2/APTOS caveats
3. Quality assessment & preprocessing methodology
4. Candidate extraction methodology per structure
5. Grading model architecture, training procedure, class-imbalance handling
6. Explainability methodology (Grad-CAM + evidence correlation + confidence)
7. Simulink digital-twin design and stated measured/assumed/sourced parameters
8. Results — grading metrics, candidate-extraction quality, cross-dataset results
9. Honest limitations (candidate-level lesion detection, no neovascularization,
   research-grade only, simulation assumptions)
10. Future work (full ablation study, additional scenarios, real clinical validation)

---

## 12. Final Success Checklist

- [ ] Every feature maps to one of the five PS requirements
- [ ] Pipeline runs natively in MATLAB/Simulink, not a ported Python prototype
- [ ] Preprocessing is deterministic and uniform for every image reaching the CNN
- [ ] Reported metrics are real, measured — not invented
- [ ] Referable-DR binary metric reported separately from 5-class accuracy
- [ ] Genuine cross-dataset (Messidor-2) result exists, with label source documented
- [ ] Grad-CAM evidence correlation uses region-level comparison, resolution caveat stated
- [ ] Confidence calibration focused on the binary referable-DR decision
- [ ] SimEvents model is explicitly parameterized by measured pipeline values
- [ ] All three demo scenarios (happy path, safety gate, human-in-loop → Simulink pivot)
      run live, not as a batch script
- [ ] Compute fallback protocol rehearsed before the event
- [ ] Every team member has drilled the anti-hallucination guardrails in §8
- [ ] Limitations stated honestly, not glossed over
