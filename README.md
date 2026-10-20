# HIV 相关脓毒症临床亚型聚类分析

**Clinical subphenotype clustering in HIV-associated sepsis**

本仓库收录该研究的全部分析代码：基于临床与实验室指标的高斯混合模型（GMM）聚类、
文献方法（潜在类别分析，LCA）对照、外部队列映射验证、亚型间统计比较、
LASSO / Logistic 预测模型、校准评价，以及论文用图与 Shiny 预测网页。

> [!IMPORTANT]
> **本仓库不包含任何原始数据或患者级数据。**
> `*.xlsx`、`*.csv`、`*.RData` 等均已被 `.gitignore` 屏蔽。
> 数据准备方式见 [`data/README.md`](data/README.md)。

---

## 研究概要

| 项目 | 内容 |
|---|---|
| 研究人群 | HIV 合并脓毒症的住院患者 |
| 推导队列 | MIMIC-IV 提取队列（约 1800 例；建模分析表 1690 例） |
| 外部验证 | 上海市第八人民医院（市八）队列（约 240 例） |
| 分型方法 | 高斯混合模型（GMM，`mclust`，2–5 类）；`poLCA` 潜在类别分析作方法学对照 |
| 输入变量 | 人口学、HIV 相关指标（CD4、病毒载量）、合并症指数、肝肾功能、凝血、乳酸、炎症指标等 |
| 亚型命名 | **Subtype 1 — Immunosuppression-OI**（免疫抑制 / 机会性感染型）<br>**Subtype 2 — Sepsis-MOF**（脓毒症多器官衰竭型） |
| 预测模型 | LASSO → Logistic 回归 → 约登指数 cutoff → Shiny 网页计算器 |

---

## 仓库内容

- **57 个 R 脚本**，按分析阶段分为 5 个模块，保留原始中文文件名与编号
- 覆盖从聚类、验证、统计、建模到出图的完整链路
- 绘图脚本内置已汇总的 OR / 率 / p 值，**不含患者级数据**，可单独运行复现图形版式
- 全部脚本通过 R 4.4.0 `parse()` 语法检查
- 部署脚本中的 shinyapps.io 凭据已移除，改用环境变量

---

## 目录结构

```
hiv-sepsis-clustering/
├── README.md
├── packages.R                  # 依赖包安装与版本清单
├── data/
│   └── README.md               # 数据放置说明（不含数据）
├── docs/
│   ├── pipeline.md             # 分析流程与运行顺序
│   ├── code-index.md           # 57 个脚本索引（作用 / 类型 / 输入输出）
│   ├── input-output.md         # 每个脚本的输入 / 输出文件清单
│   └── variable-dictionary.md  # 变量字典
└── scripts/
    ├── 1-clustering/           # GMM 聚类、LCA 对照、外部验证
    ├── 2-statistics/           # 组间比较、差异变量、校准、缺失统计
    ├── 3-prediction/           # LASSO / Logistic / 约登指数
    ├── 4-figures/              # 森林图、雷达图、KM、热图、饼图等
    └── 5-shiny-app/            # 预测网页与部署脚本
```

---

## 快速开始

### 1. 环境

- R ≥ 4.4.0（开发环境 R 4.4.0，Windows 11）
- 依赖包见 [`packages.R`](packages.R)

```r
source("packages.R")
```

国内网络可先切换镜像：

```r
options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))
```

### 2. 准备数据

将输入表放入同一目录，并设置环境变量：

```r
Sys.setenv(SEPSIS_DATA_DIR = "D:/sepsis-data")
```

未设置时脚本默认使用 `D:/Desktop`。文件清单见
[`data/README.md`](data/README.md)。

### 3. 运行

在 RStudio 中打开项目，按 [`docs/pipeline.md`](docs/pipeline.md) 的顺序运行；
或直接 `source()` 单个脚本。脚本开头的

```r
setwd(Sys.getenv("SEPSIS_DATA_DIR", unset = "D:/Desktop"))
```

会把工作目录切到数据目录，**所有相对路径的输出也写回该目录**（已被 `.gitignore` 屏蔽）。

---

## 分析流程

| 阶段 | 目录 | 主要内容 | 建议入口 |
|---|---|---|---|
| 1 | `scripts/1-clustering/` | GMM 聚类（2–5 类）、BIC/AIC 选择、TableOne、LCA 对照、外部队列映射 | `1-LCP.R` → `3-外部验证.R` |
| 2 | `scripts/2-statistics/` | 组间两两比较、差异变量、校准曲线、H–L 检验、缺失统计 | `4-挑选最有差异变量.R`、`4-校准图形绘制.R` |
| 3 | `scripts/3-prediction/` | LASSO 稳定性分析、Logistic 系数、约登 cutoff、外部分组 | `3-lasso-log-cutoff1.R` → `6-校准调整后/` |
| 4 | `scripts/4-figures/` | 森林图、雷达图、KM、细胞因子热图、饼图、差异曲线 | 按图选择 |
| 5 | `scripts/5-shiny-app/` | 交互式亚型概率预测网页 | `网页预测-交互页面-终.R` |

完整的运行顺序、依赖关系与已知问题见
[`docs/pipeline.md`](docs/pipeline.md)。

---

## 主要图表

| 图 | 脚本 |
|---|---|
| GMM 模型 BIC 选择图 | `scripts/4-figures/0-绘制聚类统计图.R` |
| PCA 聚类散点图 | `scripts/4-figures/0-绘制聚类图.R` |
| 结局森林图（MIMIC / 市八） | `scripts/4-figures/1-森林图/2版/` |
| 倾向性评分五模型森林图 | `scripts/4-figures/1-森林图/7-森林图4-有p值.R` |
| 干预 / 药物森林图（市八） | `scripts/4-figures/1-森林图/市八/` |
| 雷达图（合并症、HIV 相关、疾病严重程度） | `scripts/4-figures/1-简化雷达图数据图例版.R` 等 |
| Kaplan–Meier 曲线 | `scripts/4-figures/3-KM.R` |
| 细胞因子热图 | `scripts/4-figures/21-细胞因子热图横置.R` |
| 结局饼图 | `scripts/4-figures/5-绘制饼图.R` |
| 变量差异曲线 | `scripts/4-figures/6-绘制差异曲线.R` |

---

## 文档索引

| 文档 | 内容 |
|---|---|
| [`docs/pipeline.md`](docs/pipeline.md) | 分阶段流程、脚本作用与运行顺序 |
| [`docs/code-index.md`](docs/code-index.md) | 57 个脚本的完整索引（作用 / 类型 / 读 / 写） |
| [`docs/input-output.md`](docs/input-output.md) | 输入 / 输出文件清单 |
| [`docs/variable-dictionary.md`](docs/variable-dictionary.md) | 聚类与建模变量说明 |
| [`data/README.md`](data/README.md) | 数据放置与隐私说明 |

---

## 已知问题与命名说明

脚本保留原始文件名以便与历史分析记录对应，其中几处命名与实际内容不一致：

- `scripts/1-clustering/1-LCP.R` **实际是 GMM 聚类**，不是 LCA；
- `scripts/4-figures/1-森林图/市八/肾素.R` **实际画的是肝素（Heparin）**；
- `scripts/4-figures/4-细胞因子热图.R` **实际是 TyG × CD4 死亡热图**，
  聚类主线的细胞因子热图是 `21-细胞因子热图横置.R`；
- `scripts/2-statistics/4-log.R` 存在未定义变量 `categorical_vars`，
  正式结果请使用 `3-prediction/2-逻辑回归系数生成.R`；
- `0-绘制聚类图.R`、`4-校准图形绘制两图放一起.R`、
  `1-简化/3-lasso-log-精简构建公式.R` 依赖上游脚本的内存对象，不能单独运行。

详见 [`docs/pipeline.md`](docs/pipeline.md) 与各脚本头部注释。

---

## 数据与伦理

- 原始数据、中间表、患者级信息**均未收录**，且被 `.gitignore` 屏蔽。
- 使用数据前需获得伦理委员会批准及数据使用授权。
- 部署脚本中的账号 / token / secret 已全部移除，请勿把真实凭据写回仓库。

## 使用许可

本仓库代码仅供学术研究与复现参考。未经作者许可，不得用于商业用途或二次发表。
