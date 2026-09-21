"""
Comprehensive gate test across the ENTIRE messidor-2 dataset (1057 images)
and the user's actual uploads.

Goal: Find EVERY false rejection so we can fix thresholds properly.
"""
import numpy as np
from PIL import Image
import glob
import os
from pathlib import Path

def validate_retinal_image_with_details(image_path):
    """Run the EXACT same logic as server.py and return detailed diagnostics."""
    try:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((256, 256))
        arr = np.array(img)
    except Exception as e:
        return False, f"Invalid image file: {e}", {}

    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    mask = gray > 15
    fov_ratio = np.sum(mask) / mask.size

    border_pixels = np.concatenate([
        gray[:13, :].flatten(),
        gray[-13:, :].flatten(),
        gray[:, :13].flatten(),
        gray[:, -13:].flatten()
    ])
    border_dark_ratio = np.sum(border_pixels <= 15) / len(border_pixels)

    if np.sum(mask) > 0:
        mean_r = float(np.mean(r[mask]))
        mean_g = float(np.mean(g[mask]))
        mean_b = float(np.mean(b[mask]))
        std_g = float(np.std(g[mask]))
    else:
        mean_r = mean_g = mean_b = std_g = 0.0

    details = {
        'fov': fov_ratio,
        'border_dark': border_dark_ratio,
        'mean_r': mean_r,
        'mean_g': mean_g,
        'mean_b': mean_b,
        'rg_gap': mean_r - mean_g,
        'gb_gap': mean_g - mean_b,
        'std_g': std_g,
    }

    # Run the EXACT checks from server.py
    if fov_ratio > 0.95 or fov_ratio < 0.2:
        return False, f"FOV={fov_ratio:.3f}", details
    if border_dark_ratio < 0.2:
        return False, f"bDark={border_dark_ratio:.3f}", details
    if mean_r < (mean_g + 15):
        return False, f"R-G={mean_r-mean_g:.1f}", details
    if mean_g < mean_b:
        return False, f"G<B ({mean_g:.1f}<{mean_b:.1f})", details
    if std_g > 35 or std_g < 5:
        return False, f"stdG={std_g:.1f}", details

    return True, "PASS", details


# Test ALL 1057 messidor-2 preprocessed images
all_fundus = glob.glob(r"d:\SIH-26038\messidor-2\preprocess\*.png")
print(f"Testing {len(all_fundus)} messidor-2 preprocessed fundus images...")
print("=" * 80)

fail_count = 0
pass_count = 0
failures = []

for p in all_fundus:
    ok, reason, details = validate_retinal_image_with_details(p)
    if ok:
        pass_count += 1
    else:
        fail_count += 1
        failures.append((Path(p).name, reason, details))

print(f"\nRESULTS: {pass_count} PASS, {fail_count} FAIL out of {len(all_fundus)}")
print(f"False rejection rate: {fail_count/len(all_fundus)*100:.2f}%\n")

if failures:
    print("FAILED IMAGES (false rejections of genuine fundus):")
    print("-" * 80)
    for name, reason, d in failures[:30]:
        print(f"  {name}: {reason}")
        print(f"    FOV={d['fov']:.3f} bDark={d['border_dark']:.3f} R-G={d['rg_gap']:.1f} G-B={d['gb_gap']:.1f} stdG={d['std_g']:.1f}")

# Also test user uploads that are fundus images
print("\n" + "=" * 80)
print("USER UPLOADS (most recent)")
print("=" * 80)
uploads = sorted(glob.glob(r"d:\SIH-26038\dashboard\uploads\*.*"), 
                 key=os.path.getmtime, reverse=True)[:10]
for p in uploads:
    ok, reason, details = validate_retinal_image_with_details(p)
    print(f"  {Path(p).name}: {'PASS' if ok else 'FAIL'} ({reason})")
    if not ok:
        d = details
        print(f"    FOV={d['fov']:.3f} bDark={d['border_dark']:.3f} R-G={d['rg_gap']:.1f} G-B={d['gb_gap']:.1f} stdG={d['std_g']:.1f}")
