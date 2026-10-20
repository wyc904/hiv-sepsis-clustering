



# 加载必要的库
library(readxl)
library(dplyr)
library(lubridate)
library(writexl)

library(openxlsx)
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
# 
# setwd("D:/Desktop/Cursor/")
# # 
# list.files()


# "姓名", "性别", "当前年龄"
# 工作簿1
# 读取两个Excel文件
cat("开始读取Excel文件...\n")
df <- read_excel("mimic-缺失.xlsx")

# colnames(df_total)





# 创建缺失统计函数
missing_stats <- function(df) {
  missing_count <- colSums(is.na(df))
  missing_percent <- round(missing_count / nrow(df) * 100, 2)
  data.frame(
    Variable = names(missing_count),
    Missing_Count = missing_count,
    Missing_Percent = missing_percent,
    row.names = NULL
  )
}

# 应用函数到数据框
missing_summary <- missing_stats(df)

# 添加数据类型信息
missing_summary$Data_Type <- sapply(df, class)

# 输出到Excel
write.xlsx(missing_summary, 
           "Missing_Data_Report.xlsx",
           creator = "R Analysis",
           sheetName = "Missing Data",
           row.names = FALSE)

# 在控制台打印结果
print("缺失统计已保存到 Missing_Data_Report.xlsx")
print(missing_summary)


