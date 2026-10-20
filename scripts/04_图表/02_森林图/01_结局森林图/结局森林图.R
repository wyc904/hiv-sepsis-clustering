setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

library(ggplot2)
library(dplyr)
library(forcats) # 用于因子操作







# 假设这是您整理好的用于画图的数据框
plot_df <- data.frame(
  variable = c("28-day Mortality", "Mechanical Ventilation", "Vasopressor Use", 
               "CRRT", "ICU Length of Stay", "Hospital Length of Stay"),
  category = c("Outcome", "Outcome", "Outcome", "Outcome", "Utilization", "Utilization"),
  crude_est = c(2.1, 1.8, 2.5, 3.2, 1.5, 1.4), # Crude OR/HR
  crude_low = c(1.5, 1.3, 1.7, 2.1, 1.1, 1.0),
  crude_high = c(3.0, 2.5, 3.7, 4.9, 2.0, 1.9),
  adj_est = c(1.7, 1.5, 2.0, 2.5, 1.3, 1.2),   # Adjusted OR/HR
  adj_low = c(1.2, 1.1, 1.4, 1.7, 1.0, 0.9),
  adj_high = c(2.4, 2.1, 2.9, 3.7, 1.7, 1.6),
  adj_p = c(0.004, 0.012, "<0.001", "<0.001", 0.041, 0.15)
)




library(ggplot2)
library(dplyr)
library(forcats)

library(ggplot2)
library(dplyr)
library(forcats)

# 1. 数据预处理 - 确保变量是因子并正确排序
plot_df <- plot_df %>%
  mutate(
    variable = factor(variable, levels = rev(unique(variable))), # 创建因子并反转顺序
    sig_status = ifelse(adj_p < 0.05, "Significant", "Non-significant"),
    # 为每个变量创建两个位置：一个用于未校正，一个用于校正
    position_adjusted = as.numeric(variable),
    position_crude = as.numeric(variable) + 0.2
  )

# 2. 创建森林图 - 使用离散y轴并错开显示
forest_plot <- ggplot(plot_df) +
  # 添加参考线
  geom_vline(xintercept = 1, linetype = "dashed", color = "black", alpha = 0.5) +
  
  # 绘制未校正效应点与线 (Crude) - 使用单独的y位置
  geom_errorbarh(
    aes(xmin = crude_low, xmax = crude_high, y = position_crude),
    height = 0.05, color = "grey50", size = 0.8
  ) +
  geom_point(
    aes(x = crude_est, y = position_crude),
    shape = 15, size = 2, color = "grey50"
  ) +
  
  # 绘制校正后效应点与线 (Adjusted) - 使用单独的y位置
  geom_errorbarh(
    aes(xmin = adj_low, xmax = adj_high, y = position_adjusted),
    height = 0.05, color = "black", size = 0.8
  ) +
  geom_point(
    aes(x = adj_est, y = position_adjusted, fill = sig_status),
    shape = 22, size = 3
  ) +
  scale_fill_manual(values = c("Non-significant" = "white", "Significant" = "black")) +
  
  # 设置y轴刻度和标签
  scale_y_continuous(
    breaks = plot_df$position_adjusted,
    labels = plot_df$variable,
    sec.axis = sec_axis(
      trans = ~., 
      breaks = plot_df$position_adjusted,
      labels = plot_df$variable
    )
  ) +
  
  # 设置x轴
  scale_x_log10(breaks = c(0.5, 1, 2, 4), limits = c(0.4, 5)) +
  
  # 主题设置
  theme_classic() +
  theme(
    axis.title.y = element_blank(),
    axis.text.y = element_text(face = "bold", size = 10),
    axis.line.y = element_blank(),
    axis.ticks.y = element_blank(),
    legend.position = "none",
    plot.margin = unit(c(1, 1, 1, 1), "cm")
  ) +
  labs(
    x = "Odds Ratio / Hazard Ratio (95% CI)",
    title = "Association Between Sepsis Cluster and Clinical Outcomes",
    subtitle = "Grey squares: Unadjusted estimates\nBlack/white squares: Estimates adjusted for age, sex, SOFA score, CD4 count, and HIV viral load"
  )

# 3. 显示图形
print(forest_plot)