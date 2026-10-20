# ----------------------- 环境与数据 -----------------------
library(glmnet)
library(readxl)
library(dplyr)
library(purrr)
library(lubridate)
library(writexl)
library(tidyr)
library(broom)   # 整理回归结果
library(pROC)    # ROC + Youden Index
library(ggplot2) # 可视化
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
df_total <- read_excel("1690.xlsx")

# ----------------------- 变量类型定义 -----------------------
continuous_vars <- c("AGE", "HIVRNA", "CD4", "CCI", "TBIL", "Cr", "PLT", "LYM",
                     "INR", "LDH", "ALB", "GLU", "UREA", 
                     "AST", "LAC","CRP","PCT","MONO","WBC")

categorical_vars <- c("gender")

# ----------------------- 类型转换 -----------------------
df_total <- df_total %>%
  mutate(across(all_of(continuous_vars), ~ suppressWarnings(as.numeric(.x)))) %>%
  mutate(across(all_of(categorical_vars), ~ factor(.x)))

# ----------------------- 数据准备 -----------------------
vars_used <- c(continuous_vars, categorical_vars, "cluster")
df_model <- df_total %>% select(all_of(vars_used))
df_model <- df_model[complete.cases(df_model), , drop = FALSE]

# ✅ 确保 cluster 是 0/1
df_model$cluster <- ifelse(df_model$cluster == min(df_model$cluster), 0, 1)

mm <- model.matrix(~ . , data = df_model[, c(continuous_vars, categorical_vars), drop = FALSE])
x  <- mm[, -1, drop = FALSE]   # 去掉截距
y  <- df_model$cluster         # 0/1 变量

# ----------------------- 稳定性分析（10次交叉验证） -----------------------
set.seed(123)
iterations <- 10
lambda_results <- list()
coef_results <- list()

for (i in 1:iterations) {
  cvfit <- cv.glmnet(
    x, y,
    family = "binomial",
    alpha = 1,
    nfolds = 10,
    standardize = TRUE
  )
  
  lambda_results[[i]] <- data.frame(
    iteration = i,
    lambda_min = cvfit$lambda.min
  )
  
  coef_results[[i]] <- coef(cvfit, s = "lambda.min")
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

# ----------------------- 多变量逻辑回归（所有 LASSO 变量） -----------------------
glm_data <- as.data.frame(cbind(y, x))
names(glm_data)[1] <- "y"  # 确保响应变量名为y

selected_vars_mm <- results_df %>% 
  filter(Variable != "(Intercept)") %>% 
  pull(Variable)

if (length(selected_vars_mm) == 0) {
  stop("⚠️ LASSO 未选择任何变量")
}

glm_all <- glm(
  formula = as.formula(paste("y ~", paste(selected_vars_mm, collapse = " + "))),
  data = glm_data,
  family = binomial
)

reg_table_all <- broom::tidy(glm_all, conf.int = TRUE, exponentiate = TRUE) %>%
  mutate(across(where(is.numeric), ~round(.x, 3))) %>%
  select(term, estimate, conf.low, conf.high, p.value) %>%
  rename(Variable = term, OR = estimate, CI_low = conf.low, CI_high = conf.high, P = p.value)

# ----------------------- 保留显著性变量 (p < 0.05) -----------------------
sig_vars <- reg_table_all %>% 
  filter(P < 0.05 & Variable != "(Intercept)") %>% 
  pull(Variable)

if (length(sig_vars) == 0) {
  stop("⚠️ 没有显著变量，请检查数据或放宽阈值")
}

glm_sig <- glm(
  formula = as.formula(paste("y ~", paste(sig_vars, collapse = " + "))),
  data = glm_data,
  family = binomial
)

# ----------------------- 输出显著性回归结果 -----------------------
reg_table_sig <- broom::tidy(glm_sig, conf.int = TRUE, exponentiate = TRUE) %>%
  mutate(across(where(is.numeric), ~round(.x, 3))) %>%
  select(term, estimate, conf.low, conf.high, p.value) %>%
  rename(Variable = term, OR = estimate, CI_low = conf.low, CI_high = conf.high, P = p.value)

# ----------------------- 公式构建 -----------------------
coef_vals <- coef(glm_sig)
formula_eq <- paste0(
  "logit(P) = ", round(coef_vals[1], 4), " + ",
  paste(paste0(round(coef_vals[-1], 4), " * ", names(coef_vals)[-1]), collapse = " + ")
)

# ----------------------- 预测概率 & 分层 (Youden Index) -----------------------
pred_prob <- predict(glm_sig, type = "response")
roc_obj <- roc(glm_data$y, pred_prob)

best_coords <- coords(roc_obj, "best", ret = c("threshold", "sensitivity", "specificity"),
                      best.method = "youden")

best_cutoff <- as.numeric(best_coords["threshold"])
risk_group <- ifelse(pred_prob >= best_cutoff, "High risk", "Low risk")

# ----------------------- 风险评分（基于最终模型） -----------------------
risk_score_raw <- as.vector(predict(final_model, newx = x, type = "link"))
df_model$risk_score <- as.numeric(scale(risk_score_raw))

# ----------------------- 保存结果 -----------------------
time_stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
output_dir <- file.path("LASSO_Results", time_stamp)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 1. 稳定性分析结果
stability_dir <- file.path(output_dir, "Stability_Analysis")
dir.create(stability_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(results_df, file.path(stability_dir, "LASSO_Selected_Variables.csv"), row.names = FALSE)
write.csv(variable_summary, file.path(stability_dir, "Variable_Selection_Frequency.csv"), row.names = FALSE)
write.csv(lambda_df, file.path(stability_dir, "Lambda_Values.csv"), row.names = FALSE)
write.csv(all_coefs, file.path(stability_dir, "All_Coefficients.csv"), row.names = FALSE)

ggsave(file.path(stability_dir, "Lambda_Distribution.png"), lambda_plot, width = 8, height = 6)
ggsave(file.path(stability_dir, "Variable_Selection_Frequency.png"), freq_plot, width = 10, height = 6)
ggsave(file.path(stability_dir, "Coefficient_Stability.png"), coef_stability, width = 12, height = 9)

# 2. 回归分析结果
regression_dir <- file.path(output_dir, "Regression_Analysis")
dir.create(regression_dir, recursive = TRUE, showWarnings = FALSE)

output_list <- list(
  "LASSO_Variables" = data.frame(Variable = selected_vars_mm),
  "Logit_All" = reg_table_all,
  "Logit_Significant" = reg_table_sig,
  "Formula" = data.frame(Formula = formula_eq),
  "Best_Cutoff" = data.frame(
    Cutoff = round(best_cutoff, 3),
    Sensitivity = round(best_coords["sensitivity"], 3),
    Specificity = round(best_coords["specificity"], 3)
  ),
  "Risk_Assignment" = data.frame(
    Death = glm_data$y,
    Pred_Prob = round(pred_prob, 3),
    Risk_Group = risk_group
  )
)

write_xlsx(output_list, file.path(regression_dir, "Regression_Results.xlsx"))

# 3. 风险评分结果
risk_dir <- file.path(output_dir, "Risk_Scores")
dir.create(risk_dir, recursive = TRUE, showWarnings = FALSE)

risk_df <- df_model %>%
  select(all_of(c("cluster", continuous_vars, categorical_vars))) %>%
  mutate(
    Risk_Score = df_model$risk_score,
    Risk_Group = risk_group
  )

write.csv(risk_df, file.path(risk_dir, "Risk_Scores.csv"), row.names = FALSE)

# 4. 汇总报告
report <- list(
  "项目信息" = data.frame(
    项目名称 = "LASSO稳定性分析与风险模型",
    分析时间 = Sys.time(),
    样本量 = nrow(df_model),
    响应变量 = "cluster"
  ),
  "稳定性分析摘要" = data.frame(
    交叉验证次数 = iterations,
    Lambda中位数 = best_lambda,
    平均选择变量数 = mean(sapply(coef_results, function(x) sum(x != 0) - 1))
  ),
  "最终模型摘要" = data.frame(
    最终变量数 = length(sig_vars),
    最佳截点 = round(best_cutoff, 3),
    灵敏度 = round(best_coords["sensitivity"], 3),
    特异度 = round(best_coords["specificity"], 3)
  )
)

write_xlsx(report, file.path(output_dir, "项目摘要.xlsx"))

cat("\n✅ 所有结果已输出至:", output_dir, "\n")
cat("项目结构:\n")
cat("  |- Stability_Analysis: 稳定性分析结果\n")
cat("  |- Regression_Analysis: 回归分析结果\n")
cat("  |- Risk_Scores: 风险评分结果\n")
cat("  |- 项目摘要.xlsx: 项目汇总报告\n")
