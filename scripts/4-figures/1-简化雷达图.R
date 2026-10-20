setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

library(ggplot2)
library(dplyr)
library(tidyr)

# 创建数据框 - 使用您提供的变量和最大值
radar_data <- data.frame(
  Indicator = c("DF", "Hospital Stay>7", "Male", "CCI≥3", "Age>60", "COPD"),
  Value = c(4.8, 17.8, 55.2, 1.9, 16.4, 1.1),  # 百分比值
  Max = c(7, 40, 70, 8, 30, 2)  # 每个指标设置不同的最大值
)

# time1:2.2, 16.3, 52.9, 0.1, 25.2, 0.9

# time3:5, 29.2, 56.6, 2.1, 26.7, 0.7



# 计算角度
radar_data <- radar_data %>%
  mutate(angle = seq(0, 2*pi, length.out = n() + 1)[1:n()])

# 归一化数据
radar_data <- radar_data %>%
  mutate(Normalized = Value / Max)

# 创建闭合多边形
radar_poly <- radar_data %>%
  bind_rows(radar_data[1, ]) %>%
  mutate(
    x = Normalized * cos(angle),
    y = Normalized * sin(angle)
  )

# 网格线
grid_lines <- data.frame(
  r = c(0.25, 0.5, 0.75, 1)
) %>%
  crossing(angle = seq(0, 2*pi, length.out = 200)) %>%
  mutate(
    x = r * cos(angle),
    y = r * sin(angle)
  )

# 坐标轴标签 —— 不显示百分比，只显示名称
axis_labels <- radar_data %>%
  mutate(
    x = 1.15 * cos(angle),  # 稍微往外移，避免“Charlson Index”被遮挡
    y = 1.15 * sin(angle)
  )

# 绘制雷达图
ggplot() +
  # 网格线
  geom_path(
    data = grid_lines,
    aes(x = x, y = y, group = r),
    color = "gray80", size = 0.3
  ) +
  # 坐标轴
  geom_segment(
    data = radar_data,
    aes(x = 0, y = 0, xend = cos(angle), yend = sin(angle)),
    color = "gray60", size = 0.4
  ) +
  # 多边形
  geom_polygon(
    data = radar_poly,
    aes(x = x, y = y),
    fill = "#55a0fb", alpha = 0.3,
    color = "#0000ff", size = 0.8
  ) +
  # 数据点
  geom_point(
    data = radar_data,
    aes(x = Normalized * cos(angle), y = Normalized * sin(angle)),
    shape = 21, fill = "#0000ff", color = "white", size = 3, stroke = 1
  ) +
  # 标签（只显示指标）
  geom_text(
    data = axis_labels,
    aes(x = x, y = y, label = Indicator),
    size = 4, family = "serif"
  ) +
  # 主题设置（缩小空白）
  coord_equal(clip = "off") +
  theme_void(base_family = "serif") +
  theme(
    plot.margin = margin(5, 5, 5, 5), # 缩小空白
    panel.border = element_blank()
  )
