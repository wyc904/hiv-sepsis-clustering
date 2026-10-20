setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# 加载必要的包
library(ggplot2)
library(ggradar)
library(dplyr)
library(tibble)
library(scales)

# 创建数据框（百分比数据直接使用，连续变量进行标准化）
data <- data.frame(
  Variables = c("Shock", "Vasopressor", "IMV", "CRRT", "SOFA", "HospitalLOS"),
  Group1 = c(6.6, 9.3, 5.7, 0.3, 4.5, 12.2),
  Group2 = c(25.0, 27.6, 17.2, 10.6, 8.3, 33.1)
)

# 对连续变量SOFA和住院时长进行标准化（缩放到0-100范围）
# SOFA评分通常范围0-24，住院时长根据数据特点调整
max_sofa <- 20 # 假设最大SOFA评分
max_los <- 50 # 假设最大住院时长

data$Group1[5] <- (data$Group1[5] / max_sofa) * 100 # SOFA标准化
data$Group1[6] <- (data$Group1[6] / max_los) * 100 # 住院时长标准化
data$Group2[5] <- (data$Group2[5] / max_sofa) * 100 # SOFA标准化
data$Group2[6] <- (data$Group2[6] / max_los) * 100 # 住院时长标准化

# 准备雷达图数据
radar_data <- data %>%
  as_tibble() %>%
  mutate_at(vars(starts_with("Group")), ~./100) %>% # 将所有值转换为0-1范围
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
        values.radar = c("0", "50", "100"),
        grid.min = 0, 
        grid.mid = 0.5, 
        grid.max = 1,
        axis.labels = c("Shock", "Vasopressor", "IMV", "CRRT", "SOFA", "LOS<7"),
        group.colours = c("#f94040", "#0000ff"),
        group.line.width = 1.5,
        group.point.size = 3,
        legend.position = "bottom",
        legend.text.size = 10,
        plot.title = "危重症临床指标比较 - 组1 vs 组2",
        axis.label.size = 4) +
  theme(legend.title = element_blank(),
        plot.title = element_text(hjust = 0.5, face = "bold"),
        legend.position = "bottom") +
  scale_y_continuous(labels = function(x) paste0(x*100, "%"))