# ----------------------- 多变量逻辑回归 -----------------------

# 加载必要的包
library(survival)
library(pROC)
library(dplyr)
library(readxl)
library(forestplot)
library(writexl)
library(ggplot2)
library(openxlsx)

# 设置工作目录
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
# 读取数据
cat("开始读取Excel文件...\n")
df_total <- read_excel("1690.xlsx")

# HIV阳性患者
hiv_pos <- df_total

# ----------------------- 逻辑回归模型 -----------------------
# 使用所有指定的连续性变量
model_full <- glm(cluster ~ AGE + CCI + TBIL + Cr +PLT + LYM + WBC + INR + LDH + ALB + GLU + UREA +AST+ LAC +PCT+MONO+ CRP + VL + CD4,
                  data = hiv_pos, family = binomial)

# 获取线性预测值
lp_full <- predict(model_full, type = "link")

# 模型性能评价 (AIC, BIC, ROC AUC)
aic_full <- extractAIC(model_full)[2]
bic_full <- extractAIC(model_full, k = log(nrow(hiv_pos)))[2]
roc_obj <- roc(hiv_pos$cluster, fitted(model_full))  # 使用cluster作为因变量
auc_full <- auc(roc_obj)

results <- data.frame(
  Model = c("Full logistic model"),
  AIC = round(aic_full, 2),
  BIC = round(bic_full, 2),
  AUC = round(auc_full, 3)
)

# 提取 OR, CI, P值
summary_model <- summary(model_full)
or <- round(exp(coef(model_full)), 2)
ci <- round(exp(confint(model_full)), 2)
pval <- signif(summary_model$coefficients[, "Pr(>|z|)"], 3)

# 创建详细结果表格
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
  Coefficient = round(coef(model_full), 6)
)

# ----------------------- 保存结果到Excel -----------------------
wb <- createWorkbook()

addWorksheet(wb, "Logit_Coefficients")
writeData(wb, "Logit_Coefficients", coef_table)

addWorksheet(wb, "Logit_Summary")
writeData(wb, "Logit_Summary", logit_table)

addWorksheet(wb, "Model_Performance")
writeData(wb, "Model_Performance", results)

# 保存Excel文件
saveWorkbook(wb, "Logistic_Model_Results.xlsx", overwrite = TRUE)
cat("\n所有逻辑回归模型分析结果已保存为 Logistic_Model_Results.xlsx\n")

# ----------------------- 森林图可视化 -----------------------
forest_data <- data.frame(
  Variable = logit_table$Variable,
  OR = logit_table$OR,
  Lower = logit_table$CI_lower,
  Upper = logit_table$CI_upper
)

# 森林图
p <- ggplot(forest_data, aes(x = Variable, y = OR, ymin = Lower, ymax = Upper)) +
  geom_pointrange() +
  geom_hline(yintercept = 1, linetype = "dashed") +
  coord_flip() +
  scale_y_log10() +
  labs(
    title = "多变量逻辑回归结果",
    x = "风险因子",
    y = "比值比 (OR) (对数尺度)"
  ) +
  theme_bw()

