setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))


# 加载必要的包
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)

# 读取数据
data <- read_excel("1690.xlsx")




# 市八
# # # 连续变量
cont_vars <- c("AGE", "VL", "CD4", "CCI", "TBIL", "Cr", "PLT", "LYM",
               "INR", "LDH", "ALB", "GLU", "UREA",
               "AST", "LAC", "CRP", "PCT", "MONO", "WBC","SOFA", "HOSLOS")


# # 连续变量
# 
# 
# cont_vars <- c("AGE",  "CD4", "CCI", "TBIL", "Cr", "PLT", "LYM",
#                "INR", "LDH", "ALB", "GLU", "UREA",
#                "AST", "LAC","SOFA","HOSLOS")

# 标准化 (z-score)
data_z <- data %>%
  mutate(across(all_of(cont_vars), scale))

# 计算每个cluster的均值
cluster_means <- data_z %>%
  group_by(cluster) %>%
  summarise(across(all_of(cont_vars), mean, na.rm = TRUE)) %>%
  pivot_longer(-cluster, names_to = "Variable", values_to = "MeanZ")

# ---- 按差异大小排序变量（保留正负，不取绝对值）----
diff_order <- cluster_means %>%
  pivot_wider(names_from = cluster, values_from = MeanZ) %>%
  mutate(diff = `2` - `1`) %>%   # 直接算差异，不取绝对值
  arrange(desc(diff)) %>%
  pull(Variable)

# 设置因子顺序，差异最大的（正值）在最左边，差异最小（负值）在最右边
cluster_means$Variable <- factor(cluster_means$Variable, levels = diff_order)

# ---- 保持对称绘图：cluster=1 负值，cluster=2 正值 ----
cluster_means <- cluster_means %>%
  mutate(MeanZ_plot = ifelse(cluster == 1, -MeanZ, MeanZ))

ggplot(cluster_means, aes(y = Variable, x = MeanZ_plot, 
                          group = factor(cluster), 
                          color = factor(cluster))) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_x_continuous(limits = c(-0.5, 1),   # 设置 x 轴范围为 [-1, 1]
                     breaks = seq(-1, 1, 0.5),  # 刻度可以按 0.5 间隔
                     labels = c("-1", "-0.5", "0", "0.5", "1")) +
  scale_color_manual(values = c("blue", "red"), 
                     labels = c("Cluster 1", "Cluster 2")) +
  theme_minimal(base_size = 14) +
  labs(x = "Mean z-score (mirrored)", y = "Variables",
       color = "Cluster") +
  theme(
    # 去除网格线
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    
    # 增加坐标轴线
    axis.line = element_line(color = "black", size = 0.6),
    
    # Times New Roman 字体，x轴水平
    axis.text.x = element_text(size = 12, face = "bold", 
                               angle = 0, hjust = 0.5, 
                               family = "Times New Roman"),
    axis.text.y = element_text(size = 12, family = "Times New Roman"),
    axis.title.x = element_text(size = 14, family = "Times New Roman"),
    axis.title.y = element_text(size = 14, family = "Times New Roman"),
    
    # 图例
    legend.position = "top",
    legend.title = element_blank(),
    legend.text = element_text(family = "Times New Roman", size = 12)
  )
