# 整理说明

本仓库由本地分析工程 `G:\1-Project\0-script\2-脓毒症聚类分析` 整理而来，
只保留代码与文档。

## 1. 未收录的内容

| 内容 | 处理 |
|---|---|
| `*.xlsx` / `*.xls` / `*.csv` / `*.RData` / `*.rds` | 未复制，`.gitignore` 已屏蔽 |
| 绘图输出（PNG / PDF / TIFF） | 未复制；脚本中的 `ggsave()` 多数被注释 |
| `.Rhistory` | 未复制 |
| shinyapps.io 账号 / token / secret | 已从部署脚本中删除 |

## 2. 目录调整

原始工程的顶层目录与新仓库的对应关系：

| 原始位置 | 新位置 |
|---|---|
| `1-LCP.R`、`1- GMM聚类.R` 等根级聚类脚本 | `scripts/1-clustering/` |
| `2-27分文献/` | `scripts/1-clustering/2-27分文献/` |
| `3-统计/` | `scripts/2-statistics/`（部分脚本保留原编号） |
| `4-log.R`、`4-挑选最有差异变量.R` | `scripts/2-statistics/` |
| `4-网页预测/`（建模部分） | `scripts/3-prediction/` |
| `4-网页预测/1-简化/`、`6-校准调整后/` | `scripts/3-prediction/` 对应子目录 |
| `1-绘图/` | `scripts/4-figures/` |
| `4-网页预测/网页预测*.R` | `scripts/5-shiny-app/` |

脚本文件名、中文注释与原始编号保持不变，便于与原始分析记录对应。

## 3. 代码改动

### 3.1 数据目录可配置（57 处）

原始脚本中的：

```r
setwd("D:/Desktop")     # 或 setwd("D:/Desktop/")
```

统一替换为：

```r
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
```

未设置环境变量时行为与原来一致；设置后可在其他机器上复现。
绝对输出路径 `D:/Desktop/model_performance_summary.xlsx` 改为相对路径。

### 3.2 凭据脱敏

`scripts/5-shiny-app/网页预测-部署-终.R` 中原有的 shinyapps.io 账号、token、secret
已全部删除，改为从环境变量读取：

- `SHINYAPPS_NAME`
- `SHINYAPPS_TOKEN`
- `SHINYAPPS_SECRET`

`appDir` 改为仓库内相对路径 `scripts/5-shiny-app`。

### 3.3 缺失依赖

以下两个脚本调用 `write.xlsx()` 但未加载 `openxlsx`，已补 `library(openxlsx)`：

- `scripts/2-statistics/1-组间两两比较.R`
- `scripts/2-statistics/4-校准图形绘制.R`

整理后 57 个脚本全部通过 R 4.4.0 `parse()` 检查。

## 4. 未改动的逻辑问题

以下问题保留原样，仅在 [`pipeline.md`](pipeline.md) 中标注：

- `1-clustering/1-LCP.R` 文件名含 LCP，实际是 GMM；
- `4-figures/1-森林图/市八/肾素.R` 实际是肝素森林图；
- `4-figures/4-细胞因子热图.R` 实际是 TyG × CD4 热图；
- `2-statistics/4-log.R` 存在未定义变量 `categorical_vars`；
- 三个脚本依赖上游脚本的内存对象，不能单独运行。
