import numpy as np
from PIL import Image

def score_image(image_path):
    img = Image.open(image_path).convert('RGB')
    img = img.resize((256, 256))
    arr = np.array(img)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    mask = gray > 15
    fov_ratio = float(np.sum(mask) / mask.size)
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
    
    print(f"  Raw: FOV={fov_ratio:.3f} bDark={border_dark_ratio:.3f} R={mean_r:.1f} G={mean_g:.1f} B={mean_b:.1f} R-G={rg_gap:.1f} G-B={gb_gap:.1f} stdG={std_g:.1f}")

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
    
    for k in scores:
        print(f"    {k}: {scores[k]:.1f} (weight {weights[k]})")
    print(f"  FINAL SCORE: {final_score:.3f}")
    return final_score

p = r"C:\Users\LENOVO\.gemini\antigravity-ide\brain\55b90fbe-6c6d-4b29-a132-f80136a218ca\human_face_1789452046787.png"
print("HUMAN FACE:")
score_image(p)
