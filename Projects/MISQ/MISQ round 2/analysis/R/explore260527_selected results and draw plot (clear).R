##############################################
######## 260527 Setup 1 + AISimWithOpus47_fillna
##############################################
m1_felm_int <- felm(log_answer_que_within7day ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
mydata_survival$surv_human_answer <- with(mydata_survival, Surv(wait1Resp_surv, human_answer_event))
m1_cox_int <- coxph(surv_human_answer ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)+ strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
summary(m1_felm_int)

##############################################
######## 260527 Setup 2 + AISimWithOpus47_fillna
##############################################
m2_felm_int <- felm(log_answer_que_within7day_other ~ treatment+treatment*(log_textLengthCN1Ans + SimWithOpus1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
m2_cox_int <- coxph(surv_second_answer ~ treatment+treatment*(log_textLengthCN1Ans + SimWithOpus1Ans)+ strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
m2_felm_sim_int <- felm (ans1_ans2_similarity ~ treatment+treatment*(log_textLengthCN1Ans + SimWithOpus1Ans )
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)

# 统计treatment的mean和std
mean(mydata_AI$treatment)
sd(mydata_AI$treatment)

mean(mydata_AI$log_textLengthCN1Ans, na.rm = TRUE)
sd(mydata_AI$log_textLengthCN1Ans, na.rm = TRUE)
mean(mydata_AI$SimWithOpus1Ans, na.rm = TRUE)
sd(mydata_AI$SimWithOpus1Ans, na.rm = TRUE)

summary(mydata_AI$AISimWithOpus47_fillna)
sd(mydata_AI$AISimWithOpus47_fillna, na.rm = TRUE)

summary(mydata_survival$surv_human_answer)
sd(mydata_survival$surv_human_answer, na.rm = TRUE)


treatment
- mean: 0.4887905
- std: 0.4999435

log_textLengthCNAI_fillna
- mean:2.77437
- std:2.86413

AISimWithOpus47_fillna
- mean: 0.2707
- std: 0.2972415


> mean(mydata_AI$log_textLengthCN1Ans, na.rm = TRUE)

mydata_AI_isAI <- mydata_AI %>% filter(treatment == 1)
mydata_AI_isNOTAI <- mydata_AI %>% filter(treatment == 0)
mean(mydata_AI_isAI$textLengthCN1Ans, na.rm = TRUE)
sd(mydata_AI_isAI$log_textLengthCN1Ans, na.rm = TRUE)
mean(mydata_AI_isNOTAI$textLengthCN1Ans, na.rm = TRUE)
sd(mydata_AI_isNOTAI$log_textLengthCN1Ans, na.rm = TRUE)


mean(mydata_AI_isAI$SimWithOpus1Ans, na.rm = TRUE)
sd(mydata_AI_isAI$SimWithOpus1Ans, na.rm = TRUE)
mean(mydata_AI_isNOTAI$SimWithOpus1Ans, na.rm = TRUE)
sd(mydata_AI_isNOTAI$SimWithOpus1Ans, na.rm = TRUE)


[1] 4.662178
> sd(mydata_AI$log_textLengthCN1Ans, na.rm = TRUE)
[1] 1.488808
> mean(mydata_AI$SimWithOpus1Ans, na.rm = TRUE)
[1] 0.5062086
> sd(mydata_AI$SimWithOpus1Ans, na.rm = TRUE)
[1] 0.1771589


# ================================================================
# Marginal Prediction Plots — 5 Figures
# ================================================================
library(ggplot2)
library(dplyr)

# ----------------------------------------------------------------
# § 1. 工具函数
# ----------------------------------------------------------------

#' 从数据集提取模型协变量均值
#' 交互项（如 treatment:log_textLengthCNAI_fillna）不在数据列中，返回 NA
get_cov_means <- function(model, data) {
  cn <- names(coef(model))
  sapply(setNames(cn, cn), function(nm) {
    if (nm %in% names(data)) mean(data[[nm]], na.rm = TRUE) else NA_real_
  })
}

#' 构造预测行向量 L，与 coef(model) 严格对齐
#' Setup 1 模型无 len/opus 主效应，相关分支自动跳过
build_L <- function(model, cov_means, treatment_val,
                    len_val, opus_val, len_name, opus_name) {
  cn   <- names(coef(model))
  L    <- setNames(numeric(length(cn)), cn)
  # 1. 填入协变量均值（跳过 NA，即交互项）
  valid <- !is.na(cov_means[cn])
  L[cn[valid]] <- cov_means[cn[valid]]
  # 2. 覆盖 treatment
  if ("treatment" %in% cn)  L["treatment"] <- treatment_val
  # 3. 覆盖 length / Opus 主效应（Setup 2 模型有；Setup 1 无，条件为 FALSE）
  if (len_name  %in% cn)    L[len_name]    <- len_val
  if (opus_name %in% cn)    L[opus_name]   <- opus_val
  # 4. 覆盖交互项
  tl <- paste0("treatment:", len_name)
  to <- paste0("treatment:", opus_name)
  if (tl %in% cn) L[tl] <- treatment_val * len_val
  if (to %in% cn) L[to] <- treatment_val * opus_val
  L
}

#' felm 线性预测 + SE
#' vcov(model) 在 cluster = 0 时返回经典 OLS 协方差矩阵（非 robust）
lp_felm <- function(model, L_vec) {
  b   <- coef(model)
  V   <- vcov(model)
  L   <- matrix(L_vec[names(b)], nrow = 1)
  pt  <- as.numeric(L %*% b)
  se  <- sqrt(pmax(as.numeric(L %*% V %*% t(L)), 0))
  c(point = pt, se = se)
}

#' coxph 预测 HR 及 95% CI，相对于参考点 L_ref
#' delta 法：HR = exp(delta %*% beta)，CI = exp(delta%*%beta ± 1.96*SE)
cox_hr <- function(model, L_vec, L_ref) {
  b     <- coef(model)
  V     <- vcov(model)
  delta <- matrix(L_vec[names(b)] - L_ref[names(b)], nrow = 1)
  diff  <- as.numeric(delta %*% b)
  se    <- sqrt(pmax(as.numeric(delta %*% V %*% t(delta)), 0))
  list(hr = exp(diff),
       lo = exp(diff - 1.96 * se),
       hi = exp(diff + 1.96 * se))
}

#' "high" / "low" / "mean" → 实际数值
resolve_z <- function(s, hi, lo, mu) {
  switch(s, high = hi, low = lo, mean = mu,
         stop(sprintf("resolve_z: '%s' 不合法，应为 'high'/'low'/'mean'", s)))
}

# ----------------------------------------------------------------
# § 2. 构建绘图数据框
# ----------------------------------------------------------------

build_felm_pdata <- function(model, data, pts,
                              len_name, opus_name,
                              zl_hi, zl_lo, zl_mu,
                              zo_hi, zo_lo, zo_mu) {
  cm <- get_cov_means(model, data)
  do.call(rbind, lapply(pts, function(p) {
    lv <- resolve_z(p$len_z,  zl_hi, zl_lo, zl_mu)
    ov <- resolve_z(p$opus_z, zo_hi, zo_lo, zo_mu)
    L  <- build_L(model, cm, p$tx, lv, ov, len_name, opus_name)
    ps <- lp_felm(model, L)
    data.frame(x = p$x, group = p$group,
               y    = ps["point"],
               ymin = ps["point"] - 1.96 * ps["se"],
               ymax = ps["point"] + 1.96 * ps["se"],
               stringsAsFactors = FALSE, row.names = NULL)
  }))
}

build_cox_pdata <- function(model, data, pts,
                             len_name, opus_name,
                             zl_hi, zl_lo, zl_mu,
                             zo_hi, zo_lo, zo_mu) {
  cm    <- get_cov_means(model, data)
  # 参考点：treatment = 0，len = mean，opus = mean
  L_ref <- build_L(model, cm, 0, zl_mu, zo_mu, len_name, opus_name)
  do.call(rbind, lapply(pts, function(p) {
    lv <- resolve_z(p$len_z,  zl_hi, zl_lo, zl_mu)
    ov <- resolve_z(p$opus_z, zo_hi, zo_lo, zo_mu)
    L  <- build_L(model, cm, p$tx, lv, ov, len_name, opus_name)
    hr <- cox_hr(model, L, L_ref)
    data.frame(x = p$x, group = p$group,
               y = hr$hr, ymin = hr$lo, ymax = hr$hi,
               stringsAsFactors = FALSE, row.names = NULL)
  }))
}

# ----------------------------------------------------------------
# § 3. ggplot 绘图模板
# ----------------------------------------------------------------

make_marg_plot <- function(pdata, title_str, ylab_str, hline_val = NA) {
  shape_vals <- c(
    baseline    = 1,
    length_low  = 2,
    length_high = 17,
    opus_low    = 0,
    opus_high   = 15
  )
  p <- ggplot(pdata, aes(x = x, y = y, shape = group)) +
    geom_errorbar(aes(ymin = ymin, ymax = ymax),
                  width = 0.025, linewidth = 0.45, color = "black") +
    geom_point(size = 3.2, color = "black") +
    scale_shape_manual(
      values = shape_vals,
      breaks = c("length_high", "length_low", "opus_high", "opus_low"),
      labels = c("high length", "low length", "high Opus", "low Opus")
    ) +
    scale_x_continuous(
      breaks = c(0, 1),
      labels = c("control", "treatment"),
      limits = c(-0.4, 1.4)
    ) +
    labs(title = title_str, x = NULL, y = ylab_str) +
    theme_classic() +
    theme(
      panel.grid           = element_blank(),
      axis.line            = element_line(color = "black", linewidth = 0.4),
      legend.position      = "bottom",          # ← 改这里
      legend.direction     = "horizontal",       # ← 加这里
      legend.title         = element_blank(),
      legend.background    = element_rect(fill = "white", color = "black",
                                          linewidth = 0.4),
      legend.key           = element_rect(fill = "white"),
      legend.text          = element_text(size = 8),
      plot.title           = element_text(size = 10, face = "bold"),
      axis.title.y         = element_text(size = 9),
      axis.text            = element_text(size = 9)
    ) +
    guides(shape = guide_legend(nrow = 1))       # ← 加这里：强制一行
  
  if (!is.na(hline_val))
    p <- p + geom_hline(yintercept = hline_val,
                        linetype = "dashed", color = "black", linewidth = 0.4)
  p
}

# ----------------------------------------------------------------
# § 4. 高/低分组取值
# ----------------------------------------------------------------

## —— Setup 1 ——
len1  <- "log_textLengthCNAI_fillna"
opus1 <- "AISimWithOpus47_fillna"

# 仅 treatment 组、非零样本（两个变量各自独立过滤）
d1l <- mydata_AI %>%
  filter(treatment == 1, .data[[len1]]  != 0, !is.na(.data[[len1]]))
d1o <- mydata_AI %>%
  filter(treatment == 1, .data[[opus1]] != 0, !is.na(.data[[opus1]]))

c1l <- mean(d1l[[len1]])
c1o <- mean(d1o[[opus1]])

z1 <- list(
  len_hi  = mean(d1l[[len1]][d1l[[len1]]   >  c1l]),
  len_lo  = mean(d1l[[len1]][d1l[[len1]]   <= c1l]),
  opus_hi = mean(d1o[[opus1]][d1o[[opus1]] >  c1o]),
  opus_lo = mean(d1o[[opus1]][d1o[[opus1]] <= c1o]),
  len_mu  = mean(mydata_AI[[len1]],  na.rm = TRUE),
  opus_mu = mean(mydata_AI[[opus1]], na.rm = TRUE)
)

## —— Setup 2 ——
len2  <- "log_textLengthCN1Ans"
opus2 <- "SimWithOpus1Ans"

# 全样本（含两组）非缺失子集；用 mydata_AI 定义分位点
d2l <- mydata_AI %>% filter(!is.na(.data[[len2]]))
d2o <- mydata_AI %>% filter(!is.na(.data[[opus2]]))

c2l <- mean(d2l[[len2]])
c2o <- mean(d2o[[opus2]])

z2 <- list(
  len_hi       = mean(d2l[[len2]][d2l[[len2]]   >  c2l]),
  len_lo       = mean(d2l[[len2]][d2l[[len2]]   <= c2l]),
  opus_hi      = mean(d2o[[opus2]][d2o[[opus2]] >  c2o]),
  opus_lo      = mean(d2o[[opus2]][d2o[[opus2]] <= c2o]),
  len_mu_AI    = mean(mydata_AI[[len2]],        na.rm = TRUE),
  opus_mu_AI   = mean(mydata_AI[[opus2]],       na.rm = TRUE),
  len_mu_surv  = mean(mydata_survival[[len2]],  na.rm = TRUE),
  opus_mu_surv = mean(mydata_survival[[opus2]], na.rm = TRUE)
)

## 打印确认（便于 debug）
cat("\n=== Setup 1 分组取值 ===\n")
cat(sprintf("  len:  mu=%7.4f  lo=%7.4f  hi=%7.4f\n",
            z1$len_mu,  z1$len_lo,  z1$len_hi))
cat(sprintf("  opus: mu=%7.4f  lo=%7.4f  hi=%7.4f\n",
            z1$opus_mu, z1$opus_lo, z1$opus_hi))
cat("=== Setup 2 分组取值（基于 mydata_AI）===\n")
cat(sprintf("  len:  mu=%7.4f  lo=%7.4f  hi=%7.4f\n",
            z2$len_mu_AI,  z2$len_lo,  z2$len_hi))
cat(sprintf("  opus: mu=%7.4f  lo=%7.4f  hi=%7.4f\n",
            z2$opus_mu_AI, z2$opus_lo, z2$opus_hi))

# ----------------------------------------------------------------
# § 5. 预测点坐标定义
# ----------------------------------------------------------------

# Setup 1：1 控制基准 + 4 处理侧
# x 偏移（处理侧中心=1）：-0.15, -0.05, +0.10, +0.20
s1_pts <- list(
  list(x = 0.00, group = "baseline",    tx = 0, len_z = "mean", opus_z = "mean"),
  list(x = 0.85, group = "length_low",  tx = 1, len_z = "low",  opus_z = "mean"),
  list(x = 0.95, group = "length_high", tx = 1, len_z = "high", opus_z = "mean"),
  list(x = 1.10, group = "opus_low",    tx = 1, len_z = "mean", opus_z = "low"),
  list(x = 1.20, group = "opus_high",   tx = 1, len_z = "mean", opus_z = "high")
)

# Setup 2：控制侧 4 点（中心=0）+ 处理侧 4 点（中心=1）
# 各自偏移：-0.15, -0.05, +0.10, +0.20
s2_pts <- list(
  # 控制侧
  list(x = -0.15, group = "length_low",  tx = 0, len_z = "low",  opus_z = "mean"),
  list(x = -0.05, group = "length_high", tx = 0, len_z = "high", opus_z = "mean"),
  list(x =  0.10, group = "opus_low",    tx = 0, len_z = "mean", opus_z = "low"),
  list(x =  0.20, group = "opus_high",   tx = 0, len_z = "mean", opus_z = "high"),
  # 处理侧
  list(x =  0.85, group = "length_low",  tx = 1, len_z = "low",  opus_z = "mean"),
  list(x =  0.95, group = "length_high", tx = 1, len_z = "high", opus_z = "mean"),
  list(x =  1.10, group = "opus_low",    tx = 1, len_z = "mean", opus_z = "low"),
  list(x =  1.20, group = "opus_high",   tx = 1, len_z = "mean", opus_z = "high")
)

# ----------------------------------------------------------------
# § 5.5  felm 偏移量工具函数
# ----------------------------------------------------------------

#' 计算偏移量 = mean(DV) − 中心点线性预测值
#' 中心点定义：treatment 取样本均值，len/opus 取各自均值
#' 目的：将去掉固定效应后的 L·β 还原到 DV 原始尺度
compute_felm_offset <- function(model, data, dv_name,
                                len_name, opus_name,
                                len_mu, opus_mu) {
  cm     <- get_cov_means(model, data)
  tx_mu  <- mean(data[["treatment"]], na.rm = TRUE)

  L_center <- build_L(model, cm,
                      treatment_val = tx_mu,
                      len_val       = len_mu,
                      opus_val      = opus_mu,
                      len_name, opus_name)

  pred_center <- lp_felm(model, L_center)["point"]
  y_bar       <- mean(data[[dv_name]], na.rm = TRUE)
  offset      <- y_bar - pred_center

  cat(sprintf(
    "  [offset] DV='%s'  mean(DV)=%.4f  pred_center=%.4f  offset=%.4f\n",
    dv_name, y_bar, pred_center, offset
  ))
  offset
}

#' 将偏移量统一加到 pdata 的三列
apply_offset <- function(pdata, offset) {
  pdata$y    <- pdata$y    + offset
  pdata$ymin <- pdata$ymin + offset
  pdata$ymax <- pdata$ymax + offset
  pdata
}

# ----------------------------------------------------------------
# § 6. 生成 5 张图（felm 图均加入固定效应偏移量）
# ----------------------------------------------------------------

## Figure 1：Setup 1 felm — log(# human answers)
pdata1 <- build_felm_pdata(
  m1_felm_int, mydata_AI, s1_pts, len1, opus1,
  z1$len_hi, z1$len_lo, z1$len_mu,
  z1$opus_hi, z1$opus_lo, z1$opus_mu
)
cat("Figure 1 offset:\n")
offset1 <- compute_felm_offset(
  m1_felm_int, mydata_AI,
  dv_name  = "log_answer_que_within7day",
  len_name = len1, opus_name = opus1,
  len_mu   = z1$len_mu, opus_mu = z1$opus_mu
)
pdata1 <- apply_offset(pdata1, offset1)

fig1 <- make_marg_plot(
  pdata1,
  title_str = "Setup 1: # human answers (log)",
  ylab_str  = "Predicted log(# human answers)"
)
ggsave("fig1_setup1_human_answer.png", fig1, width = 5, height = 4, dpi = 300)
cat("Figure 1 saved.\n")

## Figure 2：Setup 1 coxph — hazard of first human answer
## Cox 输出 HR，无需偏移
pdata2 <- build_cox_pdata(
  m1_cox_int, mydata_survival, s1_pts, len1, opus1,
  z1$len_hi, z1$len_lo, z1$len_mu,
  z1$opus_hi, z1$opus_lo, z1$opus_mu
)
fig2 <- make_marg_plot(
  pdata2,
  title_str = "Setup 1: hazard of first human answer",
  ylab_str  = "Predicted hazard ratio (vs. control mean)",
  hline_val = 1
)
ggsave("fig2_setup1_cox_human.png", fig2, width = 5, height = 4, dpi = 300)
cat("Figure 2 saved.\n")

## Figure 3：Setup 2 felm — log(# other answers)
pdata3 <- build_felm_pdata(
  m2_felm_int, mydata_AI, s2_pts, len2, opus2,
  z2$len_hi, z2$len_lo, z2$len_mu_AI,
  z2$opus_hi, z2$opus_lo, z2$opus_mu_AI
)
cat("Figure 3 offset:\n")
offset3 <- compute_felm_offset(
  m2_felm_int, mydata_AI,
  dv_name  = "log_answer_que_within7day_other",
  len_name = len2, opus_name = opus2,
  len_mu   = z2$len_mu_AI, opus_mu = z2$opus_mu_AI
)
pdata3 <- apply_offset(pdata3, offset3)

fig3 <- make_marg_plot(
  pdata3,
  title_str = "Setup 2: # other answers (log)",
  ylab_str  = "Predicted log(# other answers)"
)
ggsave("fig3_setup2_other_answer.png", fig3, width = 5, height = 4, dpi = 300)
cat("Figure 3 saved.\n")

## Figure 4：Setup 2 coxph — hazard of second answer
## Cox 输出 HR，无需偏移
pdata4 <- build_cox_pdata(
  m2_cox_int, mydata_survival, s2_pts, len2, opus2,
  z2$len_hi, z2$len_lo, z2$len_mu_surv,
  z2$opus_hi, z2$opus_lo, z2$opus_mu_surv
)
fig4 <- make_marg_plot(
  pdata4,
  title_str = "Setup 2: hazard of second answer",
  ylab_str  = "Predicted hazard ratio (vs. control mean)",
  hline_val = 1
)
ggsave("fig4_setup2_cox_second.png", fig4, width = 5, height = 4, dpi = 300)
cat("Figure 4 saved.\n")

## Figure 5：Setup 2 felm — ans1_ans2_similarity
pdata5 <- build_felm_pdata(
  m2_felm_sim_int, mydata_AI, s2_pts, len2, opus2,
  z2$len_hi, z2$len_lo, z2$len_mu_AI,
  z2$opus_hi, z2$opus_lo, z2$opus_mu_AI
)
cat("Figure 5 offset:\n")
offset5 <- compute_felm_offset(
  m2_felm_sim_int, mydata_AI,
  dv_name  = "ans1_ans2_similarity",
  len_name = len2, opus_name = opus2,
  len_mu   = z2$len_mu_AI, opus_mu = z2$opus_mu_AI
)
pdata5 <- apply_offset(pdata5, offset5)

fig5 <- make_marg_plot(
  pdata5,
  title_str = "Setup 2: answer1-answer2 similarity",
  ylab_str  = "Predicted similarity"
)
ggsave("fig5_setup2_similarity.png", fig5, width = 5, height = 4, dpi = 300)
cat("Figure 5 saved.\n")

cat("\n=== 全部 5 张图已保存 ===\n")



















































# ----------------------------------------------------------------
# § 6. 生成 5 张图
# ----------------------------------------------------------------

## Figure 1：Setup 1 felm — log(# human answers)
pdata1 <- build_felm_pdata(
  m1_felm_int, mydata_AI, s1_pts, len1, opus1,
  z1$len_hi, z1$len_lo, z1$len_mu,
  z1$opus_hi, z1$opus_lo, z1$opus_mu
)
fig1 <- make_marg_plot(
  pdata1,
  title_str = "Setup 1: # human answers (log)",
  ylab_str  = "Predicted log(# human answers)"
)
ggsave("fig1_setup1_human_answer.png", fig1, width = 5, height = 4, dpi = 300)
cat("Figure 1 saved.\n")

## Figure 2：Setup 1 coxph — hazard of first human answer
pdata2 <- build_cox_pdata(
  m1_cox_int, mydata_survival, s1_pts, len1, opus1,
  z1$len_hi, z1$len_lo, z1$len_mu,
  z1$opus_hi, z1$opus_lo, z1$opus_mu
)
fig2 <- make_marg_plot(
  pdata2,
  title_str = "Setup 1: hazard of first human answer",
  ylab_str  = "Predicted hazard ratio (vs. control mean)",
  hline_val = 1
)
ggsave("fig2_setup1_cox_human.png", fig2, width = 5, height = 4, dpi = 300)
cat("Figure 2 saved.\n")

## Figure 3：Setup 2 felm — log(# other answers)
pdata3 <- build_felm_pdata(
  m2_felm_int, mydata_AI, s2_pts, len2, opus2,
  z2$len_hi, z2$len_lo, z2$len_mu_AI,
  z2$opus_hi, z2$opus_lo, z2$opus_mu_AI
)
fig3 <- make_marg_plot(
  pdata3,
  title_str = "Setup 2: # other answers (log)",
  ylab_str  = "Predicted log(# other answers)"
)
ggsave("fig3_setup2_other_answer.png", fig3, width = 5, height = 4, dpi = 300)
cat("Figure 3 saved.\n")

## Figure 4：Setup 2 coxph — hazard of second answer
## 协变量均值用 mydata_survival（cox 的拟合数据集）
pdata4 <- build_cox_pdata(
  m2_cox_int, mydata_survival, s2_pts, len2, opus2,
  z2$len_hi, z2$len_lo, z2$len_mu_surv,
  z2$opus_hi, z2$opus_lo, z2$opus_mu_surv
)
fig4 <- make_marg_plot(
  pdata4,
  title_str = "Setup 2: hazard of second answer",
  ylab_str  = "Predicted hazard ratio (vs. control mean)",
  hline_val = 1
)
ggsave("fig4_setup2_cox_second.png", fig4, width = 5, height = 4, dpi = 300)
cat("Figure 4 saved.\n")

## Figure 5：Setup 2 felm — ans1_ans2_similarity
pdata5 <- build_felm_pdata(
  m2_felm_sim_int, mydata_AI, s2_pts, len2, opus2,
  z2$len_hi, z2$len_lo, z2$len_mu_AI,
  z2$opus_hi, z2$opus_lo, z2$opus_mu_AI
)
fig5 <- make_marg_plot(
  pdata5,
  title_str = "Setup 2: answer1-answer2 similarity",
  ylab_str  = "Predicted similarity"
)
ggsave("fig5_setup2_similarity.png", fig5, width = 5, height = 4, dpi = 300)
cat("Figure 5 saved.\n")

cat("\n=== 全部 5 张图已保存 ===\n")

