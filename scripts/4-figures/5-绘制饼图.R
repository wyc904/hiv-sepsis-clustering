setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要的包
library(readxl)
library(dplyr)
library(ggplot2)
library(scales)

# 读取Excel数据
data <- read_excel("0211.xlsx")


# day28_outcome
# 筛选 cluster = 1 和 2，并修改因子水平标签为英文
df <- data %>%
  filter(cluster %in% c(0, 1)) %>%
  mutate(死亡终 = factor(死亡终, levels = c(0, 1), labels = c("Alive", "Death")),
         cluster = factor(cluster, levels = c(0, 1), labels = c("Cluster 1", "Cluster 2")))

# 统计各组死亡分布
df_summary <- df %>%
  group_by(cluster, 死亡终) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(cluster) %>%
  mutate(prop = n / sum(n),
         label = paste0(死亡终, "\n", n, " (", percent(prop, accuracy = 0.1), ")"))

# 设置JAMA风格的颜色方案 - 蓝色系和红色系
cluster_colors <- c("Cluster 1_Death" = "#00468B", "Cluster 1_Alive" = "#d4d4d4",
                    "Cluster 2_Death" = "#ED0000", "Cluster 2_Alive" = "#d4d4d4")

# 创建组合的fill变量用于分面着色
df_summary <- df_summary %>%
  mutate(fill_combo = paste(cluster, 死亡终, sep = "_"))

# 绘制并排饼图（图例位于底部）
ggplot(df_summary, aes(x = "", y = prop, fill = fill_combo)) +
  geom_col(width = 1, color = "white", linewidth = 0.5) +
  coord_polar(theta = "y") +
  facet_wrap(~cluster, nrow = 1) +
  scale_fill_manual(
    values = cluster_colors,
    name = "Legend",
    labels = c( "Alive", "Death", "Alive","Death")
  ) +
  theme_void() +
  theme(
    legend.position = "bottom",  # 将图例移动到底部[1,2,3](@ref)
    strip.text = element_text(size = 14, face = "bold", margin = margin(b = 5)),
    panel.spacing = unit(0.5, "cm"),
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9),
    legend.key.size = unit(0.8, "cm"),
    plot.title = element_blank()
  ) +
  guides(fill = guide_legend(
    title.position = "top",
    nrow = 1,  # 确保图例项单行排列[5](@ref)
    label.position = "right"
  ))