import os
from pathlib import Path
import numpy as np
from PIL import Image
import glob

def check_fundus(image_path):
    try:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((256, 256))
        arr = np.array(img)
    except Exception as e:
        return False, "Invalid image file"

    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    mask = gray > 15
    fov_ratio = np.sum(mask) / mask.size

    if fov_ratio > 0.95 or fov_ratio < 0.2:
        return False, f"Invalid FOV ratio ({fov_ratio:.2f})"
        
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
    
    if border_dark_ratio < 0.2:
        return False, f"Border too bright (bDark={border_dark_ratio:.2f})"
        
    if mean_r < (mean_g + 15):
        return False, f"Red channel not dominant enough (R-G={mean_r-mean_g:.1f})"
        
    if mean_g < mean_b:
        return False, f"Green channel lower than Blue (G-B={mean_g-mean_b:.1f})"
        
    if std_g > 35 or std_g < 5:
        return False, f"Invalid texture variance (stdG={std_g:.1f})"
        
    return True, "PASS"

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
    uploads = glob.glob(r"d:\SIH-26038\dashboard\uploads\*.jpeg") + glob.glob(r"d:\SIH-26038\dashboard\uploads\*.png")
    test_images.extend(uploads[-20:])
    
    print(f"{'Filename':<25} | {'Result':<6} | {'Reason'}")
    print("-" * 80)
    for p in test_images:
        res, msg = check_fundus(p)
        print(f"{Path(p).name[:25]:<25} | {'PASS' if res else 'FAIL':<6} | {msg}")
