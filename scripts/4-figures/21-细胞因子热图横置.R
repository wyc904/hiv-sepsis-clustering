# -----------------------------
# 组均值热图（每组一行，细胞因子为列）
# -----------------------------
library(readxl)
library(dplyr)
library(pheatmap)
library(tibble)
library(RColorBrewer)

# 读取数据
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
df_total <- read_excel("1-188-聚类细胞因子-初次合并未处理.xlsx")

# 选取分组和细胞因子
heatmap_data <- df_total %>%
  select(group = cluster,
         `IL-1β (A4)`,
         `IFN-α2 (A5)`,
         `IFN-γ (A6)`,
         `TNF-α (A7)`,
         `MCP-1 (A8)`,
         `IL-6 (A10)`,
         `IL-8 (B2)`,
         `IL-10 (B3)`,
         `IL-12p70 (B4)`,
         `IL-17A (B5)`,
         `IL-18 (B6)`,
         `IL-23 (B7)`,
         `IL-33 (B9)`)

# 确保为数值
heatmap_data[, -1] <- lapply(heatmap_data[, -1], as.numeric)

# 按分组计算均值
grouped_mean <- heatmap_data %>%
  group_by(group) %>%
  summarise(across(everything(), mean, na.rm = TRUE)) %>%
  column_to_rownames("group") %>%
  as.matrix()

# 修改组名（示例，可以按你研究实际修改）
rownames(grouped_mean) <- c("Group 1", "Group 2")

# 注释行（对应 group）
annotation_row <- data.frame(
  Group = rownames(grouped_mean)
)
rownames(annotation_row) <- rownames(grouped_mean)

# JAMA风格颜色方案
# 使用高对比度的蓝-白-红配色，适合学术出版
jama_colors <- colorRampPalette(c("#2166AC", "white", "#B2182B"))(100)

# 组注释颜色
ann_colors <- list(
  Group = c("Group 1" = "#4A6FA5",
            "Group 2" = "#B0B7C3")
)

# 绘制热图
pheatmap(grouped_mean,
         main = "Cytokine Expression by Group",
         color = jama_colors,          # 使用JAMA风格配色
         scale = "column",             # 按细胞因子标准化
         cluster_rows = FALSE,         # 保持组顺序
         cluster_cols = TRUE,          # 聚类细胞因子
         show_rownames = TRUE,         # 显示组名
         show_colnames = TRUE,         # 显示细胞因子
         annotation_row = annotation_row,
         annotation_colors = ann_colors,
         fontsize_row = 12,
         fontsize_col = 10,
         fontsize = 10,
         fontfamily = "sans",          # 使用无衬线字体，更符合现代出版风格
         angle_col = 45,
         cellwidth = 30,               # 调整单元格大小
         cellheight = 30,
         border_color = "grey60",      # 更细的边框
         legend = TRUE,
         annotation_legend = TRUE,
         annotation_legend_side = "right",
         treeheight_row = 0,           # 隐藏行聚类树
         treeheight_col = 30,          # 调整列聚类树高度
         breaks = seq(-2, 2, length.out = 101), # 固定颜色断点范围，确保对称
         display_numbers = FALSE,      # 不显示数值
         gaps_row = NULL,              # 不在行间添加间隔
         gaps_col = NULL,              # 不在列间添加间隔
         na_col = "grey90"             # NA值的颜色
)