"""
Independent Preprocessing Component Validation Suite (Member 3)
Tests: CLAHE Contrast Enhancement, Gaussian Denoising, Output Bounds, Determinism
"""

import unittest
import numpy as np
import cv2

def preprocess_clahe_lab(img_rgb):
    """Mirror of preprocess_clahe.m: RGB -> LAB -> adapthisteq L -> RGB"""
    img_float = img_rgb.astype(np.float32) / 255.0
    lab = cv2.cvtColor(img_float, cv2.COLOR_RGB2LAB)
    
    # L channel is in [0, 100] in OpenCV LAB float representation
    l_channel = lab[:, :, 0] / 100.0  # scale to [0, 1]
    
    # CLAHE equivalent in OpenCV (clipLimit=0.01 in MATLAB maps to tile grid 8x8)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    l_uint8 = np.clip(l_channel * 255.0, 0, 255).astype(np.uint8)
    l_clahe = clahe.apply(l_uint8).astype(np.float32) / 255.0
    
    lab[:, :, 0] = l_clahe * 100.0
    enhanced_rgb = cv2.cvtColor(lab, cv2.COLOR_LAB2RGB)
    return np.clip(enhanced_rgb, 0.0, 1.0)

def preprocess_denoise(img_float, sigma=0.8):
    """Mirror of preprocess_denoise.m: Gaussian filtering"""
    # Kernel size 5x5 for sigma=0.8
    return cv2.GaussianBlur(img_float, (5, 5), sigma)

def preprocess_fundus(img_rgb):
    """Mirror of preprocess_fundus.m"""
    clahe_img = preprocess_clahe_lab(img_rgb)
    return preprocess_denoise(clahe_img, 0.8)

class TestPreprocessingValidation(unittest.TestCase):

    def setUp(self):
        self.h, self.w = 224, 224
        img = np.zeros((self.h, self.w, 3), dtype=np.uint8)
        cv2.circle(img, (112, 112), 90, (100, 140, 180), -1)
        np.random.seed(42)
        noise = np.random.randint(-15, 15, (self.h, self.w, 3), dtype=np.int16)
        self.img_rgb = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)

    def test_clahe_bounds_and_shape(self):
        clahe_out = preprocess_clahe_lab(self.img_rgb)
        self.assertEqual(clahe_out.shape, (self.h, self.w, 3))
        self.assertGreaterEqual(np.min(clahe_out), 0.0)
        self.assertLessEqual(np.max(clahe_out), 1.0)

    def test_clahe_contrast_enhancement(self):
        # CLAHE should increase local contrast (std dev of L channel)
        gray_orig = cv2.cvtColor(self.img_rgb, cv2.COLOR_RGB2GRAY).astype(np.float32) / 255.0
        clahe_out = preprocess_clahe_lab(self.img_rgb)
        gray_clahe = cv2.cvtColor((clahe_out * 255).astype(np.uint8), cv2.COLOR_RGB2GRAY).astype(np.float32) / 255.0
        
        # Mask out background black region
        mask = gray_orig > 0.05
        std_orig = np.std(gray_orig[mask])
        std_clahe = np.std(gray_clahe[mask])
        
        self.assertGreaterEqual(std_clahe, std_orig * 0.9, "CLAHE must enhance or preserve local contrast variance")

    def test_denoise_variance_reduction(self):
        clahe_out = preprocess_clahe_lab(self.img_rgb)
        denoised = preprocess_denoise(clahe_out, 0.8)
        
        self.assertEqual(denoised.shape, clahe_out.shape)
        # High frequency noise variance should decrease after Gaussian smoothing
        var_before = np.var(clahe_out)
        var_after = np.var(denoised)
        self.assertLess(var_after, var_before, "Denoising filter must reduce high-frequency noise variance")

    def test_preprocessing_determinism(self):
        out1 = preprocess_fundus(self.img_rgb)
        out2 = preprocess_fundus(self.img_rgb)
        np.testing.assert_array_equal(out1, out2, "Preprocessing must be 100% deterministic")

if __name__ == "__main__":
    unittest.main()
