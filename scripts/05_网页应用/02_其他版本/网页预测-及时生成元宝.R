library(shiny)
library(ggplot2)
library(dplyr)
library(bslib)
library(plotly)

# ---- Prediction function ----
predict_cluster <- function(CCI, TBIL, Cr, LYM, INR, LDH, GLU, UREA, AST, LAC, CD4) {
  logit <- -21.221 + 
    0.1750 * CCI +
    0.0649 * TBIL +
    0.0287 * Cr +
    1.008 * LYM +
    4.066 * INR +
    0.00188 * LDH +
    0.0161 * GLU +
    0.0983 * UREA +
    0.00643 * AST +
    0.634 * LAC +
    0.00548 * CD4
  
  prob_high_risk <- 1 / (1 + exp(-logit))   # High mortality risk (Sepsis with Multiple Organ Failure)
  prob_low_risk <- 1 - prob_high_risk        # Lower mortality risk (Immunosuppression with Opportunistic Infections)
  
  return(list(
    high_risk_prob = prob_high_risk,
    low_risk_prob = prob_low_risk,
    logit = logit,
    contrib = c(
      CCI = 0.1750 * CCI,
      TBIL = 0.0649 * TBIL,
      Cr   = 0.0287 * Cr,
      LYM  = 1.008 * LYM,
      INR  = 4.066 * INR,
      LDH  = 0.00188 * LDH,
      GLU  = 0.0161 * GLU,
      UREA = 0.0983 * UREA,
      AST  = 0.00643 * AST,
      LAC  = 0.634 * LAC,
      CD4  = 0.00548 * CD4
    )
  ))
}

# ---- UI ----
ui <- page_fluid(
  theme = bs_theme(
    bootswatch = "flatly",
    primary = "#1f77b4",  # Clinical blue
    secondary = "#d62728", # Alert red
    base_font = font_google("Noto Sans")
  ),
  titlePanel("HIV-Associated Sepsis Subtyping Tool"),
  
  sidebarLayout(
    sidebarPanel(
      width = 4,
      h4("Patient Clinical Variables", class = "text-primary"),
      helpText("Enter the latest laboratory results"),
      
      tabsetPanel(
        tabPanel("Key Variables",
                 numericInput("INR", "International Normalized Ratio (INR)", value = 1.2, min = 0.5, max = 5, step = 0.1),
                 numericInput("LAC", "Lactate (mmol/L)", value = 2.0, min = 0, max = 20, step = 0.1),
                 numericInput("LYM", "Lymphocyte count (10^9/L)", value = 0.8, min = 0, max = 10, step = 0.1),
                 numericInput("CD4", "CD4 count (cells/μL)", value = 100, min = 0, max = 2000)
        ),
        tabPanel("Additional Variables",
                 numericInput("CCI", "Charlson Comorbidity Index (CCI)", value = 2, min = 0, max = 20),
                 numericInput("TBIL", "Total Bilirubin (μmol/L)", value = 20, min = 0, max = 500),
                 numericInput("Cr", "Creatinine (μmol/L)", value = 90, min = 0, max = 2000),
                 numericInput("LDH", "Lactate Dehydrogenase (U/L)", value = 300, min = 50, max = 2000),
                 numericInput("GLU", "Glucose (mmol/L)", value = 6, min = 0, max = 50),
                 numericInput("UREA", "Urea Nitrogen (mmol/L)", value = 12, min = 0, max = 50),
                 numericInput("AST", "Aspartate Aminotransferase (U/L)", value = 40, min = 0, max = 2000)
        )
      ),
      
      actionButton("calculate", "Calculate Risk", class = "btn-primary btn-lg", icon = icon("calculator")),
      actionButton("reset", "Reset", class = "btn-outline-secondary"),
      
      hr(),
      div(class = "alert alert-info",
          h5("Clinical Guidance"),
          tags$ul(
            tags$li("INR > 1.5 indicates coagulopathy risk"),
            tags$li("Lactate > 4 mmol/L suggests tissue hypoperfusion"),
            tags$li("Lymphocyte count < 0.8×10⁹/L indicates severe immunosuppression")
          )
      )
    ),
    
    mainPanel(
      width = 8,
      fluidRow(
        column(
          width = 12,
          div(class = "card border-primary",
              div(class = "card-header bg-primary text-white", 
                  h4("Prediction Summary", class = "mb-0")),
              div(class = "card-body",
                  uiOutput("riskText"),
                  hr(),
                  fluidRow(
                    column(6, 
                           div(class = "alert alert-danger",
                               h5("Sepsis with Multiple Organ Failure"),
                               p("Characteristics: Multiple organ dysfunction, high mortality risk", class = "mb-1"),
                               p("Management focus: Organ support, hemodynamic monitoring")
                           )
                    ),
                    column(6,
                           div(class = "alert alert-success",
                               h5("Immunosuppression with Opportunistic Infections"),
                               p("Characteristics: Opportunistic infections, lower mortality risk", class = "mb-1"),
                               p("Management focus: Antimicrobial therapy, immune reconstitution")
                           )
                    )
                  )
              )
          )
        )
      ),
      
      fluidRow(
        column(
          width = 6,
          div(class = "card",
              div(class = "card-header", h4("Subtype Probability Distribution")),
              div(class = "card-body",
                  plotlyOutput("gaugePlot", height = "300px")
              )
          )
        ),
        column(
          width = 6,
          div(class = "card",
              div(class = "card-header", h4("Variable Contribution")),
              div(class = "card-body",
                  plotOutput("waterfallPlot", height = "300px")
              )
          )
        )
      ),
      
      fluidRow(
        column(
          width = 12,
          div(class = "card border-info mt-3",
              div(class = "card-header bg-info text-white", 
                  h4("Clinical Interpretation and Recommendations", class = "mb-0")),
              div(class = "card-body",
                  uiOutput("clinicalInterpretation"),
                  hr(),
                  div(class = "text-muted small",
                      p("Disclaimer: This tool is for clinical decision support only and does not replace professional medical judgment."),
                      p("Model formula: logit = -21.221 + 0.1750*CCI + ... + 0.00548*CD4")
                  )
              )
          )
        )
      )
    )
  )
)

# ---- SERVER ----
server <- function(input, output, session) {
  # Reset button
  observeEvent(input$reset, {
    updateNumericInput(session, "CCI", value = 2)
    updateNumericInput(session, "TBIL", value = 20)
    updateNumericInput(session, "Cr", value = 90)
    updateNumericInput(session, "LYM", value = 0.8)
    updateNumericInput(session, "INR", value = 1.2)
    updateNumericInput(session, "LDH", value = 300)
    updateNumericInput(session, "GLU", value = 6)
    updateNumericInput(session, "UREA", value = 12)
    updateNumericInput(session, "AST", value = 40)
    updateNumericInput(session, "LAC", value = 2.0)
    updateNumericInput(session, "CD4", value = 100)
  })
  
  # Calculate results
  result <- reactive({
    req(input$calculate)  # Wait for calculate button
    
    predict_cluster(
      input$CCI, input$TBIL, input$Cr, input$LYM,
      input$INR, input$LDH, input$GLU, input$UREA,
      input$AST, input$LAC, input$CD4
    )
  }) %>% bindEvent(input$calculate)
  
  # Risk summary - JAMA style
  output$riskText <- renderUI({
    req(result())
    
    high_risk_prob <- result()$high_risk_prob
    low_risk_prob <- result()$low_risk_prob
    
    # Risk stratification
    riskColor <- ifelse(high_risk_prob >= 0.7, "#d73027", 
                        ifelse(high_risk_prob >= 0.5, "#fc8d59", "#1a9850"))
    riskLabel <- ifelse(high_risk_prob >= 0.7, 
                        "High Risk (Sepsis with Multiple Organ Failure)", 
                        ifelse(high_risk_prob >= 0.5, 
                               "Intermediate Risk (Mixed Profile)", 
                               "Low Risk (Immunosuppression with Opportunistic Infections)"))
    
    tagList(
      div(style = "font-size:20px; font-weight:bold; color:#333; margin-bottom:10px;",
          "Predicted Subtype Probabilities"),
      
      div(style = "margin-bottom:15px;",
          div(style = "display: flex; align-items: center; margin-bottom:8px;",
              div(style = paste0("width:16px; height:16px; background-color:", riskColor, "; margin-right:8px;")),
              span(style = "font-size:18px; font-weight:600; color:#444;", riskLabel)
          ),
          
          div(style = "display: flex; justify-content: space-between; margin-bottom:12px;",
              div(style = "text-align: center;",
                  span(style = "font-size:14px; color:#555;", "Immunosuppression-OI"),
                  br(),
                  span(style = "font-size:22px; font-weight:bold; color:#1a9850;",
                       sprintf("%.1f%%", low_risk_prob * 100))
              ),
              div(style = "text-align: center;",
                  span(style = "font-size:14px; color:#555;", "Sepsis-MOF"),
                  br(),
                  span(style = paste0("font-size:22px; font-weight:bold; color:", riskColor, ";"),
                       sprintf("%.1f%%", high_risk_prob * 100))
              )
          ),
          
          # JAMA-style progress bar
          div(style = "background-color:#f0f0f0; border-radius:4px; height:18px; width:100%; overflow:hidden;",
              div(style = paste0("height:100%; width:", round(high_risk_prob * 100), "%; 
                                 background:", riskColor, ";"))
          ),
          div(style = "display: flex; justify-content: space-between; margin-top:4px;",
              span(style = "font-size:12px; color:#555;", "0%"),
              span(style = "font-size:12px; color:#555;", "100%")
          )
      )
    )
  })
  
  # Clinical interpretation
  output$clinicalInterpretation <- renderUI({
    req(result())
    
    high_risk_prob <- result()$high_risk_prob
    
    tagList(
      p("Based on the current clinical variables:"),
      tags$ul(
        if(input$INR > 1.5) {
          tags$li(strong("Coagulopathy: "), sprintf("INR=%.2f indicates potential disseminated intravascular coagulation risk.", input$INR))
        },
        if(input$LAC > 4) {
          tags$li(strong("Tissue Hypoperfusion: "), sprintf("Lactate=%.1f mmol/L suggests inadequate tissue oxygenation.", input$LAC))
        },
        if(input$LYM < 0.8) {
          tags$li(strong("Severe Lymphopenia: "), sprintf("Lymphocyte count=%.1f×10⁹/L indicates profound immunosuppression.", input$LYM))
        },
        if(input$CD4 < 200) {
          tags$li(strong("CD4 Depletion: "), sprintf("CD4=%d cells/μL increases risk for opportunistic infections.", input$CD4))
        }
      ),
      if(high_risk_prob >= 0.7) {
        div(class = "alert alert-danger",
            h5("Management Recommendations:"),
            tags$ol(
              tags$li("Immediate transfer to intensive care unit"),
              tags$li("Initiate broad-spectrum antimicrobial therapy"),
              tags$li("Continuous hemodynamic monitoring"),
              tags$li("Daily Sequential Organ Failure Assessment (SOFA) scoring")
            )
        )
      } else {
        div(class = "alert alert-success",
            h5("Management Recommendations:"),
            tags$ol(
              tags$li("Comprehensive workup for opportunistic pathogens"),
              tags$li("Optimize antiretroviral therapy regimen"),
              tags$li("Monitor inflammatory biomarkers"),
              tags$li("Assess potential for immune reconstitution")
            )
        )
      }
    )
  })
  
  # Interactive gauge plot
  output$gaugePlot <- renderPlotly({
    req(result())
    
    high_risk_prob <- result()$high_risk_prob
    
    fig <- plot_ly(
      domain = list(x = c(0, 1), y = c(0, 1)),
      value = high_risk_prob * 100,
      title = list(text = "Sepsis-MOF Probability"),
      type = "indicator",
      mode = "gauge+number",
      gauge = list(
        axis = list(range = list(0, 100)),
        bar = list(color = ifelse(high_risk_prob > 0.7, "red", "blue")),
        steps = list(
          list(range = c(0, 50), color = "lightgreen"),
          list(range = c(50, 70), color = "yellow"),
          list(range = c(70, 100), color = "red")
        ),
        threshold = list(
          line = list(color = "black", width = 4),
          thickness = 0.75,
          value = high_risk_prob * 100
        )
      )
    )
    
    fig %>% layout(margin = list(l=20, r=20))
  })
  
  # Waterfall plot
  output$waterfallPlot <- renderPlot({
    req(result())
    
    contrib <- result()$contrib
    df <- data.frame(
      Variable = names(contrib),
      Contribution = contrib,
      Impact = ifelse(contrib > 0, "Positive", "Negative")
    ) %>% 
      arrange(desc(abs(Contribution)))
    
    ggplot(df, aes(x = reorder(Variable, Contribution), y = Contribution, fill = Impact)) +
      geom_bar(stat = "identity", width = 0.7) +
      scale_fill_manual(values = c("Negative" = "#1f77b4", "Positive" = "#d62728")) +
      coord_flip() +
      labs(x = "Clinical Variable", y = "Contribution to High-Risk Subtype (logit units)",
           title = "Variable Contribution to Prediction") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "top",
            plot.title = element_text(face = "bold"))
  })
}

# ---- Run app ----
shinyApp(ui = ui, server = server)