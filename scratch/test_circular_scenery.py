import os
import numpy as np
from PIL import Image

def test_circular_scenery():
    img_path = r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\landscape_1789452071464.png"
    img = Image.open(img_path).convert('RGB')
    img = img.resize((256, 256))
    arr = np.array(img)
    
    # Create circular mask
    Y, X = np.ogrid[:256, :256]
    dist_from_center = np.sqrt((X - 128)**2 + (Y-128)**2)
    mask = dist_from_center <= 100
    
    # Apply mask
    arr[~mask] = 0
    
    # Now run validation logic on arr
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    valid_mask = gray > 15
    
    fov_ratio = np.sum(valid_mask) / valid_mask.size
    print(f"FOV: {fov_ratio:.2f}")
    
    mean_r = np.mean(r[valid_mask])
    mean_g = np.mean(g[valid_mask])
    mean_b = np.mean(b[valid_mask])
    std_g = np.std(g[valid_mask])
    
    print(f"R: {mean_r:.1f}, G: {mean_g:.1f}, B: {mean_b:.1f}")
    print(f"R-G: {mean_r-mean_g:.1f}")
    print(f"G-B: {mean_g-mean_b:.1f}")
    print(f"stdG: {std_g:.1f}")

test_circular_scenery()
