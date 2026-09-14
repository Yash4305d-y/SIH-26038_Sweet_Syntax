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

btnDownloadJson?.addEventListener('click', () => {
  if (currentResult) {
    downloadJSON(currentResult);
  }
});

btnNewAnalysis?.addEventListener('click', () => {
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

// ── Result Rendering ──

function renderResults(result) {
  resultsContainer.classList.remove('hidden');
  resultsContainer.classList.add('fade-in');

  const iqaPassed = renderIQA(result);
  
  if (iqaPassed) {
    document.getElementById('metrics-grid-container').classList.remove('hidden');
    
    renderAlertBanner(result);
    renderMainScreen(result);
    populateReport(result);
  } else {
    document.getElementById('metrics-grid-container').classList.add('hidden');
    document.getElementById('alert-banner').innerHTML = '';
  }

  setTimeout(() => {
    resultsContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }, 200);
}

function renderIQA(result) {
  const iqaCard = document.getElementById('iqa-card');
  const actionList = document.getElementById('iqa-action-list');

  if (!result.iqa) {
    iqaCard.style.display = 'none';
    return true;
  }
  
  const iqa = result.iqa;
  if (iqa.pass) {
    iqaCard.style.display = 'none';
    return true;
  } else {
    iqaCard.style.display = 'block';
    
    // Map IQA reason to actionable feedback
    const reason = iqa.reason || '';
    let actions = [];
    
    if (reason === "Focus failure") {
      actions = [
        "Hold the camera steady.",
        "Make sure the camera is focused on the retina.",
        "Retake the image."
      ];
    } else if (reason === "Illumination failure") {
      actions = [
        "Improve the lighting.",
        "Avoid very dark images or severe glare.",
        "Retake the image with even lighting."
      ];
    } else if (reason === "FOV failure") {
      actions = [
        "Center the patient's eye.",
        "Make sure the retinal area is clearly visible.",
        "Retake the image."
      ];
    } else {
      actions = [
        "Check the camera and lighting.",
        "Make sure the retina is clearly visible.",
        "Retake the image."
      ];
    }
    
    if (actionList) {
      actionList.innerHTML = actions.map(action => 
        `<li style="margin-bottom: 8px; display: flex; align-items: start; gap: 8px;">
           <span class="material-symbols-outlined" style="color: var(--color-success); font-size: 20px;">check</span>
           <span>${action}</span>
         </li>`
      ).join('');
    }
    
    return false;
  }
}

function renderAlertBanner(result) {
  const banner = document.getElementById('alert-banner');
  const isReferable = result.referableStatus === 'Referable';

  if (isReferable) {
    banner.innerHTML = `
      <div class="alert-banner alert-banner-danger fade-in">
        <div class="alert-icon">
          <span class="material-symbols-outlined" style="font-size:24px;">warning</span>
        </div>
        <div class="alert-content">
          <div class="alert-title">
            <span style="color: var(--color-danger);">REFERABLE DR DETECTED</span>
          </div>
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
          </div>
        </div>
      </div>
    `;
  }
}

function renderMainScreen(result) {
  const grade = result.predictedGrade;
  const color = GRADE_COLORS[grade] || 'var(--text-primary)';
  
  // Patient ID (Using filename if available, else generated)
  const patientId = selectedFile ? selectedFile.name : 'Unknown Patient';
  document.getElementById('main-patient-id').textContent = patientId;

  // Viewports
  if (previewDataUrl) {
    document.getElementById('main-viewport-orig').src = previewDataUrl;
  }
  
  const gradcamImg = document.getElementById('main-viewport-gradcam');
  const gradcamPlaceholder = document.getElementById('main-viewport-gradcam-placeholder');
  
  if (result.gradcam_url) {
    gradcamImg.src = result.gradcam_url;
    gradcamImg.style.display = 'block';
    gradcamPlaceholder.style.display = 'none';
  } else {
    gradcamImg.style.display = 'none';
    gradcamPlaceholder.style.display = 'flex';
  }

  const sublabel = document.getElementById('grade-sublabel');
  const title = document.getElementById('grade-title');
  const refDecision = document.getElementById('main-ref-decision');
  const calibRefProb = document.getElementById('calib-ref-prob');

  sublabel.textContent = 'Diagnostic DR Grade';
  title.textContent = `Grade ${grade}`;
  title.style.color = color;

  const isReferable = result.referableStatus === 'Referable';
  refDecision.textContent = isReferable ? 'Refer to Ophthalmologist' : 'No Ophthalmologist Referral Required';
  refDecision.style.color = isReferable ? 'var(--color-danger)' : 'var(--color-success)';

  const probPercent = (result.calibratedReferableProbability * 100).toFixed(1);
  calibRefProb.textContent = `${probPercent}%`;
}

function populateReport(result) {
  const patientId = selectedFile ? selectedFile.name : 'Unknown Patient';
  const dateStr = new Date().toLocaleString();
  const modelName = `${result.modelName || 'Baseline ResNet-50'}`;
  const modelVersion = `${result.modelVersion || '1.0'} (${result.modelStatus || 'LOCKED'})`;
  const grade = result.predictedGrade;
  const gradeName = GRADE_NAMES[grade] || 'Unknown';
  const confPercent = result.confidence ? (result.confidence * 100).toFixed(2) + '%' : 'N/A';
  const refProbPercent = result.calibratedReferableProbability ? (result.calibratedReferableProbability * 100).toFixed(2) + '%' : 'N/A';
  const isReferable = result.referableStatus === 'Referable';

  // COVER
  document.getElementById('report-patient-id').textContent = patientId;
  document.getElementById('report-date').textContent = dateStr;
  document.getElementById('report-model-name').textContent = modelName;
  document.getElementById('report-grade').textContent = `Grade ${grade} (${gradeName})`;
  document.getElementById('report-ref-status').textContent = isReferable ? 'Referable' : 'Non-referable';
  document.getElementById('report-ref-prob').textContent = refProbPercent;

  // SEC 2
  document.getElementById('sec2-patient').textContent = patientId;
  document.getElementById('sec2-date').textContent = dateStr;

  // SEC 4
  document.getElementById('sec4-grade').textContent = `Grade ${grade}`;
  document.getElementById('sec4-class').textContent = gradeName;
  document.getElementById('sec4-ref-status').textContent = isReferable ? 'Referable' : 'Non-referable';
  document.getElementById('sec4-ref-prob').textContent = refProbPercent;
  document.getElementById('sec4-confidence').textContent = confPercent;

  // SEC 5
  if (previewDataUrl) {
    document.getElementById('report-original-img').src = previewDataUrl;
  }

  // SEC 6
  if (result.gradcam_url) {
    document.getElementById('report-gradcam-img').src = result.gradcam_url;
  } else {
    document.getElementById('report-gradcam-container').innerHTML = '<p><em>Grad-CAM visualization not available.</em></p>';
  }

  // SEC 7
  const probs = result.probabilities || [0,0,0,0,0];
  for(let i=0; i<5; i++) {
    const val = (probs[i] * 100).toFixed(1);
    document.getElementById(`prob-bar-${i}`).style.width = `${val}%`;
    document.getElementById(`prob-bar-${i}`).style.background = BAR_COLORS[i];
    document.getElementById(`prob-val-${i}`).textContent = `${val}%`;
  }

  // SEC 9
  document.getElementById('sec9-model-version').textContent = modelVersion;

  // SEC 21
  document.getElementById('sec21-id').textContent = patientId;
  document.getElementById('sec21-grade').textContent = `Grade ${grade} (${gradeName})`;
  document.getElementById('sec21-ref-status').textContent = isReferable ? 'Referable' : 'Non-referable';
  document.getElementById('sec21-ref-prob').textContent = refProbPercent;
  document.getElementById('sec21-confidence').textContent = confPercent;
  document.getElementById('sec21-date').textContent = dateStr;
}


// ── Utilities & Event Listeners ──

function formatFileSize(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

function resetDashboard() {
  selectedFile = null;
  currentResult = null;
  previewDataUrl = null;

  fileInput.value = '';
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

  // Reset main viewports
  document.getElementById('main-viewport-orig').src = '';
  document.getElementById('main-viewport-gradcam').src = '';
  document.getElementById('main-viewport-gradcam').style.display = 'none';
  document.getElementById('main-viewport-gradcam-placeholder').style.display = 'flex';

  resultsContainer.classList.add('hidden');
  document.getElementById('iqa-card').style.display = 'none';
  
  btnReupload.disabled = true;
  btnAnalyze.disabled = true;
}

// ── Report Actions ──

document.getElementById('btn-show-report')?.addEventListener('click', () => {
  document.getElementById('report-modal').classList.remove('hidden');
});

document.getElementById('btn-close-report')?.addEventListener('click', () => {
  document.getElementById('report-modal').classList.add('hidden');
});

document.getElementById('report-modal-backdrop')?.addEventListener('click', () => {
  document.getElementById('report-modal').classList.add('hidden');
});

const handleDownloadReport = async (e) => {
  const btn = e ? e.currentTarget : document.getElementById('btn-download-report');
  const originalText = btn ? btn.innerHTML : '';
  if (btn) {
    btn.innerHTML = '<span class="material-symbols-outlined" style="animation: spin 1s linear infinite;">hourglass_empty</span> Generating PDF...';
    btn.disabled = true;
  }

  try {
    const element = document.getElementById('pdf-report');
    
    const modal = document.getElementById('report-modal');
    const wasHidden = modal.classList.contains('hidden');
    
    if (wasHidden) {
      // Unhide but keep offscreen
      modal.style.opacity = '0.01';
      modal.style.position = 'absolute';
      modal.style.top = '-9999px';
      modal.style.display = 'block'; // force display
      modal.classList.remove('hidden');
      await new Promise(r => setTimeout(r, 100)); // allow DOM to render
    }
    
    const patientId = document.getElementById('sec2-patient').textContent || 'Unknown';
    const safeId = patientId.replace(/[^a-z0-9]/gi, '_');
    const filename = `DR_Screening_Report_${safeId}.pdf`;

    const opt = {
      margin:       10,
      filename:     filename,
      image:        { type: 'jpeg', quality: 0.98 },
      html2canvas:  { scale: 2, useCORS: true, logging: false },
      jsPDF:        { unit: 'mm', format: 'a4', orientation: 'portrait' },
      pagebreak:    { mode: ['css', 'legacy'] }
    };
    
    await html2pdf().set(opt).from(element).toPdf().get('pdf').then(function(pdf) {
      const totalPages = pdf.internal.getNumberOfPages();
      for (let i = 1; i <= totalPages; i++) {
        pdf.setPage(i);
        pdf.setFontSize(9);
        pdf.setTextColor(100);
        pdf.text('SIH-26038 | Diabetic Retinopathy Screening Report', 10, pdf.internal.pageSize.getHeight() - 8);
        pdf.text(`Page ${i} of ${totalPages}`, pdf.internal.pageSize.getWidth() - 25, pdf.internal.pageSize.getHeight() - 8);
      }
    }).save();
    
    if (wasHidden) {
      modal.classList.add('hidden');
      modal.style.opacity = '';
      modal.style.position = '';
      modal.style.top = '';
      modal.style.display = '';
    }
  } catch (error) {
    console.error("PDF generation failed:", error);
    alert("Unable to generate the report. Please try again.");
  } finally {
    if (btn) {
      btn.innerHTML = originalText;
      btn.disabled = false;
    }
  }
};

document.getElementById('btn-download-report')?.addEventListener('click', handleDownloadReport);
document.getElementById('btn-modal-download')?.addEventListener('click', handleDownloadReport);

document.getElementById('btn-share-report')?.addEventListener('click', async () => {
  if (navigator.share) {
    try {
      await navigator.share({
        title: 'DR Screening Report',
        text: 'Screening Result generated by Retina-AI',
        url: window.location.href,
      });
    } catch (err) {
      console.log('Share canceled or failed', err);
    }
  } else {
    // Fallback if share is not supported
    handleDownloadReport();
  }
});

document.getElementById('btn-retake-image')?.addEventListener('click', () => {
  fileInput.click();
});
