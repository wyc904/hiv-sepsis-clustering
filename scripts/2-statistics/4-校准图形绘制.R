# -----------------------
# 依赖包
# -----------------------
library(openxlsx)
library(readxl)
library(dplyr)
library(ggplot2)
library(pROC)
library(ResourceSelection)  # 用于Hosmer-Lemeshow检验

# -----------------------
# 读取数据并计算 logit/p
# -----------------------
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
df_total <- read_excel("1690.xlsx")

df_total <- df_total %>%
  mutate(
    logit = -20.789426 + 
      0.177599 * CCI +
      0.065839 * TBIL +
      0.029115 * Cr +
      1.022455 * LYM +
      4.12217 * INR +
      0.001907 * LDH +
      0.016368 * GLU +
      0.099735 * UREA +
      0.006523 * AST +
      0.643103 * LAC +
      0.182929 * PCT +
      1.821501 * MONO +
      0.000001 * VL +
      0.005557 * CD4,
    p = 1 / (1 + exp(-logit))
  )

# -----------------------
# 确认并转换结局为0/1数值
# -----------------------
df_total <- df_total %>%
  mutate(死亡终_num = as.numeric(as.character(cluster0)))

# 检查
table(df_total$死亡终_num, useNA = "ifany")

# -----------------------
# 原始模型评估
# -----------------------

# 生成分组校准数据（10组）
n_groups <- 10
df_calib <- df_total %>%
  filter(!is.na(p), !is.na(死亡终_num)) %>%
  mutate(group = ntile(p, n_groups)) %>%
  group_by(group) %>%
  summarise(
    Predicted = mean(p),
    Observed = mean(死亡终_num),
    n = n(),
    se = sqrt(Observed * (1 - Observed) / n),
    lower = pmax(0, Observed - 1.96 * se),
    upper = pmin(1, Observed + 1.96 * se),
    .groups = "drop"
  )

# JAMA 风格校准图（原始模型）
ggplot(df_calib, aes(x = Predicted, y = Observed)) +
  geom_line(color = "black", size = 0.8) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.02, size = 0.8) +
  geom_point(size = 3, shape = 16) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray40") +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(
    x = "Predicted probability",
    y = "Observed event rate",
    title = "Calibration Plot (Original Model)"
  ) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid = element_blank(),
    axis.text = element_text(color = "black"),
    axis.title = element_text(face = "plain"),
    plot.title = element_text(hjust = 0.5, face = "bold")
  )

# Brier score
brier_old <- mean((df_total$p - df_total$死亡终_num)^2, na.rm = TRUE)
cat("Brier score (original):", round(brier_old, 4), "\n")

# Hosmer-Lemeshow 检验
hl <- hoslem.test(df_total$死亡终_num, df_total$p, g = n_groups)
print(hl)

# ROC AUC
roc_old <- roc(df_total$死亡终_num, df_total$p)
cat("ROC AUC (original):", auc(roc_old), "\n")

# -----------------------
# 重新校准模型
# -----------------------

# 诊断：回归估计校准截距与斜率
cal_mod <- glm(死亡终_num ~ logit, data = df_total, family = binomial)
print(summary(cal_mod))
cal_coef <- coef(cal_mod)
cat("Calibration intercept (a):", round(cal_coef[1], 4), "\n")
cat("Calibration slope (b):", round(cal_coef[2], 4), "\n")

# 计算校准-in-the-large
mean_pred <- mean(df_total$p, na.rm = TRUE)
mean_obs <- mean(df_total$死亡终_num, na.rm = TRUE)
cat("Mean predicted:", round(mean_pred, 4), "Mean observed:", round(mean_obs, 4), "\n")

# 重新校准（Platt scaling）
a <- cal_coef[1]
b <- cal_coef[2]
df_total$logit_recal <- a + b * df_total$logit
df_total$p_recal <- 1 / (1 + exp(-df_total$logit_recal))

# -----------------------
# 重新校准后模型评估
# -----------------------

# 生成重新校准后的分组校准数据
df_calib_recal <- df_total %>%
  filter(!is.na(p_recal), !is.na(死亡终_num)) %>%
  mutate(group = ntile(p_recal, n_groups)) %>%
  group_by(group) %>%
  summarise(
    Predicted = mean(p_recal),
    Observed = mean(死亡终_num),
    n = n(),
    se = sqrt(Observed * (1 - Observed) / n),
    lower = pmax(0, Observed - 1.96 * se),
    upper = pmin(1, Observed + 1.96 * se),
    .groups = "drop"
  )

# JAMA 风格校准图（重新校准后）
ggplot(df_calib_recal, aes(x = Predicted, y = Observed)) +
  geom_line(color = "black", size = 0.8) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.02, size = 0.8) +
  geom_point(size = 3, shape = 16) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray40") +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(
    x = "Predicted probability",
    y = "Observed event rate",
    title = "Calibration Plot (Recalibrated Model)"
  ) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid = element_blank(),
    axis.text = element_text(color = "black"),
    axis.title = element_text(face = "plain"),
    plot.title = element_text(hjust = 0.5, face = "bold")
  )

# Brier score (recalibrated)
brier_new <- mean((df_total$p_recal - df_total$死亡终_num)^2, na.rm = TRUE)
cat("Brier score (recalibrated):", round(brier_new, 4), "\n")

# Hosmer-Lemeshow 检验 (recalibrated)
hl_recal <- hoslem.test(df_total$死亡终_num, df_total$p_recal, g = n_groups)
print(hl_recal)

# ROC AUC (recalibrated)
roc_new <- roc(df_total$死亡终_num, df_total$p_recal)
cat("ROC AUC (recalibrated):", auc(roc_new), "\n")

# -----------------------
# 原始与重新校准对比图
# -----------------------

# 创建分组函数
make_calib <- function(pcol, df, ng = 10) {
  df %>% filter(!is.na(!!rlang::sym(pcol)), !is.na(死亡终_num)) %>%
    mutate(group = ntile(!!rlang::sym(pcol), ng)) %>%
    group_by(group) %>%
    summarise(
      Pred = mean(!!rlang::sym(pcol)),
      Obs = mean(死亡终_num),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(
      se = sqrt(Obs * (1 - Obs) / n),
      lower = pmax(0, Obs - 1.96 * se),
      upper = pmin(1, Obs + 1.96 * se)
    )
}

# 创建分组数据
df_old_cal <- make_calib("p", df_total, ng = 10)
df_new_cal <- make_calib("p_recal", df_total, ng = 10)

# 绘制对比图
ggplot() +
  # 原始模型
  geom_line(data = df_old_cal, aes(x = Pred, y = Obs), color = "gray60", size = 0.8) +
  geom_point(data = df_old_cal, aes(x = Pred, y = Obs), color = "gray60", size = 2) +
  geom_errorbar(data = df_old_cal, aes(x = Pred, ymin = lower, ymax = upper), width = 0.01, color = "gray60") +
  
  # 重新校准后模型
  geom_line(data = df_new_cal, aes(x = Pred, y = Obs), color = "black", size = 1) +
  geom_point(data = df_new_cal, aes(x = Pred, y = Obs), color = "black", size = 3) +
  geom_errorbar(data = df_new_cal, aes(x = Pred, ymin = lower, ymax = upper), width = 0.01, color = "black") +
  
  # 理想线
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray40") +
  
  # 坐标轴和标签
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(
    x = "Predicted probability",
    y = "Observed event rate"
    # ,
    # title = "Calibration: Original (Gray) vs Recalibrated (Black)"
  ) +
  
  # 设置颜色和图例
  scale_color_manual(
    name = "Model",
    values = c("Original" = "gray60", "Recalibrated" = "black")
  ) +
  theme_bw(base_size = 14) +
  theme(
    panel.grid = element_blank(),
    axis.text = element_text(color = "black"),
    axis.title = element_text(face = "plain"),
    plot.title = element_text(hjust = 0.5, face = "plain")
  )








# # 
# # 加图例版
# # # 绘制对比图（带图例，位于图形内部）
# ## 绘制对比图（带图例，位于图形内部）
# ggplot() +
#   # 原始模型
#   geom_line(data = df_old_cal, aes(x = Pred, y = Obs, color = "Original"), size = 0.8) +
#   geom_point(data = df_old_cal, aes(x = Pred, y = Obs, color = "Original"), size = 2) +
#   geom_errorbar(data = df_old_cal, aes(x = Pred, ymin = lower, ymax = upper, color = "Original"), width = 0.01) +
#   
#   # 重新校准后模型
#   geom_line(data = df_new_cal, aes(x = Pred, y = Obs, color = "Recalibrated"), size = 1) +
#   geom_point(data = df_new_cal, aes(x = Pred, y = Obs, color = "Recalibrated"), size = 3) +
#   geom_errorbar(data = df_new_cal, aes(x = Pred, ymin = lower, ymax = upper, color = "Recalibrated"), width = 0.01) +
#   
#   # 理想线
#   geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray40") +
#   
#   # 设置颜色和图例
#   scale_color_manual(
#     name = "Model",
#     values = c("Original" = "gray60", "Recalibrated" = "black")
#   ) +
#   
#   # 坐标轴和标签
#   coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
#   labs(
#     x = "Predicted probability",
#     y = "Observed event rate"
#   ) +
#   theme_bw(base_size = 12) +
#   theme(
#     panel.grid = element_blank(),
#     axis.text = element_text(color = "black"),
#     axis.title = element_text(face = "plain"),
#     plot.title = element_text(hjust = 0.5, face = "plain"),
#     legend.position = c(0.95, 0.05),  # 图例位于右上角
#     legend.justification = c(1, 0),    # 对齐到右下角
#     legend.title = element_text(face = "plain"),
#     legend.text = element_text(size = 8),
#     legend.background = element_rect(fill = "white", color = "black", size = 0.1)  # 图例背景
#   )






















# -----------------------
# 性能指标总结
# -----------------------
cat("\n===== Model Performance Summary =====\n")
cat("Original Model:\n")
cat("  Brier score:", round(brier_old, 4), "\n")
cat("  ROC AUC:", round(auc(roc_old), 4), "\n")
cat("  Hosmer-Lemeshow: χ²(", hl$df, ") = ", round(hl$statistic, 2), ", p = ", 
    ifelse(hl$p.value < 0.001, "<0.001", round(hl$p.value, 4)), "\n", sep = "")
cat("\nRecalibrated Model:\n")
cat("  Brier score:", round(brier_new, 4), "\n")
cat("  ROC AUC:", round(auc(roc_new), 4), "\n")
cat("  Hosmer-Lemeshow: χ²(", hl_recal$df, ") = ", round(hl_recal$statistic, 2), ", p = ", 
    ifelse(hl_recal$p.value < 0.001, "<0.001", round(hl_recal$p.value, 4)), "\n", sep = "")
cat("  Calibration intercept (a):", round(a, 4), "\n")
cat("  Calibration slope (b):", round(b, 4), "\n")





# 辅助函数，安全提取
safe_extract <- function(x, field) {
  if (!is.null(x) && length(x[[field]]) > 0) {
    return(x[[field]])
  } else {
    return(NA)
  }
}

# 安全提取
hl_chisq  <- safe_extract(hl, "statistic")
hl_df     <- safe_extract(hl, "df")
hl_pvalue <- safe_extract(hl, "p.value")

hl_recal_chisq  <- safe_extract(hl_recal, "statistic")
hl_recal_df     <- safe_extract(hl_recal, "df")
hl_recal_pvalue <- safe_extract(hl_recal, "p.value")

# 整理结果
results <- data.frame(
  Model = c("Original", "Recalibrated"),
  Brier = c(round(brier_old, 4), round(brier_new, 4)),
  AUC   = c(round(auc(roc_old), 4), round(auc(roc_new), 4)),
  HL_chisq = c(round(hl_chisq, 2), round(hl_recal_chisq, 2)),
  HL_df    = c(hl_df, hl_recal_df),
  HL_p     = c(
    ifelse(!is.na(hl_pvalue) & hl_pvalue < 0.001, "<0.001", round(hl_pvalue, 4)),
    ifelse(!is.na(hl_recal_pvalue) & hl_recal_pvalue < 0.001, "<0.001", round(hl_recal_pvalue, 4))
  ),
  Intercept = c(NA, round(a, 4)),  # 原始模型没有截距校准
  Slope     = c(NA, round(b, 4))   # 原始模型没有斜率校准
)


# 保存到 Excel
output_file <- "model_performance_summary.xlsx"
write.xlsx(results, output_file, rowNames = FALSE)

cat("结果已保存至：", output_file, "\n")

