#########################################
# Hosmer–Lemeshow 校准检验
#########################################
library(readxl)
library(dplyr)
library(ResourceSelection)  # H-L 检验用

# 1. 导入数据
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
df <- read_excel("1665-风险分层1.xlsx")

# 2. 确保变量格式
df <- df %>%
  mutate(
    死亡终 = as.numeric(死亡终),     # 0 = 存活, 1 = 死亡
    new_score = as.numeric(new_score)
  )

# 3. 拟合逻辑回归模型
fit <- glm(死亡终 ~ new_score, data = df, family = binomial)

# 4. Hosmer–Lemeshow 检验 (默认分成10组)
hl <- hoslem.test(df$死亡终, fitted(fit), g = 10)

print(hl)


# 
# 
# p-value：若 >0.05，说明模型预测概率与实际观测频率差异 不显著 → 模型校准度良好。
# 
# 若 <0.05，说明模型预测与实际差异显著 → 校准欠佳。
# 
