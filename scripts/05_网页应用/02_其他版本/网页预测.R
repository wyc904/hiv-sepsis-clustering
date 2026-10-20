# 加载必要的包
library(shiny)
library(ggplot2)
library(dplyr)

# 定义逻辑回归模型函数（基于假设的系数）
predict_cluster <- function(SOFA, UREA, PCT, Cr, LAC) {
  # 标准化变量（基于假设的均值和标准差）
  SOFA_z <- (SOFA - 8) / 3
  UREA_z <- (UREA - 12) / 5
  PCT_z <- (PCT - 2.5) / 1.5
  Cr_z <- (Cr - 1.2) / 0.5
  LAC_z <- (LAC - 2.0) / 0.8
  
  # 计算线性组合（基于假设的系数）
  linear_score <- 1.2 * SOFA_z + 1.0 * UREA_z + 0.8 * PCT_z + 0.7 * Cr_z + 0.6 * LAC_z
  
  # 计算属于Cluster A的概率
  prob_A <- 1 / (1 + exp(-linear_score))
  
  # 返回结果
  return(list(
    probability = round(prob_A, 3),
    classification = ifelse(prob_A > 0.5, "Cluster A (高危)", "Cluster B (低危)"),
    score = round(linear_score, 2)
  ))
}

# 创建Shiny应用界面
ui <- fluidPage(
  titlePanel("临床患者分群预测工具"),
  sidebarLayout(
    sidebarPanel(
      h4("请输入患者临床指标:"),
      numericInput("sofa", "SOFA评分:", value = 8, min = 0, max = 24, step = 0.1),
      numericInput("urea", "尿素(UREA, mmol/L):", value = 12, min = 0, max = 50, step = 0.1),
      numericInput("pct", "降钙素原(PCT, ng/mL):", value = 2.5, min = 0, max = 20, step = 0.1),
      numericInput("cr", "肌酐(Cr, mg/dL):", value = 1.2, min = 0, max = 10, step = 0.1),
      numericInput("lac", "乳酸(LAC, mmol/L):", value = 2.0, min = 0, max = 15, step = 0.1),
      actionButton("calculate", "计算风险", class = "btn-primary")
    ),
    mainPanel(
      h3("预测结果:"),
      verbatimTextOutput("result"),
      br(),
      h4("风险解释:"),
      p("基于实验室指标聚类分析，患者被分为两个群体:"),
      tags$ul(
        tags$li(strong("Cluster A (高危):"), "预后较差，需要密切监测和积极干预"),
        tags$li(strong("Cluster B (低危):"), "预后较好，常规监测即可")
      ),
      br(),
      h4("使用说明:"),
      p("1. 输入患者的五项关键临床指标"),
      p("2. 点击'计算风险'按钮"),
      p("3. 查看预测概率和分类结果"),
      p("4. 概率 > 0.5 表示属于Cluster A (高危群组)")
    )
  )
)

# 定义服务器逻辑
server <- function(input, output) {
  observeEvent(input$calculate, {
    result <- predict_cluster(input$sofa, input$urea, input$pct, input$cr, input$lac)
    
    output$result <- renderText({
      paste0(
        "预测概率: ", result$probability, "\n",
        "风险分类: ", result$classification, "\n",
        "风险评分: ", result$score, "\n",
        "\n",
        ifelse(result$probability > 0.7, "高风险警报: 该患者极可能属于高危群组，建议立即干预",
               ifelse(result$probability > 0.5, "中度风险: 该患者可能属于高危群组，建议加强监测",
                      "低风险: 该患者可能属于低危群组，常规监测即可"))
      )
    })
  })
}

# 运行应用
shinyApp(ui = ui, server = server)