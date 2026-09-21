"""
IDRiD Split Generator for Sprint 1
Member 3 — Dataset + Image Processing + Evaluation Lead

Splits the IDRiD 81 annotated images dataset into:
- Calibration-Fit subset: 40 images
- Held-Out Validation subset: 41 images
"""

import os
import pandas as pd
import numpy as np

def generate_idrid_splits():
    data_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..", "data", "splits")
    os.makedirs(data_dir, exist_ok=True)
    out_file = os.path.join(data_dir, "idrid_splits.csv")
    
    # IDRiD 81 annotated image IDs (IDRiD_01 to IDRiD_81)
    np.random.seed(42)  # Deterministic seed for reproducibility
    image_ids = [f"IDRiD_{i:02d}" for i in range(1, 82)]
    
    # Stratified/random allocation into 40 fit and 41 held-out
    shuffled_ids = image_ids.copy()
    np.random.shuffle(shuffled_ids)
    
    fit_set = set(shuffled_ids[:40])
    heldout_set = set(shuffled_ids[40:])
    
    records = []
    for img_id in image_ids:
        split_name = "calibration_fit" if img_id in fit_set else "heldout_validation"
        records.append({"image_id": img_id, "split": split_name})
        
    df = pd.DataFrame(records)
    df.to_csv(out_file, index=False)
    print(f"[SUCCESS] Wrote IDRiD splits to {out_file}")
    print(f"Calibration-fit count: {len(fit_set)}, Held-out count: {len(heldout_set)}")
    
if __name__ == "__main__":
    generate_idrid_splits()
