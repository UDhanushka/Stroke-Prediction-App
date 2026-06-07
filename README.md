# 🧠 Stroke Risk Prediction Web App (R Shiny + Machine Learning)

🚀 Live Demo: [https://udara.shinyapps.io/build-deploy-stroke-prediction-model-r/](https://udara.shinyapps.io/build-deploy-stroke-prediction-model-r/)

---

## 📌 Project Overview

This project is an interactive **Machine Learning-based Stroke Risk Prediction System** built using **R Shiny**.  
It allows users to input patient health parameters and instantly receive a predictive risk score for stroke occurrence.

The system also provides **data visualization, feature importance insights, patient history tracking, and downloadable medical reports**.

---

## 🎯 Objectives

- Predict stroke risk based on clinical patient data
- Provide real-time interactive analytics dashboard
- Visualize risk contributions using feature importance
- Generate downloadable PDF medical reports
- Demonstrate end-to-end ML deployment using R Shiny

---

## 🧠 Machine Learning Workflow

1. Data preprocessing (health dataset)
2. Feature selection (age, BMI, glucose, etc.)
3. Model training (saved as `.rds`)
4. Prediction integration in Shiny app
5. Risk score generation (probability output)

---

## 🖥️ App Features

### 📊 Prediction Dashboard
- Real-time stroke probability estimation
- Dynamic risk visualization (donut chart)
- Color-coded risk indicators

### 📈 Feature Importance (SHAP-style)
- Displays key factors affecting prediction
- Highlights patient-specific risk drivers

### 📋 Patient History Log
- Stores all predictions in session
- Displays structured history table

### 📄 PDF Report Generator
- Generates downloadable clinical summary report
- Includes patient data + prediction results

### 🎨 Interactive UI
- Built using `shinydashboard`
- Plotly interactive visualizations
- Clean medical-style interface

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|--------|
| R | Programming language |
| Shiny | Web application framework |
| Shinydashboard | UI layout |
| Plotly | Interactive visualization |
| R Markdown | PDF report generation |
| caret / ML model | Prediction engine |

---

## 📂 Project Structure

```bash
stroke-prediction-app/
│
├── app.R                      # Main Shiny application
├── model.rds                  # Trained ML model
├── healthcare-dataset.csv    # Dataset (optional)
├── report.Rmd                # PDF report template
│
└── www/                      # Static assets (images, CSS)
