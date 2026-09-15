"""
Test the new scoring-based gate against the full dataset and non-fundus images.
"""
import numpy as np
from PIL import Image
import glob
import os
from pathlib import Path

def validate_retinal_image(image_path):
    """Exact copy of the scoring function from server.py"""
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

    THRESHOLD = 0.45
    parts = [f"{k}={scores[k]:.1f}" for k in scores]
    detail = f"score={final_score:.2f} ({', '.join(parts)})"

    if final_score >= THRESHOLD:
        return True, f"PASS ({detail})", final_score
    else:
        worst = sorted(scores.items(), key=lambda x: x[1])
        worst_names = [f"{k}={v:.1f}" for k, v in worst[:3]]
        return False, f"FAIL ({detail})", final_score


# ─── TEST ALL MESSIDOR-2 ───
all_fundus = glob.glob(r"d:\SIH-26038\messidor-2\preprocess\*.png")
print(f"{'='*60}")
print(f"MESSIDOR-2 DATASET: {len(all_fundus)} fundus images")
print(f"{'='*60}")

fail_count = 0
pass_count = 0
min_score = 1.0
failures = []

for p in all_fundus:
    ok, reason, score = validate_retinal_image(p)
    min_score = min(min_score, score)
    if ok:
        pass_count += 1
    else:
        fail_count += 1
        failures.append((Path(p).name, reason, score))

print(f"PASS: {pass_count}, FAIL: {fail_count}")
print(f"False rejection rate: {fail_count/len(all_fundus)*100:.2f}%")
print(f"Minimum score across all fundus images: {min_score:.3f}")

if failures:
    print("\nFalse rejections:")
    for name, reason, score in failures:
        print(f"  {name}: {reason}")

# ─── TEST NON-FUNDUS IMAGES ───
non_fundus = [
    r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\human_face_1789452046787.png",
    r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\landscape_1789452071464.png",
    r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\document_1789452228703.png",
    r"d:\SIH-26038\dashboard\img\oculaai_logo.png",
    r"d:\SIH-26038\dashboard\uploads\80cc9efe.jpg",      # banana
    r"d:\SIH-26038\dashboard\uploads\ef6dcd12.png",       # scenery
    r"d:\SIH-26038\dashboard\uploads\e333f611.jpeg",      # building
    r"d:\SIH-26038\dashboard\uploads\cf181109.jpg",       # banana duplicate
]

print(f"\n{'='*60}")
print(f"NON-FUNDUS IMAGES: {len(non_fundus)} images")
print(f"{'='*60}")

non_fundus_pass = 0
for p in non_fundus:
    if os.path.exists(p):
        ok, reason, score = validate_retinal_image(p)
        status = "PASS" if ok else "FAIL"
        if ok:
            non_fundus_pass += 1
        print(f"  {status} (score={score:.2f}): {Path(p).name[:30]}")

if non_fundus_pass > 0:
    print(f"\n  WARNING: {non_fundus_pass} non-fundus images incorrectly passed!")
else:
    print(f"\n  All non-fundus images correctly rejected.")

# ─── TEST USER UPLOADS ───
print(f"\n{'='*60}")
print(f"ALL USER UPLOADS")
print(f"{'='*60}")
uploads = sorted(glob.glob(r"d:\SIH-26038\dashboard\uploads\*.*"), key=os.path.getmtime, reverse=True)[:15]
for p in uploads:
    ok, reason, score = validate_retinal_image(p)
    status = "PASS" if ok else "FAIL"
    print(f"  {status} (score={score:.2f}): {Path(p).name}")
