setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要的包
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyr)

# 读取数据
data <- read_excel("1690.xlsx")




# 市八
# # 连续变量
cont_vars <- c("AGE", "VL", "CD4", "CCI", "TBIL", "Cr", "PLT", "LYM",
               "INR", "LDH", "ALB", "GLU", "UREA","SOFA", "CCI","HOSLOS",
               "AST", "LAC", "CRP", "PCT", "MONO", "WBC")


# 标准化 (z-score)
data_z <- data %>%
  mutate(across(all_of(cont_vars), scale))

# 计算每个cluster的均值
cluster_means <- data_z %>%
  group_by(cluster) %>%
  summarise(across(all_of(cont_vars), mean, na.rm = TRUE)) %>%
  pivot_longer(-cluster, names_to = "Variable", values_to = "MeanZ")

# ---- 计算变量区分度 ----
variable_diff <- cluster_means %>%
  pivot_wider(names_from = cluster, values_from = MeanZ) %>%
  mutate(
    diff = `2` - `1`,        # 计算原始差异
    abs_diff = abs(`2` - `1`) # 计算绝对差异
  ) %>%
  arrange(desc(abs_diff))    # 按绝对差异降序排列

# 提取前5个最具区分度的变量
top5_vars <- head(variable_diff, 5) %>% 
  pull(Variable) %>% 
  as.character()

# 打印结果
cat("最具区分度的前5个变量:\n")
print(top5_vars)

# 提取前5个变量的数据
top5_data <- cluster_means %>% 
  filter(Variable %in% top5_vars)

# 可视化前5个变量的差异
ggplot(top5_data, aes(x = reorder(Variable, -abs(MeanZ)), 
                      y = MeanZ, 
                      fill = factor(cluster))) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), 
           width = 0.7, color = "black") +
  scale_fill_manual(values = c("#1f77b4", "#ff7f0e"), 
                    labels = c("Cluster 1", "Cluster 2")) +
  labs(title = "Top 5 Discriminative Variables",
       x = "Variables", y = "Mean z-score",
       fill = "Cluster") +
  theme_minimal(base_size = 14) +
  theme(
    text = element_text(family = "Times New Roman"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 12, face = "bold"),
    axis.text.y = element_text(size = 12),
    axis.title.x = element_text(size = 14, face = "bold"),
    axis.title.y = element_text(size = 14, face = "bold"),
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
    legend.position = "top",
    legend.title = element_text(face = "bold"),
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  geom_text(aes(label = round(MeanZ, 2)), 
            position = position_dodge(width = 0.8), 
            vjust = -0.5, size = 4, fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0.1, 0.2))) # 为标签留出空间

# 保存结果到CSV文件
write.csv(variable_diff, "variable_discrimination_scores.csv", row.names = FALSE)
write.csv(top5_data, "top5_discriminative_variables.csv", row.names = FALSE)