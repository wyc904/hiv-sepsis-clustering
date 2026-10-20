setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))



# 市八hiv

# 创建数据框
radar_data <- data.frame(
  Indicator = c("OC", "PCP","CD4<200", "CMV","ART-naïve", "LYM"),
  Group1 = c(21.2, 22.3, 24, 89.2,69.3 , 0.5),
  Group2 = c(17.7, 12.2, 19.1,82.5 , 69.3, 0.5)
)

# 设置每个指标的最大值（百分比）
max_values <- c(30, 30, 100,30,100, 2)



# MIMIC



radar_data <- data.frame(
  Indicator = c("OC", "PCP", "CD4<200","CMV",   "ART-naïve","LYM"),
  Group1 = c(6.2, 4.1,45.4,2.1, 20.6,  1.0),  # 更新为第1组实际值
  Group2 = c(0.0, 0.7, 32.2,0.0,  19.6, 1.5)   # 更新为第2组实际值
)



# 设置每个指标的最大值（百分比）
max_values <- c(30, 30, 100,30,100, 2)







# 市八合并症



radar_data <- data.frame(
  Indicator = c("CKD", "COPD", "Diabetes", "CHD", "Hypertension", "LiverCirrhosis"),
  Group1 = c(2.3, 5.7, 5.9, 3.3, 5.3, 3.7),
  Group2 = c(9.6, 6.7, 8.3, 5.3, 10.6, 10.0)
)

max_values <- c(50, 25, 30,  15,60, 25)  # 前5个指标最大15%，年龄最大60岁



# MIMIC



radar_data <- data.frame(
  Indicator = c("CKD", "COPD", "Diabetes", "CHD", "Hypertension", "LiverCirrhosis"),
  Group1 = c(6.2, 7.2, 15.5, 12.4, 33.0, 8.2),   # 1组百分比 (n=97)
  Group2 = c(39.2, 8.4, 29.4, 11.9, 53.8, 20.3)   # 2组百分比 (n=143)
)



# 市八严重程度


radar_data <- data.frame(
  Indicator = c("SOFA", "AGE", "SepticShock", "CCI", "CRRT", "Hospital Mortality"),
  Group1 = c(4.5, 43.3,31.2,6.5, 0.3, 18.6),   # 1组数据 (n=1181)
  Group2 = c(8.7, 45.5,57.0, 6.8, 10.6, 41.7)    # 2组数据 (n=509)
)

max_values <- c(10,60, 60, 10, 15, 50)  # 前5个指标最大15%，年龄最大60岁





# mimic

radar_data <- data.frame(
  Indicator = c("SOFA", "AGE", "SepticShock", "CRRT", "CCI", "Hospital Mortality"),
  Group1 = c(5.1, 52.4, 21.6, 1.0, 5.9, 7.2),   # 1组数据 (n=97)
  Group2 = c(7.4, 53.5, 29.4, 3.5, 6.8, 16.8)    # 2组数据 (n=143)
)


















