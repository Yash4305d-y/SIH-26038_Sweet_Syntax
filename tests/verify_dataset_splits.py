"""
Automated Dataset Split & Isolation Verification Suite
Member 3 — Dataset + Image Processing + Evaluation Lead

Verifies:
1. Zero contamination/leakage in APTOS train_split.csv, val_split.csv, test_split.csv.
2. Zero leakage between calibration_fit (40) and heldout_validation (41) in IDRiD.
3. Frozen external validation status of Messidor-2 dataset metadata.
"""

import os
import unittest
import pandas as pd

class TestDatasetSplits(unittest.TestCase):
    
    def setUp(self):
        self.root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        self.splits_dir = os.path.join(self.root_dir, "data", "splits")
        self.metadata_dir = os.path.join(self.root_dir, "data", "metadata")
        
    def test_aptos_split_isolation(self):
        train_file = os.path.join(self.splits_dir, "train_split.csv")
        val_file = os.path.join(self.splits_dir, "val_split.csv")
        test_file = os.path.join(self.splits_dir, "test_split.csv")
        
        self.assertTrue(os.path.exists(train_file), f"Missing {train_file}")
        self.assertTrue(os.path.exists(val_file), f"Missing {val_file}")
        self.assertTrue(os.path.exists(test_file), f"Missing {test_file}")
        
        df_tr = pd.read_csv(train_file)
        df_val = pd.read_csv(val_file)
        df_test = pd.read_csv(test_file)
        
        set_tr = set(df_tr["id_code"])
        set_val = set(df_val["id_code"])
        set_test = set(df_test["id_code"])
        
        self.assertEqual(len(df_tr), 2051, "APTOS train split must be 2051")
        self.assertEqual(len(df_val), 440, "APTOS val split must be 440")
        self.assertEqual(len(df_test), 439, "APTOS test split must be 439")
        
        overlap_tr_val = set_tr & set_val
        overlap_tr_test = set_tr & set_test
        overlap_val_test = set_val & set_test
        
        self.assertEqual(len(overlap_tr_val), 0, f"Leakage between train and val: {overlap_tr_val}")
        self.assertEqual(len(overlap_tr_test), 0, f"Leakage between train and locked test: {overlap_tr_test}")
        self.assertEqual(len(overlap_val_test), 0, f"Leakage between val and locked test: {overlap_val_test}")
        
        print("[SUCCESS] APTOS locked test set isolation verified: 0 leakage across 2051/440/439 splits.")

    def test_idrid_splits(self):
        idrid_file = os.path.join(self.splits_dir, "idrid_splits.csv")
        self.assertTrue(os.path.exists(idrid_file), f"Missing {idrid_file}")
        
        df = pd.read_csv(idrid_file)
        fit_set = set(df[df["split"] == "calibration_fit"]["image_id"])
        heldout_set = set(df[df["split"] == "heldout_validation"]["image_id"])
        
        self.assertEqual(len(fit_set), 40, f"Expected 40 calibration-fit images, found {len(fit_set)}")
        self.assertEqual(len(heldout_set), 41, f"Expected 41 held-out images, found {len(heldout_set)}")
        
        overlap = fit_set & heldout_set
        self.assertEqual(len(overlap), 0, f"Overlap in IDRiD splits: {overlap}")
        print("[SUCCESS] IDRiD splits verified: 40 calibration-fit, 41 held-out validation, 0 overlap.")
        
    def test_messidor_freeze_status(self):
        messidor_file = os.path.join(self.metadata_dir, "messidor_data.csv")
        self.assertTrue(os.path.exists(messidor_file), f"Missing {messidor_file}")
        
        df = pd.read_csv(messidor_file)
        self.assertEqual(len(df), 1744, f"Expected 1744 Messidor-2 records, found {len(df)}")
        print("[SUCCESS] Messidor-2 dataset confirmed as frozen external validation (1744 images).")

if __name__ == "__main__":
    unittest.main()
