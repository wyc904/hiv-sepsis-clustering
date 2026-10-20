setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要的包
library(ggplot2)
library(ggsci)
library(patchwork)  # 用于组合多个图形
library(scales)

# -----------------------
# 1. 创建校准曲线对比图
# -----------------------

# 使用之前创建的校准数据
# 确保df_old_cal和df_new_cal已创建

# 创建校准曲线对比图
calibration_plot <- ggplot() +
  # 原始模型
  geom_line(data = df_old_cal, aes(x = Pred, y = Obs), color = "gray60", size = 0.8) +
  geom_point(data = df_old_cal, aes(x = Pred, y = Obs), color = "gray60", size = 2) +
  geom_errorbar(data = df_old_cal, aes(x = Pred, ymin = lower, ymax = upper), 
                width = 0.01, color = "gray60") +
  
  # 重新校准后模型
  geom_line(data = df_new_cal, aes(x = Pred, y = Obs), color = "black", size = 1) +
  geom_point(data = df_new_cal, aes(x = Pred, y = Obs), color = "black", size = 3) +
  geom_errorbar(data = df_new_cal, aes(x = Pred, ymin = lower, ymax = upper), 
                width = 0.01, color = "black") +
  
  # 理想线
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray40") +
  
  # 坐标轴和标签
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(
    x = "Predicted probability",
    y = "Observed event rate",
    title = "A. Calibration Curves"
  ) +
  theme_bw() +
  theme(
    text = element_text(family = "sans", size = 10),
    axis.text = element_text(color = "black", size = 9),
    axis.title = element_text(face = "bold", size = 10),
    plot.title = element_text(face = "bold", size = 11, hjust = 0.5),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "black", linewidth = 0.5),
    legend.position = "none"
  )

# -----------------------
# 2. 创建Hosmer-Lemeshow检验柱状图
# -----------------------

# 创建数据框
model_data <- data.frame(
  Model = c("Original", "Recalibrated"),
  HL_chisq = c(32.4, 3.74),
  HL_p = c("<0.001", "0.879")
)

# 创建柱状图
hl_plot <- ggplot(model_data, aes(x = Model, y = HL_chisq, fill = Model)) +
  geom_col(width = 0.6, color = "black", linewidth = 0.3) +
  
  geom_text(aes(label = format(HL_chisq, digits = 3, nsmall = 1)), 
            vjust = -0.5, size =4, fontface = "bold") +
  # 设置Y轴范围为0-40
  scale_y_continuous(limits = c(0, 40), breaks = seq(0, 40, 10),
                     expand = expansion(mult = c(0, 0.1))) +
  scale_fill_manual(values = c("Original" = "gray60", "Recalibrated" = "black")) +
  labs(
    x = "Model",
    y = "Hosmer-Lemeshow χ² Statistic",
    title = "B. Model Calibration Assessment"
  ) +
  theme_bw() +
  theme(
    text = element_text(family = "sans", size = 10),
    axis.text = element_text(color = "black", size = 9),
    axis.title = element_text(face = "bold", size = 10),
    plot.title = element_text(face = "bold", size = 11, hjust = 0.5),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "black", linewidth = 0.5),
    legend.position = "none"
  ) 

# -----------------------
# 3. 组合两个图形
# -----------------------

# 使用patchwork组合图形
combined_plot <- calibration_plot + hl_plot +
  plot_layout(ncol = 2) +
  plot_annotation(
    
    theme = theme(
      plot.title = element_text(
        family = "sans",
        face = "bold",
        size = 12,
        hjust = 0.5,
        margin = margin(b = 10)
      )
    )
  )

# 显示组合图形
print(combined_plot)

# -----------------------
# 4. 保存高质量图片
# -----------------------
