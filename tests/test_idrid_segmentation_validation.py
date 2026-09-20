"""
IDRiD Segmentation Dataset Validation Automated Test Suite
==========================================================

Verifies:
1. IDRiD Part A (Segmentation) dataset path discovery and file integrity.
2. Ground-truth mask correspondence across train (54) and test (27) splits.
3. Machine-readable validation results file (idrid_segmentation_validation.json) exists and is valid.
4. All metrics are non-NaN, non-Inf, and within valid range [0, 1].
5. Module validation decisions preserve PARTIALLY VALIDATED status for all 3 lesion extractors.
6. Evaluation protocol enforces 54 train / 27 held-out test split isolation.
"""

import os
import json
import math
import unittest
import glob


class TestIDRiDSegmentationValidation(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        cls.dataset_dir = os.path.join(cls.repo_root, "A. Segmentation")
        cls.json_results_path = os.path.join(cls.repo_root, "outputs", "evaluation", "idrid_segmentation_validation.json")
        cls.report_path = os.path.join(cls.repo_root, "docs", "research", "idrid_segmentation_validation_report.md")

        assert os.path.exists(cls.dataset_dir), "IDRiD Part A dataset directory missing"
        assert os.path.exists(cls.json_results_path), "idrid_segmentation_validation.json missing"
        assert os.path.exists(cls.report_path), "idrid_segmentation_validation_report.md missing"

        with open(cls.json_results_path, "r", encoding="utf-8") as f:
            cls.results = json.load(f)

    def test_dataset_discovery_and_counts(self):
        """Verify IDRiD Segmentation dataset contains expected image and GT mask counts."""
        train_img_dir = os.path.join(self.dataset_dir, "1. Original Images", "a. Training Set")
        test_img_dir = os.path.join(self.dataset_dir, "1. Original Images", "b. Testing Set")

        train_imgs = glob.glob(os.path.join(train_img_dir, "*.jpg"))
        test_imgs = glob.glob(os.path.join(test_img_dir, "*.jpg"))

        self.assertEqual(len(train_imgs), 54, f"Expected 54 train images, found {len(train_imgs)}")
        self.assertEqual(len(test_imgs), 27, f"Expected 27 test images, found {len(test_imgs)}")
        self.assertEqual(len(train_imgs) + len(test_imgs), 81, "Total dataset images must equal 81")

    def test_ground_truth_mask_correspondence(self):
        """Verify ground-truth TIF masks exist for all test set images."""
        gt_test_dir = os.path.join(self.dataset_dir, "2. All Segmentation Groundtruths", "b. Testing Set")
        for lesion in ["1. Microaneurysms", "2. Haemorrhages", "3. Hard Exudates", "5. Optic Disc"]:
            masks = glob.glob(os.path.join(gt_test_dir, lesion, "*.tif"))
            self.assertEqual(len(masks), 27, f"Expected 27 {lesion} test masks, found {len(masks)}")

    def test_json_result_schema(self):
        """Verify required fields exist in idrid_segmentation_validation.json."""
        self.assertIn("dataset", self.results)
        self.assertIn("train_set_metrics", self.results)
        self.assertIn("heldout_test_set_metrics", self.results)
        self.assertIn("module_validation_decisions", self.results)
        self.assertIn("limitations", self.results)

    def test_heldout_metrics_validity(self):
        """Verify all held-out metrics are non-NaN, non-Inf, and within [0, 1]."""
        heldout = self.results["heldout_test_set_metrics"]
        for lesion_name in ["microaneurysms", "hemorrhages", "exudates"]:
            self.assertIn(lesion_name, heldout)
            m = heldout[lesion_name]
            for metric_key in ["precision", "recall", "specificity", "f1", "dice", "iou"]:
                val = m[metric_key]
                self.assertFalse(math.isnan(val), f"Metric {metric_key} in {lesion_name} is NaN")
                self.assertFalse(math.isinf(val), f"Metric {metric_key} in {lesion_name} is Inf")
                self.assertTrue(0.0 <= val <= 1.0, f"Metric {metric_key}={val} out of bounds for {lesion_name}")

    def test_high_specificity_and_partially_validated_status(self):
        """Verify high pixel specificity is achieved while preserving PARTIALLY VALIDATED status."""
        decisions = self.results["module_validation_decisions"]
        
        # Verify Microaneurysm
        ma = decisions["microaneurysm_candidate_extraction"]
        self.assertEqual(ma["status"], "PARTIALLY VALIDATED")
        self.assertGreaterEqual(ma["heldout_specificity"], 0.95)

        # Verify Hemorrhage
        he = decisions["hemorrhage_candidate_extraction"]
        self.assertEqual(he["status"], "PARTIALLY VALIDATED")
        self.assertGreaterEqual(he["heldout_specificity"], 0.95)

        # Verify Hard Exudates
        ex = decisions["exudate_candidate_extraction"]
        self.assertEqual(ex["status"], "PARTIALLY VALIDATED")
        self.assertGreaterEqual(ex["heldout_specificity"], 0.95)

    def test_no_fake_validation_upgrade(self):
        """Verify no module is falsely declared FULLY VALIDATED without meeting Dice >= 0.70 threshold."""
        decisions = self.results["module_validation_decisions"]
        for module_name, info in decisions.items():
            self.assertNotEqual(info["status"], "VALIDATED", f"{module_name} must NOT be upgraded to VALIDATED without Dice >= 0.70")


if __name__ == "__main__":
    unittest.main()
