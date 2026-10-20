# 数据目录说明

**本仓库不包含任何原始数据或患者级数据。** 所有 `*.xlsx`、`*.csv`、`*.RData`
均已被 `.gitignore` 排除。

## 本地复现

把所有输入表放在**同一个目录**，然后设置环境变量指向该目录：

```powershell
# Windows PowerShell
$env:SEPSIS_DATA_DIR = "D:/sepsis-data"
```

```bash
# macOS / Linux
export SEPSIS_DATA_DIR=/path/to/sepsis-data
```

脚本开头的写法为：

```r
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
```

未设置环境变量时沿用原分析环境的 `D:/Desktop`。

## 预期输入文件

| 文件 | 用途 | 使用脚本 |
|---|---|---|
| `7-1800-质控28天死亡分组.xlsx` | 推导队列（含 28 天死亡分组与聚类变量） | `01_聚类分析/01_主分析/1-LCP.R`、`01_聚类分析/04_迭代版本/2--GMM所有连续变量.R`、`01_聚类分析/03_外部验证/3-外部验证.R` |
| `7-1800-质控28天死亡11.xlsx` | 推导队列（文献 LCA 方法） | `01_聚类分析/02_方法学对照/2-27-文献方法.R` |
| `240-1.xlsx` | 外部队列（市八） | `01_聚类分析/03_外部验证/3-外部验证.R` |
| `1690.xlsx` | 建模 / 统计分析主表 | `02_统计与校准/`、`03_预测建模/` |
| `聚类结果.xlsx` | 带聚类标签的数据 | `02_统计与校准/01_组间比较/1-组间两两比较.R` |
| `1-188-聚类细胞因子-初次合并未处理.xlsx` | 细胞因子数据 | `04_图表/05_热图/21-细胞因子热图横置.R`、`04_图表/05_热图/4-细胞因子热图.R` |
| `0211.xlsx` | 结局构成 / 正态性检验 | `04_图表/06_构成与差异图/5-绘制饼图.R`、`01_聚类分析/02_方法学对照/1-检验正态性.R` |
| `1665-风险分层1.xlsx` | 风险分层数据 | `02_统计与校准/02_校准评价/5-Hosmer–Lemeshow校准统计分析.R` |
| `mimic-缺失.xlsx` | 缺失情况数据 | `02_统计与校准/03_数据准备/6-数据缺失统计.R` |
| `79w-肝素_20250918.xlsx` | 肝素医嘱原始表 | `02_统计与校准/03_数据准备/2-提取文字.R` |
| `240-5.xlsx` | 旧公式外部打分 | `03_预测建模/04_迭代版本/4-约登数筛选（旧公式）.R` |
| `sepsis指标检测数据(1).xlsx` | 校准后公式外部打分 | `03_预测建模/02_阈值与外部打分/4-约登数筛选（校准后）.R` |

## 中间文件

脚本之间通过同一目录下的中间文件衔接，常见的有：

- `Cluster_Selection_Criteria.xlsx`、`Clustered_Data_Results.xlsx`
- `Cluster_Validation_Results.xlsx`
- `Logistic_Model_Results.xlsx`、`Logistic_约登指数.xlsx`
- `Regression_Results.xlsx`、`Risk_Scores.csv`
- `240-6.xlsx`、`240-11.xlsx`
- `Missing_Data_Report.xlsx`、`model_performance_summary.xlsx`

这些文件由脚本生成，同样不入库。完整清单见
[`docs/input-output.md`](../docs/input-output.md)。

## 隐私说明

- 原始数据涉及患者临床信息，须在伦理批准与数据使用授权范围内使用。
- 不得将任何原始表、中间表或可识别信息上传至公共平台。
- 仓库中只保留分析代码；绘图脚本内置的是已汇总的 OR / 率 / p 值，
  不含患者级记录。
