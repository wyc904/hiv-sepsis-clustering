# ============================================================
# packages.R — 安装本仓库所需的 R 包
#
# 用法（项目根目录）：
#   source("packages.R")
#
# 国内网络可先切换镜像：
#   options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))
#
# 开发环境：R 4.4.0（Windows 11）
# 注：括号内为开发时使用的版本，仅作可复现性参考。
# ============================================================

pkgs <- c(
  # ---- 数据处理 ----
  "dplyr",        # 1.2.0
  "tidyr",        # 1.3.2
  "tibble",       # 3.3.1
  "purrr",        # 1.2.1
  "readr",        # 2.2.0
  "lubridate",    # 1.9.5
  "tidyverse",    # 2.0.0
  # ---- Excel ----
  "readxl",       # 1.4.5
  "openxlsx",     # 4.2.8.1
  "writexl",      # 1.5.4
  # ---- 聚类 / 潜在类别 ----
  "mclust",       # 6.1.2
  "poLCA",        # 1.6.0.2
  "factoextra",   # 2.0.0
  "cluster",      # 2.1.8.2
  # ---- 统计与建模 ----
  "tableone",     # 0.13.2
  "pROC",         # 1.19.0.1
  "glmnet",       # 4.1.10
  "ResourceSelection", # 0.3.6
  "broom",        # 1.0.12
  "MASS",         # 7.3.65
  "psych",        # 2.6.3
  "survival",     # 3.8.6
  "survminer",    # 0.5.2
  # ---- 绘图 ----
  "ggplot2",      # 4.0.2
  "scales",       # 1.4.0
  "patchwork",    # 1.3.2
  "gridExtra",    # 2.3
  "ggtext",       # 0.1.2
  "ggsci",        # 4.2.0
  "ggradar",      # 0.2
  "pheatmap",     # 1.0.13
  "RColorBrewer", # 1.1.3
  "showtext",     # 0.9.8
  "forestplot",   # 3.2.0
  # ---- Shiny ----
  "shiny",        # 1.13.0
  "bslib",        # 0.10.0
  "shinydashboard",     # 0.7.3
  "shinydashboardPlus", # 2.0.6
  "plotly",       # 4.12.0
  "rsconnect"     # 1.7.0
)

to_install <- setdiff(pkgs, rownames(installed.packages()))
if (length(to_install)) {
  message("准备安装 ", length(to_install), " 个包：",
          paste(to_install, collapse = ", "))
  install.packages(to_install)
} else {
  message("所有依赖包均已安装。")
}

versions <- data.frame(
  package = pkgs,
  version = vapply(
    pkgs,
    function(p) tryCatch(as.character(packageVersion(p)), error = function(e) NA_character_),
    character(1)
  )
)
print(versions, row.names = FALSE)
