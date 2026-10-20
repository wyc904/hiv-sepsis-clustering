




# 加载必要的库
library(readxl)
library(dplyr)
library(lubridate)
library(writexl)
# 加载必要的包
library(readr)
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
# 
# setwd("D:/Desktop/Cursor/")
# # 
# list.files()
# s

# "姓名", "性别", "当前年龄"
# 工作簿1
# 读取两个Excel文件
cat("开始读取Excel文件...\n")
df <- read_excel("79w-肝素_20250918.xlsx")



# 定义脓毒症肝素常规给药途径列表
valid_routes <- c("IV", "IV BOLUS", "IV DRIP", "IV FLUSH", "IV INFUSION",
                  "PO", "NG", "G TUBE", "PO OR ENTERAL TUBE", "PO/NG")


# # 定义脓毒症糖皮质激素常规给药途径列表
# valid_routes <- c("IV", "IV BOLUS", "IV DRIP", "IV FLUSH",
#                   "PO", "NG", "G TUBE", "PO OR ENTERAL TUBE")

# 假设您的数据框名为df，给药途径列名为route
# 步骤1：过滤保留有效给药途径
filtered_df <- df %>%
  filter(route %in% valid_routes)

# 步骤2：查看过滤后的给药途径分布（可选）
table(filtered_df$route)

# 如果需要直接在原数据框中删除非常规途径
df_clean <- df %>%
  filter(route %in% valid_routes)

# 如果数据中有大小写不一致问题，可以先标准化
df <- df %>%
  mutate(route = toupper(route))  # 全部转为大写

# 然后执行过滤
df_clean <- df %>%
  filter(route %in% toupper(valid_routes))  # 确保比较时大小写一致


write_xlsx(df_clean, "33w-肝素_20250918.xlsx")








###################

df <- df_clean


# 定义需要删除的非治疗性肝素药物列表
non_therapeutic_heparin <- c(
  "Heparin Flush (10 units/ml)",
  "Heparin (IABP)",
  "Heparin Flush (100 units/ml)",
  "Heparin (via Anti-Xa Monitoring)",
  "Heparin (Hemodialysis)",
  "Heparin Flush Port (10 units/mL)",
  "Heparin Flush CRRT (5000 Units/mL)",
  "Heparin Flush (1000 units/mL)",
  "Heparin Flush CVL (100 units/ml)",
  "Heparin Flush Hickman (100 units/ml)",
  "Heparin Flush PICC (100 units/ml)",
  "Heparin Flush (5000 Units/mL)",
  "Heparin CRRT",
  "Heparin (Impella)",
  "Heparin Desensitization",
  "Heparin Flush Midline (100 units/ml)",
  "Heparin Flush",
  "Heparin Lock Flush",
  "Heparin (Preservative Free)",
  "Enoxaparin (Prophylaxis)",
  "heparin (porcine)"  # 注意：这里保留了普通肝素，只删除特定标注的
)

# 假设您的数据框名为df，药物名称列名为drug
# 步骤1：标准化药物名称（全部转为小写）
df <- df %>%
  mutate(drug = tolower(drug))

# 步骤2：过滤删除非治疗性肝素药物
df_clean <- df %>%
  filter(!drug %in% tolower(non_therapeutic_heparin))

# 步骤3：查看保留的治疗性肝素药物（可选）
table(df_clean$drug)

# 步骤4：保存清洗后的数据
write_xlsx(df_clean, "脓毒症肝素治疗数据.xlsx")








