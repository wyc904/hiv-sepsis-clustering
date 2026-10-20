# 代码总索引

共 **57** 个 R 脚本，按分析阶段分为 5 个模块。
所有脚本均已通过 R 4.4.0 `parse()` 语法检查。

类型说明：

| 类型 | 含义 |
|---|---|
| 主线 | 当前分析流程使用的脚本 |
| 迭代 | 同一分析的不同版本 / 探索性草稿，保留以备追溯 |
| 工具 | 数据清洗、格式转换、部署等辅助脚本 |
| 依赖 | 需先运行上游脚本、复用其内存对象，不能单独运行 |

> 读取 / 输出由脚本中的字面量自动提取；通过变量拼接的路径不在表中。

## 01 聚类与外部验证

GMM 聚类、LCA 方法对照、外部队列映射。

| 脚本 | 作用 | 类型 | 读取 | 输出 |
|---|---|---|---|---|
| `scripts/1-clustering/1-LCP.R` | 主 GMM 聚类（2–5 类）+ BIC/AIC + TableOne + 导出 | 主线 | `7-1800-质控28天死亡分组.xlsx` | `Cluster_Selection_Criteria.xlsx`<br>`Clustered_Data_Results.xlsx` |
| `scripts/1-clustering/2--GMM所有连续变量.R` | 全连续变量 GMM 变体，导出聚类数据 | 迭代 | `7-1800-质控28天死亡分组.xlsx` | `Cluster_Selection_Criteria.xlsx`<br>`Clustered_Data.xlsx` |
| `scripts/1-clustering/1- GMM聚类.R` | 最早 GMM 原型（需内存 data） | 迭代 | — | `clustered_patient_data.csv` |
| `scripts/1-clustering/2-27-文献方法.R` | 文献方法：潜在类别分析（poLCA，1–5 类） | 主线 | `7-1800-质控28天死亡11.xlsx` | — |
| `scripts/1-clustering/2-27分文献/1-检验正态性.R` | Shapiro–Wilk 检验与 log / z-score 转换 | 工具 | `0211.xlsx` | `processed_data.xlsx` |
| `scripts/1-clustering/3-外部验证.R` | 推导队列 GMM 建模 + 外部队列映射验证 | 主线 | `7-1800-质控28天死亡分组.xlsx`<br>`240-1.xlsx` | `Cluster_Validation_Results.xlsx` |

## 02 统计与校准

组间比较、差异变量、校准曲线、H–L 检验、缺失统计。

| 脚本 | 作用 | 类型 | 读取 | 输出 |
|---|---|---|---|---|
| `scripts/2-statistics/1-组间两两比较.R` | 分类变量逐水平卡方 / Fisher 两两比较 | 主线 | `聚类结果.xlsx` | — |
| `scripts/2-statistics/2-提取文字.R` | 肝素医嘱文本清洗（旁支数据准备） | 工具 | `79w-肝素_20250918.xlsx` | `33w-肝素_20250918.xlsx`<br>`脓毒症肝素治疗数据.xlsx` |
| `scripts/2-statistics/4-log.R` | 多变量 Logistic（cluster 结局），含已知错误 | 迭代 | `1690.xlsx` | `Logistic_Model_Results.xlsx` |
| `scripts/2-statistics/4-挑选最有差异变量.R` | 标准化均值差 Top5 差异变量 | 主线 | `1690.xlsx` | `variable_discrimination_scores.csv`<br>`top5_discriminative_variables.csv` |
| `scripts/2-statistics/4-校准图形绘制.R` | 校准曲线、H–L、Brier、AUC、Platt 重校准 | 主线 | `1690.xlsx` | — |
| `scripts/2-statistics/4-校准图形绘制两图放一起.R` | 校准曲线 + H–L 组合图（依赖上游对象） | 依赖 | — | — |
| `scripts/2-statistics/5-Hosmer–Lemeshow校准统计分析.R` | Hosmer–Lemeshow 校准检验 | 主线 | `1665-风险分层1.xlsx` | — |
| `scripts/2-statistics/6-数据缺失统计.R` | 各变量缺失数与比例 | 工具 | `mimic-缺失.xlsx` | — |

## 03 预测建模

LASSO、Logistic 系数、约登 cutoff 与外部打分。

| 脚本 | 作用 | 类型 | 读取 | 输出 |
|---|---|---|---|---|
| `scripts/3-prediction/1-lasso-逻辑.R` | 死亡结局的 LASSO 稳定性分析（旁支） | 迭代 | `1690.xlsx` | `LASSO_Selected_Variables.csv`<br>`Variable_Selection_Frequency.csv`<br>`Lambda_Values.csv`<br>`All_Coefficients.csv`<br>`Lambda_Distribution.png`<br>`Variable_Selection_Frequency.png`<br>`Coefficient_Stability.png` |
| `scripts/3-prediction/1-简化/2-逻辑回归系数生成-简易模型.R` | 5 变量简化 Logistic | 迭代 | `1690.xlsx` | `Logistic_Model_Continuous_Results.xlsx` |
| `scripts/3-prediction/1-简化/3-lasso-log-精简构建公式.R` | LASSO 入选变量的 BIC 逐步回归（依赖上游） | 依赖 | — | `BIC_Logit_Results.csv` |
| `scripts/3-prediction/2-逻辑回归系数生成.R` | 全变量 Logistic 系数 / OR / 性能 | 主线 | `1690.xlsx` | `Logistic_Model_Results.xlsx` |
| `scripts/3-prediction/3-lasso-log-cutoff1.R` | 主建模：10 次 CV LASSO + Logistic + 约登 cutoff | 主线 | `1690.xlsx` | `LASSO_Selected_Variables.csv`<br>`Variable_Selection_Frequency.csv`<br>`Lambda_Values.csv`<br>`All_Coefficients.csv`<br>`Lambda_Distribution.png`<br>`Variable_Selection_Frequency.png`<br>`Coefficient_Stability.png`<br>`Regression_Results.xlsx`<br>`Risk_Scores.csv`<br>`项目摘要.xlsx` |
| `scripts/3-prediction/4-约登数筛选.R` | 旧公式外部分组 | 迭代 | `240-5.xlsx` | `240-6.xlsx` |
| `scripts/3-prediction/4-计算最大约登指数.R` | 旧公式约登 cutoff | 迭代 | `1690.xlsx`<br>`Logistic_Model_Results.xlsx` | `Logistic_Model_Results.xlsx`<br>`Logistic_约登指数.xlsx` |
| `scripts/3-prediction/6-校准调整后/4-约登数筛选.R` | 校准后公式外部分组 | 主线 | `sepsis指标检测数据(1).xlsx` | `240-11.xlsx` |
| `scripts/3-prediction/6-校准调整后/4-计算最大约登指数.R` | 校准后公式约登 cutoff | 主线 | `1690.xlsx`<br>`Logistic_Model_Results.xlsx` | `Logistic_Model_Results.xlsx`<br>`Logistic_约登指数.xlsx` |

## 04 绘图

森林图、雷达图、KM、热图、饼图、差异曲线。

| 脚本 | 作用 | 类型 | 读取 | 输出 |
|---|---|---|---|---|
| `scripts/4-figures/0-绘制聚类图.R` | PCA 聚类散点图（依赖 1-LCP 对象） | 依赖 | — | — |
| `scripts/4-figures/0-绘制聚类统计图.R` | GMM 模型 BIC 折线图（内置汇总数据） | 主线 | — | — |
| `scripts/4-figures/1-森林图/2版/1-正式版结局森林图-mimic.R` | MIMIC 结局森林图（正式版） | 主线 | — | — |
| `scripts/4-figures/1-森林图/2版/2-结局森林图-市八.R` | 市八结局森林图（正式版） | 主线 | — | — |
| `scripts/4-figures/1-森林图/2版/结局森林图.R` | 结局森林图初稿 | 迭代 | — | — |
| `scripts/4-figures/1-森林图/7-森林图1.R` | 倾向性评分五模型森林图 v1 | 迭代 | — | — |
| `scripts/4-figures/1-森林图/7-森林图2.R` | 倾向性评分五模型森林图 v2（字体 / 间距） | 迭代 | — | — |
| `scripts/4-figures/1-森林图/7-森林图3.R` | 倾向性评分五模型森林图 v3（分组 / 分隔线） | 迭代 | — | — |
| `scripts/4-figures/1-森林图/7-森林图4-有p值.R` | 倾向性评分五模型森林图 v4（最终通用版） | 迭代 | — | — |
| `scripts/4-figures/1-森林图/市八/ART.R` | 市八 ART 森林图 | 主线 | — | — |
| `scripts/4-figures/1-森林图/市八/IMV.R` | 市八 IMV 森林图 | 主线 | — | `IMVzong_ForestPlot.tiff` |
| `scripts/4-figures/1-森林图/市八/糖皮质激素.R` | 市八糖皮质激素森林图 | 主线 | — | `Glucocorticoid_ForestPlot.tiff` |
| `scripts/4-figures/1-森林图/市八/肾素.R` | 市八肝素森林图（文件名误写为肾素） | 主线 | — | — |
| `scripts/4-figures/1-森林图/市八/血管活性药物.R` | 市八血管活性药物森林图 | 主线 | — | — |
| `scripts/4-figures/1-简化双雷达图.R` | 双组雷达图前身 | 迭代 | — | — |
| `scripts/4-figures/1-简化雷达图-显著性版.R` | 雷达图 + p 值星号变体 | 迭代 | — | — |
| `scripts/4-figures/1-简化雷达图.R` | 单组雷达图 | 迭代 | — | — |
| `scripts/4-figures/1-简化雷达图数据储存.R` | 多套雷达图数值草稿 | 工具 | — | — |
| `scripts/4-figures/1-简化雷达图数据图例版.R` | 最终双组雷达图 + 手工图例 | 主线 | — | — |
| `scripts/4-figures/1-雷达图.R` | ggradar 合并症雷达图初版 | 迭代 | — | — |
| `scripts/4-figures/1-雷达图hiv相关.R` | ggradar HIV 相关指标初版 | 迭代 | — | — |
| `scripts/4-figures/1-雷达图疾病严重程度.R` | ggradar 疾病严重程度初版 | 迭代 | — | — |
| `scripts/4-figures/2-柱状图.R` | CD4 / 病毒载量分层柱状图 | 主线 | — | — |
| `scripts/4-figures/3-KM.R` | 28 天 KM 生存曲线 + 风险表 | 主线 | `1690.xlsx` | — |
| `scripts/4-figures/4-细胞因子热图.R` | TyG × CD4 死亡热图（旁支） | 迭代 | `1-188-聚类细胞因子-初次合并未处理.xlsx` | `tyg_cd4_heatmap.png`<br>`tyg_cd4_heatmap.pdf`<br>`tyg_cd4_heatmap_data.csv` |
| `scripts/4-figures/21-细胞因子热图横置.R` | 细胞因子热图（聚类主线） | 主线 | `1-188-聚类细胞因子-初次合并未处理.xlsx` | — |
| `scripts/4-figures/5-绘制饼图.R` | 两 cluster 结局饼图 | 主线 | `0211.xlsx` | — |
| `scripts/4-figures/6-绘制差异曲线.R` | 镜像 z-score 差异曲线 | 主线 | `1690.xlsx` | — |

## 05 Shiny 预测网页

交互式亚型概率预测页面与部署脚本。

| 脚本 | 作用 | 类型 | 读取 | 输出 |
|---|---|---|---|---|
| `scripts/5-shiny-app/网页预测.R` | 最老 Shiny 原型（占位模型） | 迭代 | — | — |
| `scripts/5-shiny-app/网页预测-交互页面.R` | 旧版 shinydashboard 页面 | 迭代 | — | — |
| `scripts/5-shiny-app/网页预测-交互页面-终.R` | 最终交互页面（概率条 + 贡献图） | 主线 | — | — |
| `scripts/5-shiny-app/网页预测-及时生成gpt.R` | GPT 生成的 UI 变体 | 迭代 | — | — |
| `scripts/5-shiny-app/网页预测-及时生成元宝.R` | 功能最全的 UI 变体 | 迭代 | — | — |
| `scripts/5-shiny-app/网页预测-部署-终.R` | rsconnect 部署脚本（凭据已移除） | 工具 | — | — |
