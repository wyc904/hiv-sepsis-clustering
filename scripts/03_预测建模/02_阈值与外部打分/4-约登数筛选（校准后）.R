



# 加载必要的包
library(readxl)
library(pROC)
library(dplyr)
library(openxlsx)

# 设置工作目录
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
# 读取数据
cat("开始读取Excel文件...\n")
df_total <- read_excel("sepsis指标检测数据(1).xlsx")


colnames(df_total)

# 
# data$logit <- -13.498381 + 
#   0.048692 * data$TBIL +
#   0.022428 * data$Cr +
#   3.211523 * data$INR +
#   0.001789 * data$LDH +
#   0.010546 * data$GLU +
#   0.08723 * data$UREA +
#   0.555907 * data$LAC +
#   0.004718 * data$CRP +
#   0.000001 * data$VL +  # VL系数极小，实际影响可忽略
#   0.005605 * data$CD4
# 



# 
# # 原有
# # 定义风险评分计算函数
# calculate_risk_groups <- function(data) {
#   # 计算logit值
#   data$logit <- -20.789426 + 
#     0.177599 * data$CCI +
#     0.065839 * data$TBIL +
#     0.029115 * data$Cr +
#     1.022455 * data$LYM +
#     4.12217 * data$INR +
#     0.001907 * data$LDH +
#     0.016368 * data$GLU +
#     0.099735 * data$UREA +
#     0.006523 * data$AST +
#     0.643103 * data$LAC +
#   
#    
#    
#     0.005557 * data$CD4
#   # 计算概率值
#   data$prob <- 1 / (1 + exp(-data$logit))
#   
#   # 根据截断点分组 (0.5498874)
#   data$group <- ifelse(data$prob >= 0.4113599, "1", "0")
#   
#   # 转换为因子变量
#   data$group <- factor(data$group, levels = c("0", "1"))
#   
#   return(data)
# }
# 


# 0.1750 * data$CCI +



# 定义风险评分计算函数
calculate_risk_groups <- function(data) {
  # 计算logit值
  data$logit = -21.221 + 
    0.0649 * data$TBIL +
    0.0287 * data$Cr +
    1.008 * data$LYM +
    4.066 * data$INR +
    0.00188 * data$LDH +
    0.0161 * data$GLU +
    0.0983 * data$UREA +
    0.00643 * data$AST +
    0.634 * data$LAC +
    0.18 * data$PCT +
    0.175 * data$CCI +
    1.76 * data$mono +
    0.0001 * data$VL +
   0.00548 * data$CD4
  data$prob <- 1 / (1 + exp(-data$logit))   # 更稳定的概率计算方式

  
  # 根据截断点分组 (0.5498874)
  data$group <- ifelse(data$prob >= 0.252984, "1", "0")
  
  # 转换为因子变量
  data$group <- factor(data$group, levels = c("0", "1"))
  
  return(data)
}





# 应用风险评分模型
cat("应用风险评分模型...\n")
df_total <- calculate_risk_groups(df_total)

# 检查分组结果
cat("\n风险分组分布:\n")
print(table(df_total$group))

# 描述性统计
cat("\n概率值统计摘要:\n")
print(summary(df_total$prob))

# 保存结果到新Excel文件
cat("\n保存结果到Excel文件...\n")
wb <- createWorkbook()
addWorksheet(wb, "风险分组结果")
writeData(wb, sheet = "风险分组结果", df_total)
saveWorkbook(wb, "240-11.xlsx", overwrite = TRUE)

cat("\n分析完成! 结果已保存为: 风险评分分组结果.xlsx\n")
































