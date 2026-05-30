make_descriptive_table <- function(df,
                                   var_list,
                                   treatment   = "treatment",
                                   output_path = NULL,
                                   labels      = NULL,
                                   digits      = 3,
                                   na.rm       = TRUE,
                                   sd_format   = "paren",   # "paren" -> (1.234); "plain" -> 1.234
                                   excel_text  = TRUE)      # TRUE: 强制 Excel 按文本显示
{
  # ---- 输入检查 ----
  if (!treatment %in% names(df)) {
    stop(sprintf("treatment 变量 '%s' 不在 df 中。", treatment))
  }
  miss_vars <- setdiff(var_list, names(df))
  if (length(miss_vars) > 0) {
    stop(sprintf("以下变量不在 df 中: %s", paste(miss_vars, collapse = ", ")))
  }

  # ---- 分组 ----
  grp <- df[[treatment]]
  if (!all(grp %in% c(0, 1) | is.na(grp))) {
    warning("treatment 变量包含非 0/1 的取值，这些行将不计入 treatment/control 组。")
  }
  idx_treat   <- which(grp == 1)
  idx_control <- which(grp == 0)

  # ---- 数字格式化 ----
  # 强制文本：把非空值包成  ="..."  让 Excel 当公式 -> 返回纯文本
  to_text <- function(s) {
    if (!excel_text) return(s)
    ifelse(s == "" | is.na(s), s, paste0("=\"", s, "\""))
  }

  fmt    <- function(x) to_text(formatC(x, format = "f", digits = digits))
  fmt_sd <- function(x) {
    s <- formatC(x, format = "f", digits = digits)
    if (sd_format == "paren") s <- paste0("(", s, ")")
    to_text(s)
  }

  # ---- 逐变量计算 ----
  rows <- list()
  for (i in seq_along(var_list)) {
    v <- var_list[[i]]

    if (is.null(labels)) {
      vlabel <- v
    } else if (!is.null(names(labels))) {
      vlabel <- if (v %in% names(labels)) labels[[v]] else v
    } else {
      vlabel <- labels[[i]]
    }

    x_all   <- df[[v]]
    x_treat <- df[[v]][idx_treat]
    x_ctrl  <- df[[v]][idx_control]

    if (!is.numeric(x_all)) {
      stop(sprintf("变量 '%s' 不是数值型，无法计算均值/标准差。", v))
    }

    mean_all   <- mean(x_all,   na.rm = na.rm)
    mean_treat <- mean(x_treat, na.rm = na.rm)
    mean_ctrl  <- mean(x_ctrl,  na.rm = na.rm)

    sd_all   <- sd(x_all,   na.rm = na.rm)
    sd_treat <- sd(x_treat, na.rm = na.rm)
    sd_ctrl  <- sd(x_ctrl,  na.rm = na.rm)

    min_all  <- min(x_all, na.rm = na.rm)
    max_all  <- max(x_all, na.rm = na.rm)

    # 第一行：均值 + min/max
    rows[[length(rows) + 1]] <- data.frame(
      Variable          = vlabel,
      `All samples`     = fmt(mean_all),
      `Treatment group` = fmt(mean_treat),
      `Control group`   = fmt(mean_ctrl),
      Min               = fmt(min_all),
      Max               = fmt(max_all),
      check.names = FALSE, stringsAsFactors = FALSE
    )

    # 第二行：标准差（括号），min/max 留空
    rows[[length(rows) + 1]] <- data.frame(
      Variable          = "",
      `All samples`     = fmt_sd(sd_all),
      `Treatment group` = fmt_sd(sd_treat),
      `Control group`   = fmt_sd(sd_ctrl),
      Min               = "",
      Max               = "",
      check.names = FALSE, stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL

  # ---- 输出 ----
  if (!is.null(output_path)) {
    write.csv(out, file = output_path, row.names = FALSE, fileEncoding = "UTF-8")
    message(sprintf("已写出: %s", normalizePath(output_path, mustWork = FALSE)))
  }

  return(invisible(out))
}

labels <- c(
  textLengthCN_ask        = "question length (number of Chinese characters)",
  answer_que   = "number of human-generated answers received by a question",
  ans1_ans2_similarity  = "similarity between the second answer to the first answer",
  netlikeNum_sumResp   = "average number of net likes received by all the answers to a question",
  log_textLengthCNAI_fillna = "log of length for AI-generated answer (with 0 filled for control group)",
  AISimWithOpus47_fillna = "similarity between AI-generated answer and LLM (with 0 filled for control group)",
  log_textLengthCN1Ans = "log of length for the first answer",
  SimWithOpus1Ans = "similarity between the first answer and LLM"
)

tbl <- make_descriptive_table(
  df          = mydata_AI,
  var_list    = c("textLengthCN_ask","answer_que","ans1_ans2_similarity","netlikeNum_sumResp", "log_textLengthCNAI_fillna", "AISimWithOpus47_fillna", "log_textLengthCN1Ans", "SimWithOpus1Ans"),
  treatment   = "treatment",
  output_path = "Projects/MISQ/MISQ round 2/analysis/outputs/descriptive_table.csv",
  labels      = labels
)

names(mydata_AI)[1:110]




























