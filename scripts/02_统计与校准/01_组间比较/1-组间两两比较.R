setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# -----------------------
# 1. 加载包 & 数据
# -----------------------
library(openxlsx)
library(readxl)
library(dplyr)
library(tidyr)

cat("开始读取Excel文件...\n")
df_total <- read_excel("聚类结果.xlsx")

# -----------------------
# 2. 定义函数：逐水平比较
# -----------------------
test_levels <- function(data, cluster_var, target_var) {
  res_list <- list()
  
  levels_target <- sort(unique(data[[target_var]]))
  
  for (lv in levels_target) {
    # 构造 2x2 列联表： cluster vs (是否等于该水平)
    tab <- table(data[[cluster_var]], data[[target_var]] == lv)
    
    # 提取该水平的列
    sub_tab <- tab[, "TRUE"]
    
    # 形成 2x2 矩阵 (该水平 vs 不是该水平)
    mat <- cbind(sub_tab, rowSums(tab) - sub_tab)
    rownames(mat) <- paste0("cluster_", rownames(mat))
    colnames(mat) <- c(paste0(target_var, "=", lv), "Others")
    
    # 选择检验方法
    if(any(mat < 5)) {
      test_res <- fisher.test(mat)
      method <- "Fisher"
    } else {
      test_res <- chisq.test(mat)
      method <- "Chi-square"
    }
    
    res_list[[as.character(lv)]] <- tibble(
      Variable = target_var,
      Level = lv,
      Method = method,
      P_value = test_res$p.value
    )
  }
  
  bind_rows(res_list)
}

# -----------------------
# 3. 执行检验
# -----------------------
results <- bind_rows(
  test_levels(df_total, "cluster", "CD48"),
  test_levels(df_total, "cluster", "VL38")
)

cat("\n逐水平显著性检验结果：\n")
print(results)











results <- bind_rows(
  test_levels(df_total, "cluster", "CD48"),
  test_levels(df_total, "cluster", "VL38")
)

cat("\n逐水平显著性检验结果：\n")
print(results)

# -----------------------
# 4. 保存到 Excel
# -----------------------
output_file <- "cluster_level_compare.xlsx"
write.xlsx(results, output_file, rowNames = FALSE)

cat("\n结果已保存到：", output_file, "\n")













