"""Final comprehensive verification of the scoring gate with threshold=0.50"""
import numpy as np
from PIL import Image
import glob
import os
from pathlib import Path

def validate_retinal_image(image_path):
    try:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((256, 256))
        arr = np.array(img)
    except Exception as e:
        return False, f"ERROR: {e}", 0.0

    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    mask = gray > 15
    fov_ratio = float(np.sum(mask) / mask.size)

    if np.sum(mask) == 0:
        return False, "Empty", 0.0

    mean_r = float(np.mean(r[mask]))
    mean_g = float(np.mean(g[mask]))
    mean_b = float(np.mean(b[mask]))
    std_g = float(np.std(g[mask]))

    border_pixels = np.concatenate([
        gray[:13, :].flatten(), gray[-13:, :].flatten(),
        gray[:, :13].flatten(), gray[:, -13:].flatten()
    ])
    border_dark_ratio = float(np.sum(border_pixels <= 15) / len(border_pixels))

    rg_gap = mean_r - mean_g
    gb_gap = mean_g - mean_b
    scores = {}

    if fov_ratio > 0.97: scores['fov'] = 0.0
    elif fov_ratio > 0.95: scores['fov'] = 0.2
    elif fov_ratio > 0.90: scores['fov'] = 0.5
    elif 0.2 <= fov_ratio <= 0.90: scores['fov'] = 1.0
    elif fov_ratio >= 0.15: scores['fov'] = 0.5
    else: scores['fov'] = 0.0

    if border_dark_ratio > 0.5: scores['border'] = 1.0
    elif border_dark_ratio > 0.2: scores['border'] = 0.8
    elif border_dark_ratio > 0.1: scores['border'] = 0.4
    else: scores['border'] = 0.0

    if rg_gap > 30: scores['rg_dom'] = 1.0
    elif rg_gap > 15: scores['rg_dom'] = 0.8
    elif rg_gap > 5: scores['rg_dom'] = 0.3
    else: scores['rg_dom'] = 0.0

    if gb_gap > 20: scores['gb'] = 1.0
    elif gb_gap > 0: scores['gb'] = 0.7
    else: scores['gb'] = 0.0

    if 8 <= std_g <= 40: scores['texture'] = 1.0
    elif 5 <= std_g <= 45: scores['texture'] = 0.6
    elif std_g > 60: scores['texture'] = 0.0
    else: scores['texture'] = 0.2

    weights = {'fov': 2, 'border': 2, 'rg_dom': 3, 'gb': 1, 'texture': 1}
    total_weight = sum(weights.values())
    weighted_sum = sum(scores[k] * weights[k] for k in scores)
    final_score = weighted_sum / total_weight

    THRESHOLD = 0.50
    if final_score >= THRESHOLD:
        return True, "PASS", final_score
    else:
        return False, "FAIL", final_score

# FUNDUS images (must ALL pass)
all_fundus = glob.glob(r"d:\SIH-26038\messidor-2\preprocess\*.png")
fund_pass = sum(1 for p in all_fundus if validate_retinal_image(p)[0])
fund_fail = len(all_fundus) - fund_pass
min_fund = min(validate_retinal_image(p)[2] for p in all_fundus)

# NON-FUNDUS (must ALL fail)
non_fundus = [
    r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\human_face_1789452046787.png",
    r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\landscape_1789452071464.png",
    r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\document_1789452228703.png",
    r"d:\SIH-26038\dashboard\img\oculaai_logo.png",
    r"d:\SIH-26038\dashboard\uploads\80cc9efe.jpg",
    r"d:\SIH-26038\dashboard\uploads\ef6dcd12.png",
    r"d:\SIH-26038\dashboard\uploads\e333f611.jpeg",
]
non_fundus = [p for p in non_fundus if os.path.exists(p)]
nf_pass = sum(1 for p in non_fundus if validate_retinal_image(p)[0])
max_nf = max(validate_retinal_image(p)[2] for p in non_fundus)

print("=" * 60)
print("FINAL VERIFICATION (threshold=0.50)")
print("=" * 60)
print()
print(f"FUNDUS IMAGES ({len(all_fundus)} total):")
print(f"  Pass: {fund_pass}  Fail: {fund_fail}")
print(f"  False rejection rate: {fund_fail/len(all_fundus)*100:.2f}%")
print(f"  Minimum fundus score: {min_fund:.3f}")
print()
print(f"NON-FUNDUS IMAGES ({len(non_fundus)} total):")
print(f"  Correctly rejected: {len(non_fundus) - nf_pass}")
print(f"  Incorrectly passed: {nf_pass}")
print(f"  Maximum non-fundus score: {max_nf:.3f}")
print()
print(f"SEPARATION GAP: {min_fund - max_nf:.3f}")
print(f"  (min fundus = {min_fund:.3f}, max non-fundus = {max_nf:.3f})")
print()

if fund_fail == 0 and nf_pass == 0:
    print("✅ PERFECT: All fundus accepted, all non-fundus rejected!")
else:
    if fund_fail > 0:
        print(f"❌ {fund_fail} genuine fundus images falsely rejected")
    if nf_pass > 0:
        print(f"❌ {nf_pass} non-fundus images incorrectly accepted")

# Show individual non-fundus scores
print()
print("Non-fundus detail:")
for p in non_fundus:
    ok, reason, score = validate_retinal_image(p)
    print(f"  {'PASS' if ok else 'FAIL'} ({score:.3f}): {Path(p).name[:35]}")
