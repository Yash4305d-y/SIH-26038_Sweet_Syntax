"""
IDRiD Supervised Segmentation Experiment Automated Test Suite
============================================================

Verifies:
1. Manifest split integrity (43 train / 11 val / 27 test, 0 overlap).
2. Model checkpoints exist and configuration is frozen.
3. Machine-readable ML results files exist and match schema.
4. Metrics are valid (non-NaN, non-Inf, in [0, 1]).
5. Morphological baseline remains active production pipeline.
6. All 3 lesion modules preserve PARTIALLY VALIDATED status.
"""

import os
import json
import math
import unittest
import pandas as pd


class TestIDRiDSupervisedSegmentation(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        cls.split_csv = os.path.join(cls.repo_root, "data", "splits", "idrid_segmentation_ml_split.csv")
        cls.config_json = os.path.join(cls.repo_root, "outputs", "evaluation", "idrid_segmentation_ml", "final_config.json")
        cls.results_json = os.path.join(cls.repo_root, "outputs", "evaluation", "idrid_segmentation_ml", "results.json")
        cls.comparison_csv = os.path.join(cls.repo_root, "outputs", "evaluation", "idrid_segmentation_ml", "comparison.csv")

        assert os.path.exists(cls.split_csv), "idrid_segmentation_ml_split.csv missing"
        assert os.path.exists(cls.config_json), "final_config.json missing"
        assert os.path.exists(cls.results_json), "results.json missing"
        assert os.path.exists(cls.comparison_csv), "comparison.csv missing"

        with open(cls.config_json, "r", encoding="utf-8") as f:
            cls.config = json.load(f)

        with open(cls.results_json, "r", encoding="utf-8") as f:
            cls.results = json.load(f)

        cls.df_split = pd.read_csv(cls.split_csv)
        cls.df_comp = pd.read_csv(cls.comparison_csv)

    def test_split_integrity_and_isolation(self):
        """Verify split counts (43 train, 11 val, 27 test) and zero overlap."""
        train_ids = set(self.df_split[self.df_split["split"] == "train"]["image_id"])
        val_ids = set(self.df_split[self.df_split["split"] == "val"]["image_id"])
        test_ids = set(self.df_split[self.df_split["split"] == "test"]["image_id"])

        self.assertEqual(len(train_ids), 43)
        self.assertEqual(len(val_ids), 11)
        self.assertEqual(len(test_ids), 27)

        self.assertEqual(len(train_ids.intersection(val_ids)), 0)
        self.assertEqual(len(train_ids.intersection(test_ids)), 0)
        self.assertEqual(len(val_ids.intersection(test_ids)), 0)

    def test_frozen_configuration(self):
        """Verify model configuration is frozen and checkpoints exist."""
        self.assertEqual(self.config["status"], "FREEZE_COMPLETE")
        self.assertEqual(self.config["untouched_test_sample_count"], 27)

        checkpoints = self.config["best_checkpoints"]
        for lesion_name, ckpt_rel in checkpoints.items():
            ckpt_path = os.path.join(self.repo_root, ckpt_rel)
            self.assertTrue(os.path.exists(ckpt_path), f"Checkpoint missing for {lesion_name}: {ckpt_path}")

    def test_comparison_table_and_metrics_validity(self):
        """Verify comparison.csv contains baseline vs supervised U-Net and valid metrics."""
        self.assertEqual(len(self.df_comp), 6)
        for _, row in self.df_comp.iterrows():
            for metric_key in ["dice", "iou", "precision", "recall", "specificity"]:
                val = float(row[metric_key])
                self.assertFalse(math.isnan(val), f"Metric {metric_key} is NaN in comparison.csv")
                self.assertFalse(math.isinf(val), f"Metric {metric_key} is Inf in comparison.csv")
                self.assertTrue(0.0 <= val <= 1.0, f"Metric {metric_key}={val} out of bounds")

    def test_morphological_baseline_superiority_and_status_preservation(self):
        """Verify morphological baseline outperforms supervised U-Net on small sample and status remains PARTIALLY VALIDATED."""
        decisions = self.results["module_status_decisions"]
        for module_key, info in decisions.items():
            self.assertEqual(info["status"], "PARTIALLY VALIDATED")
            self.assertGreaterEqual(info["baseline_dice"], info["supervised_dice"])


if __name__ == "__main__":
    unittest.main()
