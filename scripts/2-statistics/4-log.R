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
df_total <-  read_excel("1690.xlsx")


colnames(df_total)

# HIV阳性患者
hiv_pos <- df_total

# 设置所有模型变量为分类变量，并以最小水平作为参考组
# 定义连续变量列表（根据您提供的变量名）
cont_vars <- c("AGE", "VL", "CD4", "CCI", "TBIL", "Cr", "PLT", "LYM",
               "INR", "LDH", "ALB", "GLU", "UREA", "SOFA", "CCI", "HOSLOS",
               "AST", "LAC", "CRP", "PCT", "MONO", "WBC")

cluster

# 转换变量为因子并以最小水平作为参考
hiv_pos <- hiv_pos %>%
  mutate(across(all_of(categorical_vars), function(x) {
    if (!is.numeric(x)) {
      x_num <- suppressWarnings(as.numeric(as.character(x)))
      if (all(is.na(x_num))) {
        lev <- sort(unique(as.character(x)))
        return(factor(x, levels = lev))
      } else {
        x <- x_num
      }
    }
    lev <- sort(unique(x))
    factor(x, levels = lev)
  }))

# ----------------------- 逻辑回归模型 -----------------------
model_full <- glm(`cluster` ~ 
                  ART+VL2+CD42+PCP+CMV
  +PLT_group+INR_group+LDH_group+ALB_group+UREA_group+lac_group+Cr_group+glu_group
  
  +WBC_group+lym_group
  +ccirisk +Shock+IMV+CRRT+ageff3+gender
  +CKD+Hypertension +LiverCirrhosis,
  
                  data = hiv_pos, family = binomial)
# +lym_group
# +LiverCirrhosis
# +ccirisk

# 模型变量参考水平信息
cat("\n===== 模型变量及其参考水平 =====\n")
model_info <- data.frame(
  Variable = categorical_vars,
  Reference = sapply(categorical_vars, function(var) {
    levels(hiv_pos[[var]])[1]
  })
)
print(model_info)

# 获取线性预测值
lp_full <- predict(model_full, type = "link")

# 模型性能评价 (AIC, BIC, ROC AUC)
aic_full <- extractAIC(model_full)[2]
bic_full <- extractAIC(model_full, k = log(nrow(hiv_pos)))[2]
roc_obj <- roc(hiv_pos$`死亡终`, fitted(model_full))
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
  Coefficient = round(coef(model_full), 4)
)

# ----------------------- 保存结果到Excel -----------------------
wb <- createWorkbook()

addWorksheet(wb, "Model_Variables")
writeData(wb, "Model_Variables", model_info)

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

# 添加参考行
reference_rows <- data.frame(
  Variable = model_info$Reference,
  OR = 1,
  Lower = 1,
  Upper = 1
)
forest_data <- rbind(reference_rows, forest_data)

# 森林图
p <- ggplot(forest_data, aes(x = Variable, y = OR, ymin = Lower, ymax = Upper)) +
  geom_pointrange() +
  geom_hline(yintercept = 1, linetype = "dashed") +
  coord_flip() +
  scale_y_log10() +
  labs(
    title = "多变量逻辑回归结果",
    x = "风险因子 (参考组 vs 比较组)",
    y = "比值比 (OR) (对数尺度)"
  ) +
  theme_bw()
