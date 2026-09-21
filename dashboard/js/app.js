/* ===================================================================
   OculaAI Dashboard — Application Logic
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

fileInput?.addEventListener('change', (e) => {
  if (e.target.files.length > 0) {
    handleFileSelect(e.target.files[0]);
  }
});

btnReupload?.addEventListener('click', () => {
  fileInput?.click();
});

btnAnalyze?.addEventListener('click', () => {
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
    const viewportOrigImg = document.getElementById('main-viewport-orig');
    if (viewportOrigImg) {
      viewportOrigImg.src = previewDataUrl;
    }
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
  document.getElementById('non-retinal-card').style.display = 'none';
  document.getElementById('iqa-card').style.display = 'none';
}

// ── Analysis ──

let currentAnalysisId = 0;

async function runAnalysis(file) {
  const analysisId = ++currentAnalysisId;
  
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

    if (analysisId !== currentAnalysisId) {
      console.log('Stale async response (HTTP error) ignored.');
      return;
    }
    if (!response.ok) {
      throw new Error(`Server error: ${response.status}`);
    }

    const data = await response.json();
    progressBar.style.width = '100%';

    if (analysisId !== currentAnalysisId) {
      console.log('Stale async response ignored due to new upload/analysis.');
      return;
    }

    if (data.success === false || data.success === 0) {
      if (data.errorType === 'NON_RETINAL') {
        renderNonRetinalError(data);
        analysisStatus.textContent = 'Validation failed';
        analysisStatus.style.color = 'var(--color-danger)';
        return; // Stop execution
      }
      throw new Error(data.errorMessage || 'Inference failed');
    }

    currentResult = data;
    analysisStatus.textContent = 'Analysis complete';
    analysisStatus.style.color = 'var(--color-success)';

    renderResults(data);
  } catch (err) {
    if (analysisId !== currentAnalysisId) return;
    
    progressBar.style.width = '100%';
    progressBar.style.background = 'var(--color-danger)';
    analysisStatus.textContent = `Error: ${err.message}`;
    analysisStatus.style.color = 'var(--color-danger)';
    console.error('Analysis error:', err);
  } finally {
    if (analysisId === currentAnalysisId) {
      btnAnalyze.disabled = false;
      btnAnalyze.innerHTML = '<span class="material-symbols-outlined">play_arrow</span><span>Run AI Analysis (MATLAB)</span>';
    }
  }
}

// ── Result Rendering ──

function renderResults(result) {
  resultsContainer.classList.remove('hidden');
  resultsContainer.classList.add('fade-in');

  // CRITICAL FIX: Ensure error cards are hidden when displaying valid results
  document.getElementById('non-retinal-card').style.display = 'none';

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

function renderNonRetinalError(data) {
  // Clear any existing metrics, reports, and Grad-CAM
  if (document.getElementById('grade-title')) document.getElementById('grade-title').textContent = '-';
  if (document.getElementById('main-ref-decision')) document.getElementById('main-ref-decision').textContent = '-';
  if (document.getElementById('main-viewport-gradcam')) document.getElementById('main-viewport-gradcam').src = '';
  if (document.getElementById('alert-banner')) document.getElementById('alert-banner').innerHTML = '';
  
  // Reset probability bars
  const bars = document.querySelectorAll('.prob-fill');
  bars.forEach(bar => {
    bar.style.width = '0%';
    bar.textContent = '';
  });
  
  resultsContainer.classList.remove('hidden');
  resultsContainer.classList.add('fade-in');
  
  // hide other cards
  document.getElementById('iqa-card').style.display = 'none';
  document.getElementById('metrics-grid-container').classList.add('hidden');
  
  // show non-retinal card
  document.getElementById('non-retinal-card').style.display = 'block';
  if (data.guidance) {
    document.getElementById('non-retinal-guidance').textContent = data.guidance;
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

  // --- LAYER 1 REPORT FIELDS ---
  
  // Section 1: Header
  document.getElementById('report-patient-id').textContent = result.case_id || patientId;
  document.getElementById('report-date').textContent = dateStr;

  // Section 2: Screening Result
  if (document.getElementById('sec2-class')) {
    document.getElementById('sec2-class').textContent = `${gradeName}`;
    document.getElementById('sec2-grade').textContent = `Grade ${grade}`;
    document.getElementById('sec2-ref-status').textContent = isReferable ? 'Referable' : 'Non-referable';
    document.getElementById('sec2-ref-status').style.color = isReferable ? 'var(--color-danger)' : 'var(--color-success)';
    document.getElementById('sec2-ref-prob').textContent = refProbPercent;
  }

  // Section 3: Retinal Image
  if (previewDataUrl && document.getElementById('report-original-img')) {
    document.getElementById('report-original-img').src = previewDataUrl;
  }

  // Section 4: Explanation (Grad-CAM)
  if (document.getElementById('report-gradcam-container')) {
    if (result.gradcam_url) {
      document.getElementById('report-gradcam-container').innerHTML = `<img id="report-gradcam-img" src="${result.gradcam_url}" style="max-height: 250px; display: block;">`;
    } else {
      document.getElementById('report-gradcam-container').innerHTML = '<p style="color: var(--text-faint); padding: 12px; border: 1px dashed var(--border-default);"><em>Grad-CAM visualization not persisted for this case.</em></p>';
    }
  }

  // Section 5: Referral Recommendation
  const recommendation = isReferable ? 'Specialist Review Recommended' : 'Routine Screening';
  if (document.getElementById('sec5-ref-status')) {
    document.getElementById('sec5-ref-status').textContent = isReferable ? 'Referable' : 'Non-referable';
    document.getElementById('sec5-recommendation').textContent = recommendation;
    document.getElementById('sec5-followup').textContent = result.follow_up_status || (isReferable ? 'PENDING' : 'NOT_REFERRED');
    
    if (result.referral_id) {
      document.getElementById('sec5-ref-id').textContent = result.referral_id;
      document.getElementById('sec5-ref-id-row').style.display = 'table-row';
      document.getElementById('sec7-ref-id').textContent = result.referral_id;
      document.getElementById('sec7-ref-id-row').style.display = 'table-row';
    } else {
      document.getElementById('sec5-ref-id-row').style.display = 'none';
      if (document.getElementById('sec7-ref-id-row')) document.getElementById('sec7-ref-id-row').style.display = 'none';
    }
  }

  // Section 6: Next Action
  if (document.getElementById('sec6-next-action')) {
    document.getElementById('sec6-next-action').textContent = isReferable 
      ? 'Specialist review is recommended according to the screening workflow.' 
      : 'Continue according to the local screening/follow-up protocol.';
  }

  // Section 7: Case Identification
  if (document.getElementById('sec7-case-id')) {
    document.getElementById('sec7-case-id').textContent = result.case_id || patientId;
    document.getElementById('sec7-date').textContent = result.timestamp ? new Date(result.timestamp).toLocaleString() : dateStr;
    document.getElementById('sec7-followup').textContent = result.follow_up_status || (isReferable ? 'PENDING' : 'NOT_REFERRED');
  }

  // --- EVIDENCE PACKAGE POPULATION ---
  const probs = result.probabilities || [0,0,0,0,0];
  for(let i=0; i<5; i++) {
    const val = (probs[i] * 100).toFixed(1);
    if(document.getElementById(`prob-bar-${i}`)) {
      document.getElementById(`prob-bar-${i}`).style.width = `${val}%`;
      document.getElementById(`prob-bar-${i}`).style.background = BAR_COLORS[i];
      document.getElementById(`prob-val-${i}`).textContent = `${val}%`;
    }
  }

  if(document.getElementById('sec9-model-version')) {
    document.getElementById('sec9-model-version').textContent = modelVersion;
  }
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
  document.getElementById('non-retinal-card').style.display = 'none';
  document.getElementById('alert-banner').innerHTML = '';
  if (document.getElementById('grade-title')) document.getElementById('grade-title').textContent = '-';
  if (document.getElementById('main-ref-decision')) document.getElementById('main-ref-decision').textContent = '-';
  if (document.getElementById('main-viewport-gradcam')) document.getElementById('main-viewport-gradcam').src = '';
  if (document.getElementById('alert-banner')) document.getElementById('alert-banner').innerHTML = '';
  
  const bars = document.querySelectorAll('.prob-fill');
  bars.forEach(bar => {
    bar.style.width = '0%';
    bar.textContent = '';
  });
  
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

document.getElementById('btn-show-evidence')?.addEventListener('click', () => {
  document.getElementById('evidence-modal').classList.remove('hidden');
});

document.getElementById('btn-close-evidence')?.addEventListener('click', () => {
  document.getElementById('evidence-modal').classList.add('hidden');
});

document.getElementById('btn-close-evidence-footer')?.addEventListener('click', () => {
  document.getElementById('evidence-modal').classList.add('hidden');
});

document.getElementById('evidence-modal-backdrop')?.addEventListener('click', () => {
  document.getElementById('evidence-modal').classList.add('hidden');
});

const handleDownloadReport = async (e) => {
  const btn = e ? e.currentTarget : document.getElementById('btn-download-report');
  const originalText = btn ? btn.innerHTML : '';
  if (btn) {
    btn.innerHTML = '<span class="material-symbols-outlined" style="animation: spin 1s linear infinite;">hourglass_empty</span> Generating PDF...';
    btn.disabled = true;
  }

  try {
    const { jsPDF } = window.jspdf;
    
    const modal = document.getElementById('report-modal');
    const wasHidden = modal.classList.contains('hidden');
    
    if (wasHidden) {
      modal.style.opacity = '0.01';
      modal.style.position = 'absolute';
      modal.style.top = '-9999px';
      modal.style.display = 'block'; 
      modal.classList.remove('hidden');
      await new Promise(r => setTimeout(r, 150)); 
    }
    
    const pdf = new jsPDF('p', 'mm', 'a4');
    const pdfWidth = 210;
    const pdfHeight = 297;
    const margin = 15; 
    const usableWidth = pdfWidth - margin * 2;
    const usableHeight = pdfHeight - margin * 2 - 12; // 12mm reserved for footer
    
    let currentY = margin;
    const sections = document.querySelectorAll('#pdf-report .report-section');
    
    for (let i = 0; i < sections.length; i++) {
      const section = sections[i];
      
      const canvas = await html2canvas(section, { scale: 2, useCORS: true, logging: false, backgroundColor: '#ffffff' });
      const imgData = canvas.toDataURL('image/jpeg', 0.98);
      
      const imgWidth = usableWidth;
      let imgHeight = (canvas.height * imgWidth) / canvas.width;
      
      if (currentY + imgHeight > usableHeight && currentY > margin + 5) {
        pdf.addPage();
        currentY = margin;
      }
      
      if (imgHeight > usableHeight) {
        const scaleFactor = usableHeight / imgHeight;
        const scaledWidth = imgWidth * scaleFactor;
        const scaledHeight = usableHeight;
        
        const xOffset = margin + (usableWidth - scaledWidth) / 2;
        pdf.addImage(imgData, 'JPEG', xOffset, currentY, scaledWidth, scaledHeight);
        currentY += scaledHeight + 8;
      } else {
        pdf.addImage(imgData, 'JPEG', margin, currentY, imgWidth, imgHeight);
        currentY += imgHeight + 8; 
      }
      
      // Removed forced page break for cover-section to allow compact Layer 1 report
    }
    
    const totalPages = pdf.internal.getNumberOfPages();
    for (let i = 1; i <= totalPages; i++) {
      pdf.setPage(i);
      pdf.setFontSize(9);
      pdf.setTextColor(100);
      pdf.text('SIH-26038 | Diabetic Retinopathy Screening Report', margin, pdfHeight - 10);
      pdf.text(`Page ${i} of ${totalPages}`, pdfWidth - margin - 20, pdfHeight - 10);
    }
    
    const patientIdElement = document.getElementById('report-patient-id');
    const patientId = patientIdElement ? patientIdElement.textContent : 'Unknown';
    const safeId = patientId.replace(/[^a-z0-9]/gi, '_');
    const filename = `DR_Screening_Report_${safeId}.pdf`;
    
    pdf.save(filename);
    
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
        text: 'Screening Result generated by OculaAI',
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

document.getElementById('btn-retake-invalid-image')?.addEventListener('click', () => {
  fileInput.click();
});
