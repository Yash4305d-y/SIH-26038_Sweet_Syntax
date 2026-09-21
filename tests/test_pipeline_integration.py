"""
Role 2 Pipeline Integration & Boundary Validation Suite (Member 3 - Sprint 2)
Tests: Input image formats, pipeline output struct integrity, 29-feature vector construction, threshold decision rules
"""

import unittest
import numpy as np
import cv2

def simulate_role2_pipeline(img_rgb):
    """Simulates role2_pipeline.m and final_DR_inference.m feature extraction & thresholding logic"""
    if img_rgb is None or img_rgb.size == 0:
        return {"status": "FAIL", "reason": "Input image is empty."}
        
    if img_rgb.ndim != 3 or img_rgb.shape[2] != 3:
        return {"status": "FAIL", "reason": "Image must be 3-channel RGB matrix."}
        
    h, w, c = img_rgb.shape
    if h < 50 or w < 50:
        return {"status": "FAIL", "reason": "Image resolution too small for fundus processing."}
        
    img_gray = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2GRAY)
    mask = (img_gray > 15).astype(np.uint8)
    fov_ratio = float(np.sum(mask) / mask.size)
    
    if fov_ratio < 0.10:
        return {"status": "FAIL", "reason": "FOV failure: Retinal area too small."}
        
    # Feature construction (29 features)
    vessel_ratio = float(np.sum(cv2.Canny(img_gray, 50, 150) > 0) / mask.size)
    disc_detected = 1.0 if np.max(img_gray) > 220 else 0.0
    disc_compactness = 0.85 if disc_detected else 0.0
    fovea_detected = 1.0 if disc_detected else 0.0
    
    ex_count = float(np.sum(img_gray > 230) // 10)
    ex_area_ratio = float(ex_count * 1e-4)
    ex_largest = float(ex_count * 5.0)
    ex_circ = 0.75 if ex_count > 0 else 0.0
    
    ma_count = float(np.sum(img_gray < 30) // 20)
    ma_area_ratio = float(ma_count * 5e-5)
    ma_largest = float(ma_count * 2.0)
    ma_circ = 0.80 if ma_count > 0 else 0.0
    
    ex_density = ex_count / max(vessel_ratio, 0.001)
    ma_density = ma_count / max(vessel_ratio, 0.001)
    ex_approx_area = ex_area_ratio / max(ex_count, 1.0)
    ma_approx_area = ma_area_ratio / max(ma_count, 1.0)
    
    total_count = ex_count + ma_count
    total_area_ratio = ex_area_ratio + ma_area_ratio
    count_ratio = ma_count / max(ex_count, 1.0)
    area_ratio = ma_area_ratio / max(ex_area_ratio, 1e-7)
    
    ex_large_count = ex_largest / max(ex_count, 1.0)
    ma_large_count = ma_largest / max(ma_count, 1.0)
    ex_vessel_burden = ex_area_ratio / max(vessel_ratio, 0.001)
    ma_vessel_burden = ma_area_ratio / max(vessel_ratio, 0.001)
    
    comb_circ = (ex_circ * ex_count + ma_circ * ma_count) / max(total_count, 1.0)
    lesion_morph_idx = (ex_circ + ma_circ) / 2.0
    vasc_lesion_inter = vessel_ratio * total_area_ratio
    disc_lesion_inter = disc_compactness * total_area_ratio
    fovea_lesion_inter = fovea_detected * total_area_ratio
    
    features = np.array([
        vessel_ratio, disc_detected, disc_compactness, fovea_detected,
        ex_count, ex_area_ratio, ex_largest, ex_circ,
        ma_count, ma_area_ratio, ma_largest, ma_circ,
        ex_density, ma_density, ex_approx_area, ma_approx_area,
        total_count, total_area_ratio, count_ratio, area_ratio,
        ex_large_count, ma_large_count, ex_vessel_burden, ma_vessel_burden,
        comb_circ, lesion_morph_idx, vasc_lesion_inter, disc_lesion_inter, fovea_lesion_inter
    ], dtype=np.float64)
    
    # Replace non-finite values safely with 0.0
    features = np.nan_to_num(features, nan=0.0, posinf=0.0, neginf=0.0)
    
    # Score simulation
    dr_prob = float(1.0 / (1.0 + np.exp(- (features[4] * 0.1 + features[8] * 0.15 - 0.5))))
    threshold = 0.84
    decision = "DR" if dr_prob >= threshold else "NoDR"
    
    return {
        "status": "PASS",
        "decision": decision,
        "drProbability": dr_prob,
        "threshold": threshold,
        "features": features,
        "featureCount": len(features)
    }

class TestPipelineIntegration(unittest.TestCase):

    def setUp(self):
        np.random.seed(42)
        img = np.zeros((224, 224, 3), dtype=np.uint8)
        cv2.circle(img, (112, 112), 90, (120, 160, 200), -1)
        noise = np.random.randint(-20, 20, (224, 224, 3), dtype=np.int16)
        self.valid_img = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)

    def test_valid_image_pipeline(self):
        res = simulate_role2_pipeline(self.valid_img)
        self.assertEqual(res["status"], "PASS")
        self.assertIn(res["decision"], ["DR", "NoDR"])
        self.assertEqual(res["featureCount"], 29)
        self.assertFalse(np.any(np.isnan(res["features"])))

    def test_empty_image_handling(self):
        empty_img = np.array([])
        res = simulate_role2_pipeline(empty_img)
        self.assertEqual(res["status"], "FAIL")
        self.assertIn("empty", res["reason"].lower())

    def test_resolution_too_small_handling(self):
        tiny_img = np.zeros((20, 20, 3), dtype=np.uint8)
        res = simulate_role2_pipeline(tiny_img)
        self.assertEqual(res["status"], "FAIL")
        self.assertIn("small", res["reason"].lower())

    def test_dr_threshold_operating_point(self):
        res = simulate_role2_pipeline(self.valid_img)
        self.assertEqual(res["threshold"], 0.84)
        if res["drProbability"] >= 0.84:
            self.assertEqual(res["decision"], "DR")
        else:
            self.assertEqual(res["decision"], "NoDR")

if __name__ == "__main__":
    unittest.main()
