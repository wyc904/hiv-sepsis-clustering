setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))

# rm(list=ls());gc()



# dev.off()
# 加载必要的库
library(survival)
library(survminer)
library(writexl)
# 加载必要的库
library(readxl)

# 读取Excel数据
data <- read_excel("1690.xlsx")


# day28_outcome
# day28_los
 surv_obj <- Surv(data$hoslos, data$'死亡终')
 # 

# 创建生存对象
# surv_obj <- Surv(data$day28_los, data$'day28_outcome')

 # cluster
 # CD47
 # 
# 进行KM生存分析
km_fit <- survfit(surv_obj ~ data$'cluster')

# table(data$TYGCD4)

# 绘制KM曲线
flatui_colors <- c(
  "#34495E", "#2ECC71", "#E74C3C", "#3498DB", "#9B59B6", 
  "#F1C40F", "#1ABC9C", "#E67E22", "#95A5A6", "#D35400", 
  "#16A085", "#27AE60"
)
# # # 
# TyG:"#FC4E07", "#E69F00""TYG<9.22", "TYG≥9.22"
# CD4: "#270C01FF", "#3498DB" "CD4<50", "CD4≥50"
# # # 补充的新颜色 - 确保与已有颜色有足够区分度
# TYG-cd4   "#228B22","#FF00FF", "#FF0000", "#000000"
# # # title = "Overall Survival",

# "CD4≥50,TYG<9.22", "CD4≥50,TYG≥9.22","CD4<50,TYG<9.22", "CD4<50,TYG≥9.22"

#"Group 1" = "#f94040", "Group 2" = "#0000ff"

# 修改后的代码 - 更新图例标签
p <- ggsurvplot(
  km_fit, 
  data = data,
  pval = TRUE,
  pval.coord = c(0, 0.1),
  conf.int = FALSE,
  risk.table = TRUE,
  palette = c("#0000ff","#f94040"),  # 使用深蓝和深红
  legend = "none",  # 不在默认位置显示图例
  
  legend.labs = c( "cluster1", "cluster2"),  # 手动设置图例标签
  xlab = "Time (days)",
  ylab = "Survival Probability",
  xlim = c(0,28),
  ylim = c(0, 1),
  size = 0.5,
  break.time.by = 7,
  tables.theme = theme(
    axis.title.y = element_blank(),
    axis.text.y = element_text(face = "bold", size = 10),
    panel.border = element_rect(colour = "black", fill = NA, size = 1)  # 风险表边框
  ),
  risk.table.title = "Number at risk",
  risk.table.y.text = TRUE,
  risk.table.fontsize = 4,  # 增大风险表字体
  ggtheme = theme_bw()  # 使用有边框的主题
)

# 使用ggplot2函数手动添加图例到右下角
p$plot <- p$plot +
  theme(legend.position = c(1, 0),  # 调整图例位置到更合适的地方
        legend.justification = c(1, 0),    # 对齐到右下角
        legend.title = element_blank(),    # 保留图例标题
        legend.text = element_text(size = 9),
        legend.background = element_blank(), # 透明背景
        legend.key = element_blank()) 

# 给主图添加边框并去除网格线
p$plot <- p$plot + 
  theme(
    panel.border = element_rect(color = "black", fill = NA, size = 0.5),
    panel.grid.major = element_blank(),  # 移除主要网格线
    panel.grid.minor = element_blank(),  # 移除次要网格线
    text = element_text(family = "Times New Roman", size = 11)  # 设置统一字体
  )

# 调整风险表字体
p$table <- p$table + 
  theme(text = element_text(family = "Times New Roman", size = 9))

# # 加粗生存曲线线条
# p$plot$layers[[1]]$aes_params$size <- 1 # 加粗主要生存曲线



# 组合并打印图形
print(p)

# 保存高质量图像















# 
# 
# 
# ggsurvplot(
#   km_fit, 
#   data = data,
#   pval = TRUE, # 显示p值
#   conf.int = FALSE, # 显示置信区间
#   risk.table = F, # 显示风险表
#   palette = c( "#FC4E07", "#E69F00","#009E73"), # 自定义颜色
#   legend.title = "Quartile", # 图例标题
#   legend.labs = unique(data$TyGbmi3), # 使用分层名作为图例标签
#   xlab = "Survival Time",
#   ylab = "Survival Probability (%)",
#   title = "Overall Survival",
#   xlim = c(0, 90),
#   ylim = c(0, 1), # 设置 y 轴坐标
#   break.time.by = 7, # x轴的坐标轴设为7为一个间距
#   
# )
# 
# 
# # 计算四个TyG组之间的两两比较的p值
# pairwise_pvals <- pairwise_survdiff(Surv(year1_los, year1_outcome) ~ tyg_group, data = data)
# 
# # 提取和输出p值
# pairwise_pvals
# 
# 
# # 提取p值并格式化输出
# pvals_matrix <- pairwise_pvals$p.value
# pvals_matrix <- as.data.frame(as.table(pvals_matrix))
# 
# # 打印p值矩阵
# print(pvals_matrix)
# 
# 
# 
# 
# 
# 
# 





























