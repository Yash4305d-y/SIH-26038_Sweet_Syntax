import numpy as np
from PIL import Image
import os
from pathlib import Path

def extract_and_diagnose(image_path):
    """Extract all features and show exactly which check would fail."""
    try:
        img = Image.open(image_path).convert('RGB')
        img_resized = img.resize((256, 256))
        arr = np.array(img_resized)
    except Exception as e:
        print(f"  ERROR: Cannot open image: {e}")
        return

    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    mask = gray > 15
    fov_ratio = np.sum(mask) / mask.size

    # Border dark
    border_pixels = np.concatenate([
        gray[:13, :].flatten(),
        gray[-13:, :].flatten(),
        gray[:, :13].flatten(),
        gray[:, -13:].flatten()
    ])
    border_dark_ratio = np.sum(border_pixels <= 15) / len(border_pixels)

    if np.sum(mask) > 0:
        mean_r = np.mean(r[mask])
        mean_g = np.mean(g[mask])
        mean_b = np.mean(b[mask])
        std_g = np.std(g[mask])
    else:
        mean_r = mean_g = mean_b = std_g = 0

    print(f"  Original size: {img.size}")
    print(f"  FOV ratio:     {fov_ratio:.4f}  (need 0.2 < x < 0.95)  {'PASS' if 0.2 < fov_ratio < 0.95 else 'FAIL <---'}")
    print(f"  Border dark:   {border_dark_ratio:.4f}  (need > 0.2)           {'PASS' if border_dark_ratio > 0.2 else 'FAIL <---'}")
    print(f"  Mean R:        {mean_r:.1f}")
    print(f"  Mean G:        {mean_g:.1f}")
    print(f"  Mean B:        {mean_b:.1f}")
    print(f"  R-G gap:       {mean_r - mean_g:.1f}  (need > 15)            {'PASS' if mean_r > mean_g + 15 else 'FAIL <---'}")
    print(f"  G-B gap:       {mean_g - mean_b:.1f}  (need > 0)             {'PASS' if mean_g > mean_b else 'FAIL <---'}")
    print(f"  Std G:         {std_g:.1f}  (need 5 < x < 35)       {'PASS' if 5 < std_g < 35 else 'FAIL <---'}")

# Test the most recent uploads
uploads = [
    r"d:\SIH-26038\dashboard\uploads\0257ab36.jpeg",
    r"d:\SIH-26038\dashboard\uploads\b86698b2.png",
    r"d:\SIH-26038\dashboard\uploads\ef6dcd12.png",
    r"d:\SIH-26038\dashboard\uploads\4a7d9c60.png",
    r"d:\SIH-26038\dashboard\uploads\397644d6.png",
]

# Also test known good fundus images from the dataset
known_fundus = [
    r"d:\SIH-26038\messidor-2\preprocess\20051020_43808_0100_PP.png",
    r"d:\SIH-26038\messidor-2\preprocess\20051020_44261_0100_PP.png",
]

print("=" * 60)
print("RECENT UPLOADS (user's images)")
print("=" * 60)
for p in uploads:
    if os.path.exists(p):
        print(f"\n--- {Path(p).name} ---")
        extract_and_diagnose(p)

print("\n" + "=" * 60)
print("KNOWN VALID FUNDUS (messidor-2)")
print("=" * 60)
for p in known_fundus:
    if os.path.exists(p):
        print(f"\n--- {Path(p).name} ---")
        extract_and_diagnose(p)

# Also test ALL fundus images from messidor-2 preprocess to find edge cases
import glob
all_fundus = glob.glob(r"d:\SIH-26038\messidor-2\preprocess\*_PP.png")[:20]
print("\n" + "=" * 60)
print("BROADER FUNDUS SAMPLE (first 20 messidor-2)")
print("=" * 60)
fail_count = 0
pass_count = 0
fail_reasons = {}
for p in all_fundus:
    img = Image.open(p).convert('RGB')
    img = img.resize((256, 256))
    arr = np.array(img)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    mask = gray > 15
    fov_ratio = np.sum(mask) / mask.size
    border_pixels = np.concatenate([
        gray[:13, :].flatten(), gray[-13:, :].flatten(),
        gray[:, :13].flatten(), gray[:, -13:].flatten()
    ])
    border_dark_ratio = np.sum(border_pixels <= 15) / len(border_pixels)
    if np.sum(mask) > 0:
        mean_r = np.mean(r[mask])
        mean_g = np.mean(g[mask])
        mean_b = np.mean(b[mask])
        std_g = np.std(g[mask])
    else:
        mean_r = mean_g = mean_b = std_g = 0

    reasons = []
    if not (0.2 < fov_ratio < 0.95):
        reasons.append(f"FOV={fov_ratio:.3f}")
    if border_dark_ratio < 0.2:
        reasons.append(f"bDark={border_dark_ratio:.3f}")
    if not (mean_r > mean_g + 15):
        reasons.append(f"R-G={mean_r-mean_g:.1f}")
    if mean_g < mean_b:
        reasons.append(f"G<B")
    if not (5 < std_g < 35):
        reasons.append(f"stdG={std_g:.1f}")

    if reasons:
        fail_count += 1
        for r_str in reasons:
            key = r_str.split("=")[0]
            fail_reasons[key] = fail_reasons.get(key, 0) + 1
        print(f"  FAIL: {Path(p).name}: {', '.join(reasons)}")
    else:
        pass_count += 1

print(f"\nResults: {pass_count} PASS, {fail_count} FAIL out of {len(all_fundus)}")
if fail_reasons:
    print(f"Failure reasons: {fail_reasons}")
