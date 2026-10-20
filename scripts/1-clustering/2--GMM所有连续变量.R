# 安装需要的包（如未安装）
# install.packages(c("mclust", "dplyr", "factoextra", "tableone", "openxlsx"))

library(mclust)
library(dplyr)
library(factoextra)
library(tableone)
library(openxlsx)  # 用于导出Excel

# 加载必要的库
library(readxl)
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
cat("开始读取Excel文件...\n")
data <- read_excel("7-1800-质控28天死亡分组.xlsx")

# 检查数据列名
cat("数据列名:\n")
print(names(data))
# cont_vars <- c("age", "HIVRNA8", "CD48", "CCI", "TBIL", "Cr", "PLT", "LYM",
#                "WBC", "INR", "LDH", "ALB", "GLU", "UREA", "PCT", "MONO",
#                "CRP", "AST", "lac", "DIMER")
# 连续变量 - 确保这些名称与数据中的列名完全匹配
cont_vars <- c("age", "HIVRNA8", "CD48", "CCI", "TBIL", "Cr", "PLT", "LYM",
               "INR", "LDH", "ALB", "GLU", "UREA", 
               "AST", "lac","CRP")

# 验证变量是否存在
existing_vars <- intersect(cont_vars, names(data))
missing_vars <- setdiff(cont_vars, names(data))

if (length(missing_vars) > 0) {
  cat("警告: 以下变量在数据中不存在:\n")
  print(missing_vars)
  cat("将使用以下存在的变量进行分析:\n")
  print(existing_vars)
} else {
  cat("所有连续变量均存在于数据中\n")
}

# 1. 仅使用连续变量进行标准化
# 使用dplyr::select确保正确选择变量
data_cont_scaled <- as.data.frame(scale(data %>% dplyr::select(all_of(existing_vars))))

# 2. GMM 聚类，并选定 2-5 类
set.seed(123)
gmm <- Mclust(data_cont_scaled, G = 2:5)

best_k <- gmm$G
cat("最佳聚类数:", best_k, "\n")

# 3. 将聚类结果保存到原始数据
data$cluster <- gmm$classification

# 查看每个簇的样本数
cluster_counts <- table(data$cluster)
cat("各簇样本数:\n")
print(cluster_counts)

# 4. 聚类可视化
fviz_cluster(list(data = data_cont_scaled, cluster = data$cluster), 
             geom = "point",
             ellipse.type = "norm", 
             main = paste("GMM Clustering: K =", best_k),
             xlab = "主成分1", 
             ylab = "主成分2")

# 5. 生成聚类数选择依据并导出Excel
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

# 保存聚类结果到新文件
data_with_clusters <- cbind(data, cluster = data$cluster)
write.xlsx(data_with_clusters, "Clustered_Data.xlsx")
cat("聚类结果已保存到 Clustered_Data.xlsx\n")