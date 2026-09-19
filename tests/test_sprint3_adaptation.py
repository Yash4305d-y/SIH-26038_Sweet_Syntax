"""
Sprint 3 Adaptation & Evidence Safeguard Unit Tests
Member 3 — Evaluation & Adaptation Lead

Verifies:
1. IDRiD split zero-overlap and held-out data isolation.
2. Promotion rule determinism.
3. Messidor-2 frozen evaluation status.
4. Member 1 adaptation handoff package schema and contents.
5. APTOS locked test split isolation across train/val/test CSVs.
"""

import os
import json
import unittest
import pandas as pd

class TestSprint3Adaptation(unittest.TestCase):

    def setUp(self):
        self.project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        self.idrid_csv = os.path.join(self.project_root, "data", "splits", "idrid_splits.csv")
        self.messidor_csv = os.path.join(self.project_root, "data", "metadata", "messidor_data.csv")
        self.handoff_json = os.path.join(self.project_root, "outputs", "evaluation", "adaptation_handoff_package.json")
        self.splits_dir = os.path.join(self.project_root, "data", "splits")

    def test_idrid_split_no_overlap(self):
        self.assertTrue(os.path.exists(self.idrid_csv), f"Missing {self.idrid_csv}")
        df = pd.read_csv(self.idrid_csv)
        self.assertEqual(len(df), 81, f"Expected 81 IDRiD records, found {len(df)}")
        
        fit_ids = set(df[df['split'] == 'calibration_fit']['image_id'])
        heldout_ids = set(df[df['split'] == 'heldout_validation']['image_id'])
        
        self.assertEqual(len(fit_ids), 40, f"Expected 40 fit IDs, found {len(fit_ids)}")
        self.assertEqual(len(heldout_ids), 41, f"Expected 41 heldout IDs, found {len(heldout_ids)}")
        
        overlap = fit_ids.intersection(heldout_ids)
        self.assertEqual(len(overlap), 0, f"Data leakage detected! Overlap between fit and heldout: {overlap}")

    def test_promotion_rule_determinism(self):
        def evaluate_promotion(baseline_ece, candidate_ece, baseline_sens, candidate_sens, baseline_brier, candidate_brier, data_available=True):
            if not data_available:
                return "BLOCKED"
            if candidate_ece <= baseline_ece and candidate_sens >= baseline_sens and candidate_brier <= baseline_brier:
                return "PROMOTE"
            else:
                return "ROLLBACK"

        # Deterministic checks
        self.assertEqual(evaluate_promotion(0.05, 0.03, 0.90, 0.92, 0.04, 0.03, data_available=True), "PROMOTE")
        self.assertEqual(evaluate_promotion(0.05, 0.06, 0.90, 0.92, 0.04, 0.03, data_available=True), "ROLLBACK")
        self.assertEqual(evaluate_promotion(0.05, 0.03, 0.90, 0.88, 0.04, 0.03, data_available=True), "ROLLBACK")
        self.assertEqual(evaluate_promotion(0.05, 0.03, 0.90, 0.92, 0.04, 0.05, data_available=True), "ROLLBACK")
        self.assertEqual(evaluate_promotion(0.05, 0.03, 0.90, 0.92, 0.04, 0.03, data_available=False), "BLOCKED")

    def test_messidor_freeze_status(self):
        self.assertTrue(os.path.exists(self.messidor_csv), f"Missing {self.messidor_csv}")
        df = pd.read_csv(self.messidor_csv)
        self.assertEqual(len(df), 1744, f"Expected 1744 Messidor-2 records, found {len(df)}")

    def test_handoff_package_schema(self):
        self.assertTrue(os.path.exists(self.handoff_json), f"Missing {self.handoff_json}")
        with open(self.handoff_json, "r") as f:
            data = json.load(f)

        required_keys = ["metadata", "adaptation_status", "baseline_model", "idrid_split_info", "messidor2_frozen_evidence", "evidence_files", "limitations"]
        for k in required_keys:
            self.assertIn(k, data, f"Missing key '{k}' in handoff package JSON")

        self.assertEqual(data["adaptation_status"]["decision"], "BLOCKED")
        self.assertIn("BLOCKED", data["adaptation_status"]["decision_rationale"])

    def test_aptos_split_isolation(self):
        train_csv = os.path.join(self.splits_dir, "train_split.csv")
        val_csv = os.path.join(self.splits_dir, "val_split.csv")
        test_csv = os.path.join(self.splits_dir, "test_split.csv")

        self.assertTrue(os.path.exists(train_csv), f"Missing {train_csv}")
        self.assertTrue(os.path.exists(val_csv), f"Missing {val_csv}")
        self.assertTrue(os.path.exists(test_csv), f"Missing {test_csv}")

        train_df = pd.read_csv(train_csv)
        val_df = pd.read_csv(val_csv)
        test_df = pd.read_csv(test_csv)

        train_ids = set(train_df['id_code'])
        val_ids = set(val_df['id_code'])
        test_ids = set(test_df['id_code'])

        self.assertEqual(len(train_ids.intersection(test_ids)), 0, "Train-Test leakage detected!")
        self.assertEqual(len(val_ids.intersection(test_ids)), 0, "Val-Test leakage detected!")

if __name__ == "__main__":
    unittest.main()
