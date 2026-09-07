# Grad-CAM Layer Selection for Baseline ResNet-50

## Network Information
- **Model Checkpoint**: `D:\SIH-26038\models\baseline_resnet50_smoketest.mat`
- **Network Variable**: `net`
- **Network Type**: `dlnetwork` (R2026a API, 176 layers)

## Input & Preprocessing
- **Input Layer Name**: `input_1`
- **Input Size**: `[224, 224, 3]`
- **Preprocessing Pipeline**: The retinal images are only resized to 224x224x3 using an `augmentedImageDatastore`. There is no CLAHE, normalization, or aggressive augmentation performed on the images before they are passed to the Baseline model.

## Output & Prediction Format
- **Classification Output Layer**: `fc1000_softmax` (SoftmaxLayer)
- **Output Class Count**: 5 outputs (verified via the `fc1000` FullyConnectedLayer which has an `OutputSize` of 5). 
- **Adaptation**: Despite retaining the legacy name `fc1000`, the network has been correctly adapted to output exactly 5 classes for the Diabetic Retinopathy screening task, not 1000 ImageNet classes.
- **Output Class Names**: The 5 DR classes are mapped to indices 0–4 during evaluation, representing:
  1. No DR (0)
  2. Mild (1)
  3. Moderate (2)
  4. Severe (3)
  5. Proliferative DR (4)

## Selected Grad-CAM Layer
- **Layer Name**: `res5c_branch2c`
- **Layer Type**: `Convolution2DLayer`

### Justification for Selection
Grad-CAM requires the final convolutional feature map of the network because it retains the highest level of spatial information while capturing complex, high-level semantic features before they are flattened by pooling layers. 

By inspecting the exact `dlnetwork`, the final convolutional layer was identified as `res5c_branch2c`. The layers immediately following this are:
1. `bn5c_branch2c` (Batch Normalization)
2. `add_16` (Addition)
3. `activation_49_relu` (ReLU)
4. `avg_pool` (Global Average Pooling) -> *Spatial information is lost here*
5. `fc1000` (Fully Connected)
6. `fc1000_softmax` (Softmax)

Therefore, `res5c_branch2c` is the precise and correct layer to extract spatial activation gradients for generating faithful Grad-CAM heatmaps.
