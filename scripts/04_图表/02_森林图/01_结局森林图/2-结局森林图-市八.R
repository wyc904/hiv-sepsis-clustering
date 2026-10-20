setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

library(ggplot2)
library(dplyr)
library(forcats)

# 创建数据集（使用新数据）
plot_df <- data.frame(
  variable = c("28-day Mortality", "CRRT", "IMV", 
               "Septic Shock", "Hospital Mortality", "Vasopressor", "Glucocorticoid"),
  OR = c(4.15, 7.15, 2.83, 3.22, 3.30, 3.11, 2.29),
  Lower = c(3.15, 4.75, 2.17, 2.55, 2.59, 2.47, 1.72),
  Upper = c(5.45, 10.76, 3.68, 4.05, 4.20, 3.91, 3.03),
  Pvalue = c("<0.001", "<0.001", "<0.001", "<0.001", "<0.001", "<0.001", "<0.001")
)

# 修改顺序（按临床重要性排列）
plot_df <- plot_df %>%
  mutate(
    variable = factor(variable, levels = c(
       "CRRT", "Glucocorticoid",
      "IMV", "Vasopressor", "Septic Shock", "28-day Mortality", "Hospital Mortality"
    )),
    sig_status = "Significant", # 所有结果都显著
    position = as.numeric(variable)
  )

# 森林图
forest_plot1 <- ggplot(plot_df, aes(x = OR, y = position)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "black", alpha = 0.5) +
  
  # 置信区间
  geom_errorbarh(
    aes(xmin = Lower, xmax = Upper),
    height = 0.1, color = "black", size = 0.5
  ) +
  
  # 点估计（所有点均为黑色）
  geom_point(
    fill = "black",
    shape = 22, size = 3, color = "black"
  )  +
  
  # y轴
  scale_y_continuous(
    breaks = plot_df$position,
    labels = plot_df$variable
  ) +
  
  # x轴（对数）
  scale_x_log10(
    breaks = c(0.1, 0.5, 1, 2, 5, 10, 25),
    limits = c(0.09, 30)
  )  +
  
  theme_classic() +
  theme(
    axis.title.y = element_blank(),
    axis.text.y = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(size = 14),
    axis.title.x = element_text(size = 10, face = "bold"),
    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),
    legend.position = "none",
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm")
  ) +
  labs(
    x = "Adjusted Odds Ratio (95% CI)"
  ) +
  
  # P值
  geom_text(
    aes(x = 30, y = position, 
        label = Pvalue),
    hjust = 1, size = 5
  ) +
  
  # OR和CI
  geom_text(
    aes(x = 0.1, y = position, 
        label = sprintf("%.2f (%.2f-%.2f)", OR, Lower, Upper)),
    hjust = 0, size = 5
  )

print(forest_plot1)


ggsave(
  filename = "市八森林图.pdf",   # 文件名
  plot = forest_plot1,                    # 要保存的图形
  width = 6,                            # 宽度（英寸）
  height = 6,                            # 高度（英寸）
  device = "pdf",                        # 格式
  bg = "white"                           # 背景颜色
)

