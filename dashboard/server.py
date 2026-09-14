"""
RETINA-AI Dashboard — Flask Backend Server
SIH-26038 Diabetic Retinopathy Screening

This server:
1. Serves the static dashboard frontend
2. Receives image uploads via POST /api/predict
3. Calls MATLAB runDRInference (or mock mode if MATLAB unavailable)
4. Returns the inference result as JSON

Run: python server.py
"""

import os
import sys
import json
import uuid
import shutil
import tempfile
import subprocess
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory, send_file

# ── Configuration ──
DASHBOARD_DIR = Path(__file__).parent.resolve()
PROJECT_DIR = DASHBOARD_DIR.parent.resolve()
UPLOAD_DIR = DASHBOARD_DIR / 'uploads'
GRADCAM_DIR = DASHBOARD_DIR / 'gradcam_output'
RESULTS_DIR = PROJECT_DIR / 'results'
OUTPUTS_DIR = PROJECT_DIR / 'outputs'

UPLOAD_DIR.mkdir(exist_ok=True)
GRADCAM_DIR.mkdir(exist_ok=True)

# Check if MATLAB is available
MATLAB_AVAILABLE = shutil.which('matlab') is not None
MATLAB_ENGINE_AVAILABLE = False

try:
    import matlab.engine
    MATLAB_ENGINE_AVAILABLE = True
except ImportError:
    pass

# ── Flask App ──
app = Flask(__name__, static_folder=str(DASHBOARD_DIR))


# ── Static File Serving ──

@app.route('/')
def serve_index():
    return send_from_directory(str(DASHBOARD_DIR), 'index.html')


@app.route('/css/<path:filename>')
def serve_css(filename):
    return send_from_directory(str(DASHBOARD_DIR / 'css'), filename)


@app.route('/js/<path:filename>')
def serve_js(filename):
    return send_from_directory(str(DASHBOARD_DIR / 'js'), filename)


@app.route('/gradcam_output/<path:filename>')
def serve_gradcam(filename):
    return send_from_directory(str(GRADCAM_DIR), filename)


@app.route('/uploads/<path:filename>')
def serve_upload(filename):
    return send_from_directory(str(UPLOAD_DIR), filename)


@app.route('/results/<path:filename>')
def serve_results(filename):
    return send_from_directory(str(RESULTS_DIR), filename)


@app.route('/outputs/<path:filename>')
def serve_outputs(filename):
    return send_from_directory(str(OUTPUTS_DIR), filename)


# ── API Endpoint ──

@app.route('/api/predict', methods=['POST'])
def predict():
    """
    Receives a retinal fundus image and returns DR inference results.
    
    Tries MATLAB Engine API first, then subprocess, then falls back to mock mode.
    """
    if 'image' not in request.files:
        return jsonify({'success': False, 'errorMessage': 'No image file provided'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'success': False, 'errorMessage': 'Empty filename'}), 400

    # Save uploaded image
    ext = Path(file.filename).suffix.lower()
    if ext not in ['.jpg', '.jpeg', '.png']:
        return jsonify({'success': False, 'errorMessage': 'Unsupported file type. Use .jpg or .png'}), 400

    image_id = str(uuid.uuid4())[:8]
    saved_filename = f'{image_id}{ext}'
    saved_path = UPLOAD_DIR / saved_filename
    file.save(str(saved_path))

    print(f'[INFO] Image saved: {saved_path}')

    # Try to run MATLAB inference
    result = None

    # Method 1: MATLAB Engine API
    if MATLAB_ENGINE_AVAILABLE and result is None:
        result = run_matlab_engine(str(saved_path))

    # Method 2: MATLAB subprocess
    if MATLAB_AVAILABLE and result is None:
        result = run_matlab_subprocess(str(saved_path))

    # Method 3: Mock mode (development fallback)
    if result is None:
        print('[WARN] MATLAB not available. Using mock inference mode.')
        result = generate_mock_result(str(saved_path))

    # Add the gradcam URL if applicable
    gradcam_path = GRADCAM_DIR / f'{image_id}_gradcam.png'
    if gradcam_path.exists():
        result['gradcam_url'] = f'/gradcam_output/{image_id}_gradcam.png'
    elif 'gradcam_url' not in result:
        result['gradcam_url'] = None

    return jsonify(result)


# ── MATLAB Integration Methods ──

def run_matlab_engine(image_path):
    """Run inference using MATLAB Engine API for Python."""
    try:
        import matlab.engine
        print('[INFO] Starting MATLAB Engine...')
        eng = matlab.engine.start_matlab()
        eng.addpath(str(PROJECT_DIR / 'src'), nargout=0)

        json_str = eng.runUnifiedPipeline(image_path, True)
        eng.quit()

        result = json.loads(json_str)

        # Save Grad-CAM if available
        if 'gradCAM' in result and isinstance(result['gradCAM'], list) and len(result['gradCAM']) > 0:
            save_gradcam_from_matlab(result['gradCAM'], image_path)
            del result['gradCAM']

        return result
    except Exception as e:
        print(f'[ERROR] MATLAB Engine failed: {e}')
        return None


def run_matlab_subprocess(image_path):
    """Run inference by calling MATLAB as a subprocess."""
    try:
        # Build the MATLAB command
        matlab_cmd = (
            f"addpath('{PROJECT_DIR / 'src'}'); "
            f"disp(runUnifiedPipeline('{image_path}', true)); "
            f"exit;"
        )

        print('[INFO] Running MATLAB subprocess...')
        proc = subprocess.run(
            ['matlab', '-batch', matlab_cmd],
            capture_output=True,
            text=True,
            timeout=120,
            cwd=str(PROJECT_DIR)
        )

        if proc.returncode != 0:
            print(f'[ERROR] MATLAB subprocess error: {proc.stderr}')
            return None

        # Extract JSON from stdout (find the JSON block)
        output = proc.stdout.strip()
        json_start = output.find('{')
        json_end = output.rfind('}') + 1

        if json_start == -1 or json_end == 0:
            print(f'[ERROR] Could not find JSON in MATLAB output')
            return None

        json_str = output[json_start:json_end]
        result = json.loads(json_str)
        
        # Save Grad-CAM if available
        if 'gradCAM' in result and isinstance(result['gradCAM'], list) and len(result['gradCAM']) > 0:
            save_gradcam_from_matlab(result['gradCAM'], image_path)
            del result['gradCAM']
            
        return result

    except subprocess.TimeoutExpired:
        print('[ERROR] MATLAB subprocess timed out')
        return None
    except Exception as e:
        print(f'[ERROR] MATLAB subprocess failed: {e}')
        return None


def generate_mock_result(image_path):
    """
    Generate a realistic mock inference result for development.
    
    This uses randomized but structurally valid data matching the exact
    output format of runDRInference.m. Clearly labelled as MOCK.
    """
    import random
    import math

    # Generate random but realistic probabilities
    # Pick a dominant class
    dominant_class = random.randint(0, 4)
    raw_probs = [random.uniform(0.01, 0.08) for _ in range(5)]
    raw_probs[dominant_class] = random.uniform(0.55, 0.95)

    # Normalize to sum to 1
    total = sum(raw_probs)
    probs = [p / total for p in raw_probs]

    predicted_grade = probs.index(max(probs))
    max_prob = max(probs)

    # Referable probability = P(2) + P(3) + P(4)
    referable_prob = probs[2] + probs[3] + probs[4]

    # Simulate Platt scaling calibration
    calibrated_ref_prob = 1 / (1 + math.exp(-(3.5 * referable_prob - 1.2)))

    threshold = 0.22
    referable_status = 'Referable' if calibrated_ref_prob >= threshold else 'Non-referable'

    result = {
        'modelName': 'Baseline ResNet-50',
        'modelVersion': '1.0',
        'modelStatus': 'LOCKED',
        'predictedGrade': predicted_grade,
        'classLabels': [0, 1, 2, 3, 4],
        'probabilities': [round(p, 6) for p in probs],
        'predictedClassProbability': round(max_prob, 6),
        'confidence': round(max_prob, 6),
        'referableProbability': round(referable_prob, 6),
        'calibratedReferableProbability': round(calibrated_ref_prob, 6),
        'referableThreshold': threshold,
        'referableStatus': referable_status,
        'calibrationMethod': 'Platt scaling',
        'uncertaintyStatus': 'Not implemented in frozen inference interface',
        'gradCAM': None,
        'gradcam_url': None,
        'success': True,
        'errorMessage': '',
        'iqa': {
            'focusScore': 0.00005,
            'illumination': {
                'meanIntensity': 0.45,
                'darkPixelRatio': 0.10,
                'brightPixelRatio': 0.05
            },
            'fov': {
                'areaRatio': 0.35,
                'circularity': 0.85
            },
            'focusPass': True,
            'illuminationPass': True,
            'fovPass': True,
            'pass': True,
            'reason': 'PASS'
        },
        '_mock': True,
        '_mockNote': 'MATLAB not available. This is simulated data for UI development.'
    }

    return result


def save_gradcam_from_matlab(gradcam_data, image_path):
    """Save Grad-CAM array as a PNG overlay image."""
    try:
        import numpy as np
        from PIL import Image
        import matplotlib.pyplot as plt

        # Load and resize original image
        orig_img = Image.open(image_path).convert('RGB')
        orig_img = orig_img.resize((224, 224))
        orig_arr = np.array(orig_img).astype(np.float32) / 255.0

        heatmap = np.array(gradcam_data)
        heatmap = (heatmap - heatmap.min()) / (heatmap.max() - heatmap.min() + 1e-8)
        
        # Apply colormap (jet)
        cmap = plt.get_cmap('jet')
        heatmap_colored = cmap(heatmap)
        heatmap_rgb = heatmap_colored[:, :, :3]
        
        # Blend 50% original image and 50% heatmap
        overlay = 0.5 * orig_arr + 0.5 * heatmap_rgb
        overlay_uint8 = (overlay * 255).astype(np.uint8)

        img = Image.fromarray(overlay_uint8)

        image_id = Path(image_path).stem
        output_path = GRADCAM_DIR / f'{image_id}_gradcam.png'
        img.save(str(output_path))

    except Exception as e:
        print(f'[WARN] Could not save Grad-CAM image: {e}')


# ── Main ──

if __name__ == '__main__':
    print('=' * 60)
    print('  RETINA-AI Dashboard Server')
    print('  SIH-26038 Diabetic Retinopathy Screening')
    print('=' * 60)
    print(f'  Project dir:    {PROJECT_DIR}')
    print(f'  Dashboard dir:  {DASHBOARD_DIR}')
    print(f'  MATLAB Engine:  {"Available" if MATLAB_ENGINE_AVAILABLE else "Not installed"}')
    print(f'  MATLAB CLI:     {"Available" if MATLAB_AVAILABLE else "Not found on PATH"}')

    if not MATLAB_ENGINE_AVAILABLE and not MATLAB_AVAILABLE:
        print()
        print('  ⚠  MATLAB not available — running in MOCK MODE')
        print('     Install MATLAB Engine API for Python or ensure')
        print('     matlab is on your PATH for real inference.')
    
    print()
    print('  Dashboard: http://localhost:5050')
    print('=' * 60)

    app.run(host='0.0.0.0', port=5050, debug=True)
