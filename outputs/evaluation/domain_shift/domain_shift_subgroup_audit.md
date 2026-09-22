# Domain Shift Subgroup Audit Report

## APTOS TEST AUDIT

### PART 1 — EXACT DOMAIN-STATUS COUNTS
- WITHIN_REFERENCE: 410
- POTENTIAL_SHIFT: 21
- HIGH_MISMATCH: 8
- TOTAL FLAGGED (POTENTIAL_SHIFT + HIGH_MISMATCH): 29

### PART 2 — TRUE GRADE COMPOSITION
| Domain Status | n | G0 | G1 | G2 | G3 | G4 |
|---|---|---|---|---|---|---|
| WITHIN_REFERENCE | 410 | 189 (46.1%) | 44 (10.7%) | 119 (29.0%) | 23 (5.6%) | 35 (8.5%) |
| POTENTIAL_SHIFT | 21 | 19 (90.5%) | 0 (0.0%) | 2 (9.5%) | 0 (0.0%) | 0 (0.0%) |
| HIGH_MISMATCH | 8 | 7 (87.5%) | 1 (12.5%) | 0 (0.0%) | 0 (0.0%) | 0 (0.0%) |
| FLAGGED | 29 | 26 (89.7%) | 1 (3.4%) | 2 (6.9%) | 0 (0.0%) | 0 (0.0%) |

### PART 3 — PREDICTED GRADE COMPOSITION
| Domain Status | n | Pred G0 | Pred G1 | Pred G2 | Pred G3 | Pred G4 |
|---|---|---|---|---|---|---|
| WITHIN_REFERENCE | 410 | 192 | 27 | 167 | 9 | 15 |
| POTENTIAL_SHIFT | 21 | 20 | 0 | 1 | 0 | 0 |
| HIGH_MISMATCH | 8 | 7 | 1 | 0 | 0 | 0 |
| FLAGGED | 29 | 27 | 1 | 1 | 0 | 0 |

### PART 4 — CONFUSION MATRICES (Rows: True 0-4, Cols: Pred 0-4)

#### WITHIN_REFERENCE
```text
 185    3    1    0    0 
   4   21   18    0    1 
   3    2  113    0    1 
   0    1   14    6    2 
   0    0   21    3   11 
```

#### POTENTIAL_SHIFT
```text
  19    0    0    0    0 
   0    0    0    0    0 
   1    0    1    0    0 
   0    0    0    0    0 
   0    0    0    0    0 
```

#### HIGH_MISMATCH
```text
   7    0    0    0    0 
   0    1    0    0    0 
   0    0    0    0    0 
   0    0    0    0    0 
   0    0    0    0    0 
```

#### FLAGGED
```text
  26    0    0    0    0 
   0    1    0    0    0 
   1    0    1    0    0 
   0    0    0    0    0 
   0    0    0    0    0 
```

### PART 5 — REFERABLE COMPOSITION
| Domain Status | True Ref | True Non-Ref | Pred Ref | Pred Non-Ref | False Pos | False Neg | Ref Error Rate |
|---|---|---|---|---|---|---|---|
| WITHIN_REFERENCE | 177 | 233 | 203 | 207 | 28 | 2 | 0.073 |
| POTENTIAL_SHIFT | 2 | 19 | 2 | 19 | 0 | 0 | 0.000 |
| HIGH_MISMATCH | 0 | 8 | 0 | 8 | 0 | 0 | 0.000 |
| FLAGGED | 2 | 27 | 2 | 27 | 0 | 0 | 0.000 |

### PART 6 — DISTANCE BY TRUE GRADE
| True Grade | n | Mean Dist | Median Dist | Std Dev | 95th Pct |
|---|---|---|---|---|---|
| 0 | 215 | 191.84 | 181.47 | 42.13 | 272.00 |
| 1 | 45 | 136.78 | 142.16 | 48.67 | 202.55 |
| 2 | 121 | 149.55 | 147.09 | 32.78 | 207.07 |
| 3 | 23 | 147.99 | 161.93 | 48.28 | 200.70 |
| 4 | 35 | 145.62 | 151.26 | 44.33 | 199.68 |

### PART 7 — DISTANCE BY CORRECTNESS
| Prediction | n | Mean Dist | Median Dist | Std Dev | 25th Pct | 75th Pct |
|---|---|---|---|---|---|---|
| CORRECT | 364 | 172.19 | 166.68 | 47.41 | 144.29 | 196.05 |
| INCORRECT | 75 | 150.89 | 150.03 | 40.40 | 137.70 | 173.13 |

### PART 8 — ERROR RATE CONFIDENCE INTERVALS (Wilson 95%)
| Domain Status | n | 5-Class Error | 95% CI | Ref Error | 95% CI |
|---|---|---|---|---|---|
| WITHIN_REFERENCE | 410 | 0.180 | [0.146, 0.221] | 0.073 | [0.052, 0.103] |
| POTENTIAL_SHIFT | 21 | 0.048 | [0.008, 0.227] | 0.000 | [0.000, 0.155] |
| HIGH_MISMATCH | 8 | 0.000 | [0.000, 0.324] | 0.000 | [0.000, 0.324] |
| FLAGGED | 29 | 0.034 | [0.006, 0.172] | 0.000 | [0.000, 0.117] |

## MESSIDOR-2 AUDIT

### PART 1 — EXACT DOMAIN-STATUS COUNTS
- WITHIN_REFERENCE: 1463
- POTENTIAL_SHIFT: 201
- HIGH_MISMATCH: 80
- TOTAL FLAGGED (POTENTIAL_SHIFT + HIGH_MISMATCH): 281

### PART 2 — TRUE GRADE COMPOSITION
| Domain Status | n | G0 | G1 | G2 | G3 | G4 |
|---|---|---|---|---|---|---|
| WITHIN_REFERENCE | 1463 | 828 (56.6%) | 221 (15.1%) | 308 (21.1%) | 72 (4.9%) | 34 (2.3%) |
| POTENTIAL_SHIFT | 201 | 142 (70.6%) | 31 (15.4%) | 25 (12.4%) | 2 (1.0%) | 1 (0.5%) |
| HIGH_MISMATCH | 80 | 47 (58.8%) | 18 (22.5%) | 14 (17.5%) | 1 (1.2%) | 0 (0.0%) |
| FLAGGED | 281 | 189 (67.3%) | 49 (17.4%) | 39 (13.9%) | 3 (1.1%) | 1 (0.4%) |

### PART 3 — PREDICTED GRADE COMPOSITION
| Domain Status | n | Pred G0 | Pred G1 | Pred G2 | Pred G3 | Pred G4 |
|---|---|---|---|---|---|---|
| WITHIN_REFERENCE | 1463 | 1318 | 5 | 130 | 3 | 7 |
| POTENTIAL_SHIFT | 201 | 194 | 0 | 3 | 1 | 3 |
| HIGH_MISMATCH | 80 | 79 | 0 | 1 | 0 | 0 |
| FLAGGED | 281 | 273 | 0 | 4 | 1 | 3 |

### PART 4 — CONFUSION MATRICES (Rows: True 0-4, Cols: Pred 0-4)

#### WITHIN_REFERENCE
```text
 808    0   18    0    2 
 220    0    1    0    0 
 260    4   44    0    0 
  16    1   52    3    0 
  14    0   15    0    5 
```

#### POTENTIAL_SHIFT
```text
 138    0    2    0    2 
  31    0    0    0    0 
  23    0    1    1    0 
   2    0    0    0    0 
   0    0    0    0    1 
```

#### HIGH_MISMATCH
```text
  46    0    1    0    0 
  18    0    0    0    0 
  14    0    0    0    0 
   1    0    0    0    0 
   0    0    0    0    0 
```

#### FLAGGED
```text
 184    0    3    0    2 
  49    0    0    0    0 
  37    0    1    1    0 
   3    0    0    0    0 
   0    0    0    0    1 
```

### PART 5 — REFERABLE COMPOSITION
| Domain Status | True Ref | True Non-Ref | Pred Ref | Pred Non-Ref | False Pos | False Neg | Ref Error Rate |
|---|---|---|---|---|---|---|---|
| WITHIN_REFERENCE | 414 | 1049 | 163 | 1300 | 32 | 283 | 0.215 |
| POTENTIAL_SHIFT | 28 | 173 | 7 | 194 | 4 | 25 | 0.144 |
| HIGH_MISMATCH | 15 | 65 | 2 | 78 | 2 | 15 | 0.212 |
| FLAGGED | 43 | 238 | 9 | 272 | 6 | 40 | 0.164 |

### PART 6 — DISTANCE BY TRUE GRADE
| True Grade | n | Mean Dist | Median Dist | Std Dev | 95th Pct |
|---|---|---|---|---|---|
| 0 | 1017 | 212.21 | 205.76 | 36.19 | 276.38 |
| 1 | 270 | 211.92 | 205.37 | 40.04 | 291.53 |
| 2 | 347 | 202.33 | 196.66 | 34.46 | 272.79 |
| 3 | 75 | 195.95 | 192.93 | 26.96 | 240.43 |
| 4 | 35 | 205.22 | 208.20 | 23.62 | 241.60 |

### PART 7 — DISTANCE BY CORRECTNESS
| Prediction | n | Mean Dist | Median Dist | Std Dev | 25th Pct | 75th Pct |
|---|---|---|---|---|---|---|
| CORRECT | 1046 | 210.72 | 204.48 | 36.36 | 184.95 | 231.81 |
| INCORRECT | 698 | 207.32 | 203.29 | 35.94 | 181.87 | 224.35 |

### PART 8 — ERROR RATE CONFIDENCE INTERVALS (Wilson 95%)
| Domain Status | n | 5-Class Error | 95% CI | Ref Error | 95% CI |
|---|---|---|---|---|---|
| WITHIN_REFERENCE | 1463 | 0.412 | [0.387, 0.438] | 0.215 | [0.195, 0.237] |
| POTENTIAL_SHIFT | 201 | 0.303 | [0.244, 0.370] | 0.144 | [0.102, 0.200] |
| HIGH_MISMATCH | 80 | 0.425 | [0.323, 0.534] | 0.212 | [0.137, 0.314] |
| FLAGGED | 281 | 0.338 | [0.285, 0.395] | 0.164 | [0.125, 0.211] |

## PART 9 — DETERMINE WHAT EXPLAINS THE 3.4% RESULT
Based strictly on the numbers (see APTOS TEST tables), the flagged groups are extremely small (n=29 total flagged vs n=410 within reference) and heavily skewed toward specific grades that the model may naturally classify more accurately (e.g. grade 0). Wide confidence intervals (e.g. Wilson CI for the flagged error rate) indicate that the 3.4% error rate is statistically uncertain due to the tiny subgroup size. Thus, the observed inverse relationship is primarily explained by sample size artifacts and unequal class composition in the extremely small flagged subgroups, rather than flagged images being inherently easier to predict in a generalizable way.

