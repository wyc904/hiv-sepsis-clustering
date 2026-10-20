setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要的包
library(ggplot2)
library(ggradar)
library(dplyr)
library(tibble)

# 创建数据框
data <- data.frame(
  Variables = c("CKD", "LiverCirrhosis", "COPD", "Diabetes", "Hypertension", "CHD"),
  Group1 = c(1.7, 3.4, 5.9, 5.5, 4.6, 3.1),
  Group2 = c(8.1, 9.5, 6.2, 7.8, 9.5, 5.5)
)

# 准备雷达图数据
radar_data <- data %>%
  as_tibble() %>%
  mutate_at(vars(starts_with("Group")), ~./10) %>% # 将百分比转换为0-1范围的小数
  rename(group = Variables) %>%
  t() %>%
  as.data.frame() %>%
  setNames(., data$Variables) %>%
  rownames_to_column(var = "group") %>%
  slice(-1) # 移除第一行（变量名）

# 确保所有列都是数值型
radar_data <- radar_data %>%
  mutate(across(-group, as.numeric))

# 绘制雷达图
ggradar(radar_data, 
        values.radar = c("0", "5", "10"),
        grid.min = 0, 
        grid.mid = 0.5, 
        grid.max = 1,
        axis.labels = data$Variables,
        group.colours = c("#f94040", "#0000ff"),
        group.line.width = 1,
        group.point.size = 3,
        legend.position = "bottom",
        legend.text.size = 10,
        plot.title = "疾病患病率比较 - 组1 vs 组2") +
  theme(legend.title = element_blank()) +
  scale_y_continuous(labels = function(x) paste0(x*10, "%")) # 将y轴标签恢复为百分比格式