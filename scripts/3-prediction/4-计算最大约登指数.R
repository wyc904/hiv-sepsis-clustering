# ----------------------- 多变量逻辑回归预测 & 最大约登指数 -----------------------

# 加载必要的包
library(readxl)
library(pROC)
library(dplyr)
library(openxlsx)

# 设置工作目录
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
# 读取数据
cat("开始读取Excel文件...\n")
df_total <- read_excel("1690.xlsx")

# -----------------------
# 1. 根据公式计算 logit 和预测概率 p
# -----------------------
# 更优化的版本
df_total <- df_total %>%
  mutate(
    logit = -20.789426 + 
      0.177599 * CCI +
      0.065839 * TBIL +
      0.029115 * Cr +
      1.022455 * LYM +
      4.12217 * INR +
      0.001907 * LDH +
      0.016368 * GLU +
      0.099735 * UREA +
      0.006523 * AST +
      0.643103 * LAC +
      0.182929 * PCT +
      1.821501 * MONO +
      0.000001 * VL +
      0.005557 * CD4,
    p = 1 / (1 + exp(-logit))   # 更稳定的概率计算方式
  )

# -----------------------
# 2. 绘制 ROC 并计算最大约登指数
# -----------------------
# 假设结局变量名是 "death" (0=存活, 1=死亡)，请确认

# -----------------------
# 2. 绘制 ROC 并计算最大约登指数
# -----------------------
# 2. 绘制 ROC 并计算最大约登指数
# -----------------------
roc_obj <- roc(df_total$death, df_total$p, ci=TRUE)   # 注意这里用 death 而不是 cluster

# 最大约登指数对应的最佳截断点
opt <- coords(
  roc_obj,
  "best",
  ret = c("threshold", "sensitivity", "specificity", "youden"),
  best.method = "youden"
)

# 打印结果
cat("分析完成！ROC AUC = ", auc(roc_obj), "\n")
cat("最佳截断点（最大约登指数）= ", opt$threshold, "\n")
cat("敏感度 = ", opt$sensitivity, "，特异度 = ", opt$specificity, "\n")
cat("约登指数 = ", opt$youden, "\n")

# -----------------------
# 3. 根据最佳截断点生成 cluster 变量
# -----------------------
df_total <- df_total %>%
  mutate(cluster = ifelse(p >= opt$threshold, 1, 0))




# 创建结果数据框
roc_results <- data.frame(
  指标 = c("ROC AUC", "最佳截断点", "敏感度", "特异度", "约登指数"),
  值 = c(auc(roc_obj), opt$threshold, opt$sensitivity, opt$specificity, opt$youden)
)

# 保存结果到Excel文件
# 如果文件已存在，则追加到新工作表
if (file.exists("Logistic_Model_Results.xlsx")) {
  wb <- loadWorkbook("Logistic_Model_Results.xlsx")
  addWorksheet(wb, "ROC_Analysis")
  writeData(wb, "ROC_Analysis", roc_results)
  saveWorkbook(wb, "Logistic_Model_Results.xlsx", overwrite = TRUE)
  cat("\nROC分析结果已添加到 Logistic_Model_Results.xlsx\n")
} else {
  # 如果文件不存在，创建新文件
  wb <- createWorkbook()
  addWorksheet(wb, "ROC_Analysis")
  writeData(wb, "ROC_Analysis", roc_results)
  saveWorkbook(wb, "Logistic_约登指数.xlsx")
  cat("\nROC分析结果已保存为 Logistic_Model_Results.xlsx\n")
}




