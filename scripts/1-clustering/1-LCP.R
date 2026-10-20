# 安装需要的包（如未安装）
# install.packages(c("mclust", "dplyr", "factoextra", "tableone", "openxlsx"))

library(mclust)
library(dplyr)
library(factoextra)
library(tableone)
library(openxlsx)  # 用于导出Excel
library(readxl)
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
cat("开始读取Excel文件...\n")
data <- read_excel("7-1800-质控28天死亡分组.xlsx")

# 分类变量
cat_vars <- c("gender")

# "PCT", "MONO",,"CRP", "WBC"

# 连续变量
cont_vars <- c("age", "HIVRNA8", "CD48", "CCI", "TBIL", "Cr", "PLT", "LYM",
               "INR", "LDH", "ALB", "GLU", "UREA", 
                "AST", "lac","CRP"
               ,"PCT","MONO",
               "WBC")

# 1. 哑变量编码 & 标准化
data_cat <- data %>% 
  dplyr::select(!!cat_vars) %>% 
  mutate(across(everything(), as.factor))

# 创建哑变量
data_cat_dummy <- model.matrix(~ . -1, data = data_cat) %>% as.data.frame()

# 标准化连续变量
data_cont_scaled <- data %>% 
  dplyr::select(!!cont_vars) %>% 
  scale() %>% 
  as.data.frame()

# 合并处理后的数据
data_cluster <- cbind(data_cont_scaled, data_cat_dummy)

# 2. GMM 聚类，并选定 2–5 类
set.seed(123)
gmm <- Mclust(data_cluster, G = 2:5)

best_k <- gmm$G
cat("最佳聚类数:", best_k, "\n")

# 3. 将聚类结果保存到原始数据
data$cluster <- gmm$classification

# 查看每个簇的样本数
cluster_counts <- table(data$cluster)
print(cluster_counts)

# 4. 聚类可视化
fviz_cluster(list(data = data_cluster, cluster = data$cluster), 
             geom = "point",
             ellipse.type = "norm", 
             main = paste("GMM Clustering: K =", best_k))

# 5. 生成聚类数选择依据并导出Excel
# 提取每个聚类数的统计量
criteria <- data.frame(
  K = 2:5,
  BIC = gmm$BIC[as.character(2:5)],
  logLik = sapply(2:5, function(k) {
    model <- gmm$models[[as.character(k)]]
    if (!is.null(model)) model$loglik else NA
  })
)

# 计算AIC值
criteria$AIC <- sapply(2:5, function(k) {
  model <- gmm$models[[as.character(k)]]
  if (!is.null(model)) -2 * model$loglik + 2 * model$df else NA
})

# 添加最佳聚类数标记
criteria$Best <- ifelse(criteria$K == best_k, "★", "")

# 导出到Excel
write.xlsx(criteria, "Cluster_Selection_Criteria.xlsx")
cat("聚类选择标准已导出到 Cluster_Selection_Criteria.xlsx\n")

# 6. 生成基线特征表（Table 1）
# 将cluster转换为因子
data$cluster <- as.factor(data$cluster)

# 创建TableOne对象
table1 <- CreateTableOne(
  vars = c(cont_vars, cat_vars),
  strata = "cluster",
  data = data,
  factorVars = cat_vars
)

# 打印表格
print(table1, showAllLevels = TRUE)


# ===============================
# 7. 导出分群后的完整数据到Excel - 新增功能
# ===============================
# 添加聚类分布信息作为元数据
cluster_info <- data.frame(
  Cluster = names(cluster_counts),
  Count = as.numeric(cluster_counts),
  Proportion = round(as.numeric(cluster_counts)/sum(cluster_counts), 3)
)

# 创建Excel工作簿
wb <- createWorkbook()

# 添加数据工作表
addWorksheet(wb, "Clustered Data")
writeData(wb, sheet = "Clustered Data", x = data)

# 添加聚类信息工作表
addWorksheet(wb, "Cluster Distribution")
writeData(wb, sheet = "Cluster Distribution", x = cluster_info)

# 添加聚类选择标准工作表
addWorksheet(wb, "Selection Criteria")
writeData(wb, sheet = "Selection Criteria", x = criteria)

# 保存Excel文件
saveWorkbook(wb, "Clustered_Data_Results.xlsx", overwrite = TRUE)
cat("分群后的完整数据已导出到 Clustered_Data_Results.xlsx\n")
cat("文件中包含三个工作表：\n")
cat("1. 'Clustered Data' - 包含原始数据和聚类标签\n")
cat("2. 'Cluster Distribution' - 聚类分布统计\n")
cat("3. 'Selection Criteria' - 聚类选择标准\n")