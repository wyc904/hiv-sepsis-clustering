setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要的包
library(ggplot2)
library(gridExtra)

# 数据框
data_cd43 <- data.frame(
  Group = rep(c("Group 1", "Group 2"), each = 3),
  Category = factor(rep(c("<50", "50-200", "≥200"), 2), 
                    levels = c("<50", "50-200", "≥200")),
  Percentage = c(71.3, 20.5, 8.2, 62.4, 21.6, 16.1)
)

data_vl3 <- data.frame(
  Group = rep(c("Group 1", "Group 2"), each = 3),
  Category = factor(rep(c("<10e3", "10e3-10e5", "≥10e5"), 2), 
                    levels = c("<10e3", "10e3-10e5", "≥10e5")),
  Percentage = c(20.3, 23.2, 56.4, 25.1, 18.1, 56.7)
)
# "#f94040", "#0000ff"
# 自定义颜色 (黑灰风格, JAMA常见)
jama_colors <- c("Group 1" = "#f94040", "Group 2" = "#0000ff")

# CD43 柱状图
p1 <- ggplot(data_cd43, aes(x = Category, y = Percentage, fill = Group)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", Percentage)),
            position = position_dodge(width = 0.8), vjust = -0.5, size = 3.5) +
  scale_fill_manual(values = jama_colors) +
  labs(title = "CD4 Distribution by Group",
       x = "CD4 Levels (cells/μL)",
       y = "Percentage (%)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text = element_text(color = "black"),
    legend.title = element_blank(),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  ylim(0, 80) # 设置y轴范围以确保所有标签可见

# VL3 柱状图
p2 <- ggplot(data_vl3, aes(x = Category, y = Percentage, fill = Group)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", Percentage)),
            position = position_dodge(width = 0.8), vjust = -0.5, size = 3.5) +
  scale_fill_manual(values = jama_colors) +
  labs(title = "Viral Load Distribution by Group",
       x = "Viral Load (copies/mL)",
       y = "Percentage (%)") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    axis.text = element_text(color = "black"),
    legend.title = element_blank(),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  ylim(0, 65) # 设置y轴范围以确保所有标签可见

# 并排展示
grid.arrange(p1, p2, ncol = 2)