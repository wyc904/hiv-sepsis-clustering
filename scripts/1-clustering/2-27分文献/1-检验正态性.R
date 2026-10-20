setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要的包
library(readxl)
library(dplyr)
library(readxl)
library(dplyr)
library(lubridate)
library(writexl)
# 加载必要的包
library(readr)

# 读取Excel数据
data <- read_excel("0211.xlsx")

# 定义连续变量列表
continuous_vars <- c("age", "Cr", "PLT", "LYM", "WBC", "INR", "LDH", "ALB",
                     "GLU", "UREA", "PCT", "MONO", "CRP", "AST", "lac","charlson", "HIVRNA", "CD4")


# , "charlson"

# 1. 正态性检验与log转换
for (var in continuous_vars) {
  # 检查变量是否有零值或负值
  if (any(data[[var]] <= 0, na.rm = TRUE)) {
    # 添加小常数避免log(0)或负值问题
    data[[paste0("log_", var)]] <- log(data[[var]] + 1e-5)
  } else {
    data[[paste0("log_", var)]] <- log(data[[var]])
  }
  
  # 对原始变量进行Shapiro-Wilk正态性检验
  test_result <- shapiro.test(data[[var]])
  
  # 输出检验结果
  cat("变量:", var, 
      "\tW统计量:", round(test_result$statistic, 4),
      "\tp值:", format.pval(test_result$p.value, digits = 4),
      "\t是否正态:", ifelse(test_result$p.value > 0.05, "是", "否"), "\n")
  
  # 如果非正态，使用log转换后的变量替代原始变量
  if (test_result$p.value < 0.05) {
    data[[var]] <- data[[paste0("log_", var)]]
    cat("---> 已对", var, "进行log转换\n")
  } else {
    # 移除不需要的log列
    data[[paste0("log_", var)]] <- NULL
  }
}

# 2. 对所有连续变量进行z-score标准化
for (var in continuous_vars) {
  # 计算均值和标准差
  mean_val <- mean(data[[var]], na.rm = TRUE)
  sd_val <- sd(data[[var]], na.rm = TRUE)
  
  # 执行z-score标准化
  data[[paste0("z_", var)]] <- (data[[var]] - mean_val) / sd_val
  
  # 输出标准化信息
  cat("变量:", var, 
      "\t标准化后均值:", round(mean(data[[paste0("z_", var)]], na.rm = TRUE), 6),
      "\t标准差:", round(sd(data[[paste0("z_", var)]], na.rm = TRUE), 6), "\n")
}




write_xlsx(data, "processed_data.xlsx")




















