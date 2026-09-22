# Domain Shift Validation Report

## 1. Feature Selection
The `avg_pool` layer was selected because it provides a compact 2048-dimensional representation immediately before classification. It is computation and storage efficient.

## 2. APTOS Reference Distribution
Constructed strictly from the APTOS TRAIN split. We calculated the mean and a regularized covariance with diagonal ridge stabilization to avoid instability.

## 3. Threshold Selection
Thresholds were chosen strictly using the APTOS VALIDATION split. We set `POTENTIAL_SHIFT` at the 95th percentile and `HIGH_MISMATCH` at the 99th percentile.

## 4. External Domain Evaluation
Thresholds were fixed and applied to APTOS Test, IDRiD, and Messidor-2.

## 5. Domain Mismatch and Model Reliability
Domain distance was treated as a continuous variable and modeled against 5-class prediction error using logistic regression. We also compared categorical error rates (WITHIN_REFERENCE vs flagged).

## 6. Conclusions
We distinguish between:
1. **Representation distribution mismatch**: Flagged by this system.
2. **Model prediction error**: Measured via ground truth.
3. **Calibrated Referable Probability**: The clinical output scalar.
4. **Clinical correctness**: Ground truth diagnostic validity.

- Domain distance is not a probability that the prediction is wrong.
- Domain status does not automatically alter the DR prediction.
- Referable Probability is not domain confidence.
- The detector is not clinically validated.
- Dataset-level domain differences do not prove individual prediction failure.
- Statistical association does not prove causation.
- APTOS, IDRiD, and Messidor-2 are not equivalent to representative Indian field deployment data.

## Final Evidence Classification
B: Representation mismatch is detectable, but evidence is mixed/insufficient to uniformly establish that it predicts model reliability across all sets.
