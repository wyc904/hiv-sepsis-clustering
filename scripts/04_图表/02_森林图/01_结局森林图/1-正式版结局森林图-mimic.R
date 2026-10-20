setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

library(ggplot2)
library(dplyr)
library(forcats)

# 创建数据集
plot_df <- data.frame(
  variable = c("28-day Mortality", "CRRT", "IMV", 
               "Septicshock", "Hospital Mortality", "Vasopressor", "Glucocorticoid"),
  OR = c(3.59, 1.98, 0.69, 2.05, 3.48, 1.21, 1.73),
  Lower = c(1.24, 0.16, 0.34, 1.01, 1.24, 0.67, 0.85),
  Upper = c(10.42, 24.89, 1.41, 4.18, 9.79, 2.20, 3.51),
  Pvalue = c(0.019, 0.595, 0.307, 0.048, 0.018, 0.532, 0.129)
)

# 修改顺序（前后调换）
plot_df <- plot_df %>%
  mutate(
    variable = factor(variable, levels = c(
      "CRRT", "Glucocorticoid", "IMV", 
      "Vasopressor","Septicshock", "28-day Mortality", "Hospital Mortality"
    )),
    sig_status = ifelse(Pvalue < 0.05, "Significant", "Non-significant"),
    position = as.numeric(variable)
  )





# 森林图
forest_plot <- ggplot(plot_df, aes(x = OR, y = position)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "black", alpha = 0.5) +
  
  # 置信区间正常显示（不移除截断）
  geom_errorbarh(
    aes(xmin = Lower, xmax = Upper),
    height = 0.1, color = "black", size = 0.5
  ) +
  
  # 点估计
  geom_point(
    aes(fill = sig_status),
    shape = 22, size = 3, color = "black"
  )  +
  
  # 填充颜色
  scale_fill_manual(values = c("Non-significant" = "black", "Significant" = "black")) +
  
  # y轴
  scale_y_continuous(
    breaks = plot_df$position,
    labels = plot_df$variable
  ) +
  
  # x轴（对数）
  scale_x_log10(
    breaks = c(0.1, 0.5, 1, 2, 5, 10, 25),
    limits = c(0.09, 30)
  ) +
  
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
        label = ifelse(Pvalue < 0.001, "P<0.001", sprintf("P=%.3f", Pvalue))),
    hjust = 1, size = 5
  ) +
  
  # OR和CI
  geom_text(
    aes(x = 0.1, y = position, 
        label = sprintf("%.2f (%.2f-%.2f)", OR, Lower, Upper)),
    hjust = 0, size = 5
  )

print(forest_plot)


# 保存为PDF（矢量图，无限分辨率）
ggsave(
  filename = "mimic森林图.pdf",   # 文件名
  plot = forest_plot,                    # 要保存的图形
  width = 6,                            # 宽度（英寸）
  height = 6,                            # 高度（英寸）
  device = "pdf",                        # 格式
  bg = "white"                           # 背景颜色
)


# getwd()

