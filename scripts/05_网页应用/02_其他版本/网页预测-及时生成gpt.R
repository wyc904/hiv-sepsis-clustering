library(shiny)
library(ggplot2)
library(dplyr)
library(bslib)

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
  
  prob1 <- 1 / (1 + exp(-logit))   # Subtype 1: Immunosuppression-OI (lower mortality risk)
  prob2 <- 1 - prob1               # Subtype 2: Sepsis-MOF (higher mortality risk)
  
  return(list(
    prob1 = prob1,
    prob2 = prob2,
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
  theme = bs_theme(bootswatch = "flatly"),
  titlePanel("Clinical Decision Support: Clinical Subphenotypes Prediction in HIV-associated Sepsis"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Patient Clinical Variables"),
      numericInput("CCI", "Charlson Comorbidity Index (CCI)", value = 2, min = 0, max = 20),
      numericInput("TBIL", "Total Bilirubin (μmol/L)", value = 20, min = 0, max = 500),
      numericInput("Cr", "Creatinine (μmol/L)", value = 90, min = 0, max = 2000),
      numericInput("LYM", "Lymphocyte count (10^9/L)", value = 0.8, min = 0, max = 10),
      numericInput("INR", "International Normalized Ratio (INR)", value = 1.2, min = 0.5, max = 5),
      numericInput("LDH", "Lactate Dehydrogenase (U/L)", value = 300, min = 50, max = 2000),
      numericInput("GLU", "Glucose (mmol/L)", value = 6, min = 0, max = 50),
      numericInput("UREA", "Urea Nitrogen (mmol/L)", value = 12, min = 0, max = 50),
      numericInput("AST", "Aspartate Aminotransferase (U/L)", value = 40, min = 0, max = 2000),
      numericInput("LAC", "Lactate (mmol/L)", value = 2.0, min = 0, max = 20),
      numericInput("CD4", "CD4 count (/μL)", value = 100, min = 0, max = 2000)
    ),
    
    mainPanel(
      fluidRow(
        column(
          width = 12,
          div(style="background-color:white; padding:25px; border-radius:12px; 
                    box-shadow:0 2px 6px rgba(0,0,0,0.15); margin-bottom:20px;",
              h3("Prediction Summary", style="margin-bottom:20px;"),
              
              fluidRow(
                column(
                  width = 6,
                  uiOutput("riskText")
                ),
                column(
                  width = 6,
                  div(style="padding:10px; background-color:#f8f9fa; border-radius:8px; border-left:4px solid #007bff;",
                      h5("Clinical Meaning"),
                      p("Subtype 1 (Immunosuppression with OIs): patients generally show 
                         opportunistic infections and lower early mortality, requiring 
                         infection-targeted management.", style="font-size:13px; color:#555;"),
                      p("Subtype 2 (Sepsis with Multiple Organ Failure): patients present 
                         higher organ dysfunction and increased mortality risk, requiring 
                         aggressive monitoring and intervention.", style="font-size:13px; color:#555;")
                  )
                )
              )
          )
        )
      ),
      fluidRow(
        column(
          width = 6,
          div(style="background-color:white; padding:20px; border-radius:12px;
                    box-shadow:0 2px 6px rgba(0,0,0,0.15);",
              h4("Subtype Probability"),
              plotOutput("gaugePlot", height = "260px"),
              p("Probability distribution of Subtype 1 vs Subtype 2.", 
                style="font-size:13px; color:#555; font-style:italic;")
          )
        ),
        column(
          width = 6,
          div(style="background-color:white; padding:20px; border-radius:12px;
                    box-shadow:0 2px 6px rgba(0,0,0,0.15);",
              h4("Variable Contribution"),
              plotOutput("waterfallPlot", height = "260px"),
              p("Contribution of individual predictors to the logit score.", 
                style="font-size:13px; color:#555; font-style:italic;")
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          div(style="background-color:#f9f9f9; padding:15px; border-radius:8px; 
                    margin-top:20px; border-left:4px solid #007bff;",
              h4("Clinical Interpretation"),
              p("This model stratifies patients with HIV-associated sepsis into two 
                 prognostic subtypes based on laboratory and clinical variables. 
                 Subtype 1 patients demonstrate immunosuppression with opportunistic infections, 
                 generally with lower early mortality but requiring infection-focused management. 
                 Subtype 2 patients are characterized by higher organ dysfunction and 
                 are at elevated risk of mortality, requiring aggressive monitoring and intervention.",
                style="font-size:14px; color:#444;")
          )
        )
      )
    )
  )
)

# ---- SERVER ----
server <- function(input, output) {
  result <- reactive({
    predict_cluster(input$CCI, input$TBIL, input$Cr, input$LYM,
                    input$INR, input$LDH, input$GLU, input$UREA,
                    input$AST, input$LAC, input$CD4)
  })
  
  # Risk summary card
  output$riskText <- renderUI({
    prob1 <- result()$prob1
    prob2 <- result()$prob2
    
    dominantSubtype <- ifelse(prob1 > prob2, "Subtype 1 (Immunosuppression-OI)", 
                              "Subtype 2 (Sepsis-MOF)")
    
    tagList(
      div(style="font-size:22px; font-weight:bold; color:#333; margin-bottom:8px;",
          "Subtype Prediction"),
      
      div(style="margin-bottom:15px;",
          span(style="font-size:20px; font-weight:bold; color:#1f77b4;",
               sprintf("Subtype 1 Probability: %.1f%%", prob1*100)), br(),
          span(style="font-size:20px; font-weight:bold; color:#ff7f0e;",
               sprintf("Subtype 2 Probability: %.1f%%", prob2*100)), br(),
          span(style="font-size:18px; font-weight:600; color:#444;",
               paste("More likely:", dominantSubtype))
      ),
      
      # 双向进度条
      div(style="background-color:#e9ecef; border-radius:6px; height:22px; width:100%; overflow:hidden; display:flex;",
          div(style=paste0("height:100%; width:", round(prob1*100), "%; background-color:#1f77b4;")),
          div(style=paste0("height:100%; width:", round(prob2*100), "%; background-color:#ff7f0e;"))
      )
    )
  })
  
  
  # Probability bar plot
  output$gaugePlot <- renderPlot({
    probs <- data.frame(
      Subtype = c("Subtype 1", "Subtype 2"),
      Probability = c(result()$prob1, result()$prob2)
    )
    ggplot(probs, aes(x = Subtype, y = Probability, fill = Subtype)) +
      geom_col(width = 0.5) +
      scale_y_continuous(labels = scales::percent, limits = c(0,1)) +
      scale_fill_manual(values = c("forestgreen", "red")) +
      theme_minimal(base_size = 14) +
      theme(legend.position = "none",
            axis.text.x = element_text(size=12, face="bold")) +
      labs(y = "Probability", x = "")
  })
  
  # Waterfall plot
  output$waterfallPlot <- renderPlot({
    contrib <- sort(result()$contrib, decreasing = TRUE)
    df <- data.frame(Variable = names(contrib), Contribution = contrib)
    ggplot(df, aes(x = reorder(Variable, Contribution), y = Contribution, fill = Contribution > 0)) +
      geom_col(width=0.6) +
      coord_flip() +
      scale_fill_manual(values = c("steelblue", "tomato")) +
      theme_minimal(base_size = 14) +
      theme(legend.position = "none") +
      labs(x = "Variable", y = "Contribution (logit units)")
  })
}

# ---- Run app ----
shinyApp(ui = ui, server = server)
