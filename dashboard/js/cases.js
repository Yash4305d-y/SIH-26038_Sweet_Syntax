/* ===================================================================
   OculaAI Dashboard — Specialist Cases Queue & Review Logic
   SIH-26038 Diabetic Retinopathy Screening
   =================================================================== */

let currentCaseId = null;

// DOM Elements
const queueList = document.getElementById('queue-list');
const queueEmpty = document.getElementById('queue-empty');
const queueLoading = document.getElementById('queue-loading');
const apiError = document.getElementById('api-error');
const apiErrorText = document.getElementById('api-error-text');

const detailsEmpty = document.getElementById('details-empty');
const detailsContent = document.getElementById('details-content');

const btnRefresh = document.getElementById('btn-refresh');
const btnSubmitReview = document.getElementById('btn-submit-review');
const submitError = document.getElementById('submit-error');

// Details Elements
const elCaseId = document.getElementById('detail-case-id');
const elTime = document.getElementById('detail-time');
const elReferralId = document.getElementById('detail-referral-id');
const elAiGrade = document.getElementById('detail-ai-grade');
const elAiDecision = document.getElementById('detail-ai-decision');
const elAiProb = document.getElementById('detail-ai-prob');
const elModelVersion = document.getElementById('detail-model-version');
const elCalibVersion = document.getElementById('detail-calib-version');
const elFollowup = document.getElementById('detail-followup');

const imgOrig = document.getElementById('detail-img-orig');
const imgGradcam = document.getElementById('detail-img-gradcam');
const imgGradcamEmpty = document.getElementById('detail-img-gradcam-empty');

const morphTable = document.getElementById('morphology-table');

const reviewPending = document.getElementById('review-pending');
const reviewCompleted = document.getElementById('review-completed');
const specGradeInputs = document.querySelectorAll('input[name="specialist_grade"]');
const specGradeValue = document.getElementById('detail-spec-grade');
const agreementValue = document.getElementById('detail-agreement');

// Initialization
document.addEventListener('DOMContentLoaded', () => {
  fetchCases();
  btnRefresh.addEventListener('click', fetchCases);
  btnSubmitReview.addEventListener('click', submitReview);
});

// Fetch all cases
async function fetchCases() {
  queueLoading.style.display = 'block';
  queueEmpty.classList.add('hidden');
  queueList.innerHTML = '';
  apiError.classList.add('hidden');

  try {
    const res = await fetch('/api/cases');
    if (!res.ok) throw new Error(`HTTP error ${res.status}`);
    
    let cases = await res.json();
    queueLoading.style.display = 'none';

    if (cases.length === 0) {
      queueEmpty.classList.remove('hidden');
      return;
    }

    // Sort cases by timestamp descending (newest first)
    cases.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    cases.forEach(c => {
      const item = document.createElement('div');
      item.className = 'case-item';
      if (currentCaseId === c.case_id) {
        item.classList.add('active');
      }

      const isReviewed = c.specialist_grade !== null;
      const statusColor = isReviewed ? 'var(--color-success)' : 'var(--color-warning)';
      const statusText = isReviewed ? 'Reviewed' : 'Pending Review';

      item.innerHTML = `
        <div class="case-item-header">
          <span class="case-id">${c.case_id}</span>
          <span class="case-time">${new Date(c.timestamp).toLocaleString()}</span>
        </div>
        <div style="font-size: 12px; display: flex; justify-content: space-between; margin-top: 8px;">
          <div>
            <div>AI Grade: <strong>${c.ai_grade !== null ? c.ai_grade : 'N/A'}</strong></div>
            <div style="color: ${c.referable_decision === 'Referable' ? 'var(--color-danger)' : 'var(--text-muted)'}">${c.referable_decision || 'N/A'}</div>
          </div>
          <div style="text-align: right;">
            <div style="color: ${statusColor}; font-weight: 600;">${statusText}</div>
          </div>
        </div>
      `;

      item.addEventListener('click', () => {
        document.querySelectorAll('.case-item').forEach(el => el.classList.remove('active'));
        item.classList.add('active');
        loadCaseDetails(c.case_id);
      });

      queueList.appendChild(item);
    });

  } catch (err) {
    queueLoading.style.display = 'none';
    apiError.classList.remove('hidden');
    apiErrorText.textContent = `Unable to load cases: ${err.message}`;
  }
}

// Load Case Details
async function loadCaseDetails(caseId) {
  // Stale data protection: capture requested caseId
  currentCaseId = caseId;
  
  detailsEmpty.classList.add('hidden');
  detailsContent.classList.add('hidden');
  
  try {
    const res = await fetch(`/api/cases/${caseId}`);
    if (!res.ok) throw new Error(`HTTP error ${res.status}`);
    const c = await res.json();
    
    // Stale data protection check
    if (currentCaseId !== caseId) return;

    // Populate Header
    elCaseId.textContent = c.case_id;
    elTime.textContent = new Date(c.timestamp).toLocaleString();
    elReferralId.textContent = c.referral_id || 'None';
    elFollowup.textContent = c.follow_up_status || 'UNKNOWN';
    
    // Populate AI Assessment
    elAiGrade.textContent = c.ai_grade !== null ? `Grade ${c.ai_grade}` : 'N/A';
    elAiDecision.textContent = c.referable_decision || 'N/A';
    elAiProb.textContent = c.ai_referable_probability !== null ? (c.ai_referable_probability * 100).toFixed(1) + '%' : 'N/A';
    elModelVersion.textContent = c.model_version || 'N/A';
    elCalibVersion.textContent = c.calibration_version || 'N/A';
    
    if (c.referable_decision === 'Referable') {
      elAiDecision.style.color = 'var(--color-danger)';
      elAiDecision.style.fontWeight = '700';
    } else {
      elAiDecision.style.color = 'var(--text-primary)';
      elAiDecision.style.fontWeight = 'normal';
    }

    // Populate Images
    if (c.image_id) {
      imgOrig.src = `/uploads/${c.image_id}`;
      const baseId = c.image_id.split('.')[0];
      imgGradcam.src = `/gradcam_output/${baseId}_gradcam.png`;
      imgGradcam.style.display = 'block';
      imgGradcamEmpty.style.display = 'none';
      
      // Fallback if gradcam doesn't exist
      imgGradcam.onerror = () => {
        imgGradcam.style.display = 'none';
        imgGradcamEmpty.style.display = 'block';
      };
    } else {
      imgOrig.src = '';
      imgGradcam.style.display = 'none';
      imgGradcamEmpty.style.display = 'block';
    }

    // Populate Morphology
    morphTable.innerHTML = '';
    if (c.morphology && Object.keys(c.morphology).length > 0) {
      for (const [key, val] of Object.entries(c.morphology)) {
        if (key === 'overall_status') continue;
        const tr = document.createElement('tr');
        const th = document.createElement('th');
        th.textContent = formatKey(key);
        const td = document.createElement('td');
        
        let statusText = val.status || 'UNKNOWN';
        if (statusText === 'SUCCESS') {
           statusText = 'Processed';
           td.style.color = 'var(--color-success)';
        } else if (statusText === 'PROCESSING_FAILED') {
           td.style.color = 'var(--color-danger)';
        }
        
        td.innerHTML = `<strong>${statusText}</strong>`;
        if (val.count !== undefined) {
          td.innerHTML += ` &mdash; Count: ${val.count}`;
        }
        
        tr.appendChild(th);
        tr.appendChild(td);
        morphTable.appendChild(tr);
      }
    } else {
      morphTable.innerHTML = '<tr><td colspan="2" style="color: var(--text-faint);">No morphology evidence recorded</td></tr>';
    }

    // Populate Audit Section
    const elAuditTimeCreated = document.getElementById('audit-time-created');
    const elAuditTraceSpec = document.getElementById('audit-trace-specialist');
    const elAuditTraceAgre = document.getElementById('audit-trace-agreement');

    const elAuditId = document.getElementById('audit-id');
    const elAuditTimestamp = document.getElementById('audit-timestamp');
    const elAuditImageId = document.getElementById('audit-image-id');
    const elAuditReferralId = document.getElementById('audit-referral-id');
    const elAuditModelVer = document.getElementById('audit-model-version');
    const elAuditCalibVer = document.getElementById('audit-calib-version');
    const elAuditAiGrade = document.getElementById('audit-ai-grade');
    const elAuditAiProb = document.getElementById('audit-ai-prob');
    const elAuditAiDecision = document.getElementById('audit-ai-decision');
    const elAuditIqa = document.getElementById('audit-iqa');
    const elAuditGradcam = document.getElementById('audit-gradcam');
    const elAuditMorphStatus = document.getElementById('audit-morph-status');
    const elAuditMorphComps = document.getElementById('audit-morph-components');
    const elAuditRevStatus = document.getElementById('audit-review-status');
    const elAuditSpecGrade = document.getElementById('audit-spec-grade');
    const elAuditSpecAgre = document.getElementById('audit-spec-agreement');
    const elAuditFollowup = document.getElementById('audit-followup-state');

    // Timeline Trace
    const timeStr = new Date(c.timestamp).toLocaleString();
    elAuditTimeCreated.textContent = timeStr;
    elAuditTraceSpec.style.color = c.specialist_grade !== null ? 'var(--text-primary)' : 'var(--text-faint)';
    elAuditTraceAgre.style.color = c.agreement !== null ? 'var(--text-primary)' : 'var(--text-faint)';

    // Case Identity
    elAuditId.textContent = c.case_id;
    elAuditTimestamp.textContent = c.timestamp;
    elAuditImageId.textContent = c.image_id || 'Not available';
    elAuditReferralId.textContent = c.referral_id || 'None';

    // AI Traceability
    elAuditModelVer.textContent = c.model_version || 'Not stored';
    elAuditCalibVer.textContent = c.calibration_version || 'Not stored';
    elAuditAiGrade.textContent = c.ai_grade !== null ? c.ai_grade : 'Not stored';
    elAuditAiProb.textContent = c.ai_referable_probability !== null ? c.ai_referable_probability : 'Not stored';
    elAuditAiDecision.textContent = c.referable_decision || 'Not stored';

    // Quality Trace
    elAuditIqa.textContent = c.iqa_pass ? 'PASS' : 'FAIL';
    elAuditIqa.style.color = c.iqa_pass ? 'var(--color-success)' : 'var(--color-danger)';
    elAuditGradcam.textContent = 'Grad-CAM reference not persisted for this case.';

    // Morphology Trace
    elAuditMorphComps.innerHTML = '';
    if (c.morphology && Object.keys(c.morphology).length > 0) {
      elAuditMorphStatus.textContent = c.morphology.overall_status || 'EXECUTED';
      
      const orderedKeys = ['vessels', 'optic_disc', 'fovea', 'exudates', 'ma_hemorrhage'];
      orderedKeys.forEach(key => {
        if (c.morphology[key]) {
          const val = c.morphology[key];
          const tr = document.createElement('tr');
          const th = document.createElement('th');
          th.textContent = formatKey(key);
          const tdStat = document.createElement('td');
          const tdEvid = document.createElement('td');

          let friendlyStat = val.status || 'UNKNOWN';
          if (friendlyStat === 'SUCCESS') friendlyStat = 'Processed';
          else if (friendlyStat === 'PROCESSING_FAILED') friendlyStat = 'Processing failed';
          else if (friendlyStat === 'BLOCKED_BY_DEPENDENCY') friendlyStat = 'Blocked by required upstream component';
          else if (friendlyStat === 'NO_DETECTION') friendlyStat = 'No candidate evidence detected';
          
          tdStat.textContent = friendlyStat;
          if (val.status === 'SUCCESS' || val.status === 'NO_DETECTION') tdStat.style.color = 'var(--text-primary)';
          else if (val.status === 'PROCESSING_FAILED' || val.status === 'BLOCKED_BY_DEPENDENCY') tdStat.style.color = 'var(--color-danger)';
          
          if (val.ratio !== undefined) tdEvid.textContent = `Area ratio: ${val.ratio}`;
          else if (val.detected !== undefined) tdEvid.textContent = `Detected: ${val.detected}`;
          else if (val.count !== undefined) tdEvid.textContent = `Candidate ratio: ${val.count}`;
          else tdEvid.textContent = '-';
          tdEvid.style.fontFamily = 'var(--font-mono)';
          tdEvid.style.fontSize = '11px';

          tr.appendChild(th);
          tr.appendChild(tdStat);
          tr.appendChild(tdEvid);
          elAuditMorphComps.appendChild(tr);
        }
      });
    } else {
      elAuditMorphStatus.textContent = 'NOT EXECUTED';
      elAuditMorphComps.innerHTML = '<tr><td colspan="3" style="color: var(--text-faint);">No morphology evidence recorded</td></tr>';
    }

    // Specialist & Care-Loop Trace
    elAuditRevStatus.textContent = c.specialist_grade !== null ? 'REVIEWED' : 'PENDING';
    elAuditSpecGrade.textContent = c.specialist_grade !== null ? c.specialist_grade : 'None';
    elAuditSpecAgre.textContent = c.agreement || 'None';
    elAuditFollowup.textContent = c.follow_up_status || 'UNKNOWN';

    // Populate Review Form
    submitError.style.display = 'none';
    specGradeInputs.forEach(input => {
      input.checked = false;
      input.disabled = false;
    });

    if (c.specialist_grade !== null) {
      // Already reviewed
      reviewPending.classList.add('hidden');
      reviewCompleted.classList.remove('hidden');
      
      specGradeValue.textContent = `Grade ${c.specialist_grade}`;
      agreementValue.textContent = c.agreement || 'UNKNOWN';
      
      if (c.agreement === 'AGREE') {
        agreementValue.style.color = 'var(--color-success)';
      } else if (c.agreement === 'DISAGREE') {
        agreementValue.style.color = 'var(--color-warning)';
      } else {
        agreementValue.style.color = 'var(--text-primary)';
      }
    } else {
      // Pending review
      reviewPending.classList.remove('hidden');
      reviewCompleted.classList.add('hidden');
    }

    detailsContent.classList.remove('hidden');
    
  } catch (err) {
    // If user clicked another case while fetching, ignore this error
    if (currentCaseId !== caseId) return;
    
    detailsEmpty.classList.remove('hidden');
    detailsEmpty.innerHTML = `
      <span class="material-symbols-outlined" style="font-size: 48px; color: var(--color-danger);">error</span>
      <h3 class="headline-md" style="margin-top: 16px;">Error loading case</h3>
      <p class="body-md" style="color: var(--text-muted); margin-top: 4px;">${err.message}</p>
    `;
  }
}

// Submit Specialist Review
async function submitReview() {
  if (!currentCaseId) return;

  const selectedInput = document.querySelector('input[name="specialist_grade"]:checked');
  if (!selectedInput) {
    submitError.textContent = 'Please select a grade before submitting.';
    submitError.style.display = 'block';
    return;
  }

  const grade = parseInt(selectedInput.value, 10);
  
  btnSubmitReview.disabled = true;
  btnSubmitReview.innerHTML = '<div class="spinner" style="width:16px; height:16px; border-width:2px; margin-right:8px;"></div> Submitting...';
  submitError.style.display = 'none';

  try {
    const res = await fetch(`/api/cases/${currentCaseId}/specialist`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ specialist_grade: grade })
    });
    
    if (!res.ok) {
      const errData = await res.json();
      throw new Error(errData.error || `HTTP error ${res.status}`);
    }

    // Success! Reload the current case to show updated status
    await loadCaseDetails(currentCaseId);
    
    // Also refresh the queue silently to update the badge
    await fetchCasesSilently();

  } catch (err) {
    submitError.textContent = `Submission failed: ${err.message}`;
    submitError.style.display = 'block';
  } finally {
    btnSubmitReview.disabled = false;
    btnSubmitReview.innerHTML = 'Submit Specialist Review';
  }
}

async function fetchCasesSilently() {
  try {
    const res = await fetch('/api/cases');
    if (!res.ok) return;
    let cases = await res.json();
    cases.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    // Just update the list without showing loaders
    queueList.innerHTML = '';
    cases.forEach(c => {
      const item = document.createElement('div');
      item.className = 'case-item';
      if (currentCaseId === c.case_id) item.classList.add('active');

      const isReviewed = c.specialist_grade !== null;
      const statusColor = isReviewed ? 'var(--color-success)' : 'var(--color-warning)';
      const statusText = isReviewed ? 'Reviewed' : 'Pending Review';

      item.innerHTML = `
        <div class="case-item-header">
          <span class="case-id">${c.case_id}</span>
          <span class="case-time">${new Date(c.timestamp).toLocaleString()}</span>
        </div>
        <div style="font-size: 12px; display: flex; justify-content: space-between; margin-top: 8px;">
          <div>
            <div>AI Grade: <strong>${c.ai_grade !== null ? c.ai_grade : 'N/A'}</strong></div>
            <div style="color: ${c.referable_decision === 'Referable' ? 'var(--color-danger)' : 'var(--text-muted)'}">${c.referable_decision || 'N/A'}</div>
          </div>
          <div style="text-align: right;">
            <div style="color: ${statusColor}; font-weight: 600;">${statusText}</div>
          </div>
        </div>
      `;

      item.addEventListener('click', () => {
        document.querySelectorAll('.case-item').forEach(el => el.classList.remove('active'));
        item.classList.add('active');
        loadCaseDetails(c.case_id);
      });

      queueList.appendChild(item);
    });
  } catch (err) {
    console.error(err);
  }
}

function formatKey(key) {
  return key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}
