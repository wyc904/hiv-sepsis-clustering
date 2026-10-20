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
    Cluster = "Cluster 1",  # 修改为Cluster
    Model = c("Crude", "MA", "PSA", "PSM", "IPTW"),
    OR = c(1.59, 1.47, 1.45, 1.39, 1.45),
    Lower = c(1.13, 0.98, 1.00, 0.89, 1.04),
    Upper = c(2.23, 2.22, 2.09, 2.17, 2.02),
    Pvalue = c(0.008, 0.064, 0.048, 0.144, 0.029)
  ),
  # 第二组数据
  tibble(
    Cluster = "Cluster 2",  # 修改为Cluster
    Model = c("Crude", "MA", "PSA", "PSM", "IPTW"),
    OR = c(1.98, 1.40, 1.29, 1.27, 1.50),
    Lower = c(1.32, 0.85, 0.82, 0.76, 1.01),
    Upper = c(2.95, 2.31, 2.03, 2.12, 2.24),
    Pvalue = c(0.001, 0.184, 0.270, 0.362, 0.044)
  )
) %>%
  # 创建模型因子保持特定顺序
  mutate(Model = fct_relevel(Model, 
                             "IPTW",
                             "PSM",
                             "PSA",
                             "MA",
                             "Crude"),
         # 格式化P值显示
         Pvalue_fmt = ifelse(Pvalue < 0.001, "<0.001", 
                             sprintf("%.3f", Pvalue)),
         # 创建OR(95%CI)字符串
         OR_CI = sprintf("%.2f (%.2f-%.2f)", OR, Lower, Upper))

# 保留原来 Model 的顺序
model_levels <- levels(data$Model)

# 创建y轴标签顺序 (修改为Cluster)
ytick_levels <- c(paste("Cluster 2", model_levels, sep = " - "),
                  paste("Cluster 1", model_levels, sep = " - "))

# 新建 y 变量（用于绘图的行顺序）
df_plot <- data %>%
  mutate(y = factor(paste(Cluster, Model, sep = " - "), levels = ytick_levels))

n_rows <- length(ytick_levels)       # 总行数（10行）
sep_at  <- length(model_levels) + 0.5  # 分隔线位置（在两组之间）

df_plot <- df_plot %>%
  mutate(Sig = ifelse(Pvalue < 0.05, "*", ""))

# 绘图（去掉显著性标注和 OR，只保留 P 值）
forest_plot_grouped <- ggplot(df_plot, aes(x = OR, y = y)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
  # 置信区间与点
  geom_errorbarh(aes(xmin = Lower, xmax = Upper, color = Cluster),
                 height = 0.18, size = 0.8) +
  geom_point(aes(fill = Cluster, shape = Cluster), size = 3.6, stroke = 0.8) +
  # 仅显示 P 值列（右侧）
  geom_text(aes(label = Pvalue_fmt, x = 3.7, color = Cluster),
            hjust = 0, size = 4) +
  # 分隔线
  geom_hline(yintercept = sep_at, color = "gray80", size = 0.6) +
  # y 轴标签
  scale_y_discrete(labels = rep(model_levels, times = 2)) +
  # x 轴
  scale_x_continuous(trans = "log",
                     breaks = c(0.8, 1, 1.5, 2, 3),
                     limits = c(0.8, 6), expand = c(0, 0)) +
  # 主题
  theme_minimal(base_size = 14) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line.x = element_line(color = "black"),
    axis.ticks.x = element_line(color = "black"),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 12),
    axis.text.y = element_text(size = 11, color = "black"),
    axis.text.x = element_text(size = 12, color = "black"),
    axis.title.x = element_text(size = 12, face = "bold"),
    plot.margin = margin(10, 60, 10, 10) # 缩小右边边距
  ) +
  # 修改颜色和形状映射为Cluster
  scale_color_manual(values = c("Cluster 1" = "#0000ff", "Cluster 2" = "#ff0000")) +
  scale_fill_manual(values  = c("Cluster 1" = "#0000ff", "Cluster 2" = "#ff0000")) +
  scale_shape_manual(values = c("Cluster 1" = 21, "Cluster 2" = 23)) +
  labs(x = "Odds Ratio (log scale)", y = "") +
  coord_cartesian(ylim = c(0.5, n_rows + 0.9), clip = "off")

print(forest_plot_grouped)