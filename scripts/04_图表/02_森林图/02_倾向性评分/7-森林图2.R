setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))


# 加载必要包
library(ggplot2)
library(dplyr)
library(tidyr)
library(forcats)

# 创建数据集
data <- bind_rows(
  # 第一组数据
  tibble(
    Group = "Group 1",
    Model = c("Unmatched crude", "Multivariable adjusted", 
              "Propensity Score adjusted", "Propensity Score Matched",
              "Weighted IPTW"),
    OR = c(1.59, 1.47, 1.45, 1.39, 1.45),
    Lower = c(1.13, 0.98, 1.00, 0.89, 1.04),
    Upper = c(2.23, 2.22, 2.09, 2.17, 2.02),
    Pvalue = c(0.008, 0.064, 0.048, 0.144, 0.029)
  ),
  # 第二组数据
  tibble(
    Group = "Group 2",
    Model = c("Unmatched crude", "Multivariable adjusted", 
              "Propensity Score adjusted", "Propensity Score Matched",
              "Weighted IPTW"),
    OR = c(1.98, 1.40, 1.29, 1.27, 1.50),
    Lower = c(1.32, 0.85, 0.82, 0.76, 1.01),
    Upper = c(2.95, 2.31, 2.03, 2.12, 2.24),
    Pvalue = c(0.001, 0.184, 0.270, 0.362, 0.044)
  )
) %>%
  # 创建模型因子保持特定顺序（Unmatched crude在顶端）
  mutate(Model = fct_relevel(Model, 
                             "Weighted IPTW",
                             "Propensity Score Matched",
                             "Propensity Score adjusted",
                             "Multivariable adjusted",
                             "Unmatched crude"),
         # 格式化P值显示
         Pvalue_fmt = ifelse(Pvalue < 0.001, "<0.001", 
                             sprintf("%.3f", Pvalue)),
         # 创建OR(95%CI)字符串
         OR_CI = sprintf("%.2f (%.2f-%.2f)", OR, Lower, Upper))
# 创建森林图（修改版）
forest_plot <- ggplot(data, aes(x = OR, y = Model)) +
  # 参考线
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
  # 置信区间
  geom_errorbarh(aes(xmin = Lower, xmax = Upper, color = Group), 
                 height = 0.15, position = position_dodge(0.7), size = 0.8) +
  # 点估计
  geom_point(aes(fill = Group, shape = Group), 
             size = 3.8, position = position_dodge(0.7), stroke = 0.8) +
  # 数值标签 (OR和P值右移，避免重叠)
  geom_text(aes(label = OR_CI, x = 3.7, color = Group), 
            position = position_dodge(0.7), hjust = 0, size = 4) +
  geom_text(aes(label = Pvalue_fmt, x = 4.3, color = Group), 
            position = position_dodge(0.7), hjust = 0, size = 4) +
  # 主题设置（字体加大）
  theme_minimal(base_size = 14) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "black"),
    axis.ticks.x = element_line(color = "black"),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 12),
    axis.text = element_text(size = 12, color = "black"),
    axis.title.x = element_text(size = 14, face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16),
    plot.caption = element_text(hjust = 0, size = 10)
  ) +
  # 横坐标范围缩短，更聚焦
  scale_x_continuous(trans = "log", 
                     breaks = c(0.8, 1, 1.5, 2, 3),
                     limits = c(0.8, 3.5), expand = c(0, 0)) +
  # 列标题
  annotate("text", x = 3.7, y = 5.7, label = "OR (95% CI)", 
           hjust = 0, fontface = "bold", size = 4.5) +
  annotate("text", x = 4.3, y = 5.7, label = "P value", 
           hjust = 0, fontface = "bold", size = 4.5) +
  # 配色和形状
  scale_color_manual(values = c("#0000ff", "#ff0000")) +
  scale_fill_manual(values = c("#0000ff", "#ff0000")) +
  scale_shape_manual(values = c(21, 23)) +
  # 标签
  labs(x = "Odds Ratio (log scale)", y = "") +
  # 确保顺序
  coord_cartesian(ylim = c(0.5, 6), clip = "off")

# 显示
print(forest_plot)
