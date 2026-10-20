setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

library(ggplot2)
library(dplyr)
library(tidyr)


# 创建数据框
radar_data <- data.frame(
  Indicator = c("OC", "PCP","CD4<200", "CMV","ART-naïve", "LYM"),
  Group1 = c(21.2, 22.3,89.2, 24, 69.3 , 0.5),
  Group2 = c(17.7, 12.2,82.5, 19.1 , 69.3, 0.5)
)

# 设置每个指标的最大值（百分比）
max_values <- c(30, 30,100,30, 100, 2)




# 转换为长格式
radar_data_long <- radar_data %>%
  pivot_longer(cols = c(Group1, Group2), 
               names_to = "Group", 
               values_to = "Value") %>%
  mutate(Max = rep(max_values, each = 2)) %>% # 为每个指标设置最大值
  mutate(Normalized = Value / Max) # 归一化数据

# 计算角度
radar_data_long <- radar_data_long %>%
  group_by(Group) %>%
  mutate(angle = seq(0, 2*pi, length.out = n() + 1)[1:n()]) %>%
  ungroup()

# 创建闭合多边形
radar_poly <- radar_data_long %>%
  group_by(Group) %>%
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
  filter(Group == "Group1") %>% # 只需要一组标签
  mutate(
    x = 1.15 * cos(angle),  # 稍微往外移
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
    data = axis_labels,
    aes(x = 0, y = 0, xend = cos(angle), yend = sin(angle)),
    color = "gray60", size = 0.4
  ) +
  # 多边形 - Group1
  geom_polygon(
    data = filter(radar_poly, Group == "Group1"),
    aes(x = x, y = y),
    fill = "#55a0fb", alpha = 0.3,
    color = "#0000ff", size = 0.8
  ) +
  # 多边形 - Group2
  geom_polygon(
    data = filter(radar_poly, Group == "Group2"),
    aes(x = x, y = y),
    fill = "#fb5555", alpha = 0.3,
    color = "#ff0000", size = 0.8
  ) +
  # 数据点 - Group1
  geom_point(
    data = filter(radar_data_long, Group == "Group1"),
    aes(x = Normalized * cos(angle), y = Normalized * sin(angle)),
    shape = 21, fill = "#0000ff", color = "#0000ff", size = 1, stroke = 1
  ) +
  # 数据点 - Group2
  geom_point(
    data = filter(radar_data_long, Group == "Group2"),
    aes(x = Normalized * cos(angle), y = Normalized * sin(angle)),
    shape = 21, fill = "#ff0000", color = "#ff0000", size = 1, stroke = 1
  ) +
  # 标签（只显示指标）
  geom_text(
    data = axis_labels,
    aes(x = x, y = y, label = Indicator),
    size = 4, family = "serif"
  ) +
  # 主题设置
  coord_equal(clip = "off") +
  theme_void(base_family = "serif") +
  theme(
    plot.margin = margin(20, 20, 40, 20), # 增加底部边距
    panel.border = element_blank(),
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    legend.position = "bottom", # 将图例放在底部
    legend.box = "horizontal", # 水平排列图例
    legend.margin = margin(t = 10, b = 10), # 调整图例边距
    legend.text = element_text(size = 12) # 调整图例文本大小
  )  +
  # 添加图例（放在底部）
  guides(
    color = guide_legend(title = NULL, override.aes = list(fill = c("#0000ff", "#ff0000")))
  ) +
  scale_color_manual(
    name = "组别",
    values = c("#0000ff", "#ff0000"),
    labels = c("Group1", "Group2")
  ) +
  labs(color = "组别") # 设置图例标题