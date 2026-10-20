library(shiny)
library(ggplot2)
library(dplyr)
library(shinydashboard)
library(shinydashboardPlus)

# 定义逻辑回归模型函数
predict_subtype <- function(CCI, TBIL, Cr, LYM, INR, LDH, GLU, UREA, AST, LAC, CD4) {
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
  
  prob <- 1 / (1 + exp(-logit))
  
  classification <- ifelse(prob >= 0.252984, 
                           "Subtype 2: Sepsis with Multiorgan Dysfunction (High Mortality Risk)", 
                           "Subtype 1: Immunosuppression with Opportunistic Infections (Lower Mortality Risk)")
  
  list(prob = round(prob, 3), classification = classification, logit = round(logit, 2))
}

# UI
ui <- dashboardPage(
  dashboardHeader(title = "HIV-Sepsis Subtyping Tool"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Patient Input", tabName = "input", icon = icon("user-md")),
      menuItem("Results", tabName = "results", icon = icon("chart-pie"))
    )
  ),
  dashboardBody(
    tabItems(
      # 输入界面
      tabItem(tabName = "input",
              fluidRow(
                box(title = "Patient Clinical Parameters", width = 6, solidHeader = TRUE, status = "primary",
                    numericInput("CCI", "Charlson Comorbidity Index (CCI):", value = 3, min = 0, max = 20, step = 1),
                    numericInput("TBIL", "Total Bilirubin (µmol/L):", value = 20, min = 0, max = 200, step = 0.1),
                    numericInput("Cr", "Creatinine (µmol/L):", value = 80, min = 20, max = 800, step = 0.1),
                    numericInput("LYM", "Lymphocyte count (10^9/L):", value = 1.2, min = 0, max = 10, step = 0.1),
                    numericInput("INR", "INR:", value = 1.1, min = 0.5, max = 5, step = 0.01),
                    numericInput("LDH", "LDH (U/L):", value = 300, min = 100, max = 3000, step = 1),
                    numericInput("GLU", "Glucose (mmol/L):", value = 6, min = 2, max = 30, step = 0.1),
                    numericInput("UREA", "Urea (mmol/L):", value = 8, min = 2, max = 40, step = 0.1),
                    numericInput("AST", "AST (U/L):", value = 40, min = 5, max = 500, step = 1),
                    numericInput("LAC", "Lactate (mmol/L):", value = 2, min = 0.5, max = 20, step = 0.1),
                    numericInput("CD4", "CD4 count (cells/µL):", value = 150, min = 1, max = 1000, step = 1)
                )
              )
      ),
      
      # 结果界面
      tabItem(tabName = "results",
              fluidRow(
                box(title = "Subtype Classification", width = 6, status = "info", solidHeader = TRUE,
                    verbatimTextOutput("classification"),
                    uiOutput("riskMessage")
                ),
                box(title = "Probability Gauge", width = 6, status = "danger", solidHeader = TRUE,
                    plotOutput("gaugePlot", height = "300px"))
              ),
              fluidRow(
                box(title = "Variable Contribution (Waterfall Plot)", width = 12, status = "warning", solidHeader = TRUE,
                    plotOutput("waterfallPlot", height = "400px"))
              ),
              fluidRow(
                box(title = "Interpretation", width = 12, status = "success", solidHeader = TRUE,
                    h4("Clinical Explanation:"),
                    p("Patients are stratified into two HIV-sepsis subtypes based on their clinical and laboratory profiles."),
                    tags$ul(
                      tags$li(strong("Subtype 1 - Immunosuppression with Opportunistic Infections:"), 
                              " Patients primarily characterized by profound immune suppression and opportunistic infections. 
                              They show relatively lower short-term mortality risk, but require careful infection management."),
                      tags$li(strong("Subtype 2 - Sepsis with Multiorgan Dysfunction:"), 
                              " Patients presenting with severe systemic inflammation and multiorgan dysfunction. 
                              They carry a high mortality risk and need immediate intensive care interventions.")
                    )
                )
              )
      )
    )
  )
)

# 服务器逻辑
server <- function(input, output) {
  result <- reactive({
    predict_subtype(input$CCI, input$TBIL, input$Cr, input$LYM, input$INR, 
                    input$LDH, input$GLU, input$UREA, input$AST, input$LAC, input$CD4)
  })
  
  output$classification <- renderText({
    paste("Predicted Classification:", result()$classification, 
          "\nPredicted Probability:", result()$prob)
  })
  
  output$riskMessage <- renderUI({
    prob <- result()$prob
    if (grepl("Subtype 2", result()$classification)) {
      div(style = "color:red; font-weight:bold;", 
          "⚠ High Mortality Risk: This patient likely belongs to Subtype 2, requiring aggressive management.")
    } else {
      div(style = "color:green; font-weight:bold;", 
          "✔ Lower Mortality Risk: This patient likely belongs to Subtype 1, requiring infection-focused monitoring.")
    }
  })
  
  # 仪表盘概率图
  output$gaugePlot <- renderPlot({
    prob <- result()$prob
    ggplot(data.frame(x = c(0, 1)), aes(x)) +
      geom_rect(aes(xmin = 0, xmax = prob, ymin = 0, ymax = 1), fill = ifelse(prob > 0.25, "red", "green")) +
      geom_text(aes(x = prob, y = 0.5, label = paste0(prob * 100, "%")), size = 6, vjust = -0.5) +
      theme_void()
  })
  
  # 瀑布图：各变量贡献
  output$waterfallPlot <- renderPlot({
    coef <- c(0.1750,0.0649,0.0287,1.008,4.066,0.00188,0.0161,0.0983,0.00643,0.634,0.00548)
    vars <- c("CCI","TBIL","Cr","LYM","INR","LDH","GLU","UREA","AST","LAC","CD4")
    values <- c(input$CCI,input$TBIL,input$Cr,input$LYM,input$INR,input$LDH,
                input$GLU,input$UREA,input$AST,input$LAC,input$CD4)
    contrib <- coef * values
    
    df <- data.frame(Variable = vars, Contribution = contrib)
    ggplot(df, aes(x = reorder(Variable, Contribution), y = Contribution, fill = Contribution > 0)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      theme_minimal() +
      labs(title = "Variable Contribution to Logit Score", x = "Variable", y = "Contribution") +
      scale_fill_manual(values = c("TRUE"="tomato","FALSE"="steelblue"), guide = FALSE)
  })
}

shinyApp(ui = ui, server = server)
