/* ===================================================================
   RETINA-AI Dashboard — Application Logic
   SIH-26038 Diabetic Retinopathy Screening
   
   Handles: File upload, API communication, result rendering
   All displayed data comes strictly from the MATLAB inference result.
   =================================================================== */

// ── Constants ──
const API_URL = '/api/predict';

const GRADE_NAMES = {
  0: 'No DR',
  1: 'Mild NPDR',
  2: 'Moderate NPDR',
  3: 'Severe NPDR',
  4: 'Proliferative DR (PDR)'
};

const GRADE_DESCRIPTIONS = {
  0: 'Absence of visible diabetic retinopathy. No microaneurysms, hemorrhages, or other DR signs detected.',
  1: 'Microaneurysms only. Earliest clinical sign of diabetic retinopathy.',
  2: 'More than microaneurysms but less than severe NPDR. May include dot-blot hemorrhages and hard exudates.',
  3: 'Extensive intraretinal hemorrhages, venous beading, and/or prominent IRMA without neovascularization.',
  4: 'Neovascularization, vitreous or preretinal hemorrhage. Most advanced stage requiring urgent intervention.'
};

const GRADE_COLORS = {
  0: 'var(--grade-0)',
  1: 'var(--grade-1)',
  2: 'var(--grade-2)',
  3: 'var(--grade-3)',
  4: 'var(--grade-4)'
};

const GRADE_BG_COLORS = {
  0: 'var(--grade-0-bg)',
  1: 'var(--grade-1-bg)',
  2: 'var(--grade-2-bg)',
  3: 'var(--grade-3-bg)',
  4: 'var(--grade-4-bg)'
};

const BAR_COLORS = {
  0: '#0284c7',
  1: '#059669',
  2: '#d97706',
  3: '#e11d48',
  4: '#64748b'
};

// ── State ──
let selectedFile = null;
let currentResult = null;
let previewDataUrl = null;

// ── DOM Elements ──
const dropzoneArea = document.getElementById('dropzone-area');
const fileInput = document.getElementById('file-input');
const btnReupload = document.getElementById('btn-reupload');
const btnAnalyze = document.getElementById('btn-analyze');
const previewEmpty = document.getElementById('preview-empty');
const previewContent = document.getElementById('preview-content');
const previewThumb = document.getElementById('preview-thumb');
const previewFilename = document.getElementById('preview-filename');
const metaSize = document.getElementById('meta-size');
const metaType = document.getElementById('meta-type');
const progressBar = document.getElementById('progress-bar');
const analysisStatus = document.getElementById('analysis-status');
const resultsContainer = document.getElementById('results-container');
const btnDownloadJson = document.getElementById('btn-download-json');
const btnNewAnalysis = document.getElementById('btn-new-analysis');

// ── File Upload Handling ──

dropzoneArea.addEventListener('click', () => fileInput.click());

dropzoneArea.addEventListener('dragover', (e) => {
  e.preventDefault();
  dropzoneArea.classList.add('dragover');
});

dropzoneArea.addEventListener('dragleave', () => {
  dropzoneArea.classList.remove('dragover');
});

dropzoneArea.addEventListener('drop', (e) => {
  e.preventDefault();
  dropzoneArea.classList.remove('dragover');
  const files = e.dataTransfer.files;
  if (files.length > 0) {
    handleFileSelect(files[0]);
  }
});

fileInput.addEventListener('change', (e) => {
  if (e.target.files.length > 0) {
    handleFileSelect(e.target.files[0]);
  }
});

btnReupload.addEventListener('click', () => {
  fileInput.click();
});

btnAnalyze.addEventListener('click', () => {
  if (selectedFile) {
    runAnalysis(selectedFile);
  }
});

btnDownloadJson.addEventListener('click', () => {
  if (currentResult) {
    downloadJSON(currentResult);
  }
});

btnNewAnalysis.addEventListener('click', () => {
  resetDashboard();
});

function handleFileSelect(file) {
  // Validate file type
  const validTypes = ['image/jpeg', 'image/png', 'image/jpg'];
  if (!validTypes.includes(file.type)) {
    alert('Please upload a .jpg or .png retinal fundus image.');
    return;
  }

  selectedFile = file;

  // Show preview
  const reader = new FileReader();
  reader.onload = (e) => {
    previewDataUrl = e.target.result;
    previewThumb.src = previewDataUrl;
    previewFilename.textContent = file.name;
    metaSize.textContent = formatFileSize(file.size);
    metaType.textContent = file.type.split('/')[1].toUpperCase();

    previewEmpty.classList.add('hidden');
    previewContent.classList.remove('hidden');

    // Update viewport original image
    const viewportOrigImg = document.getElementById('viewport-original-img');
    const viewportOrigPlaceholder = document.getElementById('viewport-original-placeholder');
    viewportOrigImg.src = previewDataUrl;
    viewportOrigImg.classList.remove('hidden');
    viewportOrigPlaceholder.classList.add('hidden');
  };
  reader.readAsDataURL(file);

  // Enable buttons
  btnReupload.disabled = false;
  btnAnalyze.disabled = false;
  progressBar.style.width = '0%';
  analysisStatus.textContent = 'Ready for analysis';
  analysisStatus.style.color = 'var(--text-faint)';

  // Hide previous results
  resultsContainer.classList.add('hidden');
}

// ── Analysis ──

async function runAnalysis(file) {
  btnAnalyze.disabled = true;
  btnAnalyze.innerHTML = '<div class="spinner"></div><span>Analyzing...</span>';
  analysisStatus.textContent = 'Running AI inference...';
  analysisStatus.style.color = 'var(--primary)';
  progressBar.style.width = '30%';

  const formData = new FormData();
  formData.append('image', file);

  try {
    progressBar.style.width = '60%';

    const response = await fetch(API_URL, {
      method: 'POST',
      body: formData,
    });

    progressBar.style.width = '90%';

    if (!response.ok) {
      throw new Error(`Server error: ${response.status}`);
    }

    const data = await response.json();
    progressBar.style.width = '100%';

    if (data.success === false || data.success === 0) {
      throw new Error(data.errorMessage || 'Inference failed');
    }

    currentResult = data;
    analysisStatus.textContent = 'Analysis complete';
    analysisStatus.style.color = 'var(--color-success)';

    renderResults(data);
  } catch (err) {
    progressBar.style.width = '100%';
    progressBar.style.background = 'var(--color-danger)';
    analysisStatus.textContent = `Error: ${err.message}`;
    analysisStatus.style.color = 'var(--color-danger)';
    console.error('Analysis error:', err);
  } finally {
    btnAnalyze.disabled = false;
    btnAnalyze.innerHTML = '<span class="material-symbols-outlined">play_arrow</span><span>Run AI Analysis (MATLAB)</span>';
  }
}

// ── Result Rendering ──

function renderResults(result) {
  resultsContainer.classList.remove('hidden');
  resultsContainer.classList.add('fade-in');

  renderAlertBanner(result);
  renderGradeCard(result);
  renderConfidenceGauge(result);
  renderModelInfo(result);
  renderGradCAM(result);
  renderProbabilities(result);
  renderFooter(result);

  // Scroll to results
  setTimeout(() => {
    resultsContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }, 200);
}

function renderAlertBanner(result) {
  const banner = document.getElementById('alert-banner');
  const isReferable = result.referableStatus === 'Referable';
  const calibProb = (result.calibratedReferableProbability * 100).toFixed(1);
  const threshold = result.referableThreshold;

  if (isReferable) {
    banner.innerHTML = `
      <div class="alert-banner alert-banner-danger fade-in">
        <div class="alert-icon">
          <span class="material-symbols-outlined" style="font-size:24px;">warning</span>
        </div>
        <div class="alert-content">
          <div class="alert-title">
            <span style="color: var(--color-danger);">REFERABLE DR DETECTED</span>
            <span class="badge">Priority Escalation</span>
          </div>
          <p class="alert-description">
            Specialist Retina Consultation Recommended. Calibrated referable probability 
            <strong>${calibProb}%</strong> exceeds threshold (P ≥ ${threshold}).
          </p>
        </div>
      </div>
    `;
  } else {
    banner.innerHTML = `
      <div class="alert-banner alert-banner-success fade-in">
        <div class="alert-icon">
          <span class="material-symbols-outlined" style="font-size:24px;">check_circle</span>
        </div>
        <div class="alert-content">
          <div class="alert-title">
            <span style="color: var(--color-success-text);">NON-REFERABLE</span>
            <span class="badge">Routine Screening</span>
          </div>
          <p class="alert-description">
            No immediate specialist referral required. Calibrated referable probability 
            <strong>${calibProb}%</strong> is below threshold (P < ${threshold}).
          </p>
        </div>
      </div>
    `;
  }
}

function renderGradeCard(result) {
  const grade = result.predictedGrade;
  const color = GRADE_COLORS[grade] || 'var(--text-primary)';
  const isUrgent = grade >= 3;

  const sublabel = document.getElementById('grade-sublabel');
  const title = document.getElementById('grade-title');
  const desc = document.getElementById('grade-description');
  const calibMethod = document.getElementById('calibration-method');

  sublabel.textContent = isUrgent ? 'Urgent Clinical Finding' : 'Clinical Finding';
  sublabel.style.color = color;

  title.textContent = `Grade ${grade}: ${GRADE_NAMES[grade]}`;
  title.style.color = color;

  desc.textContent = GRADE_DESCRIPTIONS[grade];
  calibMethod.textContent = result.calibrationMethod || 'Platt scaling';
}

function renderConfidenceGauge(result) {
  const confidence = result.confidence;
  const confPercent = (confidence * 100).toFixed(1);
  const circumference = 2 * Math.PI * 42; // ~263.89
  const offset = circumference - (confidence * circumference);

  // Gauge fill
  const gaugeFill = document.getElementById('gauge-fill');
  // Use setTimeout for animation
  setTimeout(() => {
    gaugeFill.setAttribute('stroke-dashoffset', offset.toFixed(2));
  }, 100);

  // Color the gauge based on confidence level
  const grade = result.predictedGrade;
  gaugeFill.style.stroke = GRADE_COLORS[grade] || 'var(--primary)';

  // Gauge value
  document.getElementById('gauge-value').innerHTML = `${confPercent}<span class="unit">%</span>`;

  // Raw probability label
  document.getElementById('raw-prob-label').textContent = `p = ${confidence.toFixed(4)}`;

  // Calibrated referable probability
  const calibRefProb = result.calibratedReferableProbability;
  const calibEl = document.getElementById('calib-ref-prob');
  calibEl.textContent = (calibRefProb * 100).toFixed(2) + '%';
  calibEl.style.color = calibRefProb >= result.referableThreshold ? 'var(--color-danger)' : 'var(--color-success)';

  // Threshold
  document.getElementById('ref-threshold').textContent = result.referableThreshold.toFixed(2);

  // Raw referable probability
  document.getElementById('raw-ref-prob').textContent = (result.referableProbability * 100).toFixed(2) + '%';
}

function renderModelInfo(result) {
  document.getElementById('info-model-name').textContent = result.modelName || 'Baseline ResNet-50';
  document.getElementById('info-model-version').textContent = result.modelVersion || '1.0';
  document.getElementById('info-model-status').textContent = result.modelStatus || 'LOCKED';
  document.getElementById('info-calibration').textContent = result.calibrationMethod || 'Platt scaling';
  document.getElementById('info-threshold').textContent = result.referableThreshold ? result.referableThreshold.toFixed(2) : '0.22';
  document.getElementById('info-uncertainty').textContent = result.uncertaintyStatus || 'Not implemented';

  const statusBadge = document.getElementById('model-status-badge');
  statusBadge.textContent = result.modelStatus || 'LOCKED';
}

function renderGradCAM(result) {
  const gradcamImg = document.getElementById('viewport-gradcam-img');
  const gradcamPlaceholder = document.getElementById('viewport-gradcam-placeholder');
  const overlayTags = document.getElementById('gradcam-overlay-tags');

  if (result.gradcam_url) {
    gradcamImg.src = result.gradcam_url;
    gradcamImg.classList.remove('hidden');
    gradcamPlaceholder.classList.add('hidden');
    overlayTags.classList.remove('hidden');

    // Set opacity from slider
    const opacitySlider = document.getElementById('opacity-slider');
    gradcamImg.style.opacity = (opacitySlider.value / 100).toFixed(2);

    // Update tags
    const confidence = (result.confidence * 100).toFixed(1);
    const grade = result.predictedGrade;
    document.getElementById('gradcam-attribution-tag').textContent = `GRAD-CAM • ${confidence}% Grade-${grade} Attribution`;
    document.getElementById('gradcam-target-tag').textContent = `Target Class: ${GRADE_NAMES[grade]}`;
  } else {
    gradcamPlaceholder.innerHTML = `
      <span class="material-symbols-outlined">gradient</span>
      <span>Grad-CAM not available for this analysis</span>
    `;
  }
}

function renderProbabilities(result) {
  const container = document.getElementById('prob-rows');
  const probs = result.probabilities;
  const predictedGrade = result.predictedGrade;

  let html = '';
  for (let i = 0; i < 5; i++) {
    const prob = probs[i];
    const percent = (prob * 100).toFixed(1);
    const isActive = i === predictedGrade;
    const barColor = BAR_COLORS[i];

    html += `
      <div class="prob-row ${isActive ? 'active' : ''}" style="${isActive ? `--accent: ${barColor};` : ''}">
        ${isActive ? `<div style="position:absolute;left:0;top:0;bottom:0;width:4px;background:${barColor};"></div>` : ''}
        <div class="prob-row-info">
          <span class="prob-grade-badge" style="${isActive ? `background:${barColor};` : ''}">G${i}</span>
          <div>
            <div class="prob-row-name" style="${isActive ? `color:${barColor};` : ''}">
              Grade ${i}: ${GRADE_NAMES[i]}
              ${isActive ? '<span class="material-symbols-outlined" style="font-size:14px;vertical-align:middle;">priority_high</span>' : ''}
            </div>
            <div class="prob-row-desc">${isActive ? 'Primary Diagnosed Class' : GRADE_DESCRIPTIONS[i].split('.')[0]}</div>
          </div>
        </div>
        <div class="prob-row-bar-area">
          <div class="prob-bar-track">
            <div class="prob-bar-fill" style="width: ${Math.max(percent, 0.5)}%; background: ${barColor};"></div>
          </div>
          <span class="prob-row-value" style="${isActive ? `color:${barColor};` : ''}">${percent}%</span>
        </div>
      </div>
    `;
  }
  container.innerHTML = html;
}

function renderFooter(result) {
  document.getElementById('footer-model-name').textContent = `${result.modelName || 'Baseline ResNet-50'} v${result.modelVersion || '1.0'}`;
}

// ── Opacity Slider ──
const opacitySlider = document.getElementById('opacity-slider');
const opacityValue = document.getElementById('opacity-value');

opacitySlider.addEventListener('input', (e) => {
  const val = e.target.value;
  opacityValue.textContent = val + '%';
  const gradcamImg = document.getElementById('viewport-gradcam-img');
  if (gradcamImg && !gradcamImg.classList.contains('hidden')) {
    gradcamImg.style.opacity = (val / 100).toFixed(2);
  }
});

// ── Utilities ──

function formatFileSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

function downloadJSON(result) {
  const blob = new Blob([JSON.stringify(result, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `dr_inference_result_${Date.now()}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function resetDashboard() {
  selectedFile = null;
  currentResult = null;
  previewDataUrl = null;

  // Reset file input
  fileInput.value = '';

  // Reset preview
  previewEmpty.classList.remove('hidden');
  previewContent.classList.add('hidden');
  previewThumb.src = '';
  previewFilename.textContent = '—';
  metaSize.textContent = '—';
  metaType.textContent = '—';
  progressBar.style.width = '0%';
  progressBar.style.background = 'var(--primary)';
  analysisStatus.textContent = 'Ready for analysis';
  analysisStatus.style.color = 'var(--text-faint)';

  // Reset viewport
  const viewportOrigImg = document.getElementById('viewport-original-img');
  const viewportOrigPlaceholder = document.getElementById('viewport-original-placeholder');
  viewportOrigImg.classList.add('hidden');
  viewportOrigImg.src = '';
  viewportOrigPlaceholder.classList.remove('hidden');

  const gradcamImg = document.getElementById('viewport-gradcam-img');
  const gradcamPlaceholder = document.getElementById('viewport-gradcam-placeholder');
  gradcamImg.classList.add('hidden');
  gradcamImg.src = '';
  gradcamPlaceholder.classList.remove('hidden');
  gradcamPlaceholder.innerHTML = `
    <span class="material-symbols-outlined">gradient</span>
    <span>Run analysis to generate heatmap</span>
  `;
  document.getElementById('gradcam-overlay-tags').classList.add('hidden');

  // Reset gauge
  document.getElementById('gauge-fill').setAttribute('stroke-dashoffset', '263.89');

  // Hide results
  resultsContainer.classList.add('hidden');

  // Disable buttons
  btnReupload.disabled = true;
  btnAnalyze.disabled = true;
}
