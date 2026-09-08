# ML-Simulink Handoff

This document defines the interface parameters that must be consumed by the Simulink/telemedicine workflow from the ML pipeline.

## Telemedicine Workflow Parameters

The ML component exposes the following parameters for the Simulink integration:

- **processing status:** Boolean/enum indicating if the ML pipeline successfully processed the image (e.g., SUCCESS, FAILED_OOM, FAILED_CORRUPT).
- **predicted DR grade:** Integer from 0 to 4 representing the 5-class severity classification.
- **referable/non-referable status:** Binary decision output (Referable or Non-referable).
- **calibrated referable probability:** Float [0.0 - 1.0] representing the probability of referable DR after Platt scaling.
- **confidence/uncertainty:** Measure of the model's predictive confidence.
- **quality-gate status:** Boolean/enum indicating the upstream image quality acceptance decision.
- **processing-time measurement:** Not yet measured — must be supplied by the integrated implementation.
- **failure/rejection status:** Descriptive error string or code if the image is rejected at any stage of the pipeline.
