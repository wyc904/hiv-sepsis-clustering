# ============================================================
# Shiny 应用部署脚本（shinyapps.io）
# ------------------------------------------------------------
# 原脚本中的账号 / token / secret 已全部移除，请勿把真实凭据写回仓库。
#
# 首次使用前设置环境变量（或写入 ~/.Renviron）：
#   SHINYAPPS_NAME
#   SHINYAPPS_TOKEN
#   SHINYAPPS_SECRET
#
# 在项目根目录运行：
#   Rscript scripts/05_网页应用/网页预测-部署-终.R
# ============================================================

library(rsconnect)

app_dir <- file.path("scripts", "05_网页应用", "01_最终版")
if (!file.exists(file.path(app_dir, "网页预测-交互页面-终.R"))) {
  stop("请在仓库根目录运行本脚本。")
}

name   <- Sys.getenv("SHINYAPPS_NAME")
token  <- Sys.getenv("SHINYAPPS_TOKEN")
secret <- Sys.getenv("SHINYAPPS_SECRET")

if (!nzchar(name) || !nzchar(token) || !nzchar(secret)) {
  stop(
    "缺少 shinyapps.io 凭据。请先设置环境变量：\n",
    "  SHINYAPPS_NAME / SHINYAPPS_TOKEN / SHINYAPPS_SECRET"
  )
}

rsconnect::setAccountInfo(name = name, token = token, secret = secret)
rsconnect::deployApp(
  appDir       = app_dir,
  appPrimaryDoc = "网页预测-交互页面-终.R",
  appName      = "Subphenotypes"
)
