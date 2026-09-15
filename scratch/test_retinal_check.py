import os
from pathlib import Path
import numpy as np
from PIL import Image, ImageColor
import math

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
    
    # Calculate Center of Mass
    y_coords, x_coords = np.nonzero(mask)
    com_x = np.mean(x_coords)
    com_y = np.mean(y_coords)
    
    # Normalized distance of COM from center of image (128, 128)
    center_dist = math.sqrt((com_x - 128)**2 + (com_y - 128)**2) / 128.0
    
    # Standard deviation of mask coordinates (circularity check)
    std_x = np.std(x_coords)
    std_y = np.std(y_coords)
    std_ratio = min(std_x, std_y) / max(std_x, std_y) if max(std_x, std_y) > 0 else 0
    
    # Border dark ratio (top, bottom, left, right 5%)
    border_pixels = np.concatenate([
        gray[:13, :].flatten(),
        gray[-13:, :].flatten(),
        gray[:, :13].flatten(),
        gray[:, -13:].flatten()
    ])
    border_dark_ratio = np.sum(border_pixels <= 15) / len(border_pixels)
    
    # Check green-blue difference
    gb_diff = mean_g - mean_b

    features = {
        'fov_ratio': fov_ratio,
        'mean_r': mean_r,
        'mean_g': mean_g,
        'mean_b': mean_b,
        'std_g': std_g,
        'center_dist': center_dist,
        'std_ratio': std_ratio,
        'std_x': std_x,
        'std_y': std_y,
        'border_dark': border_dark_ratio,
        'gb_diff': gb_diff
    }
    
    return features, ""

if __name__ == "__main__":
    test_images = [
        # Valid fundus
        r"d:\SIH-26038\messidor-2\preprocess\20051020_43808_0100_PP.png",
        r"d:\SIH-26038\messidor-2\preprocess\20051020_44261_0100_PP.png",
        # Negative examples
        r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\human_face_1789452046787.png",
        r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\landscape_1789452071464.png",
        r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\document_1789452228703.png",
        r"d:\SIH-26038\dashboard\img\oculaai_logo.png"
    ]
    
    # Let's also find the user's uploaded scenery image and add it
    import glob
    uploads = glob.glob(r"d:\SIH-26038\dashboard\uploads\*.jpeg")
    if uploads:
        test_images.append(uploads[-1]) # probably the scenery
        test_images.append(uploads[-2]) # another one
    
    print(f"{'Filename':<20} | {'FOV':<5} | {'R>G>B':<5} | {'G-B':<5} | {'stdG':<5} | {'cDist':<5} | {'stdXYr':<6} | {'bDark':<5}")
    print("-" * 80)
    for p in test_images:
        if os.path.exists(p):
            feat, msg = extract_features(p)
            if feat:
                rgb_ok = feat['mean_r'] > feat['mean_g'] and feat['mean_g'] > feat['mean_b']
                print(f"{Path(p).name[:20]:<20} | {feat['fov_ratio']:.2f} | {str(rgb_ok):<5} | {feat['gb_diff']:5.1f} | {feat['std_g']:4.1f} | {feat['center_dist']:4.2f} | {feat['std_ratio']:4.2f} | {feat['border_dark']:4.2f}")
            else:
                print(f"{Path(p).name[:20]:<20} | ERROR: {msg}")
        else:
            print(f"{Path(p).name[:20]:<20} | File not found")
