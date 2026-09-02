# 06. ML & Deep Learning Model Architecture Research

## 1. Problem Statement & Classification Task
The objective is to classify color fundus images into Diabetic Retinopathy (DR) severity grades based on the International Clinical Diabetic Retinopathy (ICDR) scale:
- **Grade 0:** No DR (Healthy retina)
- **Grade 1:** Mild DR (Microaneurysms only)
- **Grade 2:** Moderate DR (Microaneurysms, blot hemorrhages, hard exudates)
- **Grade 3:** Severe DR (4-2-1 rule: extensive hemorrhages or venous beading)
- **Grade 4:** Proliferative DR (Neovascularization, vitreous hemorrhage)

We also generate a **Referable DR** binary flag:
- **Non-Referable:** Grade 0 and Grade 1
- **Referable:** Grade 2, Grade 3, and Grade 4 (requires specialist referral)

---

## 2. Model Architecture Comparison

| Model | Size / Parameters | Why It Works Well for DR | MATLAB Fit |
| :--- | :--- | :--- | :--- |
| **ResNet-50** *(Primary Choice)* | ~25M parameters | Skip connections retain subtle lesion features; easy Grad-CAM layer extraction (`activation_49_relu`). | Built-in support, stable training in Deep Learning Toolbox. |
| **EfficientNet-B0 / B3** | ~5M to 12M parameters | High accuracy with low compute; balances resolution and depth. | Native MATLAB support; slightly higher memory usage. |
| **DenseNet-121** | ~8M parameters | Reuses low-level feature maps, useful for small vessel and dot lesions. | Available in MATLAB; higher RAM footprint during training. |

**Decision:** Use **ResNet-50** as the primary backbone because it is robust, easy to extract activation maps from for Grad-CAM, and well-supported in MATLAB.

---

## 3. Training Strategy & Overcoming Class Imbalance

### 3.1 Two-Stage Transfer Learning
1. **Stage 1 (Feature Freeze):** Freeze the pre-trained ImageNet backbone. Train only the newly added classification head (FC layer + Dropout 0.4 + Softmax) for 5 epochs.
2. **Stage 2 (Fine-Tuning):** Unfreeze all layers and train end-to-end for 25–30 epochs using a low learning rate ($10^{-4}$) with cosine decay.

### 3.2 Handling Class Imbalance
Fundus datasets have far more Grade 0 images than Grade 3 or 4:
- **Weighted Cross-Entropy Loss:** Assign higher loss weights to minority classes (Severe and Proliferative) so the model is penalized heavily for missing dangerous cases.
- **Data Augmentation:** Apply random rotations ($-180^\circ$ to $+180^\circ$), horizontal/vertical flips, and slight contrast adjustments via MATLAB's `augmentedImageDatastore`.

---

## 4. Basic MATLAB Training Pipeline

```matlab
% 1. Load Pretrained Backbone
net = resnet50;
lgraph = layerGraph(net);

% 2. Replace Final Classification Layers for 5 DR Grades
newHead = [
    fullyConnectedLayer(256, 'Name', 'fc_dense')
    reluLayer('Name', 'relu_dense')
    dropoutLayer(0.4, 'Name', 'dropout')
    fullyConnectedLayer(5, 'Name', 'fc_dr_output')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
];

lgraph = replaceLayer(lgraph, 'fc1000', newHead(1));
lgraph = replaceLayer(lgraph, 'fc1000_softmax', newHead(4));
lgraph = replaceLayer(lgraph, 'ClassificationLayer_fc1000', newHead(5));

% 3. Training Settings
trainOpts = trainingOptions('adam', ...
    'InitialLearnRate', 1e-4, ...
    'MaxEpochs', 30, ...
    'MiniBatchSize', 16, ...
    'ValidationFrequency', 20, ...
    'Plots', 'training-progress');