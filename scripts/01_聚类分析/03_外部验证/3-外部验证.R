# ======= 完整稳定版：derivation 建模 + external 映射（不会因 NA/Inf 报错） =======
# 依赖包
library(mclust)
library(dplyr)
library(openxlsx)
library(readxl)

# 设置工作目录（按需修改）
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
# 读取数据（文件名按需修改）
derivation_file <- "7-1800-质控28天死亡分组.xlsx"
external_file   <- "240-1.xlsx"

cat("读取文件...\n")
derivation_data <- read_excel(derivation_file)
external_data   <- read_excel(external_file)

cat_vars <- c("gender")
# "PCT", "MONO", "WBC",,"CRP"
# 连续变量
cont_vars <- c("age", "HIVRNA8", "CD48", "CCI", "TBIL", "Cr", "PLT", "LYM",
               "INR", "LDH", "ALB", "GLU", "UREA", 
               "AST", "lac","CRP"
               ,"PCT","MONO",
               "WBC")
# -----------------------------
# 1) derivation：准备连续变量（原始 -> 计算 mean/sd -> scaled）
# -----------------------------
# 只取 derivation 中实际存在的连续变量（按 cont_vars 的顺序保留）
cont_vars_deriv <- cont_vars[cont_vars %in% colnames(derivation_data)]
if (length(cont_vars_deriv) == 0) stop("derivation 中没有任何 cont_vars，请检查变量名。")

deriv_cont_raw <- derivation_data %>%
  dplyr::select(all_of(cont_vars_deriv)) %>%
  mutate(across(everything(), as.numeric))  # 强制数值化（若为字符会变 NA）

# 训练集的均值 / 标准差（用于后续 impute + scaling）
center_vals <- sapply(deriv_cont_raw, function(x) mean(x, na.rm = TRUE))
scale_vals  <- sapply(deriv_cont_raw, function(x) sd(x, na.rm = TRUE))

# 防止 sd == 0 导致除以 0
zero_sd <- names(scale_vals)[which(scale_vals == 0 | is.na(scale_vals))]
if (length(zero_sd) > 0) {
  warning("以下变量在 derivation 中 sd==0 或为 NA，已将其 scale 设为1: ", paste(zero_sd, collapse = ", "))
  scale_vals[zero_sd] <- 1
}

# derivation 标准化（缺失值会保留为 NA）
data_cont_scaled <- sweep(deriv_cont_raw, 2, center_vals, "-")
data_cont_scaled <- sweep(data_cont_scaled, 2, scale_vals, "/")
data_cont_scaled <- as.data.frame(data_cont_scaled)

# 分类变量的哑编码（以 derivation 为模板）
cat_present_in_deriv <- cat_vars[cat_vars %in% colnames(derivation_data)]
if (length(cat_present_in_deriv) > 0) {
  data_cat <- derivation_data %>% dplyr::select(all_of(cat_present_in_deriv)) %>% mutate(across(everything(), as.factor))
  data_cat_dummy <- as.data.frame(model.matrix(~ . -1, data = data_cat))
} else {
  data_cat_dummy <- data.frame()  # 空 data.frame
}

# 合成训练时的输入矩阵（保存列顺序）
cluster_input <- cbind(data_cont_scaled, data_cat_dummy)

# -----------------------------
# 2) derivation：GMM 聚类
# -----------------------------
set.seed(123)
gmm <- Mclust(cluster_input, G = 2:5)

best_k <- gmm$G
cat("训练集最佳聚类数:", best_k, "\n")

derivation_data$cluster <- as.factor(gmm$classification)

# -----------------------------
# 3) external：构造与训练完全一致的输入矩阵（处理缺失/对齐）
# -----------------------------
n_ext <- nrow(external_data)

# 3.1 构造 continuous 部分：按 derivation 的变量模板逐列填值并 impute（用 center_vals）
# 初始化外部连续矩阵，列名与 derivation 中的 cont 列完全一致
ext_cont <- data.frame(matrix(nrow = n_ext, ncol = length(center_vals)))
colnames(ext_cont) <- names(center_vals)

# 对每个训练的连续变量：若 external 有该列则取值并转为数值；若无则填入 derivation 的均值
for (v in names(center_vals)) {
  if (v %in% colnames(external_data)) {
    ext_val <- as.numeric(external_data[[v]])   # 若转换失败会变 NA
    # 把 external 上的 NA 用 derivation 的均值填充（保证后续无 NA）
    ext_val[is.na(ext_val)] <- center_vals[v]
    ext_cont[[v]] <- ext_val
  } else {
    # external 完全缺该列：直接用 derivation 的均值填满
    ext_cont[[v]] <- rep(center_vals[v], n_ext)
  }
}

# 3.2 标准化外部连续（使用 derivation 的 center/scale）
ext_cont_scaled <- sweep(ext_cont, 2, center_vals, "-")
ext_cont_scaled <- sweep(ext_cont_scaled, 2, scale_vals, "/")
ext_cont_scaled <- as.data.frame(ext_cont_scaled)

# 3.3 分类哑变量：构造 external 的 dummy 并与 derivation 的 dummy 列完全对齐
deriv_dummy_names <- colnames(data_cat_dummy)  # 训练时的 dummy 列名模板

# external 的分类数据（若 external 没有任何分类变量，则构建空 df）
if (length(cat_present_in_deriv) > 0 && any(cat_present_in_deriv %in% colnames(external_data))) {
  ext_cat <- external_data %>% dplyr::select(any_of(cat_present_in_deriv)) %>% mutate(across(everything(), as.factor))
  ext_cat_dummy <- as.data.frame(model.matrix(~ . -1, data = ext_cat))
} else {
  # external 没有对应的分类变量 -> 创建空的 dummy（will be filled with zeros）
  ext_cat_dummy <- data.frame()
}

# 确保 ext_cat_dummy 有 derivation 中的每个 dummy 列（缺的设为0），多余的列则删除
if (length(deriv_dummy_names) > 0) {
  # add missing cols
  for (nm in setdiff(deriv_dummy_names, colnames(ext_cat_dummy))) {
    ext_cat_dummy[[nm]] <- 0
  }
  # drop extra cols not in derivation
  extra_cols <- setdiff(colnames(ext_cat_dummy), deriv_dummy_names)
  if (length(extra_cols) > 0) {
    ext_cat_dummy <- ext_cat_dummy[, !(colnames(ext_cat_dummy) %in% extra_cols), drop = FALSE]
  }
  # reorder to match derivation order
  ext_cat_dummy <- ext_cat_dummy[, deriv_dummy_names, drop = FALSE]
} else {
  # derivation 没有任何 dummy 列 -> 保持空 data.frame
  ext_cat_dummy <- data.frame()
}

# 3.4 合并 continuous + dummy，保证列顺序与 cluster_input 一致
external_cluster_input <- cbind(ext_cont_scaled, ext_cat_dummy)

# 检查列是否完全匹配训练时的 cluster_input 列名
missing_cols <- setdiff(colnames(cluster_input), colnames(external_cluster_input))
extra_cols   <- setdiff(colnames(external_cluster_input), colnames(cluster_input))

if (length(missing_cols) > 0) {
  stop("外部输入缺少以下列（应与训练集完全一致）: ", paste(missing_cols, collapse = ", "),
       "\n请检查 categorical dummy 对齐或连续变量模板是否一致。")
}
# 丢弃任何多余列（通常不应该有，但保险）
if (length(extra_cols) > 0) {
  external_cluster_input <- external_cluster_input[, !(colnames(external_cluster_input) %in% extra_cols), drop = FALSE]
}

# 最终按训练时列顺序排列
external_cluster_input <- external_cluster_input[, colnames(cluster_input)]

# 3.5 再次检查 NA / Inf
if (any(is.na(as.matrix(external_cluster_input)))) {
  stop("external_cluster_input 中仍存在 NA，请检查 external 数据和 imputation 步骤。")
}
if (any(is.infinite(as.matrix(external_cluster_input)))) {
  stop("external_cluster_input 中存在 Inf，请检查 scale/zero-division 问题。")
}

# -----------------------------
# 4) 使用训练好的 gmm 做映射（predict）
# -----------------------------
cat("开始对外部数据做映射预测...\n")
external_pred <- predict(gmm, newdata = external_cluster_input)
external_data$cluster <- as.factor(external_pred$classification)

cat("外部映射完成，总计每类样本数：\n")
print(table(external_data$cluster))

# -----------------------------
# 5) 导出结果到 Excel
# -----------------------------
wb <- createWorkbook()
addWorksheet(wb, "Derivation_Clustered")
writeData(wb, sheet = "Derivation_Clustered", derivation_data)

addWorksheet(wb, "External_Clustered")
writeData(wb, sheet = "External_Clustered", external_data)

# 也导出训练时的列模板，便于核对
addWorksheet(wb, "Cluster_Input_Cols")
writeData(wb, sheet = "Cluster_Input_Cols", data.frame(Column = colnames(cluster_input)))

saveWorkbook(wb, "Cluster_Validation_Results.xlsx", overwrite = TRUE)
cat("结果已保存为 Cluster_Validation_Results.xlsx\n")
