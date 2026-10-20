# 脚本输入 / 输出文件清单

> 由脚本中的 `read_excel()` / `write.xlsx()` / `write_csv()` / `ggsave()`
> / `saveWorkbook()` 字面量自动提取。通过变量拼接路径、`list.files()`
> 批量读取的文件不会出现在表中。

所有路径均相对于 `SEPSIS_DATA_DIR`（默认 `D:/Desktop`）。

## 01_聚类分析 · 聚类与外部验证

### 01_主分析

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/01_聚类分析/01_主分析/1-LCP.R` | `7-1800-质控28天死亡分组.xlsx` | `Cluster_Selection_Criteria.xlsx`<br>`Clustered_Data_Results.xlsx` |

### 02_方法学对照

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/01_聚类分析/02_方法学对照/2-27-文献方法.R` | `7-1800-质控28天死亡11.xlsx` | — |
| `scripts/01_聚类分析/02_方法学对照/1-检验正态性.R` | `0211.xlsx` | `processed_data.xlsx` |

### 03_外部验证

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/01_聚类分析/03_外部验证/3-外部验证.R` | `7-1800-质控28天死亡分组.xlsx`<br>`240-1.xlsx` | `Cluster_Validation_Results.xlsx` |

### 04_迭代版本

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/01_聚类分析/04_迭代版本/2--GMM所有连续变量.R` | `7-1800-质控28天死亡分组.xlsx` | `Cluster_Selection_Criteria.xlsx`<br>`Clustered_Data.xlsx` |
| `scripts/01_聚类分析/04_迭代版本/1- GMM聚类.R` | — | `clustered_patient_data.csv` |

## 02_统计与校准 · 统计与校准

### 01_组间比较

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/02_统计与校准/01_组间比较/1-组间两两比较.R` | `聚类结果.xlsx` | — |
| `scripts/02_统计与校准/01_组间比较/4-挑选最有差异变量.R` | `1690.xlsx` | `variable_discrimination_scores.csv`<br>`top5_discriminative_variables.csv` |

### 02_校准评价

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/02_统计与校准/02_校准评价/4-校准图形绘制.R` | `1690.xlsx` | — |
| `scripts/02_统计与校准/02_校准评价/4-校准图形绘制两图放一起.R` | — | — |
| `scripts/02_统计与校准/02_校准评价/5-Hosmer–Lemeshow校准统计分析.R` | `1665-风险分层1.xlsx` | — |

### 03_数据准备

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/02_统计与校准/03_数据准备/2-提取文字.R` | `79w-肝素_20250918.xlsx` | `33w-肝素_20250918.xlsx`<br>`脓毒症肝素治疗数据.xlsx` |
| `scripts/02_统计与校准/03_数据准备/6-数据缺失统计.R` | `mimic-缺失.xlsx` | — |

### 04_迭代版本

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/02_统计与校准/04_迭代版本/4-log.R` | `1690.xlsx` | `Logistic_Model_Results.xlsx` |

## 03_预测建模 · 预测建模

### 01_主模型

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/03_预测建模/01_主模型/2-逻辑回归系数生成.R` | `1690.xlsx` | `Logistic_Model_Results.xlsx` |
| `scripts/03_预测建模/01_主模型/3-lasso-log-cutoff1.R` | `1690.xlsx` | `LASSO_Selected_Variables.csv`<br>`Variable_Selection_Frequency.csv`<br>`Lambda_Values.csv`<br>`All_Coefficients.csv`<br>`Lambda_Distribution.png`<br>`Variable_Selection_Frequency.png`<br>`Coefficient_Stability.png`<br>`Regression_Results.xlsx`<br>`Risk_Scores.csv`<br>`项目摘要.xlsx` |

### 02_阈值与外部打分

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/03_预测建模/02_阈值与外部打分/4-约登数筛选（校准后）.R` | `sepsis指标检测数据(1).xlsx` | `240-11.xlsx` |
| `scripts/03_预测建模/02_阈值与外部打分/4-计算最大约登指数（校准后）.R` | `1690.xlsx`<br>`Logistic_Model_Results.xlsx` | `Logistic_Model_Results.xlsx`<br>`Logistic_约登指数.xlsx` |

### 03_简化模型

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/03_预测建模/03_简化模型/2-逻辑回归系数生成-简易模型.R` | `1690.xlsx` | `Logistic_Model_Continuous_Results.xlsx` |
| `scripts/03_预测建模/03_简化模型/3-lasso-log-精简构建公式.R` | — | `BIC_Logit_Results.csv` |

### 04_迭代版本

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/03_预测建模/04_迭代版本/1-lasso-逻辑.R` | `1690.xlsx` | `LASSO_Selected_Variables.csv`<br>`Variable_Selection_Frequency.csv`<br>`Lambda_Values.csv`<br>`All_Coefficients.csv`<br>`Lambda_Distribution.png`<br>`Variable_Selection_Frequency.png`<br>`Coefficient_Stability.png` |
| `scripts/03_预测建模/04_迭代版本/4-约登数筛选（旧公式）.R` | `240-5.xlsx` | `240-6.xlsx` |
| `scripts/03_预测建模/04_迭代版本/4-计算最大约登指数（旧公式）.R` | `1690.xlsx`<br>`Logistic_Model_Results.xlsx` | `Logistic_Model_Results.xlsx`<br>`Logistic_约登指数.xlsx` |

## 04_图表 · 论文图表

### 01_聚类图

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/04_图表/01_聚类图/0-绘制聚类图.R` | — | — |
| `scripts/04_图表/01_聚类图/0-绘制聚类统计图.R` | — | — |

### 02_森林图

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/04_图表/02_森林图/01_结局森林图/1-正式版结局森林图-mimic.R` | — | — |
| `scripts/04_图表/02_森林图/01_结局森林图/2-结局森林图-市八.R` | — | — |
| `scripts/04_图表/02_森林图/01_结局森林图/结局森林图.R` | — | — |
| `scripts/04_图表/02_森林图/02_倾向性评分/7-森林图1.R` | — | — |
| `scripts/04_图表/02_森林图/02_倾向性评分/7-森林图2.R` | — | — |
| `scripts/04_图表/02_森林图/02_倾向性评分/7-森林图3.R` | — | — |
| `scripts/04_图表/02_森林图/02_倾向性评分/7-森林图4-有p值.R` | — | — |
| `scripts/04_图表/02_森林图/03_市八干预与药物/ART.R` | — | — |
| `scripts/04_图表/02_森林图/03_市八干预与药物/IMV.R` | — | `IMVzong_ForestPlot.tiff` |
| `scripts/04_图表/02_森林图/03_市八干预与药物/糖皮质激素.R` | — | `Glucocorticoid_ForestPlot.tiff` |
| `scripts/04_图表/02_森林图/03_市八干预与药物/肾素.R` | — | — |
| `scripts/04_图表/02_森林图/03_市八干预与药物/血管活性药物.R` | — | — |

### 03_雷达图

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/04_图表/03_雷达图/1-简化双雷达图.R` | — | — |
| `scripts/04_图表/03_雷达图/1-简化雷达图-显著性版.R` | — | — |
| `scripts/04_图表/03_雷达图/1-简化雷达图.R` | — | — |
| `scripts/04_图表/03_雷达图/1-简化雷达图数据储存.R` | — | — |
| `scripts/04_图表/03_雷达图/1-简化雷达图数据图例版.R` | — | — |
| `scripts/04_图表/03_雷达图/1-雷达图.R` | — | — |
| `scripts/04_图表/03_雷达图/1-雷达图hiv相关.R` | — | — |
| `scripts/04_图表/03_雷达图/1-雷达图疾病严重程度.R` | — | — |

### 04_生存曲线

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/04_图表/04_生存曲线/3-KM.R` | `1690.xlsx` | — |

### 05_热图

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/04_图表/05_热图/4-细胞因子热图.R` | `1-188-聚类细胞因子-初次合并未处理.xlsx` | `tyg_cd4_heatmap.png`<br>`tyg_cd4_heatmap.pdf`<br>`tyg_cd4_heatmap_data.csv` |
| `scripts/04_图表/05_热图/21-细胞因子热图横置.R` | `1-188-聚类细胞因子-初次合并未处理.xlsx` | — |

### 06_构成与差异图

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/04_图表/06_构成与差异图/2-柱状图.R` | — | — |
| `scripts/04_图表/06_构成与差异图/5-绘制饼图.R` | `0211.xlsx` | — |
| `scripts/04_图表/06_构成与差异图/6-绘制差异曲线.R` | `1690.xlsx` | — |

## 05_网页应用 · Shiny 应用

### 01_最终版

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/05_网页应用/01_最终版/网页预测-交互页面-终.R` | — | — |

### 02_其他版本

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/05_网页应用/02_其他版本/网页预测.R` | — | — |
| `scripts/05_网页应用/02_其他版本/网页预测-交互页面.R` | — | — |
| `scripts/05_网页应用/02_其他版本/网页预测-及时生成gpt.R` | — | — |
| `scripts/05_网页应用/02_其他版本/网页预测-及时生成元宝.R` | — | — |

### 部署脚本

| 脚本 | 读取 | 输出 |
|---|---|---|
| `scripts/05_网页应用/网页预测-部署-终.R` | — | — |
