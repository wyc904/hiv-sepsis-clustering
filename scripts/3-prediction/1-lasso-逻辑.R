# ----------------------- 环境与数据 -----------------------
library(glmnet)
library(readxl)
library(dplyr)
library(ggplot2)
library(purrr)
library(lubridate)
library(writexl)
library(tidyr)
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
df_total <- read_excel("1690.xlsx")

# ----------------------- 变量类型定义 -----------------------
continuous_vars <- c("AGE", "HIVRNA", "CD4", "CCI", "TBIL", "Cr", "PLT", "LYM",
                     "INR", "LDH", "ALB", "GLU", "UREA", 
                     "AST", "LAC","CRP"
                     ,"PCT","MONO",
                     "WBC"
)

categorical_vars <- c(
  "gender"
)

# ----------------------- 保证类型正确 & 参考水平为最小 -----------------------
df_total <- df_total %>%
  mutate(across(all_of(continuous_vars), ~ suppressWarnings(as.numeric(.x))))

df_total <- df_total %>%
  mutate(across(all_of(categorical_vars), ~{
    if (is.numeric(.x) || is.integer(.x)) {
      lev <- sort(unique(.x))
      factor(.x, levels = lev)
    } else {
      tmp <- suppressWarnings(as.numeric(as.character(.x)))
      if (!all(is.na(tmp))) {
        lev <- sort(unique(tmp))
        factor(tmp, levels = lev)
      } else {
        lev <- sort(unique(as.character(.x)))
        factor(.x, levels = lev)
      }
    }
  }))

# ----------------------- 组装用于建模的数据框 & 缺失值处理 -----------------------
vars_used <- c(continuous_vars, categorical_vars, "HOSLOS", "死亡终")
df_model <- df_total %>% select(all_of(vars_used))

rows_use <- complete.cases(df_model)
df_model <- df_model[rows_use, , drop = FALSE]

# ----------------------- 设计矩阵（连续+分类；去掉截距） -----------------------
mm <- model.matrix(~ . , data = df_model[, c(continuous_vars, categorical_vars), drop = FALSE])
x  <- mm[, -1, drop = FALSE]
y <- df_model$`死亡终`   # 逻辑回归直接用二分类结局

# ----------------------- 10次10折交叉验证LASSO-逻辑回归 -----------------------
set.seed(123)  
iterations <- 10
lambda_results <- list()
coef_results <- list()
cv_plots <- list()  

for (i in 1:iterations) {
  cat("正在进行交叉验证迭代:", i, "/", iterations, "\n")
  
  cvfit <- cv.glmnet(
    x, y,
    family = "binomial",
    alpha = 1,
    nfolds = 10,
    standardize = TRUE
  )
  
  lambda_results[[i]] <- data.frame(
    Iteration = i,
    lambda_min = cvfit$lambda.min,
    lambda_1se = cvfit$lambda.1se
  )
  
  coef_results[[i]] <- as.matrix(coef(cvfit, s = "lambda.min"))
  
  cv_plots[[i]] <- plot(cvfit, main = paste("CV Iteration", i))
  
  rm(cvfit)
  gc()
}

lambda_df <- bind_rows(lambda_results)
best_lambda <- median(lambda_df$lambda_min)
cat("\n10次交叉验证的最佳lambda中位数:", best_lambda, "\n")

# ----------------------- 最终模型 -----------------------
final_model <- glmnet(
  x, y,
  family = "binomial",
  alpha = 1,
  lambda = best_lambda,
  standardize = TRUE
)

# ----------------------- 分析稳定性 -----------------------
all_coefs <- map_dfc(1:iterations, ~{
  coef_vec <- as.vector(coef_results[[.x]])
  setNames(data.frame(coef_vec), paste0("Iter_", .x))
})

rownames(all_coefs) <- rownames(coef_results[[1]])
all_coefs$Variable <- rownames(all_coefs)

var_frequency <- apply(all_coefs[, 1:iterations] != 0, 1, mean)
variable_summary <- data.frame(
  Variable = names(var_frequency),
  Frequency = round(var_frequency, 2)
) %>%
  arrange(desc(Frequency))

final_coefs <- as.matrix(coef(final_model))
sel_idx <- which(final_coefs[,1] != 0)
results_df <- data.frame(
  Variable = rownames(final_coefs)[sel_idx],
  Coefficient = round(final_coefs[sel_idx, 1], 4),
  row.names = NULL
)

results_df <- left_join(results_df, variable_summary, by = "Variable")

# ----------------------- 可视化结果 -----------------------
lambda_plot <- ggplot(lambda_df, aes(x = lambda_min)) +
  geom_histogram(bins = 10, fill = "skyblue", color = "black") +
  geom_vline(xintercept = best_lambda, color = "red", linetype = "dashed") +
  labs(title = "10次交叉验证的Lambda分布",
       x = "Lambda.min值", y = "出现频率",
       caption = paste("中位数lambda =", round(best_lambda, 5))) +
  theme_minimal()

freq_plot <- variable_summary %>%
  filter(Frequency > 0) %>%
  ggplot(aes(x = reorder(Variable, Frequency), y = Frequency)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "变量在10次交叉验证中被选中的频率",
       x = "变量", y = "选中频率") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent) +
  geom_hline(yintercept = 0.8, color = "red", linetype = "dashed", alpha = 0.5)

coef_stability <- all_coefs %>%
  pivot_longer(cols = starts_with("Iter"), names_to = "Iteration", values_to = "Coefficient") %>%
  filter(Coefficient != 0) %>%
  mutate(Iteration = as.numeric(gsub("Iter_", "", Iteration))) %>%
  ggplot(aes(x = Iteration, y = Coefficient, group = Variable)) +
  geom_line(alpha = 0.5) +
  geom_point(size = 1.5) +
  facet_wrap(~ Variable, scales = "free_y") +
  labs(title = "系数在不同迭代中的变化",
       x = "迭代次数", y = "系数值") +
  theme_bw()

# ----------------------- 保存结果 -----------------------
time_stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
output_dir <- file.path("LASSO_Results", time_stamp)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(results_df, file.path(output_dir, "LASSO_Selected_Variables.csv"), row.names = FALSE)
write.csv(variable_summary, file.path(output_dir, "Variable_Selection_Frequency.csv"), row.names = FALSE)
write.csv(lambda_df, file.path(output_dir, "Lambda_Values.csv"), row.names = FALSE)
write.csv(all_coefs, file.path(output_dir, "All_Coefficients.csv"), row.names = FALSE)

ggsave(file.path(output_dir, "Lambda_Distribution.png"), lambda_plot, width = 8, height = 6)
ggsave(file.path(output_dir, "Variable_Selection_Frequency.png"), freq_plot, width = 10, height = 6)
ggsave(file.path(output_dir, "Coefficient_Stability.png"), coef_stability, width = 12, height = 9)

cat("\n===== 最终选中的变量与系数 =====\n")
print(results_df)

cat("\n===== 变量选择频率摘要 =====\n")
print(variable_summary)

# ----------------------- 风险评分（基于最终模型） -----------------------
risk_score_raw <- as.vector(predict(final_model, newx = x, type = "link"))
df_model$risk_score <- as.numeric(scale(risk_score_raw))


