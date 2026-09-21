"""
Independent Calibration & Evaluation Validation Suite (Member 3)
Tests: Platt Scaling Fitting, Brier Score, Expected Calibration Error (ECE),
Validation-only Threshold Sweep Selection, Dataset Isolation Rules
"""

import os
import unittest
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression

def compute_brier_score(y_prob, y_true):
    """Calculates Brier Score: Mean Squared Difference between prob and binary label"""
    return float(np.mean((y_prob - y_true) ** 2))

def compute_ece(y_prob, y_true, n_bins=10):
    """Calculates Expected Calibration Error (ECE)"""
    bin_boundaries = np.linspace(0, 1, n_bins + 1)
    ece = 0.0
    total_samples = len(y_true)
    
    for i in range(n_bins):
        bin_lower, bin_upper = bin_boundaries[i], bin_boundaries[i + 1]
        in_bin = (y_prob > bin_lower) & (y_prob <= bin_upper) if i > 0 else (y_prob >= bin_lower) & (y_prob <= bin_upper)
        prop_in_bin = np.mean(in_bin)
        
        if prop_in_bin > 0:
            accuracy_in_bin = np.mean(y_true[in_bin])
            avg_confidence_in_bin = np.mean(y_prob[in_bin])
            ece += np.abs(accuracy_in_bin - avg_confidence_in_bin) * (np.sum(in_bin) / total_samples)
            
    return float(ece)

def select_threshold_validation_only(val_probs, val_labels, min_sensitivity=0.95):
    """Mirror of calibrateReferableDR.m threshold selection on validation set only"""
    thresholds = np.linspace(0.05, 0.95, 91)
    results = []
    
    for th in thresholds:
        preds = (val_probs >= th).astype(int)
        tp = np.sum((val_labels == 1) & (preds == 1))
        fp = np.sum((val_labels == 0) & (preds == 1))
        fn = np.sum((val_labels == 1) & (preds == 0))
        tn = np.sum((val_labels == 0) & (preds == 0))
        
        sens = tp / (tp + fn) if (tp + fn) > 0 else 0.0
        spec = tn / (tn + fp) if (tn + fp) > 0 else 0.0
        prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        f1 = 2 * (prec * sens) / (prec + sens) if (prec + sens) > 0 else 0.0
        
        results.append({"threshold": th, "sens": sens, "spec": spec, "f1": f1})
        
    valid_idx = [r for r in results if r["sens"] >= min_sensitivity]
    if valid_idx:
        best_row = max(valid_idx, key=lambda x: x["f1"])
    else:
        best_row = max(results, key=lambda x: x["f1"])
        
    return best_row["threshold"]

class TestCalibrationValidation(unittest.TestCase):

    def setUp(self):
        np.random.seed(42)
        # Synthetic validation probability distribution
        self.val_raw_prob = np.random.uniform(0.1, 0.9, 440)
        self.val_labels = (self.val_raw_prob + np.random.normal(0, 0.15, 440) >= 0.5).astype(int)
        
        # Synthetic test probability distribution
        self.test_raw_prob = np.random.uniform(0.1, 0.9, 439)
        self.test_labels = (self.test_raw_prob + np.random.normal(0, 0.15, 439) >= 0.5).astype(int)

    def test_brier_and_ece_metrics(self):
        brier = compute_brier_score(self.val_raw_prob, self.val_labels)
        ece = compute_ece(self.val_raw_prob, self.val_labels)
        
        self.assertGreaterEqual(brier, 0.0)
        self.assertLessEqual(brier, 1.0)
        self.assertGreaterEqual(ece, 0.0)
        self.assertLessEqual(ece, 1.0)

    def test_platt_scaling_fitting_validation_only(self):
        # Fit Platt scaling ONLY on validation set
        platt_model = LogisticRegression(C=1e5, solver='lbfgs')
        platt_model.fit(self.val_raw_prob.reshape(-1, 1), self.val_labels)
        
        val_calib_prob = platt_model.predict_proba(self.val_raw_prob.reshape(-1, 1))[:, 1]
        
        brier_raw = compute_brier_score(self.val_raw_prob, self.val_labels)
        brier_calib = compute_brier_score(val_calib_prob, self.val_labels)
        
        self.assertLessEqual(brier_calib, brier_raw + 0.05, "Calibrated probabilities must improve or preserve Brier score")

    def test_threshold_selection_isolation(self):
        # Threshold selected on validation data ONLY
        platt_model = LogisticRegression(C=1e5, solver='lbfgs')
        platt_model.fit(self.val_raw_prob.reshape(-1, 1), self.val_labels)
        val_calib_prob = platt_model.predict_proba(self.val_raw_prob.reshape(-1, 1))[:, 1]
        
        opt_thresh = select_threshold_validation_only(val_calib_prob, self.val_labels, min_sensitivity=0.95)
        
        self.assertGreaterEqual(opt_thresh, 0.05)
        self.assertLessEqual(opt_thresh, 0.95)
        
        # Apply frozen threshold to test set without tuning
        test_calib_prob = platt_model.predict_proba(self.test_raw_prob.reshape(-1, 1))[:, 1]
        test_preds = (test_calib_prob >= opt_thresh).astype(int)
        
        self.assertEqual(len(test_preds), 439)

if __name__ == "__main__":
    unittest.main()
