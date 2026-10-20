setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

library(MASS)     # stepAIC
library(dplyr)
library(broom)
library(pROC)

# ----------------------- LASSO候选变量 -----------------------
selected_vars_mm <- results_df %>% 
  filter(Variable != "(Intercept)") %>% 
  pull(Variable)

glm_data <- as.data.frame(cbind(y, x))
names(glm_data)[1] <- "y"

# ----------------------- 初始模型（含全部LASSO变量） -----------------------
full_model <- glm(
  formula = as.formula(paste("y ~", paste(selected_vars_mm, collapse = " + "))),
  data = glm_data,
  family = binomial
)

# ----------------------- BIC逐步回归 -----------------------
# k = log(n) 表示使用 BIC 而不是 AIC
step_bic <- stepAIC(
  full_model,
  direction = "both",
  k = log(nrow(glm_data)),
  trace = FALSE
)

summary(step_bic)

# ----------------------- 提取最终变量 -----------------------
final_vars <- names(coef(step_bic))[-1]  # 去掉截距
cat("BIC选择的最终变量:", paste(final_vars, collapse = ", "), "\n")

# 如果最终变量 >5，可以按绝对回归系数排序取前5个
if(length(final_vars) > 5){
  coefs <- coef(step_bic)[-1]
  final_vars <- names(sort(abs(coefs), decreasing = TRUE))[1:6]
  # 重建精简模型
  step_bic <- glm(
    formula = as.formula(paste("y ~", paste(final_vars, collapse = " + "))),
    data = glm_data,
    family = binomial
  )
  cat("进一步精简至5个变量:", paste(final_vars, collapse = ", "), "\n")
}

# ----------------------- 回归结果整理 -----------------------
reg_table_bic <- broom::tidy(step_bic, conf.int = TRUE, exponentiate = TRUE) %>%
  mutate(across(where(is.numeric), ~ round(.x, 3))) %>%
  dplyr::rename(
    Variable = term,
    OR = estimate,
    CI_low = conf.low,
    CI_high = conf.high,
    P = p.value
  ) %>%
  dplyr::select(Variable, OR, CI_low, CI_high, P)

# ----------------------- 构建公式 -----------------------
coef_vals <- coef(step_bic)
formula_eq <- paste0(
  "logit(P) = ", round(coef_vals[1], 4),
  " + ", paste(paste0(round(coef_vals[-1],4), " * ", names(coef_vals)[-1]), collapse = " + ")
)
cat("最终公式:\n", formula_eq, "\n")

# ----------------------- ROC评估 -----------------------
pred_prob <- predict(step_bic, type = "response")
roc_obj <- roc(glm_data$y, pred_prob)
auc_val <- auc(roc_obj)
cat("最终模型AUC:", round(auc_val, 3), "\n")

# ----------------------- 输出结果 -----------------------
if (!dir.exists(regression_dir)) dir.create(regression_dir, recursive = TRUE)

write.csv(reg_table_bic, file.path(regression_dir, "BIC_Logit_Results.csv"), row.names = FALSE)
