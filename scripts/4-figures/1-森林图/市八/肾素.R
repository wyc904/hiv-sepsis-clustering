setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要包
library(ggplot2)
library(dplyr)
library(tidyr)
library(forcats)

# 创建数据集（使用Heparin新数据）
data <- bind_rows(
  # 第一组数据
  tibble(
    Group = "Cluster 1",
    Model = c("Crude", "MA", "PSA", "PSM", "IPTW"),
    OR = c(3.12, 2.00, 1.97, 1.48, 1.59),
    Lower = c(1.98, 1.16, 1.19, 0.80, 0.95),
    Upper = c(4.90, 3.45, 3.24, 2.76, 2.66),
    Pvalue = c("<0.001", "0.013", "0.008", "0.210", "0.079")
  ),
  # 第二组数据
  tibble(
    Group = "Cluster 2",
    Model = c("Crude", "MA", "PSA", "PSM", "IPTW"),
    OR = c(1.58, 2.12, 1.80, 1.55, 2.49),
    Lower = c(0.94, 1.10, 1.01, 0.73, 1.45),
    Upper = c(2.68, 4.08, 3.19, 3.27, 4.29),
    Pvalue = c("0.087", "0.025", "0.044", "0.255", "0.001")
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
         Pvalue_fmt = Pvalue)

# 保留原来 Model 的顺序
model_levels <- levels(data$Model)

# 创建y轴标签顺序
ytick_levels <- c(paste("Cluster 2", model_levels, sep = " - "),
                  paste("Cluster 1", model_levels, sep = " - "))

# 新建 y 变量（用于绘图的行顺序）
df_plot <- data %>%
  mutate(y = factor(paste(Group, Model, sep = " - "), levels = ytick_levels))

n_rows <- length(ytick_levels)       # 总行数（10行）
sep_at  <- length(model_levels) + 0.5  # 分隔线位置（在两组之间）

# 绘图
forest_plot_grouped <- ggplot(df_plot, aes(x = OR, y = y)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
  # 置信区间与点
  geom_errorbarh(aes(xmin = Lower, xmax = Upper, color = Group),
                 height = 0.18, size = 0.8) +
  geom_point(aes(fill = Group, shape = Group), size = 3.6, stroke = 0.8) +
  # 显示 P 值列（右侧）
  geom_text(aes(label = Pvalue_fmt, x = 4.5, color = Group),
            hjust = 0, size = 4) +
  # 分隔线
  geom_hline(yintercept = sep_at, color = "gray80", size = 0.6) +
  # y 轴标签
  scale_y_discrete(labels = rep(model_levels, times = 2)) +
  # x 轴（调整范围以适应更小的OR值）
  scale_x_continuous(trans = "log",
                     breaks = c(0.5, 1,  3,  5),
                     limits = c(0.5, 5.5), expand = c(0, 0)) +
  # 列标题
  # annotate("text", x = 4.5, y = n_rows + 0.6, label = "P value",
  #          hjust = 0, fontface = "bold", size = 4.5) +
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
    axis.title.x = element_text(size = 14, face = "bold"),
    plot.margin = margin(10, 60, 10, 10) # 调整边距
  ) +
  # 修复颜色映射问题
  scale_color_manual(values = c("Cluster 1" = "#0000ff", "Cluster 2" = "#ff0000"),
                     labels = c("Cluster 1", "Cluster 2")) +
  scale_fill_manual(values  = c("Cluster 1" = "#0000ff", "Cluster 2" = "#ff0000"),
                    labels = c("Cluster 1", "Cluster 2")) +
  scale_shape_manual(values = c("Cluster 1" = 21, "Cluster 2" = 23),
                     labels = c("Cluster 1", "Cluster 2")) +
  labs(x = "Odds Ratio (log scale)", y = "") +
  coord_cartesian(ylim = c(0.5, n_rows + 0.9), clip = "off")

# 显示图形
print(forest_plot_grouped)