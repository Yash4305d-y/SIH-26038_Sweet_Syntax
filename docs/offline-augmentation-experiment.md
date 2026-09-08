# Offline Augmentation Experiment

1. **Objective**: Test whether conservative augmentation improves validation performance over Baseline ResNet-50 without OOM.
2. **Exact augmentation design**: Manual affine transforms applied to 224x224 RGB images offline. Rotation [-10, 10], H-flip 50%, translation 5%, scale 0.95-1.05, brightness/contrast adjustments.
3. **Dataset size before/after**: Original train 2049 -> Augmented train 4098.
4. **Training configuration**: Pretrained ResNet-50, Adam 1e-4, batch 16, 5 epochs, crossentropy loss.
5. **Validation results**: Accuracy: 0.8136, Macro-F1: 0.6367, QWK: 0.8581
6. **Baseline comparison**: Acc Delta: -0.0156, Macro-F1 Delta: +0.0009, QWK Delta: -0.0132
7. **Limitations**: Because this experiment uses a fixed offline 2x training dataset, it changes both image exposure and training-set size simultaneously.
8. **Final decision**: REJECTED
