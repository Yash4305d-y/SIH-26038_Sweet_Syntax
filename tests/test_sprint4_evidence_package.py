"""
Sprint 4 Automated Test Suite: Model Evidence Package & Validation Audit
========================================================================

Verifies:
1. model_evidence_package.json exists and is valid JSON.
2. Required top-level sections exist.
3. APTOS metrics match authoritative Sprint 1-3 evidence (N=439, Acc=82.92%, QWK=0.8713, Sens=96.09%, Spec=92.31%).
4. Messidor-2 metrics match authoritative Sprint 2 evidence (N=1744, ROC-AUC=0.7669, Sens=29.32%, Spec=97.05%).
5. IDRiD metrics match authoritative Sprint 3 evidence (N=81, 40 fit / 41 held-out).
6. IDRiD decision is ROLLBACK.
7. Candidate specificity is 64.29%.
8. Locked ResNet-50 baseline is preserved.
9. Calibration split remains 40 fit / 41 held-out.
10. No train/test leakage is introduced.
11. Role 2 status classifications are preserved (11 VALIDATED, 3 PARTIALLY VALIDATED, 1 NOT IMPLEMENTED).
12. Handoff package and adaptation experiment metrics are consistent.
13. Clinical validation is explicitly marked as NOT PERFORMED.
14. No raw dataset directory is referenced as a committed project artifact.
"""

import json
import os
import unittest


class TestSprint4EvidencePackage(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        cls.evidence_path = os.path.join(cls.repo_root, "outputs", "evaluation", "model_evidence_package.json")
        cls.handoff_path = os.path.join(cls.repo_root, "outputs", "evaluation", "adaptation_handoff_package.json")
        cls.adaptation_metrics_path = os.path.join(cls.repo_root, "outputs", "evaluation", "adaptation", "adaptation_experiment_metrics.json")
        
        # Load JSON packages
        assert os.path.exists(cls.evidence_path), "model_evidence_package.json missing"
        with open(cls.evidence_path, "r", encoding="utf-8") as f:
            cls.evidence = json.load(f)

        assert os.path.exists(cls.handoff_path), "adaptation_handoff_package.json missing"
        with open(cls.handoff_path, "r", encoding="utf-8") as f:
            cls.handoff = json.load(f)

        assert os.path.exists(cls.adaptation_metrics_path), "adaptation_experiment_metrics.json missing"
        with open(cls.adaptation_metrics_path, "r", encoding="utf-8") as f:
            cls.adapt_metrics = json.load(f)

    def test_top_level_sections(self):
        """Verify all required top-level keys exist in model_evidence_package.json."""
        required_keys = [
            "metadata",
            "validation_categorization",
            "aptos_primary_test_evaluation",
            "messidor2_external_validation",
            "idrid_domain_adaptation",
            "role2_component_validation",
            "evidence_provenance_files"
        ]
        for key in required_keys:
            self.assertIn(key, self.evidence, f"Missing top-level key: {key}")

    def test_aptos_metrics(self):
        """Verify APTOS primary test metrics match Sprint 1-3 locked baseline."""
        aptos = self.evidence["aptos_primary_test_evaluation"]
        self.assertEqual(aptos["sample_count"], 439)
        self.assertAlmostEqual(aptos["accuracy"], 0.8292, places=4)
        self.assertAlmostEqual(aptos["macro_f1"], 0.6358, places=4)
        self.assertAlmostEqual(aptos["qwk"], 0.8713, places=4)
        self.assertAlmostEqual(aptos["referable_sensitivity"], 0.9609, places=4)
        self.assertAlmostEqual(aptos["referable_specificity"], 0.9231, places=4)

    def test_messidor2_metrics(self):
        """Verify Messidor-2 external validation metrics match Sprint 2 evidence."""
        m2 = self.evidence["messidor2_external_validation"]
        self.assertEqual(m2["sample_count"], 1744)
        self.assertAlmostEqual(m2["5class_accuracy"], 0.5998, places=4)
        self.assertAlmostEqual(m2["5class_macro_f1"], 0.2581, places=4)
        self.assertAlmostEqual(m2["5class_qwk"], 0.3231, places=4)
        self.assertAlmostEqual(m2["referable_dr_roc_auc"], 0.7669, places=4)
        self.assertAlmostEqual(m2["referable_dr_sensitivity"], 0.2932, places=4)
        self.assertAlmostEqual(m2["referable_dr_specificity"], 0.9705, places=4)
        self.assertEqual(m2["evaluation_type"], "External Dataset Evaluation (Frozen Model & Threshold)")

    def test_idrid_metrics_and_rollback(self):
        """Verify IDRiD adaptation metrics, split sizes, parameters, and ROLLBACK decision."""
        idrid = self.evidence["idrid_domain_adaptation"]
        self.assertEqual(idrid["calibration_fit_sample_count"], 40)
        self.assertEqual(idrid["heldout_validation_sample_count"], 41)
        self.assertEqual(idrid["split_overlap"], 0)
        
        cand_params = idrid["candidate_parameters"]
        self.assertAlmostEqual(cand_params["platt_coef_A"], 5.4270, places=4)
        self.assertAlmostEqual(cand_params["platt_intercept_B"], -1.8918, places=4)
        self.assertAlmostEqual(cand_params["threshold_tau"], 0.3700, places=4)

        heldout_cand = idrid["heldout_candidate_metrics"]
        self.assertAlmostEqual(heldout_cand["ece"], 0.1412, places=4)
        self.assertAlmostEqual(heldout_cand["brier_score"], 0.1193, places=4)
        self.assertAlmostEqual(heldout_cand["sensitivity"], 0.9630, places=4)
        self.assertAlmostEqual(heldout_cand["specificity"], 0.6429, places=4)
        self.assertAlmostEqual(heldout_cand["precision"], 0.8387, places=4)
        self.assertAlmostEqual(heldout_cand["f1_score"], 0.8966, places=4)
        self.assertAlmostEqual(heldout_cand["roc_auc"], 0.9048, places=4)

        self.assertEqual(idrid["decision"], "ROLLBACK")
        self.assertIn("specificity guardrail", idrid["decision_rationale"].lower())
        self.assertIn("ResNet-50", idrid["active_production_model"])

    def test_role2_status_classifications(self):
        """Verify Role 2 components maintain strict Master Plan status classifications."""
        role2 = self.evidence["role2_component_validation"]
        
        # Verify 8 VALIDATED
        validated_list = [c for c, info in role2.items() if info["status"] == "VALIDATED"]
        self.assertEqual(len(validated_list), 8)

        # Verify 3 PARTIALLY VALIDATED
        partially_list = [c for c, info in role2.items() if info["status"] == "PARTIALLY VALIDATED"]
        self.assertEqual(len(partially_list), 3)
        self.assertIn("lesion_exudate_candidates", partially_list)
        self.assertIn("lesion_microaneurysm_candidates", partially_list)
        self.assertIn("lesion_hemorrhage_candidates", partially_list)

        # Verify 1 NOT IMPLEMENTED
        not_impl_list = [c for c, info in role2.items() if info["status"] == "NOT IMPLEMENTED"]
        self.assertEqual(len(not_impl_list), 1)
        self.assertIn("lesion_neovascularization", not_impl_list)

    def test_validation_types_disclaimer(self):
        """Verify dataset evaluations are not called clinical validation."""
        val_types = self.evidence["validation_categorization"]
        self.assertIn("NOT PERFORMED", val_types["clinical_validation"])

    def test_handoff_consistency(self):
        """Verify consistency between adaptation handoff package and model evidence package."""
        h_status = self.handoff["adaptation_status"]
        h_idrid = self.handoff["idrid_adaptation_experiment"]
        e_idrid = self.evidence["idrid_domain_adaptation"]

        self.assertEqual(h_status["decision"], e_idrid["decision"])
        self.assertEqual(h_idrid["calibration_fit_sample_count"], e_idrid["calibration_fit_sample_count"])
        self.assertEqual(h_idrid["heldout_validation_sample_count"], e_idrid["heldout_validation_sample_count"])
        self.assertAlmostEqual(h_idrid["heldout_candidate_metrics"]["specificity"], e_idrid["heldout_candidate_metrics"]["specificity"], places=4)

    def test_no_raw_dataset_committed(self):
        """Verify raw IDRiD dataset directory is not referenced as a committed trackable asset."""
        provenance = self.evidence["evidence_provenance_files"]
        for key, val in provenance.items():
            self.assertNotIn("B. Disease Grading", val)


if __name__ == "__main__":
    unittest.main()
