setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要包
library(ggplot2)
library(dplyr)
library(tidyr)
library(forcats)

# 创建数据集（使用您提供的新数据）
data <- bind_rows(
  # 第一组数据
  tibble(
    Cluster = "Cluster 1",  # 修改为Cluster
    Model = c("Crude", "MA", "PSA", "PSM", "IPTW"),
    OR = c(4.27, 2.09, 2.16, 1.99, 3.00),
    Lower = c(2.53, 1.11, 1.19, 0.95, 1.69),
    Upper = c(7.20, 3.93, 3.91, 4.15, 5.33),
    Pvalue = c("<0.001", "0.022", "0.011", "0.067", "<0.001")
  ),
  # 第二组数据
  tibble(
    Cluster = "Cluster 2",  # 修改为Cluster
    Model = c("Crude", "MA", "PSA", "PSM", "IPTW"),
    OR = c(6.81, 4.33, 3.90, 4.04, 4.14),
    Lower = c(3.84, 2.28, 2.11, 1.98, 2.44),
    Upper = c(12.06, 8.22, 7.19, 8.27, 7.02),
    Pvalue = c("<0.001", "<0.001", "<0.001", "<0.001", "<0.001")
  )
) %>%
  # 创建模型因子保持特定顺序
  mutate(Model = fct_relevel(Model, 
                             "IPTW",
                             "PSM",
                             "PSA",
                             "MA",
                             "Crude"),
         # 格式化P值显示（注意：新数据中P值已经是字符串格式）
         Pvalue_fmt = Pvalue)

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

# 绘图
forest_plot_grouped <- ggplot(df_plot, aes(x = OR, y = y)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
  # 置信区间与点
  geom_errorbarh(aes(xmin = Lower, xmax = Upper, color = Cluster),
                 height = 0.18, size = 0.8) +
  geom_point(aes(fill = Cluster, shape = Cluster), size = 3.6, stroke = 0.8) +
  # 显示 P 值列（右侧）
  geom_text(aes(label = Pvalue_fmt, x = 13, color = Cluster),
            hjust = 0, size = 4) +
  # 分隔线
  geom_hline(yintercept = sep_at, color = "gray80", size = 0.6) +
  # y 轴标签
  scale_y_discrete(labels = rep(model_levels, times = 2)) +
  # x 轴（调整范围以适应更大的OR值）
  scale_x_continuous(trans = "log",
                     breaks = c(0.5, 1, 2, 4, 8, 12),
                     limits = c(0.5, 15), expand = c(0, 0)) +
  # # 列标题
  # annotate("text", x = 13, y = n_rows + 0.6, label = "P value",
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
  # 修改颜色和形状映射为Cluster
  scale_color_manual(values = c("Cluster 1" = "#0000ff", "Cluster 2" = "#ff0000")) +
  scale_fill_manual(values  = c("Cluster 1" = "#0000ff", "Cluster 2" = "#ff0000")) +
  scale_shape_manual(values = c("Cluster 1" = 21, "Cluster 2" = 23)) +
  labs(x = "Odds Ratio (log scale)", y = "") +
  coord_cartesian(ylim = c(0.5, n_rows + 0.9), clip = "off")

# 显示图形
print(forest_plot_grouped)

# 保存为高分辨率TIFF
ggsave("IMVzong_ForestPlot.tiff", 
       plot = forest_plot_grouped,
       device = "tiff",
       width = 10, 
       height = 7,
       dpi = 600,
       compression = "lzw")