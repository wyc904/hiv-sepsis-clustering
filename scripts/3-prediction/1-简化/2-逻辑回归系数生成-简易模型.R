# ----------------------- 多变量逻辑回归（连续变量） -----------------------

# 加载必要的包
library(dplyr)
library(readxl)
library(openxlsx)
library(ggplot2)
library(pROC)

# 设置工作目录
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
# 读取数据
cat("开始读取Excel文件...\n")
df_total <- read_excel("1690.xlsx")

# HIV阳性患者
hiv_pos <- df_total


# 分类变量："CD47","VL38"
# ,"CD4","VL"

# 连续变量列表
continuous_vars <- c("INR","MONO","LYM","LAC","PCT")

# 确保连续变量为数值型
hiv_pos <- hiv_pos %>%
  mutate(across(all_of(continuous_vars), as.numeric))

# ----------------------- 去除缺失值 -----------------------
# 修复：使用正确的 select 语法
hiv_pos_complete <- hiv_pos %>%
  dplyr::select(cluster, dplyr::all_of(continuous_vars)) %>%
  na.omit()

cat("去除缺失值后样本量:", nrow(hiv_pos_complete), "\n")

# ----------------------- 逻辑回归模型 -----------------------
formula_cont <- paste("cluster ~", paste(continuous_vars, collapse = " + "))
model_full <- glm(as.formula(formula_cont), data = hiv_pos_complete, family = binomial)

# ----------------------- 模型性能评价 -----------------------
# AIC / BIC
aic_full <- extractAIC(model_full)[2]
bic_full <- extractAIC(model_full, k = log(nrow(hiv_pos_complete)))[2]

# ROC AUC
roc_obj <- roc(hiv_pos_complete$cluster, fitted(model_full))
auc_full <- auc(roc_obj)

results <- data.frame(
  Model = "Full logistic model",
  AIC = round(aic_full, 2),
  BIC = round(bic_full, 2),
  AUC = round(auc_full, 3)
)

# ----------------------- 提取 OR, CI, P值 -----------------------
summary_model <- summary(model_full)
or <- round(exp(coef(model_full)), 2)
ci <- round(exp(confint(model_full)), 2)
pval <- signif(summary_model$coefficients[, "Pr(>|z|)"], 3)

logit_table <- data.frame(
  Variable = rownames(summary_model$coefficients),
  OR = or,
  CI_lower = ci[, 1],
  CI_upper = ci[, 2],
  P_value = pval
)

# 输出logit系数
coef_table <- data.frame(
  Variable = rownames(summary_model$coefficients),
  Coefficient = round(coef(model_full), 4)
)

# ----------------------- 保存结果到Excel -----------------------
wb <- createWorkbook()

addWorksheet(wb, "Logit_Coefficients")
writeData(wb, "Logit_Coefficients", coef_table)

addWorksheet(wb, "Logit_Summary")
writeData(wb, "Logit_Summary", logit_table)

addWorksheet(wb, "Model_Performance")
writeData(wb, "Model_Performance", results)

saveWorkbook(wb, "Logistic_Model_Continuous_Results.xlsx", overwrite = TRUE)
cat("\n所有逻辑回归模型分析结果已保存为 Logistic_Model_Continuous_Results.xlsx\n")

# ----------------------- 森林图可视化 -----------------------
forest_data <- logit_table[-1, ]  # 去掉截距
forest_data$Variable <- gsub("`", "", forest_data$Variable)  # 清理变量名

p <- ggplot(forest_data, aes(x = Variable, y = OR, ymin = CI_lower, ymax = CI_upper)) +
  geom_pointrange(color = "blue") +
  geom_hline(yintercept = 1, linetype = "dashed") +
  coord_flip() +
  scale_y_log10() +
  labs(
    title = "多变量逻辑回归结果（连续变量）",
    x = "变量",
    y = "比值比 (OR) (对数尺度)"
  ) +
  theme_bw()

print(p)