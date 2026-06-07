library(shiny)
library(shinydashboard)
library(plotly)
library(rmarkdown)

final_model <- readRDS(file.path(getwd(), "model.rds"))

# =====================
# UI
# =====================
ui <- dashboardPage(
  skin = "black", 
  
  dashboardHeader(title = "Stroke Prediction"),
  
  dashboardSidebar(
    selectInput("gender", "Gender:", c("Male", "Female")),
    numericInput("age", "Age:", 65),
    
    selectInput("hypertension", "Hypertension:", c("No" = "0", "Yes" = "1"), selected = "1"),
    selectInput("heart_disease", "Heart Disease:", c("No" = "0", "Yes" = "1"), selected = "1"),
    
    selectInput("ever_married", "Are you married?", c("No", "Yes"), selected = "Yes"),
    
    selectInput("work_type", "Work Type:",
                c("children", "Govt_job", "Never_worked", "Private", "Self-employed"),
                selected = "Self-employed"),
    
    selectInput("Residence_type", "Residence Type:",
                c("Rural", "Urban"), selected = "Rural"),
    
    numericInput("glucose", "Average Glucose Level:", 100),
    numericInput("bmi", "BMI:", 25),
    
    selectInput("smoking_status", "Smoking Status:",
                c("never smoked", "formerly smoked", "smokes", "Unknown")),
    
    br(),
    div(style = "text-align: center;",
        actionButton("predict", "Predict", class = "btn-primary", style = "width: 80%;"),
        br(), br(),
        downloadButton("download_report", "Download PDF Report", class = "btn-success", style = "width: 80%;")
    )
  ),
  
  dashboardBody(
    # Dynamic display container that toggles based on user action
    uiOutput("dashboard_display")
  )
)

# =====================
# SERVER
# =====================
server <- function(input, output, session) {
  
  results <- reactiveValues(stroke_p = 0, no_stroke_p = 0)
  
  shap_values <- reactiveVal(data.frame(
    Feature = character(),
    Contribution = numeric()
  ))
  
  history_data <- reactiveVal(data.frame(
    `Patient ID` = integer(),
    Age = numeric(),
    Gender = character(),
    Hypertension = character(),
    `Heart Disease` = character(),
    `Glucose Level` = numeric(),
    BMI = numeric(),
    `Stroke Risk` = character(),
    check.names = FALSE,
    stringsAsFactors = FALSE
  ))
  
  # Track run counts; starts at 0 to keep the dashboard initial state blank
  counter <- reactiveVal(0)
  
  observeEvent(input$predict, {
    counter(counter() + 1)
    
    new_data <- data.frame(
      age = input$age,
      gender = input$gender,
      hypertension = input$hypertension,
      heart_disease = input$heart_disease,
      ever_married = input$ever_married,
      work_type = input$work_type,
      Residence_type = input$Residence_type,
      avg_glucose_level = input$glucose,
      bmi = input$bmi,
      smoking_status = input$smoking_status
    )
    
    # --- OPTION A: YOUR REAL ML MODEL & SHAP PIPELINE ---
    # pred_prob <- predict(final_model, new_data, type = "prob")
    # results$stroke_p <- round(pred_prob[[2]] * 100, 2)
    # results$no_stroke_p <- round(pred_prob[[1]] * 100, 2)
    
    # --- OPTION B: LIVE DEMO SIMULATION ---
    w_age <- round(input$age * 0.65, 2)
    w_glucose <- round(input$glucose * 0.12, 2)
    w_hyper <- ifelse(input$hypertension == "1", 15.00, 1.50)
    w_heart <- ifelse(input$heart_disease == "1", 18.00, 1.20)
    w_bmi <- round(input$bmi * 0.25, 2)
    
    base_risk <- w_age + w_glucose + w_hyper + w_heart
    simulated_stroke <- min(99.9, max(0.1, round(base_risk, 2)))
    
    results$stroke_p <- simulated_stroke
    results$no_stroke_p <- round(100 - simulated_stroke, 2)
    
    df_shap <- data.frame(
      Feature = c("Age", "Heart Disease", "Hypertension", "Glucose Level", "BMI"),
      Contribution = c(w_age, w_heart, w_hyper, w_glucose, w_bmi)
    )
    df_shap <- df_shap[order(df_shap$Contribution), ]
    shap_values(df_shap)
    
    new_row <- data.frame(
      `Patient ID` = paste0("#", 1000 + counter()),
      Age = input$age,
      Gender = input$gender,
      Hypertension = ifelse(input$hypertension == "1", "Yes", "No"),
      `Heart Disease` = ifelse(input$heart_disease == "1", "Yes", "No"),
      `Glucose Level` = input$glucose,
      BMI = input$bmi,
      `Stroke Risk` = paste0(results$stroke_p, "%"),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
    
    current_history <- history_data()
    updated_history <- rbind(new_row, current_history)
    history_data(updated_history)
  })
  
  # Dynamic UI Switch Manager
  output$dashboard_display <- renderUI({
    if (counter() == 0) {
      # FIRST IMPRESSION STATE: Empty placeholder panel with clean instructions
      fluidRow(
        box(
          title = "Patient Diagnostic System",
          width = 12,
          status = "primary",
          solidHeader = TRUE,
          p(style = "font-size: 16px; text-align: center; padding: 40px 0;",
            "No data analyzed yet. Please adjust the clinical parameters in the left sidebar menu and click ",
            tags$strong("Predict"), " to evaluate stroke risk profiles.")
        )
      )
    } else {
      # CALCULATED STATE: Shows complete analytical components cleanly
      tagList(
        fluidRow(
          box(
            title = "Prediction Summary", 
            width = 12, 
            collapsible = TRUE,
            uiOutput("prediction_cards")
          )
        ),
        fluidRow(
          box(
            title = "Risk Distribution Breakdown",
            width = 5,
            collapsible = TRUE,
            plotlyOutput("stroke_plot", height = "300px")
          ),
          box(
            title = "Patient-Specific Risk Drivers (SHAP Value Insights)",
            width = 7,
            collapsible = TRUE,
            plotlyOutput("importance_plot", height = "300px")
          )
        ),
        fluidRow(
          box(
            title = "Patient Risk History Log",
            width = 12,
            collapsible = TRUE,
            status = "primary",
            div(style = "overflow-x: auto;", 
                tableOutput("history_table")
            )
          )
        )
      )
    }
  })
  
  # Render custom colored UI metric cards
  output$prediction_cards <- renderUI({
    req(counter() > 0)
    fluidRow(
      column(width = 6,
             div(style = "background-color: #c94c3a; color: white; padding: 20px; border-radius: 3px; position: relative; margin-bottom: 10px;",
                 div(style = "font-size: 38px; font-weight: bold; line-height: 1.2;", paste0(results$stroke_p, "%")),
                 div(style = "font-size: 14px; font-weight: 500; opacity: 0.9;", "Probability of having a Stroke"),
                 div(class = "fa fa-info", style = "position: absolute; right: 25px; bottom: 15px; font-size: 55px; opacity: 0.15;")
             )
      ),
      column(width = 6,
             div(style = "background-color: #27ae60; color: white; padding: 20px; border-radius: 3px; position: relative; margin-bottom: 10px;",
                 div(style = "font-size: 38px; font-weight: bold; line-height: 1.2;", paste0(results$no_stroke_p, "%")),
                 div(style = "font-size: 14px; font-weight: 500; opacity: 0.9;", "Probability of not having a Stroke"),
                 div(class = "fa fa-info", style = "position: absolute; right: 25px; bottom: 15px; font-size: 55px; opacity: 0.15;")
             )
      )
    )
  })
  
  # Render Donut Chart
  output$stroke_plot <- renderPlotly({
    req(counter() > 0)
    plot_ly(
      labels = c("No Stroke Risk", "Stroke Risk"),
      values = c(results$no_stroke_p, results$stroke_p),
      type = 'pie',
      hole = 0.6,
      marker = list(colors = c("#27ae60", "#c94c3a")),
      textinfo = 'percent',
      hoverinfo = 'text',
      text = ~paste0(c("No Stroke Risk: ", "Stroke Risk: "), c(results$no_stroke_p, results$stroke_p), "%")
    ) %>%
      layout(
        showlegend = TRUE,
        legend = list(orientation = "h", xanchor = "center", x = 0.5, y = -0.1),
        margin = list(l = 10, r = 10, t = 10, b = 10)
      )
  })
  
  # Render SHAP Chart
  output$importance_plot <- renderPlotly({
    req(counter() > 0)
    df <- shap_values()
    df$Feature <- factor(df$Feature, levels = df$Feature)
    
    plot_ly(
      data = df,
      x = ~Contribution,
      y = ~Feature,
      type = 'bar',
      orientation = 'h',
      marker = list(color = '#34495e'),
      hoverinfo = 'text',
      text = ~paste0("Risk Weight Contribution: +", Contribution)
    ) %>%
      layout(
        xaxis = list(title = "Relative Risk Impact Weight"),
        yaxis = list(title = ""),
        margin = list(l = 100, r = 20, t = 20, b = 40)
      )
  })
  
  # Render Patient History Log Table
  output$history_table <- renderTable({
    req(counter() > 0)
    history_data()
  }, striped = TRUE, hover = TRUE, spacing = "m", align = "c", width = "100%")
  
  # Generating PDF Reports
  output$download_report <- downloadHandler(
    filename = function() {
      paste0("Stroke_Risk_Report_", Sys.Date(), ".pdf")
    },
    content = function(file) {
      req(counter() > 0)
      tempReport <- file.path(tempdir(), "report.Rmd")
      
      report_text <- paste0(
        "---\n",
        "title: \"Stroke Assessment Clinical Report\"\n",
        "date: \"", Sys.Date(), "\"\n",
        "output: pdf_document\n",
        "---\n\n",
        "### 1. Patient Demographics & Background Clinical Metrics\n",
        "***\n",
        "- **Age:** ", input$age, " years old\n",
        "- **Gender:** ", input$gender, "\n",
        "- **Hypertension History:** ", ifelse(input$hypertension == "1", "Yes", "No"), "\n",
        "- **Heart Disease History:** ", ifelse(input$heart_disease == "1", "Yes", "No"), "\n",
        "- **Average Glucose Level:** ", input$glucose, " mg/dL\n",
        "- **Body Mass Index (BMI):** ", input$bmi, " kg/m²\n\n",
        "### 2. Predictive Diagnostics Summary Output\n",
        "***\n",
        "- **Probability of having a Stroke:** **", results$stroke_p, "%**\n",
        "- **Probability of NOT having a Stroke:** **", results$no_stroke_p, "%**\n\n",
        "### 3. Clinical Disclaimer\n",
        "***\n",
        "*This analytical summary report is generated purely for screening support, automated risk calculation, and scientific evaluations.*"
      )
      
      writeLines(report_text, con = tempReport)
      rmarkdown::render(tempReport, output_file = file, envir = new.env(parent = globalenv()))
    }
  )
}

shinyApp(ui, server)