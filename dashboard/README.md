# RETINA-AI Dashboard

Local web dashboard for the SIH-26038 Diabetic Retinopathy Screening System.

## Quick Start

```bash
cd dashboard

# Install dependencies
pip install -r requirements.txt

# Run the server
python server.py
```

Then open **http://localhost:5000** in your browser.

## How It Works

1. Upload a retinal fundus image (.jpg or .png)
2. Click "Run AI Analysis (MATLAB)"
3. The server calls the MATLAB `runDRInference` pipeline
4. Results are displayed: DR Grade, Confidence, Referable Status, Grad-CAM, and 5-class probabilities

## MATLAB Integration

The server attempts to connect to MATLAB in this order:

1. **MATLAB Engine API for Python** — fastest, requires `matlab.engine` package
2. **MATLAB subprocess** — calls `matlab -batch` from the command line
3. **Mock mode** — if MATLAB is unavailable, returns simulated data for UI development

## File Structure

```
dashboard/
├── index.html          # Single-page dashboard
├── css/style.css       # Clinical design system
├── js/app.js           # Frontend logic
├── server.py           # Flask backend
├── requirements.txt    # Python dependencies
└── README.md           # This file
```

## Note

> This is a research-grade screening prototype and is not intended for clinical diagnostic use.
