setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

library(ggplot2)
library(dplyr)
library(tidyr)

# 创建数据框
radar_data <- data.frame(
  Indicator = c("OC", "PCP", "CD4<200", "CMV", "ART-naïve", "LYM"),
  Cluster1 = c(21.2, 22.3, 89.2, 24, 69.3, 0.5), # 改为Cluster1
  Cluster2 = c(17.7, 12.2, 82.5, 19.1, 69.3, 0.5)  # 改为Cluster2
)

# 设置每个指标的最大值（百分比）
max_values <- c(30, 30, 100, 30, 100, 2)

# 转换为长格式
radar_data_long <- radar_data %>%
  pivot_longer(cols = c(Cluster1, Cluster2),  # 改为Cluster1和Cluster2
               names_to = "Cluster",          # 改为Cluster
               values_to = "Value") %>%
  mutate(Max = rep(max_values, each = 2)) %>% # 为每个指标设置最大值
  mutate(Normalized = Value / Max) # 归一化数据

# 计算角度
radar_data_long <- radar_data_long %>%
  group_by(Cluster) %>%  # 改为Cluster
  mutate(angle = seq(0, 2*pi, length.out = n() + 1)[1:n()]) %>%
  ungroup()

# 创建闭合多边形
radar_poly <- radar_data_long %>%
  group_by(Cluster) %>%  # 改为Cluster
  bind_rows(slice_head(., n = 1)) %>% # 添加第一个点以闭合多边形
  mutate(
    x = Normalized * cos(angle),
    y = Normalized * sin(angle)
  ) %>%
  ungroup()

# 网格线
grid_lines <- data.frame(
  r = c(0.25, 0.5, 0.75, 1)
) %>%
  crossing(angle = seq(0, 2*pi, length.out = 200)) %>%
  mutate(
    x = r * cos(angle),
    y = r * sin(angle)
  )

# 坐标轴标签
axis_labels <- radar_data_long %>%
  filter(Cluster == "Cluster1") %>% # 改为Cluster1
  mutate(
    x = 1.15 * cos(angle),  # 稍微往外移
    y = 1.15 * sin(angle)
  )

# 创建图例数据 - 增加水平间距
legend_data <- data.frame(
  Cluster = c("Cluster1", "Cluster2"),  # 改为Cluster
  Color = c("#0000ff", "#ff0000"),
  Label = c("Cluster 1", "Cluster 2"),  # 改为Cluster
  x_pos = c(-0.4, 0.4), # 增加水平间距
  y_pos = -1.4 # 统一y位置
)

# 绘制雷达图
ggplot() +
  # 网格线
  geom_path(
    data = grid_lines,
    aes(x = x, y = y, group = r),
    color = "gray80", linewidth = 0.3
  ) +
  # 坐标轴
  geom_segment(
    data = axis_labels,
    aes(x = 0, y = 0, xend = cos(angle), yend = sin(angle)),
    color = "gray60", linewidth = 0.4
  ) +
  # 多边形 - Cluster1
  geom_polygon(
    data = filter(radar_poly, Cluster == "Cluster1"),  # 改为Cluster1
    aes(x = x, y = y),
    fill = "#55a0fb", alpha = 0.3,
    color = "#0000ff", linewidth = 0.8
  ) +
  # 多边形 - Cluster2
  geom_polygon(
    data = filter(radar_poly, Cluster == "Cluster2"),  # 改为Cluster2
    aes(x = x, y = y),
    fill = "#fb5555", alpha = 0.3,
    color = "#ff0000", linewidth = 0.8
  ) +
  # 数据点 - Cluster1
  geom_point(
    data = filter(radar_data_long, Cluster == "Cluster1"),  # 改为Cluster1
    aes(x = Normalized * cos(angle), y = Normalized * sin(angle)),
    shape = 21, fill = "#0000ff", color = "#0000ff", size = 1, stroke = 1
  ) +
  # 数据点 - Cluster2
  geom_point(
    data = filter(radar_data_long, Cluster == "Cluster2"),  # 改为Cluster2
    aes(x = Normalized * cos(angle), y = Normalized * sin(angle)),
    shape = 21, fill = "#ff0000", color = "#ff0000", size = 1, stroke = 1
  ) +
  # 标签（只显示指标）
  geom_text(
    data = axis_labels,
    aes(x = x, y = y, label = Indicator),
    size = 4, family = "serif"
  ) +
  # 添加图例点 - 增加水平间距
  geom_point(
    data = legend_data,
    aes(x = x_pos, y = y_pos, color = Label),
    size = 3
  ) +
  # 添加图例文本 - 增加水平间距
  geom_text(
    data = legend_data,
    aes(x = x_pos + 0.1, y = y_pos, label = Label),
    hjust = 0, size = 4, family = "serif"
  )  +
  # 主题设置
  coord_equal(clip = "off") +
  theme_void(base_family = "serif") +
  theme(
    plot.margin = margin(20, 20, 60, 20), # 增加底部边距为图例留空间
    panel.border = element_blank(),
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    legend.position = "none"
  ) +
  scale_color_manual(
    values = c("Cluster 1" = "#0000ff", "Cluster 2" = "#ff0000")  # 改为Cluster
  ) +
  # 添加标题
  labs(title = "Comparison of Clinical Indicators Between Patient Clusters")