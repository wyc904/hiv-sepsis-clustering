setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要的库
library(tidyverse)
library(ggtext)
library(showtext)
library(readxl)
library(ggplot2)

# 添加 Times New Roman 字体支持
font_add("Times New Roman", regular = "times.ttf")
showtext_auto()

# 读取 Excel 文件
cat("开始读取Excel文件...\n")
df <- read_excel("1-188-聚类细胞因子-初次合并未处理.xlsx")
cat("读取完成，开始数据处理...\n")


colnames(df)




# 数据处理：创建TyG指数分层和CD43分组
df_labeled <- df %>%
  mutate(
    # TyG_index分层转换
    TyG_group = case_when(
      `TyG_index分层` == 0 ~ "TyG<9.28",
      `TyG_index分层` == 1 ~ "TyG≥9.28",
      TRUE ~ NA_character_
    ) %>% factor(levels = c("TyG<9.28", "TyG≥9.28"), ordered = TRUE),
    
    # CD43分组转换
    CD43_group = case_when(
      CD4 == 0 ~ "CD4<50",
      CD4 == 1 ~ "CD4≥50",
      TRUE ~ NA_character_
    ) %>% factor(levels = c("CD4<50", "CD4≥50"), ordered = TRUE)
  )

# 计算死亡率等信息
heat_data <- df_labeled %>%
  group_by(CD43_group, TyG_group) %>%
  summarise(
    deaths = sum(df$'28天死亡', na.rm = TRUE),
    total = n(),
    mortality = ifelse(total == 0, 0, deaths / total),
    .groups = "drop"
  ) %>%
  # 确保所有组合存在（即使数据为0）
  complete(
    CD43_group = levels(df_labeled$CD43_group),
    TyG_group = levels(df_labeled$TyG_group),
    fill = list(deaths = 0, total = 0, mortality = 0)
  ) %>%
  # 确保因子顺序正确
  mutate(
    TyG_group = factor(TyG_group, levels = c("TyG<9.28", "TyG≥9.28"), ordered = TRUE),
    CD43_group = factor(CD43_group, levels = c("CD4<50", "CD4≥50"), ordered = TRUE)
  )

# 热力图绘制 - 修改x轴位置
main_heatmap <- ggplot(heat_data, aes(x = TyG_group, y = CD43_group)) +
  geom_tile(aes(fill = mortality), color = "grey70", size = 0.3, alpha = 0.95) +
  scale_fill_gradientn(
    colors = c("#005a00","#008000",  "#ffffbf", "#fdae61", "#d7191c"),
    values = scales::rescale(c(0, 0.2, 0.4, 0.6, 1)),
    limits = c(0, 0.5),
    name = "Mortality",
    labels = scales::percent_format()
  ) +
  geom_text(aes(
    label = sprintf("%.1f%%\n(%d/%d)", mortality * 100, deaths, total)
  ),
  color = "black", size = 4.5, family = "Times New Roman", lineheight = 0.8) +
  labs(
    x = "TyG",
    y = "CD4 T cell"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    text = element_text(family = "Times New Roman"),
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    axis.title.x = element_text(
      size = 14, 
      face = "bold", 
      margin = margin(t = 10)  # 增加顶部间距使标题与图形分隔
    ),
    axis.title.y = element_text(
      size = 14, 
      face = "bold", 
      margin = margin(r = 10)
    ),
    axis.text.x = element_text(
      face = "bold", 
      size = 12,
      margin = margin(t = 0, b = 5)  # 调整标签位置
    ),
    axis.text.y = element_text(
      face = "bold", 
      size = 12
    ),
    panel.grid = element_blank(),
    # 缩小图例尺寸
    legend.position = "right",
    legend.key.height = unit(0.7, "cm"),  # 减小高度
    legend.key.width = unit(0.3, "cm"),   # 减小宽度
    legend.title = element_text(size = 11, face = "bold", vjust = 1, margin = margin(b = 2)),  # 缩小标题
    legend.text = element_text(size = 10, margin = margin(b = 2)),  # 缩小文本
    legend.margin = margin(l = -5, r = 5, t = 0, b = 0),  # 调整图例边距
    plot.margin = margin(0.5, 0.5, 0.5, 0.5, "cm")  # 减小整体边距
  ) +
  coord_fixed(ratio = 0.8)

# 显示图形
print(main_heatmap)
# 显示图形

# 保存图形
ggsave("tyg_cd4_heatmap.png", main_heatmap, width = 6, height = 4, dpi = 300, bg = "white")
ggsave("tyg_cd4_heatmap.pdf", main_heatmap, width = 6, height = 4, dpi = 300, device = cairo_pdf)

cat("图形已成功保存为PNG和PDF格式。\n")

# 可选：输出数据到CSV
write_csv(heat_data, "tyg_cd4_heatmap_data.csv")
cat("数据已保存至tyg_cd4_heatmap_data.csv\n")