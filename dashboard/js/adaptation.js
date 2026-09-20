document.addEventListener('DOMContentLoaded', async () => {
  const loadingEl = document.getElementById('adaptation-loading');
  const errorEl = document.getElementById('adaptation-error');
  const contentEl = document.getElementById('adaptation-content');

  try {
    const response = await fetch('/api/adaptation');
    const data = await response.json();

    if (!response.ok || data.error) {
      throw new Error(data.error || 'Failed to load adaptation package');
    }

    loadingEl.classList.add('hidden');
    contentEl.classList.remove('hidden');

    renderPackage(data);
  } catch (err) {
    console.error(err);
    loadingEl.classList.add('hidden');
    errorEl.classList.remove('hidden');
    document.getElementById('error-message').textContent = err.message;
  }
});

function renderPackage(pkg) {
  const exp = pkg.idrid_adaptation_experiment;
  if (!exp) return;

  // 1. Mechanical Decision Banner
  const decisionStr = exp.decision || 'UNKNOWN';
  const decisionEl = document.getElementById('final-decision');
  decisionEl.textContent = decisionStr;
  
  if (decisionStr === 'PROMOTE') {
    decisionEl.style.color = 'var(--color-success)';
  } else if (decisionStr === 'ROLLBACK') {
    decisionEl.style.color = 'var(--color-danger)';
  }

  document.getElementById('decision-rationale').textContent = exp.decision_rationale || 'No rationale recorded.';

  // 2. Current Calibration
  document.getElementById('base-state').textContent = pkg.baseline_model?.status || 'LOCKED';
  const baseParams = exp.baseline_parameters || {};
  document.getElementById('base-platt-a').textContent = baseParams.platt_coef_A !== undefined ? baseParams.platt_coef_A.toFixed(4) : '—';
  document.getElementById('base-platt-b').textContent = baseParams.platt_intercept_B !== undefined ? baseParams.platt_intercept_B.toFixed(4) : '—';
  document.getElementById('base-threshold').textContent = baseParams.threshold_tau !== undefined ? baseParams.threshold_tau.toFixed(4) : '—';

  // 3. Candidate Calibration
  document.getElementById('cand-id').textContent = exp.experiment_id || '—';
  const candParams = exp.candidate_parameters || {};
  document.getElementById('cand-platt-a').textContent = candParams.platt_coef_A !== undefined ? candParams.platt_coef_A.toFixed(4) : '—';
  document.getElementById('cand-platt-b').textContent = candParams.platt_intercept_B !== undefined ? candParams.platt_intercept_B.toFixed(4) : '—';
  document.getElementById('cand-threshold').textContent = candParams.threshold_tau !== undefined ? candParams.threshold_tau.toFixed(4) : '—';

  // 4. Dataset / Experimental Design
  document.getElementById('ds-name').textContent = exp.dataset || 'IDRiD';
  document.getElementById('ds-total').textContent = pkg.idrid_split_info?.total_records || '—';
  document.getElementById('ds-fit').textContent = exp.calibration_fit_sample_count || '—';
  document.getElementById('ds-heldout').textContent = exp.heldout_validation_sample_count || '—';
  document.getElementById('ds-overlap').textContent = exp.split_overlap !== undefined ? exp.split_overlap : '—';

  // 5. & 7. A/B Metrics Table
  const tbody = document.getElementById('metrics-table-body');
  const bMetrics = exp.heldout_baseline_metrics || {};
  const cMetrics = exp.heldout_candidate_metrics || {};
  const rules = exp.promotion_rule || {};

  const metricsConfig = [
    { label: 'ECE', baseline: bMetrics.ece, candidate: cMetrics.ece, guardrailStr: '< Baseline ECE', passFlag: rules.ece_check_passed },
    { label: 'Brier Score', baseline: bMetrics.brier_score, candidate: cMetrics.brier_score, guardrailStr: '< Baseline Brier', passFlag: rules.brier_check_passed },
    { label: 'Sensitivity', baseline: bMetrics.sensitivity, candidate: cMetrics.sensitivity, guardrailStr: '>= ' + ((rules.required_sensitivity_guardrail || 0) * 100).toFixed(0) + '%', passFlag: rules.sensitivity_check_passed, isPercent: true },
    { label: 'Specificity', baseline: bMetrics.specificity, candidate: cMetrics.specificity, guardrailStr: '>= ' + ((rules.required_specificity_guardrail || 0) * 100).toFixed(0) + '%', passFlag: rules.specificity_check_passed, isPercent: true }
  ];

  metricsConfig.forEach(m => {
    const tr = document.createElement('tr');
    tr.style.borderBottom = '1px solid var(--border-subtle)';

    const formatVal = (v) => {
      if (v === undefined || v === null) return '—';
      return m.isPercent ? (v * 100).toFixed(2) + '%' : v.toFixed(4);
    };

    const statusBadge = m.passFlag 
      ? '<span style="background: rgba(16,185,129,0.15); color: #047857; padding: 4px 8px; border-radius: 4px; font-weight: 600; font-size: 12px;">PASS</span>'
      : '<span style="background: rgba(239,68,68,0.15); color: #b91c1c; padding: 4px 8px; border-radius: 4px; font-weight: 600; font-size: 12px;">FAIL</span>';

    const failStyle = !m.passFlag ? 'color: var(--color-danger); font-weight: 600;' : '';

    tr.innerHTML = `
      <td style="padding: 12px;"><strong>${m.label}</strong></td>
      <td style="padding: 12px; font-family: var(--font-mono);">${formatVal(m.baseline)}</td>
      <td style="padding: 12px; font-family: var(--font-mono); ${failStyle}">${formatVal(m.candidate)}</td>
      <td style="padding: 12px;">${m.guardrailStr}</td>
      <td style="padding: 12px;">${statusBadge}</td>
    `;
    tbody.appendChild(tr);
  });

  if (exp.promotion_rule) {
    document.getElementById('guardrail-disclaimer').textContent = pkg.adaptation_status?.promotion_rule || '';
  }

  // 8. Version / Traceability
  document.getElementById('trace-timestamp').textContent = exp.timestamp || pkg.metadata?.timestamp || 'Not recorded in current handoff package.';
  if (exp.clinical_disclaimer) {
    document.getElementById('trace-disclaimer').textContent = exp.clinical_disclaimer;
  }
}
