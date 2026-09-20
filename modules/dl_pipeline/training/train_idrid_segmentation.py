"""
Supervised Lesion Segmentation (U-Net) Training & Evaluation Script
===================================================================

Trains lightweight binary U-Net segmentation models for:
1. Microaneurysms (MA)
2. Hemorrhages (HE)
3. Hard Exudates (EX)

Data Isolation:
- Training: 43 internal training images (IDRiD Part A)
- Validation: 11 internal validation images (IDRiD Part A)
- Official Test: 27 untouched testing images (evaluated ONLY during frozen test phase)

Generates:
- outputs/models/idrid_segmentation/*.pt
- outputs/evaluation/idrid_segmentation_ml/final_config.json
- outputs/evaluation/idrid_segmentation_ml/results.json
- outputs/evaluation/idrid_segmentation_ml/comparison.csv
- outputs/evaluation/idrid_segmentation_ml/error_analysis/*.png
"""

import os
import json
import glob
import numpy as np
import pandas as pd
import cv2
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader


# Paths & Directories
BASE_DIR = r"K:\SIH 2026\Diabetic Retinopathy\SIH-26038\A. Segmentation"
TRAIN_IMG_DIR = os.path.join(BASE_DIR, "1. Original Images", "a. Training Set")
TEST_IMG_DIR = os.path.join(BASE_DIR, "1. Original Images", "b. Testing Set")

TRAIN_GT_DIR = os.path.join(BASE_DIR, "2. All Segmentation Groundtruths", "a. Training Set")
TEST_GT_DIR = os.path.join(BASE_DIR, "2. All Segmentation Groundtruths", "b. Testing Set")

SPLIT_CSV_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "data", "splits", "idrid_segmentation_ml_split.csv")
)
MODEL_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "outputs", "models", "idrid_segmentation")
)
EVAL_ML_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "outputs", "evaluation", "idrid_segmentation_ml")
)
ERROR_ANALYSIS_DIR = os.path.join(EVAL_ML_DIR, "error_analysis")


# --- 1. Lightweight U-Net Architecture ---
class DoubleConv(nn.Module):
    def __init__(self, in_ch, out_ch):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(in_ch, out_ch, 3, padding=1, bias=False),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_ch, out_ch, 3, padding=1, bias=False),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True)
        )
    def forward(self, x):
        return self.conv(x)


class UNetLight(nn.Module):
    def __init__(self, in_channels=3, out_channels=1):
        super().__init__()
        self.inc = DoubleConv(in_channels, 16)
        self.down1 = nn.Sequential(nn.MaxPool2d(2), DoubleConv(16, 32))
        self.down2 = nn.Sequential(nn.MaxPool2d(2), DoubleConv(32, 64))
        self.down3 = nn.Sequential(nn.MaxPool2d(2), DoubleConv(64, 128))
        
        self.up1 = nn.ConvTranspose2d(128, 64, 2, stride=2)
        self.conv_up1 = DoubleConv(128, 64)
        
        self.up2 = nn.ConvTranspose2d(64, 32, 2, stride=2)
        self.conv_up2 = DoubleConv(64, 32)
        
        self.up3 = nn.ConvTranspose2d(32, 16, 2, stride=2)
        self.conv_up3 = DoubleConv(32, 16)
        
        self.outc = nn.Conv2d(16, out_channels, 1)

    def forward(self, x):
        x1 = self.inc(x)
        x2 = self.down1(x1)
        x3 = self.down2(x2)
        x4 = self.down3(x3)
        
        x = self.up1(x4)
        x = torch.cat([x, x3], dim=1)
        x = self.conv_up1(x)
        
        x = self.up2(x)
        x = torch.cat([x, x2], dim=1)
        x = self.conv_up2(x)
        
        x = self.up3(x)
        x = torch.cat([x, x1], dim=1)
        x = self.conv_up3(x)
        
        return self.outc(x)


# --- 2. Combined BCE + Dice Loss ---
class DiceBCELoss(nn.Module):
    def __init__(self, smooth=1.0):
        super().__init__()
        self.smooth = smooth
        self.bce = nn.BCEWithLogitsLoss()

    def forward(self, logits, targets):
        bce_loss = self.bce(logits, targets)
        probs = torch.sigmoid(logits)
        
        probs_flat = probs.view(-1)
        targets_flat = targets.view(-1)
        
        intersection = (probs_flat * targets_flat).sum()
        dice_loss = 1.0 - (2.0 * intersection + self.smooth) / (probs_flat.sum() + targets_flat.sum() + self.smooth)
        return bce_loss + dice_loss


# --- 3. PyTorch Dataset ---
class IDRiDSegmentationDataset(Dataset):
    def __init__(self, df_split, split_name, lesion_type, img_size=(128, 128)):
        self.records = df_split[df_split['split'] == split_name].reset_index(drop=True)
        self.lesion_type = lesion_type
        self.img_size = img_size

    def __len__(self):
        return len(self.records)

    def __getitem__(self, idx):
        row = self.records.iloc[idx]
        image_id = row['image_id']
        split_name = row['split']
        
        if split_name in ['train', 'val']:
            img_path = os.path.join(TRAIN_IMG_DIR, f"{image_id}.jpg")
            gt_folder = TRAIN_GT_DIR
        else:
            img_path = os.path.join(TEST_IMG_DIR, f"{image_id}.jpg")
            gt_folder = TEST_GT_DIR
            
        img = cv2.imread(img_path)
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img_resized = cv2.resize(img_rgb, self.img_size)
        
        if self.lesion_type == "exudates":
            gt_filename = f"{image_id}_EX.tif"
            subfolder = "3. Hard Exudates"
        elif self.lesion_type == "microaneurysms":
            gt_filename = f"{image_id}_MA.tif"
            subfolder = "1. Microaneurysms"
        else:
            gt_filename = f"{image_id}_HE.tif"
            subfolder = "2. Haemorrhages"
            
        gt_path = os.path.join(gt_folder, subfolder, gt_filename)
        if os.path.exists(gt_path):
            gt = cv2.imread(gt_path, cv2.IMREAD_GRAYSCALE)
            gt_resized = cv2.resize(gt, self.img_size, interpolation=cv2.INTER_NEAREST)
            gt_mask = (gt_resized > 128).astype(np.float32)
        else:
            gt_mask = np.zeros(self.img_size, dtype=np.float32)
            
        img_tensor = torch.from_numpy(img_resized.transpose(2, 0, 1)).float() / 255.0
        gt_tensor = torch.from_numpy(gt_mask).unsqueeze(0).float()
        
        return img_tensor, gt_tensor, image_id


def compute_eval_metrics(preds, gts):
    """Computes pixel-level metrics."""
    pred_b = (preds >= 0.5).astype(np.uint8)
    gt_b = (gts >= 0.5).astype(np.uint8)
    
    tp = int(np.sum((pred_b == 1) & (gt_b == 1)))
    fp = int(np.sum((pred_b == 1) & (gt_b == 0)))
    fn = int(np.sum((pred_b == 0) & (gt_b == 1)))
    tn = int(np.sum((pred_b == 0) & (gt_b == 0)))
    
    prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    rec = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    spec = tn / (tn + fp) if (tn + fp) > 0 else 0.0
    f1 = 2 * tp / (2 * tp + fp + fn) if (2 * tp + fp + fn) > 0 else 0.0
    iou = tp / (tp + fp + fn) if (tp + fp + fn) > 0 else 0.0
    
    return {
        "tp": tp, "fp": fp, "fn": fn, "tn": tn,
        "precision": float(round(prec, 4)),
        "recall": float(round(rec, 4)),
        "specificity": float(round(spec, 4)),
        "f1": float(round(f1, 4)),
        "dice": float(round(f1, 4)),
        "iou": float(round(iou, 4))
    }


def train_model(lesion_name, df_split, epochs=5, batch_size=8, lr=1e-3):
    print(f"\n--- Training Supervised U-Net for {lesion_name.upper()} ---")
    torch.manual_seed(42)
    np.random.seed(42)
    
    train_dataset = IDRiDSegmentationDataset(df_split, "train", lesion_name)
    val_dataset = IDRiDSegmentationDataset(df_split, "val", lesion_name)
    
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False)
    
    model = UNetLight(in_channels=3, out_channels=1)
    criterion = DiceBCELoss()
    optimizer = optim.Adam(model.parameters(), lr=lr)
    
    best_val_dice = -1.0
    best_model_path = os.path.join(MODEL_DIR, f"unet_{lesion_name}_best.pt")
    
    for epoch in range(1, epochs + 1):
        model.train()
        train_loss = 0.0
        for imgs, masks, _ in train_loader:
            optimizer.zero_grad()
            outputs = model(imgs)
            loss = criterion(outputs, masks)
            loss.backward()
            optimizer.step()
            train_loss += loss.item() * imgs.size(0)
            
        train_loss /= len(train_dataset)
        
        # Validation
        model.eval()
        val_preds, val_gts = [], []
        with torch.no_grad():
            for imgs, masks, _ in val_loader:
                outputs = model(imgs)
                probs = torch.sigmoid(outputs).cpu().numpy()
                val_preds.append(probs)
                val_gts.append(masks.cpu().numpy())
                
        val_preds = np.concatenate(val_preds, axis=0)
        val_gts = np.concatenate(val_gts, axis=0)
        
        m = compute_eval_metrics(val_preds, val_gts)
        val_dice = m["dice"]
        
        print(f"Epoch [{epoch}/{epochs}] - Train Loss: {train_loss:.4f} | Val Dice: {val_dice:.4f} | Val Precision: {m['precision']:.4f} | Val Recall: {m['recall']:.4f}")
        
        if val_dice >= best_val_dice:
            best_val_dice = val_dice
            torch.save(model.state_dict(), best_model_path)
            
    print(f"[SUCCESS] Best model for {lesion_name} saved to {best_model_path} (Best Val Dice: {best_val_dice:.4f})")
    return best_model_path, best_val_dice


def evaluate_frozen_model(model_path, df_split, split_name, lesion_name):
    model = UNetLight(in_channels=3, out_channels=1)
    model.load_state_dict(torch.load(model_path))
    model.eval()
    
    dataset = IDRiDSegmentationDataset(df_split, split_name, lesion_name)
    loader = DataLoader(dataset, batch_size=4, shuffle=False)
    
    all_preds, all_gts, all_ids = [], [], []
    with torch.no_grad():
        for imgs, masks, img_ids in loader:
            outputs = model(imgs)
            probs = torch.sigmoid(outputs).cpu().numpy()
            all_preds.append(probs)
            all_gts.append(masks.cpu().numpy())
            all_ids.extend(img_ids)
            
    all_preds = np.concatenate(all_preds, axis=0)
    all_gts = np.concatenate(all_gts, axis=0)
    
    # Save error analysis visualizations for first 3 test samples
    os.makedirs(ERROR_ANALYSIS_DIR, exist_ok=True)
    for idx in range(min(3, len(all_ids))):
        img_id = all_ids[idx]
        pred_m = (all_preds[idx, 0] >= 0.5).astype(np.uint8) * 255
        gt_m = (all_gts[idx, 0] >= 0.5).astype(np.uint8) * 255
        
        vis = np.hstack([gt_m, pred_m])
        cv2.imwrite(os.path.join(ERROR_ANALYSIS_DIR, f"{lesion_name}_{img_id}_comparison.png"), vis)
        
    return compute_eval_metrics(all_preds, all_gts)


def main():
    os.makedirs(MODEL_DIR, exist_ok=True)
    os.makedirs(EVAL_ML_DIR, exist_ok=True)
    
    df_split = pd.read_csv(SPLIT_CSV_PATH)
    
    # 1. Train supervised models on train split (43 images), validating on val split (11 images)
    ex_model_path, ex_val_dice = train_model("exudates", df_split, epochs=5)
    ma_model_path, ma_val_dice = train_model("microaneurysms", df_split, epochs=5)
    he_model_path, he_val_dice = train_model("hemorrhages", df_split, epochs=5)
    
    # 2. Save frozen configuration BEFORE official test evaluation
    final_config = {
        "dataset_split_file": "data/splits/idrid_segmentation_ml_split.csv",
        "train_sample_count": 43,
        "val_sample_count": 11,
        "untouched_test_sample_count": 27,
        "random_seed": 42,
        "model_architecture": "UNetLight (16-32-64-128 filters)",
        "input_resolution": [128, 128],
        "batch_size": 8,
        "optimizer": "Adam (lr=1e-3)",
        "loss_function": "DiceBCELoss (BCEWithLogits + Dice)",
        "epochs": 5,
        "best_checkpoints": {
            "exudates": "outputs/models/idrid_segmentation/unet_exudates_best.pt",
            "microaneurysms": "outputs/models/idrid_segmentation/unet_microaneurysms_best.pt",
            "hemorrhages": "outputs/models/idrid_segmentation/unet_hemorrhages_best.pt"
        },
        "validation_dice_scores": {
            "exudates": ex_val_dice,
            "microaneurysms": ma_val_dice,
            "hemorrhages": he_val_dice
        },
        "status": "FREEZE_COMPLETE"
    }
    
    config_path = os.path.join(EVAL_ML_DIR, "final_config.json")
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(final_config, f, indent=4)
        
    print(f"\n[FREEZE COMPLETE] Model checkpoints frozen. Configuration saved to {config_path}")
    
    # 3. Evaluate ONCE on untouched official testing set (27 images)
    print("\n============================================================")
    print("EVALUATING FROZEN SUPERVISED U-NET MODELS ON OFFICIAL TEST SET (N=27)")
    print("============================================================")
    
    ex_test_metrics = evaluate_frozen_model(ex_model_path, df_split, "test", "exudates")
    ma_test_metrics = evaluate_frozen_model(ma_model_path, df_split, "test", "microaneurysms")
    he_test_metrics = evaluate_frozen_model(he_model_path, df_split, "test", "hemorrhages")
    
    # 4. Load Morphological Baseline metrics for direct comparison
    morph_json_path = os.path.join(EVAL_ML_DIR, "..", "idrid_segmentation_validation.json")
    with open(morph_json_path, "r", encoding="utf-8") as f:
        morph_data = json.load(f)
        
    morph_test = morph_data["heldout_test_set_metrics"]
    
    # 5. Build Comparison Table
    comparison_rows = [
        {
            "lesion": "Hard Exudates",
            "method": "Morphological Baseline",
            "dice": morph_test["exudates"]["dice"],
            "iou": morph_test["exudates"]["iou"],
            "precision": morph_test["exudates"]["precision"],
            "recall": morph_test["exudates"]["recall"],
            "sensitivity": morph_test["exudates"]["recall"],
            "specificity": morph_test["exudates"]["specificity"],
            "evaluation_images": 27
        },
        {
            "lesion": "Hard Exudates",
            "method": "Supervised U-Net",
            "dice": ex_test_metrics["dice"],
            "iou": ex_test_metrics["iou"],
            "precision": ex_test_metrics["precision"],
            "recall": ex_test_metrics["recall"],
            "sensitivity": ex_test_metrics["recall"],
            "specificity": ex_test_metrics["specificity"],
            "evaluation_images": 27
        },
        {
            "lesion": "Microaneurysms",
            "method": "Morphological Baseline",
            "dice": morph_test["microaneurysms"]["dice"],
            "iou": morph_test["microaneurysms"]["iou"],
            "precision": morph_test["microaneurysms"]["precision"],
            "recall": morph_test["microaneurysms"]["recall"],
            "sensitivity": morph_test["microaneurysms"]["recall"],
            "specificity": morph_test["microaneurysms"]["specificity"],
            "evaluation_images": 27
        },
        {
            "lesion": "Microaneurysms",
            "method": "Supervised U-Net",
            "dice": ma_test_metrics["dice"],
            "iou": ma_test_metrics["iou"],
            "precision": ma_test_metrics["precision"],
            "recall": ma_test_metrics["recall"],
            "sensitivity": ma_test_metrics["recall"],
            "specificity": ma_test_metrics["specificity"],
            "evaluation_images": 27
        },
        {
            "lesion": "Hemorrhages",
            "method": "Morphological Baseline",
            "dice": morph_test["hemorrhages"]["dice"],
            "iou": morph_test["hemorrhages"]["iou"],
            "precision": morph_test["hemorrhages"]["precision"],
            "recall": morph_test["hemorrhages"]["recall"],
            "sensitivity": morph_test["hemorrhages"]["recall"],
            "specificity": morph_test["hemorrhages"]["specificity"],
            "evaluation_images": 27
        },
        {
            "lesion": "Hemorrhages",
            "method": "Supervised U-Net",
            "dice": he_test_metrics["dice"],
            "iou": he_test_metrics["iou"],
            "precision": he_test_metrics["precision"],
            "recall": he_test_metrics["recall"],
            "sensitivity": he_test_metrics["recall"],
            "specificity": he_test_metrics["specificity"],
            "evaluation_images": 27
        }
    ]
    
    df_comp = pd.DataFrame(comparison_rows)
    comp_csv_path = os.path.join(EVAL_ML_DIR, "comparison.csv")
    df_comp.to_csv(comp_csv_path, index=False)
    
    # 6. Save Machine-Readable Results JSON
    results_json_path = os.path.join(EVAL_ML_DIR, "results.json")
    results_data = {
        "dataset": {
            "name": "IDRiD Part A - Segmentation",
            "official_test_count": 27,
            "split_file": "data/splits/idrid_segmentation_ml_split.csv"
        },
        "supervised_unet_heldout_metrics": {
            "exudates": ex_test_metrics,
            "microaneurysms": ma_test_metrics,
            "hemorrhages": he_test_metrics
        },
        "morphological_baseline_metrics": {
            "exudates": morph_test["exudates"],
            "microaneurysms": morph_test["microaneurysms"],
            "hemorrhages": morph_test["hemorrhages"]
        },
        "module_status_decisions": {
            "exudate_candidate_extraction": {
                "status": "PARTIALLY VALIDATED",
                "supervised_dice": ex_test_metrics["dice"],
                "baseline_dice": morph_test["exudates"]["dice"],
                "decision_rationale": f"Supervised U-Net achieved Dice={ex_test_metrics['dice']:.4f} vs Morphological Baseline Dice={morph_test['exudates']['dice']:.4f}. Preserved as PARTIALLY VALIDATED."
            },
            "microaneurysm_candidate_extraction": {
                "status": "PARTIALLY VALIDATED",
                "supervised_dice": ma_test_metrics["dice"],
                "baseline_dice": morph_test["microaneurysms"]["dice"],
                "decision_rationale": f"Supervised U-Net achieved Dice={ma_test_metrics['dice']:.4f} vs Morphological Baseline Dice={morph_test['microaneurysms']['dice']:.4f}. Preserved as PARTIALLY VALIDATED."
            },
            "hemorrhage_candidate_extraction": {
                "status": "PARTIALLY VALIDATED",
                "supervised_dice": he_test_metrics["dice"],
                "baseline_dice": morph_test["hemorrhages"]["dice"],
                "decision_rationale": f"Supervised U-Net achieved Dice={he_test_metrics['dice']:.4f} vs Morphological Baseline Dice={morph_test['hemorrhages']['dice']:.4f}. Preserved as PARTIALLY VALIDATED."
            }
        }
    }
    
    with open(results_json_path, "w", encoding="utf-8") as f:
        json.dump(results_data, f, indent=4)
        
    print(f"\n[SUCCESS] Supervised segmentation experiment complete!")
    print(f"Results written to:\n  - {comp_csv_path}\n  - {results_json_path}")


if __name__ == "__main__":
    main()
