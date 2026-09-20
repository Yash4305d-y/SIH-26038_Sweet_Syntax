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
import threading
from datetime import datetime, timezone
from pathlib import Path
from flask import Flask, request, jsonify, send_from_directory, send_file

# ── Configuration ──
DASHBOARD_DIR = Path(__file__).parent.resolve()
PROJECT_DIR = DASHBOARD_DIR.parent.resolve()
UPLOAD_DIR = DASHBOARD_DIR / 'uploads'
GRADCAM_DIR = DASHBOARD_DIR / 'gradcam_output'
DATA_DIR = DASHBOARD_DIR / 'data'
RESULTS_DIR = PROJECT_DIR / 'results'
OUTPUTS_DIR = PROJECT_DIR / 'outputs'

UPLOAD_DIR.mkdir(exist_ok=True)
GRADCAM_DIR.mkdir(exist_ok=True)
DATA_DIR.mkdir(exist_ok=True)

CASES_FILE = DATA_DIR / 'cases.json'

class CaseManager:
    def __init__(self, filepath):
        self.filepath = Path(filepath)
        self.lock = threading.Lock()
        if not self.filepath.exists():
            self._save({})

    def _load(self):
        try:
            with open(self.filepath, 'r') as f:
                return json.load(f)
        except Exception:
            return {}

    def _save(self, data):
        with open(self.filepath, 'w') as f:
            json.dump(data, f, indent=2)

    def create_case(self, ml_result, image_id):
        with self.lock:
            cases = self._load()
            date_str = datetime.now(timezone.utc).strftime("%Y%m%d")
            import uuid
            suffix = str(uuid.uuid4())[:6].upper()
            case_id = f"CASE-{date_str}-{suffix}"
            
            is_referable = ml_result.get('referableStatus') == 'Referable'
            referral_id = f"REF-{date_str}-{suffix}" if is_referable else None
            follow_up_status = "REFERRED" if is_referable else "NOT_REFERRED"
            
            case_data = {
                "case_id": case_id,
                "referral_id": referral_id,
                "ai_grade": ml_result.get('predictedGrade'),
                "ai_referable_probability": ml_result.get('calibratedReferableProbability'),
                "calibration_version": ml_result.get('calibrationVersion', 'baseline-resnet50-v1'),
                "model_version": ml_result.get('modelVersion', '1.0'),
                "specialist_grade": None,
                "agreement": None,
                "follow_up_status": follow_up_status,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "image_id": image_id,
                "iqa_pass": ml_result.get('iqa', {}).get('pass', False),
                "referable_decision": ml_result.get('referableStatus'),
                "morphology": ml_result.get('morphology', {})
            }
            cases[case_id] = case_data
            self._save(cases)
            return case_data

    def get_case(self, case_id):
        with self.lock:
            return self._load().get(case_id)

    def list_cases(self):
        with self.lock:
            return list(self._load().values())

    def update_specialist_grade(self, case_id, grade, review_duration_seconds=None):
        if grade not in [0, 1, 2, 3, 4]:
            return False, "Invalid specialist grade. Must be 0-4."
        with self.lock:
            cases = self._load()
            if case_id not in cases:
                return False, "Case not found."
            case = cases[case_id]
            case["specialist_grade"] = grade
            ai_grade = case.get("ai_grade")
            if ai_grade is not None:
                case["agreement"] = "AGREE" if ai_grade == grade else "DISAGREE"
            
            if review_duration_seconds is not None:
                case["review_duration_seconds"] = review_duration_seconds
                
            self._save(cases)
            return True, case

    def update_follow_up(self, case_id, status):
        with self.lock:
            cases = self._load()
            if case_id not in cases:
                return False, "Case not found."
            case = cases[case_id]
            curr = case["follow_up_status"]
            valid = False
            if curr == "REFERRED" and status in ["SEEN", "LOST_TO_FOLLOWUP"]:
                valid = True
            elif curr == "SEEN" and status == "COMPLETED":
                valid = True
            
            if not valid:
                return False, f"Invalid transition from {curr} to {status}."
            case["follow_up_status"] = status
            self._save(cases)
            return True, case

case_manager = CaseManager(CASES_FILE)

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


@app.route('/cases.html')
def serve_cases():
    return send_from_directory(str(DASHBOARD_DIR), 'cases.html')


@app.route('/adaptation.html')
def serve_adaptation():
    return send_from_directory(str(DASHBOARD_DIR), 'adaptation.html')


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

    # Validate that it is actually a retinal image
    is_valid_retina, msg = validate_retinal_image(str(saved_path))
    print(f"\n{'='*50}")
    print(f"[DEBUG] IMAGE ID: {saved_filename}")
    print(f"[DEBUG] GATE STATUS: {'PASS' if is_valid_retina else 'FAIL'}")
    print(f"[DEBUG] GATE REASON: {msg}")
    print(f"{'='*50}\n")
    
    if not is_valid_retina:
        # FAIL-CLOSED GUARD: DO NOT CALL INFERENCE
        print("[DEBUG] INFERENCE EXECUTED: NO (REJECTED BY GATE)")
        return jsonify({
            'success': False, 
            'errorType': 'NON_RETINAL',
            'errorMessage': 'Image not recognized as a retinal/fundus photograph.',
            'guidance': 'Please upload or capture a clear retinal/fundus image for diabetic-retinopathy screening.'
        }), 200

    print(f"Calling MATLAB DR inference for {saved_filename}...")

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

    iqa_result = result.get('iqa', {})
    if not iqa_result.get('pass', True):
        print(f"[DEBUG] IQA STATUS: FAIL ({iqa_result.get('reason', 'Unknown')})")
        print("[DEBUG] INFERENCE EXECUTED: NO (IQA FAILED)")
    else:
        print("[DEBUG] IQA STATUS: PASS")
        print("[DEBUG] INFERENCE EXECUTED: YES")
        
        # Only create a case if the inference returned success
        if result.get('success'):
            case = case_manager.create_case(result, saved_filename)
            result['case_id'] = case['case_id']
            result['referral_id'] = case['referral_id']
            result['follow_up_status'] = case['follow_up_status']
            result['calibrationVersion'] = case['calibration_version']
            result['modelVersion'] = case['model_version']

    # Add the gradcam URL if applicable
    gradcam_path = GRADCAM_DIR / f'{image_id}_gradcam.png'
    if gradcam_path.exists():
        result['gradcam_url'] = f'/gradcam_output/{image_id}_gradcam.png'
    elif 'gradcam_url' not in result:
        result['gradcam_url'] = None

    return jsonify(result)


# ── API Endpoints for Case Management ──

@app.route('/api/cases', methods=['GET'])
def get_cases():
    return jsonify(case_manager.list_cases())

@app.route('/api/cases/<case_id>', methods=['GET'])
def get_case_by_id(case_id):
    case = case_manager.get_case(case_id)
    if case:
        return jsonify(case)
    return jsonify({'error': 'Case not found'}), 404

@app.route('/api/cases/<case_id>/specialist', methods=['PUT'])
def update_specialist(case_id):
    data = request.json
    if not data or 'specialist_grade' not in data:
        return jsonify({'error': 'specialist_grade is required'}), 400
    grade = data['specialist_grade']
    
    review_duration_seconds = data.get('review_duration_seconds')
    if review_duration_seconds is not None:
        try:
            review_duration_seconds = float(review_duration_seconds)
            import math
            if math.isnan(review_duration_seconds) or math.isinf(review_duration_seconds):
                review_duration_seconds = None
        except (ValueError, TypeError):
            review_duration_seconds = None
            
    success, result = case_manager.update_specialist_grade(case_id, grade, review_duration_seconds)
    if success:
        return jsonify(result)
    return jsonify({'error': result}), 400

@app.route('/api/cases/<case_id>/follow_up', methods=['PUT'])
def update_follow_up(case_id):
    data = request.json
    if not data or 'status' not in data:
        return jsonify({'error': 'status is required'}), 400
    status = data['status']
    success, result = case_manager.update_follow_up(case_id, status)
    if success:
        return jsonify(result)
    return jsonify({'error': result}), 400

# ── API Endpoints for Controlled Adaptation ──
@app.route('/api/adaptation', methods=['GET'])
def get_adaptation():
    handoff_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'outputs', 'evaluation', 'adaptation_handoff_package.json')
    if not os.path.exists(handoff_path):
        return jsonify({'error': 'Adaptation handoff package not found'}), 404
    try:
        import json
        with open(handoff_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return jsonify(data)
    except Exception as e:
        return jsonify({'error': 'Malformed adaptation handoff package', 'details': str(e)}), 500

# ── MATLAB Integration Methods ──

def run_matlab_engine(image_path):
    """Run inference using MATLAB Engine API for Python."""
    try:
        import matlab.engine
        print('[INFO] Starting MATLAB Engine...')
        eng = matlab.engine.start_matlab()
        eng.addpath(eng.genpath(str(PROJECT_DIR / 'modules')), nargout=0)

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
            f"addpath(genpath('{PROJECT_DIR / 'modules'}')); "
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


def validate_retinal_image(image_path):
    """
    Check if the image is plausibly a retinal/fundus photograph.
    
    Uses a weighted scoring system across multiple signals rather than
    hard pass/fail thresholds. This avoids false rejections of genuine
    fundus images that may have borderline values on a single metric
    (e.g. slightly bright borders, slightly high texture variance).
    
    A non-retinal image (scenery, face, document) will fail MANY signals
    simultaneously, producing a very low score. A genuine fundus image
    may have one borderline metric but will score well overall.
    
    Limitations: This is a heuristic suitability check, not a medically
    validated fundus classifier. It provides a safety gate to block
    obviously non-retinal inputs before the locked DR inference model.
    """
    try:
        import numpy as np
        from PIL import Image
        img = Image.open(image_path).convert('RGB')
        img = img.resize((256, 256))
        arr = np.array(img)
    except Exception as e:
        return False, f"ERROR: Invalid image file: {e}"

    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]

    # Extract grayscale and FOV mask
    gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
    mask = gray > 15
    fov_ratio = float(np.sum(mask) / mask.size)

    if np.sum(mask) == 0:
        return False, "Empty image (no bright pixels)"

    mean_r = float(np.mean(r[mask]))
    mean_g = float(np.mean(g[mask]))
    mean_b = float(np.mean(b[mask]))
    std_g = float(np.std(g[mask]))

    # Border dark ratio (edges of the image)
    border_pixels = np.concatenate([
        gray[:13, :].flatten(),
        gray[-13:, :].flatten(),
        gray[:, :13].flatten(),
        gray[:, -13:].flatten()
    ])
    border_dark_ratio = float(np.sum(border_pixels <= 15) / len(border_pixels))

    rg_gap = mean_r - mean_g
    gb_gap = mean_g - mean_b

    # ── Scoring system ──
    # Each signal contributes 0.0 (strongly non-fundus) to 1.0 (strongly fundus).
    # The final score is a weighted average. Rejection threshold: < 0.45
    scores = {}

    # Signal 1: FOV ratio (weight 2)
    # Fundus images typically have 0.3-0.85 FOV ratio (circular field with dark border)
    # Full-bleed photos (>0.97) are almost certainly not fundus
    if fov_ratio > 0.97:
        scores['fov'] = 0.0
    elif fov_ratio > 0.95:
        scores['fov'] = 0.2
    elif fov_ratio > 0.90:
        scores['fov'] = 0.5
    elif 0.2 <= fov_ratio <= 0.90:
        scores['fov'] = 1.0
    elif fov_ratio >= 0.15:
        scores['fov'] = 0.5
    else:
        scores['fov'] = 0.0

    # Signal 2: Border darkness (weight 2)
    # Fundus images have dark corners/edges from the circular lens
    if border_dark_ratio > 0.5:
        scores['border'] = 1.0
    elif border_dark_ratio > 0.2:
        scores['border'] = 0.8
    elif border_dark_ratio > 0.1:
        scores['border'] = 0.4
    else:
        scores['border'] = 0.0

    # Signal 3: Red-Green dominance (weight 3 — strongest fundus indicator)
    # Fundus images are deeply reddish-orange: R >> G >> B
    if rg_gap > 30:
        scores['rg_dom'] = 1.0
    elif rg_gap > 15:
        scores['rg_dom'] = 0.8
    elif rg_gap > 5:
        scores['rg_dom'] = 0.3
    else:
        scores['rg_dom'] = 0.0

    # Signal 4: Green > Blue (weight 1)
    if gb_gap > 20:
        scores['gb'] = 1.0
    elif gb_gap > 0:
        scores['gb'] = 0.7
    else:
        scores['gb'] = 0.0

    # Signal 5: Texture variance in green channel (weight 1)
    # Fundus images have moderate variance (8-40); scenery/faces have very high (>50)
    if 8 <= std_g <= 40:
        scores['texture'] = 1.0
    elif 5 <= std_g <= 45:
        scores['texture'] = 0.6
    elif std_g > 60:
        scores['texture'] = 0.0
    else:
        scores['texture'] = 0.2

    # Weighted average
    weights = {'fov': 2, 'border': 2, 'rg_dom': 3, 'gb': 1, 'texture': 1}
    total_weight = sum(weights.values())
    weighted_sum = sum(scores[k] * weights[k] for k in scores)
    final_score = weighted_sum / total_weight

    # Threshold: 0.45 means image must score well on a combination of signals
    # A genuine fundus image scores 0.7+ even with one borderline metric
    # A scenery/face/document scores < 0.3 because it fails most signals
    THRESHOLD = 0.50

    reason_parts = [f"{k}={scores[k]:.1f}" for k in scores]
    detail = f"score={final_score:.2f} ({', '.join(reason_parts)})"

    if final_score >= THRESHOLD:
        return True, f"PASS ({detail})"
    else:
        # Find the worst signals for a helpful message
        worst = sorted(scores.items(), key=lambda x: x[1])
        worst_names = [f"{k}={v:.1f}" for k, v in worst[:3]]
        return False, f"FAIL ({detail}) worst: {', '.join(worst_names)}"


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
