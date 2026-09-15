import os
from pathlib import Path
import numpy as np
from PIL import Image
import glob

def extract_features(image_path):
    try:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((256, 256))
        arr = np.array(img)
    except Exception as e:
        return None, "Invalid image file"

    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    mask = gray > 15
    fov_ratio = np.sum(mask) / mask.size

    if np.sum(mask) == 0:
        return None, "Empty FOV"
        
    mean_r = np.mean(r[mask])
    mean_g = np.mean(g[mask])
    mean_b = np.mean(b[mask])
    std_g = np.std(g[mask])
    
    border_pixels = np.concatenate([
        gray[:13, :].flatten(),
        gray[-13:, :].flatten(),
        gray[:, :13].flatten(),
        gray[:, -13:].flatten()
    ])
    border_dark_ratio = np.sum(border_pixels <= 15) / len(border_pixels)
    
    gb_diff = mean_g - mean_b
    rg_diff = mean_r - mean_g

    features = {
        'fov_ratio': fov_ratio,
        'mean_r': mean_r,
        'mean_g': mean_g,
        'mean_b': mean_b,
        'std_g': std_g,
        'border_dark': border_dark_ratio,
        'gb_diff': gb_diff,
        'rg_diff': rg_diff
    }
    
    return features, ""

if __name__ == "__main__":
    uploads = glob.glob(r"d:\SIH-26038\dashboard\uploads\*.jpeg") + glob.glob(r"d:\SIH-26038\dashboard\uploads\*.png")
    test_images = uploads[-20:] # test the last 20 uploaded images
    
    print(f"{'Filename':<20} | {'FOV':<5} | {'R>G':<5} | {'G>B':<5} | {'R-G':<5} | {'G-B':<5} | {'stdG':<5} | {'bDark':<5}")
    print("-" * 80)
    for p in test_images:
        feat, msg = extract_features(p)
        if feat:
            print(f"{Path(p).name[:20]:<20} | {feat['fov_ratio']:4.2f} | {str(feat['mean_r']>feat['mean_g']):<5} | {str(feat['mean_g']>feat['mean_b']):<5} | {feat['rg_diff']:5.1f} | {feat['gb_diff']:5.1f} | {feat['std_g']:4.1f} | {feat['border_dark']:4.2f}")
