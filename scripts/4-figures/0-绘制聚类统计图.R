setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

library(ggplot2)
library(dplyr)

# 数据
model_data <- data.frame(
  Model = 1:13,
  Clusters = c(2, 3, 2, 2, 3, 2, 2, 3, 4, 4, 5, 5, 2),
  Covariance = c("VVI", "VEI", "VEI", "EVI", "VII", "EEI", "VII", "EII", "VII", "EII", "VII", "EII", "EII"),
  BIC = c(-63806, -63955, -71253, -78746, -76361, -91254, -79912, -93420, -73581, -91355, -71849, -90614, -95129)
)

# 标记最佳模型
model_data <- model_data %>%
  mutate(Best = ifelse(BIC == min(BIC), TRUE, FALSE))

# 绘制 JAMA 风格图 - 图例横置
# 绘制 JAMA 风格图 - 无网格线，有边框
p <- ggplot(model_data, aes(x = Clusters, y = BIC, color = Covariance)) +
  geom_point(size = 3, alpha = 0.9) + 
  geom_line(size = 0.8, alpha = 0.8) +
  
  # 突出最佳模型
  geom_point(data = subset(model_data, Best == TRUE),
             aes(x = Clusters, y = BIC),
             shape = 1, size = 4, color = "red", stroke = 1.2) +
  
  # 添加最佳模型标签
  geom_text(data = subset(model_data, Best == TRUE),
            aes(label = "Best"), 
            vjust = -1.5, size = 4, color = "black", fontface = "bold") +
  
  # 主题设置 - JAMA风格（无网格线，有边框）
  theme_classic(base_size = 12) +  # 使用经典主题
  theme(
    text = element_text(family = "Times New Roman", size = 11),
    axis.title = element_text(face = "plain", size = 12),
    axis.text = element_text(color = "black", size = 12),
    
    # 图例横置在底部
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.box = "horizontal",
    legend.title = element_text(face = "plain", size = 11),
    legend.text = element_text(size = 10),
    legend.margin = margin(t = 0, r = 0, b = 5, l = 0),
    
    # 移除所有网格线
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    
    plot.title = element_text(face = "plain", hjust = 0.5, size = 13),
    plot.margin = margin(10, 10, 20, 10),  # 增加底部边距容纳图例
    
    # 边框设置
    panel.border = element_rect(color = "black", size = 0.6, fill = NA)  # 添加黑色边框
  ) +
  labs(
    # title = "Model Selection Based on Bayesian Information Criterion (BIC)",
    x = "Number of Clusters",
    y = "BIC Value",
    color = "Covariance Structure"
  )

print(p)
# 
# # 保存高分辨率图片
# ggsave("cluster_model_selection_jama.png", p, width = 7, height = 6, dpi = 300)