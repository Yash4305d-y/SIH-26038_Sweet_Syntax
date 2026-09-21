import os
import sys
import json
import unittest
from pathlib import Path

# Add the dashboard directory to sys.path so we can import server.py
PROJECT_ROOT = Path(__file__).parent.parent.resolve()
DASHBOARD_DIR = PROJECT_ROOT / 'dashboard'
sys.path.insert(0, str(DASHBOARD_DIR))

# Import the Flask app and CaseManager from server
from server import app, case_manager

class TestCaseManagement(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        # Reset cases for clean state in tests
        with case_manager.lock:
            case_manager._save({})

    def tearDown(self):
        pass

    def test_new_non_referable_case(self):
        ml_result = {
            'success': True,
            'referableStatus': 'Non-referable',
            'predictedGrade': 1,
            'calibratedReferableProbability': 0.15,
            'calibrationVersion': 'baseline-resnet50-v1',
            'modelVersion': '1.0',
            'iqa': {'pass': True}
        }
        case = case_manager.create_case(ml_result, 'test_img_1.png')
        self.assertTrue(case['case_id'].startswith('CASE-'))
        self.assertIsNone(case['referral_id'])
        self.assertEqual(case['follow_up_status'], 'NOT_REFERRED')

    def test_new_referable_case(self):
        ml_result = {
            'success': True,
            'referableStatus': 'Referable',
            'predictedGrade': 3,
            'calibratedReferableProbability': 0.85,
            'calibrationVersion': 'baseline-resnet50-v1',
            'modelVersion': '1.0',
            'iqa': {'pass': True}
        }
        case = case_manager.create_case(ml_result, 'test_img_2.png')
        self.assertTrue(case['case_id'].startswith('CASE-'))
        self.assertTrue(case['referral_id'].startswith('REF-'))
        self.assertEqual(case['follow_up_status'], 'REFERRED')

    def test_specialist_grade_initially_null(self):
        ml_result = {'success': True, 'referableStatus': 'Referable'}
        case = case_manager.create_case(ml_result, 'img.png')
        self.assertIsNone(case['specialist_grade'])
        self.assertIsNone(case['agreement'])

    def test_specialist_grade_accepted(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 2, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        # Valid grade (0-4)
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3})
        self.assertEqual(resp.status_code, 200)
        updated = resp.get_json()
        self.assertEqual(updated['specialist_grade'], 3)
        self.assertEqual(updated['agreement'], 'DISAGREE')

    def test_specialist_grade_rejected(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 2, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        # Invalid grade outside 0-4
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 5})
        self.assertEqual(resp.status_code, 400)

    def test_specialist_grade_with_duration(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 2, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3, 'review_duration_seconds': 24.5})
        self.assertEqual(resp.status_code, 200)
        updated = resp.get_json()
        self.assertEqual(updated['specialist_grade'], 3)
        self.assertEqual(updated['review_duration_seconds'], 24.5)

    def test_specialist_grade_without_duration_succeeds(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 2, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3})
        self.assertEqual(resp.status_code, 200)
        updated = resp.get_json()
        self.assertEqual(updated['specialist_grade'], 3)
        self.assertNotIn('review_duration_seconds', updated)

    def test_specialist_grade_null_duration(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 2, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3, 'review_duration_seconds': None})
        self.assertEqual(resp.status_code, 200)
        updated = resp.get_json()
        self.assertEqual(updated['specialist_grade'], 3)
        self.assertNotIn('review_duration_seconds', updated)
        
    def test_specialist_grade_large_duration(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 2, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3, 'review_duration_seconds': 3600.5})
        self.assertEqual(resp.status_code, 200)
        updated = resp.get_json()
        self.assertEqual(updated['specialist_grade'], 3)
        self.assertEqual(updated['review_duration_seconds'], 3600.5)

    def test_specialist_grade_invalid_duration(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 2, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        
        # Test string
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3, 'review_duration_seconds': "invalid"})
        self.assertEqual(resp.status_code, 200)
        self.assertNotIn('review_duration_seconds', resp.get_json())
        
        # Test NaN
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3, 'review_duration_seconds': float('nan')})
        self.assertEqual(resp.status_code, 200)
        self.assertNotIn('review_duration_seconds', resp.get_json())
        
        # Test Infinity
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3, 'review_duration_seconds': float('inf')})
        self.assertEqual(resp.status_code, 200)
        self.assertNotIn('review_duration_seconds', resp.get_json())

    def test_agreement_agree(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 4, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 4})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()['agreement'], 'AGREE')

    def test_agreement_disagree(self):
        case = case_manager.create_case({'success': True, 'predictedGrade': 4, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/specialist', json={'specialist_grade': 3})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()['agreement'], 'DISAGREE')

    def test_follow_up_referred_to_seen(self):
        case = case_manager.create_case({'success': True, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/follow_up', json={'status': 'SEEN'})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()['follow_up_status'], 'SEEN')

    def test_follow_up_seen_to_completed(self):
        case = case_manager.create_case({'success': True, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        self.client.put(f'/api/cases/{cid}/follow_up', json={'status': 'SEEN'})
        resp = self.client.put(f'/api/cases/{cid}/follow_up', json={'status': 'COMPLETED'})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()['follow_up_status'], 'COMPLETED')

    def test_follow_up_referred_to_lost(self):
        case = case_manager.create_case({'success': True, 'referableStatus': 'Referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/follow_up', json={'status': 'LOST_TO_FOLLOWUP'})
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()['follow_up_status'], 'LOST_TO_FOLLOWUP')

    def test_invalid_transitions_rejected(self):
        # NOT_REFERRED -> SEEN is invalid
        case = case_manager.create_case({'success': True, 'referableStatus': 'Non-referable'}, 'img.png')
        cid = case['case_id']
        resp = self.client.put(f'/api/cases/{cid}/follow_up', json={'status': 'SEEN'})
        self.assertEqual(resp.status_code, 400)

        # REFERRED -> NOT_REFERRED is invalid
        case2 = case_manager.create_case({'success': True, 'referableStatus': 'Referable'}, 'img.png')
        cid2 = case2['case_id']
        resp2 = self.client.put(f'/api/cases/{cid2}/follow_up', json={'status': 'NOT_REFERRED'})
        self.assertEqual(resp2.status_code, 400)

    def test_gradcam_generated_persisted(self):
        # Create a mock gradcam file
        gradcam_dir = PROJECT_ROOT / 'dashboard' / 'gradcam_output'
        gradcam_dir.mkdir(exist_ok=True)
        mock_file = gradcam_dir / 'test_img_gc_gradcam.png'
        mock_file.touch()

        ml_result = {'success': True, 'predictedGrade': 2, 'referableStatus': 'Referable'}
        
        try:
            case = case_manager.create_case(ml_result, 'test_img_gc.png')
            self.assertIn('gradcam', case)
            self.assertTrue(case['gradcam']['generated'])
            self.assertEqual(case['gradcam']['reference'], '/gradcam_output/test_img_gc_gradcam.png')
            
            # Verify API retrieval
            resp = self.client.get(f"/api/cases/{case['case_id']}")
            self.assertEqual(resp.status_code, 200)
            fetched = resp.get_json()
            self.assertTrue(fetched['gradcam']['generated'])
            self.assertEqual(fetched['gradcam']['reference'], '/gradcam_output/test_img_gc_gradcam.png')
            
            # Verify immutability of other fields
            self.assertEqual(fetched['ai_grade'], 2)
        finally:
            if mock_file.exists():
                mock_file.unlink()

    def test_gradcam_not_generated_persisted(self):
        ml_result = {'success': True, 'predictedGrade': 1, 'referableStatus': 'Non-referable'}
        case = case_manager.create_case(ml_result, 'test_img_no_gc.png')
        self.assertIn('gradcam', case)
        self.assertFalse(case['gradcam']['generated'])
        self.assertIsNone(case['gradcam']['reference'])
        
        # Verify API retrieval
        resp = self.client.get(f"/api/cases/{case['case_id']}")
        fetched = resp.get_json()
        self.assertFalse(fetched['gradcam']['generated'])
        self.assertIsNone(fetched['gradcam']['reference'])

    def test_adaptation_persisted_baseline_locked(self):
        ml_result = {'success': True, 'predictedGrade': 1, 'referableStatus': 'Non-referable'}
        case = case_manager.create_case(ml_result, 'test_img_no_adapt.png')
        self.assertIn('adaptation', case)
        self.assertEqual(case['adaptation']['status'], 'BASELINE_LOCKED')
        self.assertEqual(case['adaptation']['experiment_id'], 'None')
        self.assertEqual(case['adaptation']['decision'], 'LOCKED')

        # Verify API retrieval
        resp = self.client.get(f"/api/cases/{case['case_id']}")
        fetched = resp.get_json()
        self.assertEqual(fetched['adaptation']['status'], 'BASELINE_LOCKED')
        self.assertEqual(fetched['adaptation']['experiment_id'], 'None')
        self.assertEqual(fetched['adaptation']['decision'], 'LOCKED')

    def test_adaptation_metadata_persisted(self):
        adapt_info = {
            "status": "EVALUATED",
            "experiment_id": "EXP-123",
            "decision": "PROMOTE"
        }
        ml_result = {'success': True, 'predictedGrade': 1, 'referableStatus': 'Non-referable', 'adaptation': adapt_info}
        case = case_manager.create_case(ml_result, 'test_img_adapt.png')
        self.assertIn('adaptation', case)
        self.assertEqual(case['adaptation']['status'], 'EVALUATED')
        self.assertEqual(case['adaptation']['experiment_id'], 'EXP-123')
        self.assertEqual(case['adaptation']['decision'], 'PROMOTE')

        # Verify API retrieval
        resp = self.client.get(f"/api/cases/{case['case_id']}")
        fetched = resp.get_json()
        self.assertEqual(fetched['adaptation']['status'], 'EVALUATED')
        self.assertEqual(fetched['adaptation']['experiment_id'], 'EXP-123')
        self.assertEqual(fetched['adaptation']['decision'], 'PROMOTE')

if __name__ == '__main__':
    unittest.main()
