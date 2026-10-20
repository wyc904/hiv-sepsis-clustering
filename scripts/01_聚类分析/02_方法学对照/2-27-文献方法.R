setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# ---------------------------
# 1. 加载必要的包
# ---------------------------
library(dplyr)
library(poLCA)      # 用于Latent Class Analysis
library(tidyr)
library(purrr)
library(readxl)
library(psych)      # 用于检查相关性

# ---------------------------
# 2. 读取数据
# ---------------------------
data <- read_excel("7-1800-质控28天死亡11.xlsx")

# ---------------------------
# 3. 选择分析变量
# ---------------------------
cont_vars <- c("age","CD4","TBIL","Cr","PLT","LYM",
               "WBC","INR","LDH","ALB","GLU","UREA","PCT","MONO","CRP","AST","lac")

cat_vars <- c("ART","gender","Talaromycosis","PCP","CMV","VL3")

# ---------------------------
# 4. 连续变量log转换与标准化
# ---------------------------
data_scaled <- data

for(v in cont_vars){
  if(v %in% colnames(data_scaled)){
    # 连续变量log+1转换
    data_scaled[[v]] <- log1p(data_scaled[[v]])
    # z-score标准化
    data_scaled[[v]] <- scale(data_scaled[[v]])
  }
}

# ---------------------------
# 5. 检查连续变量相关性
# ---------------------------
# ---------------------------
# 5. 检查连续变量相关性
# ---------------------------

# 确认哪些 cont_vars 在数据中存在
cont_vars_exist <- cont_vars[cont_vars %in% colnames(data_scaled)]
if(length(cont_vars_exist) == 0){
  stop("没有找到匹配的连续变量，请检查列名！")
}

# 使用基础 R 子集，避免 select 报错
cont_data <- data_scaled[, cont_vars_exist, drop = FALSE]

# 检查列名是否正确
colnames(cont_data)

# 计算相关性矩阵
cor_mat <- cor(cont_data, use = "pairwise.complete.obs")

# 找出高相关变量对 (Pearson > 0.5)
high_cor_idx <- which(abs(cor_mat) > 0.5 & abs(cor_mat) < 1, arr.ind = TRUE)

if(nrow(high_cor_idx) > 0){
  cat("高相关变量对 (Pearson > 0.5)：\n")
  high_cor_df <- data.frame(
    Var1 = rownames(cor_mat)[high_cor_idx[,1]],
    Var2 = colnames(cor_mat)[high_cor_idx[,2]],
    Correlation = cor_mat[high_cor_idx]
  )
  # 去重
  high_cor_df <- high_cor_df[as.character(high_cor_df$Var1) < as.character(high_cor_df$Var2), ]
  print(high_cor_df)
} else {
  cat("没有发现 Pearson > 0.5 的变量对。\n")
}

# ---------------------------
# 6. 构建poLCA输入数据
# ---------------------------
# poLCA要求变量为因子型，连续变量可分箱
data_lca <- data_scaled %>%
  mutate(across(all_of(cont_vars), ~ cut(., breaks=4, labels=FALSE))) %>%
  mutate(across(all_of(cont_vars), as.factor)) %>%
  mutate(across(all_of(cat_vars), as.factor))

# 构建poLCA公式
f <- as.formula(paste("cbind(", paste(c(cont_vars, cat_vars), collapse=","), ") ~ 1"))

# ---------------------------
# 7. Latent Class Analysis (1-5类)
# ---------------------------
k_grid <- 1:5
fit_list <- map(k_grid, function(k){
  poLCA(f, data = data_lca,
        nclass = k,
        maxiter = 10000,
        nrep = 100,       # 随机起始次数
        verbose = FALSE,
        calc.se = TRUE)
})

# ---------------------------
# 8. 模型评估：BIC, AIC, Entropy, 最小类别数量
# ---------------------------
# ---------------------------
# 9. 模型评估：BIC, AIC, Entropy, 最小类别数量
# ---------------------------
fit_summary <- map_dfr(fit_list, function(model){
  tibble(
    Classes = length(model$P),                      # 类别数直接取 P 的长度
    BIC = model$bic,
    AIC = model$aic,
    Entropy = model$entropy,
    MinClassSize = min(model$P * nrow(data_lca))
  )
})

print(fit_summary)

