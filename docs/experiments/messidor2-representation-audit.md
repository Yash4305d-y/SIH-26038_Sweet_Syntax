# Messidor-2 Representation Audit

## 1. Objective
Determine whether the poor Messidor-2 external performance could be explained by an image-representation/preprocessing mismatch between the locked baseline APTOS test inputs and the provided Messidor-2 images.

## 2. Dataset locations
- **APTOS Test Images:** `D:\SIH-26038\data\raw\test_images`
- **Messidor-2 Images:** `D:\SIH-26038\messidor-2\preprocess`

## 3. APTOS test preprocessing convention
The locked baseline uses `imageDatastore`, followed by `augmentedImageDatastore([224 224], imds)` and `minibatchpredict(net, augimds)`. No external manual resizing or cropping is applied during baseline evaluation.

## 4. Messidor-2 input representation
The Messidor-2 preprocess directory has undocumented upstream processing, so exact equivalence to the original Messidor-2 image representation cannot be established from this audit alone.

## 5. Dataset counts
- **Messidor-2 CSV rows:** 1744
- **Messidor-2 Matched images:** 1744
- **Messidor-2 Missing references:** 0
- **Messidor-2 Duplicate references:** 0
- **Messidor-2 Unmatched files:** 0
- **APTOS Test CSV rows:** 439
- **APTOS Test Matched images:** 439

## 6. Dimension statistics
| Metric | APTOS Test | Messidor-2 |
|---|---|---|
| Mean Width | 2024.69 | 512.00 |
| Mean Height | 1539.42 | 512.00 |
| Min Width | 640 | 512 |
| Min Height | 480 | 512 |
| Max Width | 4288 | 512 |
| Max Height | 2848 | 512 |

## 7. Aspect-ratio statistics
| Metric | APTOS Test | Messidor-2 |
|---|---|---|
| Mean | 1.276 | 1.000 |
| Std | 0.189 | 0.000 |
| Min | 1.000 | 1.000 |
| Max | 1.506 | 1.000 |

## 8. Pixel statistics
| Metric | APTOS Test | Messidor-2 |
|---|---|---|
| Mean Pixel Value | 61.59 | 63.25 |
| Std Pixel Value | 56.50 | 61.97 |

## 9. RGB/channel statistics
| Metric | APTOS Test | Messidor-2 |
|---|---|---|
| Mean R | 108.29 | 116.71 |
| Mean G | 57.46 | 54.36 |
| Mean B | 19.01 | 18.68 |

## 10. Dark-border statistics
| Metric | APTOS Test | Messidor-2 |
|---|---|---|
| Mean Fraction | 0.237 | 0.259 |
| Std Fraction | 0.123 | 0.006 |

## 11. Content fill-ratio statistics
| Metric | APTOS Test | Messidor-2 |
|---|---|---|
| Mean Fill | 0.905 | 0.942 |
| Std Fill | 0.118 | 0.007 |

## 12. APTOS vs Messidor-2 comparison
The quantitative differences are presented in the tables above and visualized in the attached distribution plots.

## 13. Representative image observations
A montage (`representation_montage.png`) comparing representative images from both distributions based on fill ratio has been generated.

## 14. Outlier observations
Images with unusually large dark borders, low content fill ratio, or extreme aspect ratios have been identified and saved to `messidor2_representation_outliers.csv`.

## 15. Whether an obvious representation mismatch was detected
Based on the statistics computed above, an input-representation difference was observed. No obvious gross representation mismatch was detected; therefore the observed performance degradation is more consistent with domain shift, although undocumented upstream preprocessing remains a limitation.

## 16. Limitations
The heuristic used for border/content estimation relies on a simple threshold and may not precisely reflect the true physiological retinal field border in every instance. The exact preprocessing history of Messidor-2 is undocumented.

## 17. Recommended next step
Investigate potential domain shifts (e.g., population characteristics, camera hardware, or label definitions) if the representation mismatch does not adequately explain the performance degradation.
