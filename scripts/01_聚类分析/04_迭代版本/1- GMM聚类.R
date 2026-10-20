setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要包
library(mclust)     # 高斯混合模型
library(cluster)    # 轮廓系数
library(factoextra) # 可视化
library(dplyr)

# 假设数据在 data 中
# 分类变量
cat_vars <- c( "gender")
# 连续变量
cont_vars <- c("chaerson","age","CD4","HIVRNA8","TBIL","Cr","PLT","LYM",
               "WBC","INR","LDH","ALB","GLU","UREA","PCT","MONO",
               "CRP","AST","lac")

# --- 1. 分类变量 → 哑变量编码 ---
data_cat <- data %>%
  select(all_of(cat_vars)) %>%
  mutate(across(everything(), as.factor))
data_cat_dummy <- model.matrix(~ . -1, data = data_cat) # one-hot

# --- 2. 连续变量 → 标准化 ---
data_cont <- scale(data %>% select(all_of(cont_vars)))

# --- 3. 合并数据 ---
data_for_cluster <- cbind(data_cont, data_cat_dummy)

# --- 4. GMM 聚类 ---
set.seed(123)
gmm_model <- Mclust(data_for_cluster, G=2:6) # 测试2-6类
summary(gmm_model)

# 最优类别数
best_nclass <- gmm_model$G
cat("最佳类别数：", best_nclass, "\n")

# --- 5. 保存聚类结果 ---
data$cluster <- gmm_model$classification
write.csv(data, "clustered_patient_data.csv", row.names = FALSE)

# --- 6. 可视化（PCA降维后画图） ---
fviz_cluster(list(data = data_for_cluster, cluster = gmm_model$classification),
             geom = "point", ellipse.type = "norm",
             main = paste("患者分群 (最佳类别 =", best_nclass, ")"))
