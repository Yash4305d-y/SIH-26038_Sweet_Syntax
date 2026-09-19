"""
Independent IQA Component Validation Suite (Member 3)
Tests: Focus Score, Illumination Score, FOV Score, and IQA Gate Logic
"""

import unittest
import numpy as np
import cv2

def compute_focus_score(img_gray):
    """Mirror of focus_score.m: 2D Laplacian Filter Variance"""
    img_float = img_gray.astype(np.float64) / 255.0
    kernel = np.array([[1/6, 2/3, 1/6], [2/3, -10/3, 2/3], [1/6, 2/3, 1/6]], dtype=np.float64)
    lap = cv2.filter2D(img_float, -1, kernel, borderType=cv2.BORDER_REPLICATE)
    return float(np.var(lap))

def compute_illumination_score(img_gray):
    """Mirror of illumination_score.m: Mean intensity & dark/bright ratios"""
    img_float = img_gray.astype(np.float64) / 255.0
    mean_val = float(np.mean(img_float))
    dark_ratio = float(np.mean(img_float < 0.05))
    bright_ratio = float(np.mean(img_float > 0.95))
    return {
        "meanIntensity": mean_val,
        "darkPixelRatio": dark_ratio,
        "brightPixelRatio": bright_ratio
    }

def compute_fov_score(img_gray):
    """Mirror of fov_score.m: Mask area ratio & circularity"""
    img_float = img_gray.astype(np.float64) / 255.0
    mask = (img_float > 0.05).astype(np.uint8)
    
    total_pixels = mask.size
    area = int(np.sum(mask))
    area_ratio = float(area / total_pixels)
    
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return {"areaRatio": 0.0, "circularity": 0.0, "detected": False}
    
    cnt = max(contours, key=cv2.contourArea)
    perimeter = cv2.arcLength(cnt, True)
    c_area = cv2.contourArea(cnt)
    
    circularity = float(4 * np.pi * c_area / (perimeter ** 2)) if perimeter > 0 else 0.0
    return {
        "areaRatio": area_ratio,
        "circularity": circularity,
        "detected": True
    }

def iqa_gate(img_rgb, thresholds=None):
    """Mirror of iqa_gate.m"""
    if thresholds is None:
        thresholds = {
            "focusMin": 0.00003,
            "meanMin": 0.07, "meanMax": 0.70,
            "darkMax": 0.54, "brightMax": 0.50,
            "areaMin": 0.20, "circularityMin": 0.09
        }
        
    img_gray = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2GRAY) if img_rgb.ndim == 3 else img_rgb
    
    focus = compute_focus_score(img_gray)
    illum = compute_illumination_score(img_gray)
    fov = compute_fov_score(img_gray)
    
    focus_pass = focus >= thresholds["focusMin"]
    illum_pass = (
        illum["meanIntensity"] >= thresholds["meanMin"] and
        illum["meanIntensity"] <= thresholds["meanMax"] and
        illum["darkPixelRatio"] <= thresholds["darkMax"] and
        illum["brightPixelRatio"] <= thresholds["brightMax"]
    )
    fov_pass = (
        fov["areaRatio"] >= thresholds["areaMin"] and
        fov["circularity"] >= thresholds["circularityMin"]
    )
    
    overall_pass = focus_pass and illum_pass and fov_pass
    
    if not focus_pass:
        reason = "Focus failure"
    elif not illum_pass:
        reason = "Illumination failure"
    elif not fov_pass:
        reason = "FOV failure"
    else:
        reason = "PASS"
        
    return {
        "pass": overall_pass,
        "reason": reason,
        "focusScore": focus,
        "illumination": illum,
        "fov": fov
    }

class TestIQAValidation(unittest.TestCase):

    def setUp(self):
        # Create a synthetic base fundus image (224x224 RGB)
        self.h, self.w = 224, 224
        img = np.zeros((self.h, self.w, 3), dtype=np.uint8)
        cv2.circle(img, (112, 112), 90, (120, 160, 200), -1)
        # Add high-frequency noise & details to simulate retina texture
        np.random.seed(42)
        noise = np.random.randint(-20, 20, (self.h, self.w, 3), dtype=np.int16)
        img = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
        self.valid_img = img

    def test_sharp_vs_blurred_focus_score(self):
        sharp_focus = compute_focus_score(cv2.cvtColor(self.valid_img, cv2.COLOR_RGB2GRAY))
        blurred_img = cv2.GaussianBlur(self.valid_img, (15, 15), 5)
        blurred_focus = compute_focus_score(cv2.cvtColor(blurred_img, cv2.COLOR_RGB2GRAY))
        
        self.assertGreater(sharp_focus, blurred_focus, "Sharp image must have higher focus score than blurred image")
        self.assertGreater(sharp_focus, 0.00003, "Valid sharp image must exceed minimum focus threshold")

    def test_illumination_extremes(self):
        dark_img = np.zeros((224, 224, 3), dtype=np.uint8)
        illum_dark = compute_illumination_score(cv2.cvtColor(dark_img, cv2.COLOR_RGB2GRAY))
        self.assertLess(illum_dark["meanIntensity"], 0.07, "Pure dark image must fail meanMin threshold")
        self.assertGreater(illum_dark["darkPixelRatio"], 0.54, "Pure dark image must exceed darkMax threshold")
        
        bright_img = np.full((224, 224, 3), 255, dtype=np.uint8)
        illum_bright = compute_illumination_score(cv2.cvtColor(bright_img, cv2.COLOR_RGB2GRAY))
        self.assertGreater(illum_bright["meanIntensity"], 0.70, "Pure bright image must exceed meanMax threshold")

    def test_fov_score(self):
        fov_valid = compute_fov_score(cv2.cvtColor(self.valid_img, cv2.COLOR_RGB2GRAY))
        self.assertTrue(fov_valid["detected"])
        self.assertGreater(fov_valid["areaRatio"], 0.20)
        
        # Tiny circle image (insufficient FOV)
        tiny_img = np.zeros((224, 224, 3), dtype=np.uint8)
        cv2.circle(tiny_img, (112, 112), 20, (150, 150, 150), -1)
        fov_tiny = compute_fov_score(cv2.cvtColor(tiny_img, cv2.COLOR_RGB2GRAY))
        self.assertLess(fov_tiny["areaRatio"], 0.20, "Tiny retina circle must fail minimum FOV area ratio")

    def test_iqa_gate_reason_codes(self):
        # 1. Blur test -> "Focus failure"
        blurred_img = cv2.GaussianBlur(self.valid_img, (25, 25), 10)
        res_blur = iqa_gate(blurred_img)
        self.assertFalse(res_blur["pass"])
        self.assertEqual(res_blur["reason"], "Focus failure")

        # 2. Overexposed image (meanIntensity ~0.98 > 0.70) with textured noise so focus passes
        np.random.seed(42)
        bright_noisy = np.full((224, 224, 3), 250, dtype=np.uint8)
        noise = np.random.randint(-10, 5, (224, 224, 3), dtype=np.int16)
        bright_noisy = np.clip(bright_noisy.astype(np.int16) + noise, 0, 255).astype(np.uint8)
        res_bright = iqa_gate(bright_noisy)
        self.assertFalse(res_bright["pass"])
        self.assertEqual(res_bright["reason"], "Illumination failure")

        # 3. Valid image -> "PASS"
        res_valid = iqa_gate(self.valid_img)
        self.assertTrue(res_valid["pass"])
        self.assertEqual(res_valid["reason"], "PASS")

if __name__ == "__main__":
    unittest.main()
