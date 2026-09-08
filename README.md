# Explainable AI for Diabetic Retinopathy Screening (MATLAB Pipeline)

This project implements the Machine Learning component of an Explainable AI system for Diabetic Retinopathy (DR) Screening. The entire pipeline is built purely in MATLAB using modern deep-learning workflows.

> [!NOTE]
> This is a research-grade screening prototype and is not intended for generating medical claims.

## Project Structure

- `data/`: Contains the APTOS dataset and processed images.
- `src/`: Modular, beginner-friendly MATLAB (`.m`) scripts for the pipeline.
- `models/`: Saved pretrained and fine-tuned network models.
- `results/`: Output evaluation metrics, Grad-CAM visualizations, and confidence scores.

## Machine Learning Pipeline

The pipeline follows these sequential steps:

1. **APTOS**: Loading and managing the APTOS Diabetic Retinopathy dataset.
2. **Deterministic Preprocessing**: Applying consistent preprocessing techniques (e.g., resizing, cropping, contrast enhancement) to standardize the input retinal images.
3. **Transfer Learning**: Utilizing modern MATLAB deep-learning APIs (e.g., `imagePretrainedNetwork` and `trainnet`) to fine-tune a pre-trained model.
4. **5-Class DR Grading**: Training the model to classify images into the 5 stages of Diabetic Retinopathy (0 - No DR, 1 - Mild, 2 - Moderate, 3 - Severe, 4 - Proliferative DR).
5. **Referable DR Evaluation**: Evaluating the model's capability to correctly identify referable DR (Moderate DR or worse).
6. **Grad-CAM**: Generating Gradient-weighted Class Activation Mapping (Grad-CAM) visualizations to provide explainability for the model's predictions.
7. **Confidence**: Outputting the model's prediction confidence scores alongside the grading results.

## Constraints & Guidelines

- **Pure MATLAB**: Implementation is entirely in MATLAB; no Python.
- **Modern APIs**: Relies on `trainnet` workflows rather than the deprecated `trainNetwork` workflows.
- **Data Integrity**: Uses authentic dataset statistics and metrics. Train/validation/test splits are strictly maintained without changes.
- **Code Clarity**: Modular structure with explanatory comments clarifying the *why* behind important ML operations.
