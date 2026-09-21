"""
Independent Morphology & Lesion Component Validation Suite (Member 3)
Tests: Vessel Extraction, Optic Disc Detection, Fovea Localization, Exudates & MA/Hemorrhage Candidates
"""

import unittest
import numpy as np
import cv2

def extract_vessels(green_channel):
    """Mirror of vessel_extraction.m"""
    img_float = green_channel.astype(np.float64) / 255.0 if green_channel.dtype == np.uint8 else green_channel
    # Ridge / Hessian filter approximation for vesselness
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    uint8_g = (img_float * 255).astype(np.uint8)
    enhanced = clahe.apply(uint8_g)
    
    # Invert so dark vessels are bright
    inv = 255 - enhanced
    _, mask = cv2.threshold(inv, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    vessel_ratio = float(np.sum(mask > 0) / mask.size)
    return {
        "mask": mask,
        "vesselAreaRatio": vessel_ratio
    }

def detect_optic_disc(img_gray):
    """Mirror of optic_disc.m: 99.5th percentile brightness + compactness"""
    img_float = img_gray.astype(np.float64) / 255.0 if img_gray.dtype == np.uint8 else img_gray
    thresh_val = np.percentile(img_float, 99.5)
    bright_mask = (img_float >= thresh_val).astype(np.uint8)
    
    contours, _ = cv2.findContours(bright_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return {"detected": False, "compactness": 0.0, "bestCandidate": None}
        
    candidates = []
    for cnt in contours:
        area = cv2.contourArea(cnt)
        perim = cv2.arcLength(cnt, True)
        if area > 10 and perim > 0:
            compactness = float(4 * np.pi * area / (perim ** 2))
            if compactness >= 0.30:  # Candidate filter
                M = cv2.moments(cnt)
                if M["m00"] > 0:
                    cx = int(M["m10"] / M["m00"])
                    cy = int(M["m01"] / M["m00"])
                    candidates.append({"area": area, "compactness": compactness, "centroid": (cx, cy)})
                    
    if not candidates:
        return {"detected": False, "compactness": 0.0, "bestCandidate": None}
        
    best = max(candidates, key=lambda c: c["compactness"] * np.sqrt(c["area"]))
    return {"detected": True, "compactness": best["compactness"], "bestCandidate": best}

def localize_fovea(img_gray, disc_result):
    """Mirror of fovea_heuristic.m"""
    if not disc_result["detected"]:
        return {"detected": False, "centroid": None}
        
    h, w = img_gray.shape
    disc_cx, disc_cy = disc_result["bestCandidate"]["centroid"]
    
    # ROI ~ 0.20 width to the left of disc
    search_cx = max(20, disc_cx - int(0.20 * w))
    search_cy = disc_cy
    
    roi_w, roi_h = int(0.25 * w), int(0.25 * h)
    x1 = max(0, search_cx - roi_w // 2)
    x2 = min(w, search_cx + roi_w // 2)
    y1 = max(0, search_cy - roi_h // 2)
    y2 = min(h, search_cy + roi_h // 2)
    
    roi = img_gray[y1:y2, x1:x2]
    if roi.size == 0:
        return {"detected": False, "centroid": None}
        
    # Darkest region in ROI
    min_val, _, min_loc, _ = cv2.minMaxLoc(roi)
    fovea_global_cx = x1 + min_loc[0]
    fovea_global_cy = y1 + min_loc[1]
    
    return {
        "detected": True,
        "centroid": (fovea_global_cx, fovea_global_cy)
    }

def extract_exudates(green_channel):
    """Mirror of exudate_candidates.m: Top-hat transform"""
    img_uint8 = (green_channel * 255).astype(np.uint8) if green_channel.dtype != np.uint8 else green_channel
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
    tophat = cv2.morphologyEx(img_uint8, cv2.MORPH_TOPHAT, kernel)
    
    thresh_val = np.percentile(tophat, 99)
    _, mask = cv2.threshold(tophat, thresh_val, 255, cv2.THRESH_BINARY)
    area_ratio = float(np.sum(mask > 0) / mask.size)
    return {"mask": mask, "candidateAreaRatio": area_ratio}

def extract_ma_hemorrhages(green_channel, vessel_mask):
    """Mirror of ma_hemorrhage_candidates.m: Bottom-hat minus vessels"""
    img_uint8 = (green_channel * 255).astype(np.uint8) if green_channel.dtype != np.uint8 else green_channel
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
    blackhat = cv2.morphologyEx(img_uint8, cv2.MORPH_BLACKHAT, kernel)
    
    thresh_val = np.percentile(blackhat, 99.5)
    _, mask = cv2.threshold(blackhat, thresh_val, 255, cv2.THRESH_BINARY)
    # Subtract vessels
    mask[vessel_mask > 0] = 0
    area_ratio = float(np.sum(mask > 0) / mask.size)
    return {"mask": mask, "candidateAreaRatio": area_ratio}

class TestMorphologyValidation(unittest.TestCase):

    def setUp(self):
        self.h, self.w = 224, 224
        img = np.zeros((self.h, self.w), dtype=np.uint8)
        # Background retina circle
        cv2.circle(img, (112, 112), 95, 120, -1)
        # Simulated vessel line
        cv2.line(img, (50, 112), (180, 112), 40, 3)
        # Simulated optic disc (bright circular blob on right side)
        cv2.circle(img, (170, 112), 15, 240, -1)
        # Simulated fovea (dark spot left of disc)
        cv2.circle(img, (120, 112), 8, 20, -1)
        self.img_gray = img

    def test_vessel_extraction_bounds(self):
        v_res = extract_vessels(self.img_gray)
        self.assertEqual(v_res["mask"].shape, (self.h, self.w))
        self.assertGreaterEqual(v_res["vesselAreaRatio"], 0.0)
        self.assertLessEqual(v_res["vesselAreaRatio"], 1.0)

    def test_optic_disc_detection(self):
        disc_res = detect_optic_disc(self.img_gray)
        self.assertTrue(disc_res["detected"])
        cx, cy = disc_res["bestCandidate"]["centroid"]
        # Optic disc center should be near (170, 112)
        self.assertLess(abs(cx - 170), 20)
        self.assertLess(abs(cy - 112), 20)

    def test_fovea_localization(self):
        disc_res = detect_optic_disc(self.img_gray)
        fovea_res = localize_fovea(self.img_gray, disc_res)
        self.assertTrue(fovea_res["detected"])
        fcx, fcy = fovea_res["centroid"]
        # Fovea should be located inside image bounds
        self.assertGreaterEqual(fcx, 0)
        self.assertLess(fcx, self.w)
        self.assertGreaterEqual(fcy, 0)
        self.assertLess(fcy, self.h)

    def test_lesion_candidate_masks(self):
        v_res = extract_vessels(self.img_gray)
        ex_res = extract_exudates(self.img_gray)
        ma_res = extract_ma_hemorrhages(self.img_gray, v_res["mask"])
        
        self.assertEqual(ex_res["mask"].shape, (self.h, self.w))
        self.assertEqual(ma_res["mask"].shape, (self.h, self.w))
        self.assertGreaterEqual(ex_res["candidateAreaRatio"], 0.0)
        self.assertGreaterEqual(ma_res["candidateAreaRatio"], 0.0)

if __name__ == "__main__":
    unittest.main()
