# install.packages(c("readr", "dplyr", "survival", "smcure"))
library(readr)
library(dplyr)
library(survival)
library(smcure)
# install.packages("modelsummary")
# install.packages("mediation")
library(mediation)
library(readr)
library(lfe)
library(sandwich)
library(broom)
library(dplyr)
library(officer)
library(xtable)
library(flextable)
library(stargazer)
library(fixest)
library(texreg)
library(stringr)
library(ggplot2)
library(ggpubr)
library(pandoc)
library(tidyverse)
library(forcats)
library(ggpubr)
library(broom)
library(robomit)
library(huxtable)
library(timeDate)
library(MatchIt)
library(haven)
library(janitor)
library(data.table)
library(modelsummary)
library(rmarkdown)
library(xfun)
# install.packages("rmarkdown")
# install.packages("xfun")

#' 加载并处理数据的主函数
#' @param data_path CSV 文件路径
#' @param tag_path 标签分类文件路径
#' @param ai_start AI 时期开始日期
#' @param ai_end AI 时期结束日期
#' @param full_start 完整数据开始日期
#' @return 包含两个 DataFrame 的列表：mydata_AI 和 mydata_AI_full
load_and_process_data <- function(
    data_path = "panel_factory/data/panels/question_panel_MISQ.csv",#"/Users/dylanchen/Library/CloudStorage/OneDrive-Personal/data/geek-community/result/result_question_robustness_LLM.csv",
    tag_path = "panel_factory/data/raw/tagName_classified_GBK.csv",
    ai_start = as.Date("2023-09-13"),
    ai_end = as.Date("2024-12-30"),
    full_start = as.Date("2022-01-01")
) {
  
  # ========== 1. 读取原始数据 ==========
  mydata <- read_csv(data_path)
  
  # ========== 2. 变量派生 ==========
  mydata <- update_data_fields(mydata)
  mydata <- calculate_time_info(mydata, "askTime", "")
  mydata$age_que <- as.integer(as.Date(mydata$crawldate) - as.Date(mydata$askTime))
  
  # ========== 3. 标签分类处理 ==========
  tag_df <- read.csv(tag_path, header = TRUE, sep = ",", 
                     fileEncoding = "GBK", stringsAsFactors = FALSE)
  tag_df$tagName <- replace_na(tag_df$tagName, "NA")
  
  mydata$tagName <- str_extract(mydata$tagURL, "(?<=/t/).*(?=/questions)")
  mydata$tagName <- URLdecode(mydata$tagName)
  mydata <- left_join(mydata, tag_df, by = "tagName")
  
  # ========== 4. 分类虚拟变量 ==========
  category_names <- c(
    "Web and Mobile Development",
    "Software Design and Architecture", 
    "DevOps and Cloud Computing",
    "Databases",
    "Computer Networks and Systems",
    "Data Science and Machine Learning",
    "Development Tools and Environment",
    "Programming Languages",
    "Career and Professional Development",
    "Other"
  )
  
  for (i in seq_along(category_names)) {
    mydata[[paste0("category", i)]] <- as.integer(mydata$category == category_names[i])
  }
  mydata$allCategory <- rowSums(mydata[, paste0("category", 1:10)], na.rm = TRUE)
  
  # ========== 5. 按日期筛选分成两个 DataFrame ==========
  mydata_AI <- mydata %>%
    filter(askTime >= ai_start & askTime <= ai_end)
  
  mydata_AI_full <- mydata %>%
    filter(askTime >= full_start)
  
  # ========== 6. 返回结果 ==========
  list(
    mydata_AI = mydata_AI,
    mydata_AI_full = mydata_AI_full,
    mydata_AI_isAI = mydata_AI %>% filter(preAI == 1),
    mydata_AI_isnotAI = mydata_AI %>% filter(preAI != 1)
  )
}


#' 字段更新函数（精简版）
update_data_fields <- function(df) {
  
  # ----- 平方项 -----
  df$geekAsk_squared <- df$geekAsk^2
  
  # ----- 活动日志变换 -----
  activity_cols <- c("nActivityBeforeAsk", "nActivityBeforeResp", 
                     "nActivityBeforeComment", "nActivityBefore")
  for (col in activity_cols) {
    df[[paste0("In", gsub("^n", "", col))]] <- log(df[[col]] + 1)
  }
  
  # ----- 指示变量（>0 则为1） -----
  indicator_cols <- c(
    "imgNum_ask", "inlinecodeNum_ask", "interlinecodeNum_ask", 
    "boldNum_ask", "italicNum_ask", "liNum_ask", "aNum_ask", 
    "blockquoteNum_ask", "hrNum_ask", "tableNum_ask",
    "interlinecodeNum_sumResp", "aNum_sumResp", 
    "nFollowup_sumResp", "nAddKnow_sumResp",
    "nActivityBeforeAsk", "nActivityBeforeResp", "nActivityBeforeComment", 
    "nActivityBefore", "nPayback", "nPaybackAsk", "nPaybackResp", 
    "nPaybackComment", "nPaybackCommentAsker", "nPaybackCommentResponder", 
    "nPaybackCommentOthers", "nComment_sumResp", "nCommentAsker_sumResp", 
    "nCommentResponder_sumResp", "nCommentOthers_sumResp", 
    "nAt_sumResp", "nAtAsker_sumResp", "nAtResponder_sumResp", "nAtOthers_sumResp"
  )
  for (col in indicator_cols) {
    df[[paste0("I", col)]] <- as.integer(df[[col]] > 0)
  }
  df$Ihiddenanswer_que <- as.integer(df$hiddenanswer_que > 0)
  
  # ----- 格式分类 -----
  df$codeFormatAsk <- df$IinlinecodeNum_ask + df$IinterlinecodeNum_ask
  df$textFormatAsk <- df$IliNum_ask + df$IboldNum_ask + df$IitalicNum_ask
  df$layoutFormatAsk <- df$IhrNum_ask + df$IblockquoteNum_ask + df$ItableNum_ask
  df$additionalInfo <- df$IaNum_ask + df$IimgNum_ask
  df$noaccept_gt1Resp <- as.integer(df$accepted_gt1Resp == 0)
  
  # ----- log(x+1) 变换：批量处理 -----
  log_transform_cols <- list(
    # 等待时间相关
    wait1Resp_original = 1, wait2Resp_original = 1, wait3Resp_original = 1,
    waitAccepted_original = 1, wait1Ans_original = 1, wait2Ans_original = 1, 
    wait3Ans_original = 1, deltawait2Ans_original = 1, deltawait3Ans_original = 1,
    wait1Resp = 1, wait2Resp = 1, wait3Resp = 1, waitAccepted = 1,
    wait1Ans = 1, wait2Ans = 1, wait3Ans = 1, deltawait2Ans = 1, deltawait3Ans = 1,
    # 徽章/声望相关
    badgeBefore_1Resp = 1, acceptedBefore_1Resp = 1,
    accumGold1Ans = 1, accumSilver1Ans = 1, accumCopper1Ans = 1,
    accumRep_ask = 4, accumGold_ask = 1, accumSilver_ask = 1, accumCopper_ask = 1,
    # 响应内容相关
    codeLength_sumResp = 1, textLengthCN_sumResp = 1, textLength_sumResp = 1,
    answer_que = 1, liNum_sumResp = 1, hiddenanswer_que = 1,
    # 专家/资深相关
    masterTop5pct_sumResp = 1, masterTop10pct_sumResp = 1, 
    masterTop15pct_sumResp = 1, masterTop20pct_sumResp = 1,
    seniorTop5pct_sumResp = 1, seniorTop10pct_sumResp = 1,
    seniorTop15pct_sumResp = 1, seniorTop20pct_sumResp = 1,
    preferdiscussTop5pct_sumResp = 1, preferdiscussTop10pct_sumResp = 1,
    preferdiscussTop15pct_sumResp = 1, preferdiscussTop20pct_sumResp = 1,
    # 其他
    commentOthersBefore_sumResp = 1, rookieRespNum_sumResp = 1, ageAvg_sumResp = 1,
    neglikeRespNum_sumResp = 1, nolikeRespNum_sumResp = 1,
    # 回馈相关
    nPayback = 1, nPaybackAsk = 1, nPaybackResp = 1, nPaybackComment = 1,
    nPaybackCommentAsker = 1, nPaybackCommentResponder = 1, nPaybackCommentOthers = 1,
    nActivityBeforeAsk = 1, nActivityBeforeResp = 1, 
    nActivityBeforeComment = 1, nActivityBefore = 1,
    # 评论/互动相关
    interlinecodeNum_sumResp = 1, aNum_sumResp = 1, nComment_sumResp = 1,
    nCommentAsker_sumResp = 1, nCommentResponder_sumResp = 1,
    nCommentOthers_sumResp = 2, nAt_sumResp = 1, nAtAsker_sumResp = 1,
    nAtResponder_sumResp = 1, nAtOthers_sumResp = 4,
    nFollowup_sumResp = 1, nAddKnow_sumResp = 1,
    # gt1Resp 相关
    answer_gt1Resp = 1, hiddenanswer_gt1Resp = 1,
    masterTop5pct_gt1Resp = 1, seniorTop5pct_gt1Resp = 1,
    codeLength_gt1Resp = 1, textLengthCN_gt1Resp = 1, textLength_gt1Resp = 1,
    # 2Ans 相关
    codeLength_2Ans = 1, textLength_2Ans = 1, textLengthCN_2Ans = 1,
    accepted_2Ans = 1, hiddenanswer_2Ans = 1, answer_2Ans = 1,
    masterTop5pct_2Ans = 1, masterTop10pct_2Ans = 1, 
    masterTop15pct_2Ans = 1, masterTop20pct_2Ans = 1,
    seniorTop5pct_2Ans = 1, seniorTop10pct_2Ans = 1,
    seniorTop15pct_2Ans = 1, seniorTop20pct_2Ans = 1,
    # 提问相关
    textLengthCN_ask = 1, codeLength_ask = 1, badgeBefore = 1,
    age = 1, askBefore = 1, resBefore = 1, acceptedBefore = 1,
    format1Ans = 1, textLengthCN1Ans = 1, textLength1Ans = 1, codeLength1Ans = 1,
    badgeBefore1Ans = 1, badgeBefore2Ans = 1, 
    acceptedBefore1Ans = 1, accepted1Ans = 1, accepted2Ans = 1,
    views_que = 1
  )
  
  for (col_name in names(log_transform_cols)) {
    offset <- log_transform_cols[[col_name]]
    df[[paste0("log_", col_name)]] <- log(df[[col_name]] + offset)
  }
  
  # 特殊列名处理（带数字开头或特殊字符）
  special_log_cols <- c(
    "1likeRespNum_sumResp", "3likeRespNum_sumResp", "5likeRespNum_sumResp",
    "7likeRespNum_sumResp", "10likeRespNum_sumResp",
    "0mdRespNum_sumResp", "1mdRespNum_sumResp", "2mdRespNum_sumResp",
    "3mdRespNum_sumResp", "4mdRespNum_sumResp", "5mdRespNum_sumResp"
  )
  for (col in special_log_cols) {
    df[[paste0("log_", col)]] <- log(df[[col]] + 1)
  }
  
  # badgeBefore_1Resp 特殊处理（无 +1）
  df$log_badgeBefore_1Resp <- log(df$badgeBefore_1Resp)
  
  # gt1Resp 的 Top10/15/20 使用 Top5 的值（保持原逻辑）
  for (pct in c("10", "15", "20")) {
    df[[paste0("log_masterTop", pct, "pct_gt1Resp")]] <- log(df$masterTop5pct_gt1Resp + 1)
    df[[paste0("log_seniorTop", pct, "pct_gt1Resp")]] <- log(df$seniorTop5pct_gt1Resp + 1)
  }
  
  # ----- 其他变量 -----
  df$response1Resp <- 1 - df$noresponse1Resp
  
  # ----- accepted 区间变量处理 -----
  accepted_ranges <- c(
    "0-inf", "0-100", "101-200", "201-300", "301-400", "401-500",
    "501-600", "601-700", "701-800", "801-900", "901-1000",
    "1001-1100", "1101-1200", "1201-1300", "1301-1400", "1401-inf",
    "0-5", "6-55", "56-290", "291-1500"
  )
  for (rng in accepted_ranges) {
    col_name <- paste0("accepted", rng, "_sumResp")
    df[[col_name]] <- ifelse(is.na(df[[col_name]]), 0, df[[col_name]])
    df[[paste0("log_", col_name)]] <- log(df[[col_name]] + 1)
  }
  
  return(df)
}


#' 时间信息计算函数
calculate_time_info <- function(df, askTime_col, suffix = "") {
  
  
  unique_years <- unique(year(as.Date(df[[askTime_col]])))
  
  df %>%
    mutate(
      !!paste0("year", suffix) := format(as.Date(.data[[askTime_col]]), "%Y"),
      !!paste0("monthofyear", suffix) := as.Date(format(as.Date(.data[[askTime_col]]), "%Y-%m-01")),
      !!paste0("dayofyear", suffix) := as.Date(format(as.Date(.data[[askTime_col]]), "%Y-%m-%d")),
      !!paste0("weekofyear", suffix) := floor_date(.data[[paste0("dayofyear", suffix)]], unit = "weeks"),
      !!paste0("weekofmonth", suffix) := week(.data[[paste0("dayofyear", suffix)]]) - 
        week(floor_date(.data[[paste0("dayofyear", suffix)]], unit = "month")) + 1,
      !!paste0("isWeekend", suffix) := as.integer(wday(.data[[paste0("dayofyear", suffix)]]) %in% c(1, 7))
    )
}


# ========== 使用方法 ==========
# 执行一次即可获得所有需要的 DataFrame
result <- load_and_process_data()

mydata_AI <- result$mydata_AI
mydata_AI <- mutate(mydata_AI, treatment = preAI)
mydata_AI_full <- result$mydata_AI_full
summary(mydata_AI_full$age_que)
mydata_AI_isAI <- result$mydata_AI_isAI
mydata_AI_isnotAI <- result$mydata_AI_isnotAI


mydata_AI_has1Resp = mydata_AI %>% filter(!is.na(wait1Ans_original))
mydata_AI_has1Ans = mydata_AI %>% filter(!is.na(wait1Ans_original) | treatment == 1)
summary(mydata_AI_has1Ans$wait1Ans_original)
length(mydata_AI_has1Ans$wait1Ans_original)
mydata_AI <- mydata_AI %>% mutate(
  nohumananswer = ifelse(answer_que==0, 1, 0)
  )

mydata_AI = mydata_AI %>% mutate(
  qualityAI_fillna = ifelse(treatment == 1, quality1Ans, 0),
  log_textLengthCNAI_fillna = ifelse(treatment == 1, log_textLengthCN1Ans, 0)
)














load_and_process_answer_data <- function(
    mydata_AI_full,
    data_path = "panel_factory/data/panels/answer_panel_MISQ.csv",#"/Users/dylanchen/Library/CloudStorage/OneDrive-Personal/data/geek-community/result/result_answer_robustness_LLM_deviation.csv",
    tag_path = "panel_factory/data/raw/tagName_classified_GBK.csv"
) {

  # ========== 1. 读取原始数据 ==========
  mydata_answer_original <- read_csv(data_path)
  
  # ========== 2. 时间ID处理 ==========
  mydata_answer_original <- mydata_answer_original %>%
    mutate(ansTimeID = ifelse(preAI == 1, cmnTimeID + 1, cmnTimeID)) %>%
    mutate(ansTimeID_human = cmnTimeID)
  
  # ========== 3. 计算下一答案间隔时间 ==========
  mydata_answer_original <- mydata_answer_original %>%
    group_by(questionURL) %>%
    arrange(cmnTimeID) %>%
    mutate(deltaNextAnswer = as.numeric(difftime(lead(date), date, units = "days")),
           hasNextAnswer = ifelse(is.na(deltaNextAnswer), 0, 1),
           deltaNextAnswer_nafill30 = ifelse(is.na(deltaNextAnswer), 30, deltaNextAnswer)) %>%
    ungroup()
  
  # ========== 4. 维度指标二值化 ==========
  mydata_answer_original <- mydata_answer_original %>%
    mutate(across(
      c(clarity_m2, readability_m2, accuracy_m2, relevance_m2, detail_m2,
        experience_m2, insight_m2, innovative_m2, alternative_m2, storytelling_m2),
      ~ ifelse(.x >= 1, 1, 0),
      .names = "I{.col}"
    ))
  
  # ========== 5. 计算后续答案的统计量 ==========
  mydata_answer_original <- mydata_answer_original %>%
    group_by(questionURL) %>%
    mutate(
      later_answer_count = sapply(cmnTimeID, function(x) sum(cmnTimeID > x)),
      later_answer_netlike_mean = sapply(cmnTimeID, function(x) {
        later_vals <- netlikeNum[cmnTimeID > x]
        if (length(later_vals) == 0) NA_real_ else mean(later_vals, na.rm = TRUE)
      }),
      later_answer_netlike_sum = sapply(cmnTimeID, function(x) {
        later_vals <- netlikeNum[cmnTimeID > x]
        if (length(later_vals) == 0) NA_real_ else sum(later_vals, na.rm = TRUE)
      }),
      next_Iexperience_m2 = sapply(cmnTimeID, function(x) {
        later_times <- cmnTimeID[cmnTimeID > x]
        if (length(later_times) == 0) NA_real_ else Iexperience_m2[cmnTimeID == min(later_times)][1]
      }),
      next_Iinsight_m2 = sapply(cmnTimeID, function(x) {
        later_times <- cmnTimeID[cmnTimeID > x]
        if (length(later_times) == 0) NA_real_ else Iinsight_m2[cmnTimeID == min(later_times)][1]
      }),
      next_Ialternative_m2 = sapply(cmnTimeID, function(x) {
        later_times <- cmnTimeID[cmnTimeID > x]
        if (length(later_times) == 0) NA_real_ else Ialternative_m2[cmnTimeID == min(later_times)][1]
      }),
      next_innovative_m2 = sapply(cmnTimeID, function(x) {
        later_times <- cmnTimeID[cmnTimeID > x]
        if (length(later_times) == 0) NA_real_ else innovative_m2[cmnTimeID == min(later_times)][1]
      })
    ) %>%
    ungroup()
  
  # ========== 6. 取对数 ==========
  mydata_answer_original <- mydata_answer_original %>% mutate(
    log_deltaNextAnswer = log(deltaNextAnswer + 1),
    log_deltaNextAnswer_nafill30 = log(deltaNextAnswer_nafill30 + 1)
  )
  
  # ========== 7. 从 mydata_AI_full 加入变量 ==========
  vars_to_add <- c(
    "lingComp_score",
    "techJargon_score", 
    "difficulty_score",
    "asker_acceptedBefore_allsite_1m",
    "asker_nActivityBeforeAsk_allsite_1m",
    "asker_nActivityBeforeResp_allsite_1m",
    "asker_nActivityBeforeComment_allsite_1m",
    "asker_acceptedBefore_allsite_2m",
    "asker_nActivityBeforeAsk_allsite_2m",
    "asker_nActivityBeforeResp_allsite_2m",
    "asker_nActivityBeforeComment_allsite_2m",
    "asker_acceptedBefore_allsite_3m",
    "asker_nActivityBeforeAsk_allsite_3m",
    "asker_nActivityBeforeResp_allsite_3m",
    "asker_nActivityBeforeComment_allsite_3m",
    "log_age", "log_askBefore", "log_resBefore", "age_que"
  )
  mydata_answer_original <- mydata_answer_original %>%
    left_join(
      mydata_AI_full %>% dplyr::select(questionURL, all_of(vars_to_add)),
      by = "questionURL"
    )
  
  # ========== 8. 内部函数：变量更新 ==========
  update_variables <- function(mydata_answer, tag_path) {
    mydata_answer$log_textLengthCN_ask = log(mydata_answer$textLengthCN_ask + 1)
    mydata_answer$log_codeLength_ask = log(mydata_answer$codeLength_ask + 1)
    mydata_answer$log_badgeBefore_ask = log(mydata_answer$badgeBefore_ask + 1)
    mydata_answer$log_badgeBefore = log(mydata_answer$badgeBefore + 1)
    mydata_answer$log_acceptedBefore = log(mydata_answer$acceptedBefore + 1)
    mydata_answer$log_commentOthersBefore = log(mydata_answer$commentOthersBefore + 1)
    mydata_answer$ratioAcceptedResp_adjusted = (mydata_answer$acceptedBefore + (1.98^2 / (2 * mydata_answer$resBefore + 1)) - 1) / (mydata_answer$resBefore + (1.98^2) - 2)
    mydata_answer$log_ratioAcceptedResp = log(mydata_answer$ratioAcceptedResp + 1)
    mydata_answer$log_ratioNetlikeResp = log(mydata_answer$ratioNetlikeResp + +4)
    mydata_answer$IimgNum_ask = ifelse(mydata_answer$imgNum_ask > 0, 1, 0)
    mydata_answer$IaNum_ask = ifelse(mydata_answer$aNum_ask > 0, 1, 0)
    mydata_answer$IblockquoteNum_ask = ifelse(mydata_answer$blockquoteNum_ask > 0, 1, 0)
    mydata_answer$ItableNum_ask = ifelse(mydata_answer$tableNum_ask > 0, 1, 0)
    mydata_answer$log_accumRep_ask = log(mydata_answer$accumRep_ask + 4)
    mydata_answer$log_accumRep = log(mydata_answer$accumRep + 3)
    
    mydata_answer$log_wait1Ans_original = log(mydata_answer$wait1Ans_original + 1)
    
    mydata_answer$year <- format(as.Date(mydata_answer$askTime), "%Y")
    mydata_answer$monthofyear <- as.Date(format(as.Date(mydata_answer$askTime), "%Y-%m-01"))
    mydata_answer$dayofyear <- as.Date(format(as.Date(mydata_answer$askTime), "%Y-%m-%d"))
    mydata_answer$waitAnswer_power2 <- mydata_answer$waitAnswer^2
    mydata_answer$log_waitAnswer <- log(mydata_answer$waitAnswer + 1)
    mydata_answer$log_waitAnswer_power2 <- mydata_answer$log_waitAnswer^2
    mydata_answer$cmnTimeID_power2 <- mydata_answer$cmnTimeID^2
    
    df <- read.csv(tag_path,
                   header = TRUE, sep = ",", fileEncoding = "GBK", stringsAsFactors = FALSE)
    df$tagName <- replace_na(df$tagName, "NA")
    mydata_answer$tagName <- str_extract(mydata_answer$tagURL, "(?<=/t/).*(?=/questions)")
    mydata_answer$tagName <- URLdecode(mydata_answer$tagName)
    mydata_answer <- left_join(mydata_answer, df, by = c("tagName" = "tagName"))
    
    mydata_answer$highMotivation = ifelse(mydata_answer$ratioAcceptedResp >= 0.2977, 1, 0)
    
    mydata_answer$year <- format(as.Date(mydata_answer$askTime), "%Y")
    mydata_answer$monthofyear <- as.Date(format(as.Date(mydata_answer$askTime), "%Y-%m-01"))
    mydata_answer$dayofyear <- as.Date(format(as.Date(mydata_answer$askTime), "%Y-%m-%d"))
    
    mydata_answer$category1  = ifelse(mydata_answer$category == 'Web and Mobile Development', 1, 0)
    mydata_answer$category2  = ifelse(mydata_answer$category == 'Software Design and Architecture', 1, 0)
    mydata_answer$category3  = ifelse(mydata_answer$category == 'DevOps and Cloud Computing', 1, 0)
    mydata_answer$category4  = ifelse(mydata_answer$category == 'Databases', 1, 0)
    mydata_answer$category5  = ifelse(mydata_answer$category == 'Computer Networks and Systems', 1, 0)
    mydata_answer$category6  = ifelse(mydata_answer$category == 'Data Science and Machine Learning', 1, 0)
    mydata_answer$category7  = ifelse(mydata_answer$category == 'Development Tools and Environment', 1, 0)
    mydata_answer$category8  = ifelse(mydata_answer$category == 'Programming Languages', 1, 0)
    mydata_answer$category9  = ifelse(mydata_answer$category == 'Career and Professional Development', 1, 0)
    mydata_answer$category10 = ifelse(mydata_answer$category == 'Other', 1, 0)
    mydata_answer$allCategory = mydata_answer$category1 + mydata_answer$category2 + mydata_answer$category3 +
      mydata_answer$category4 + mydata_answer$category5 + mydata_answer$category6 +
      mydata_answer$category7 + mydata_answer$category8 + mydata_answer$category9 +
      mydata_answer$category10
    
    mydata_answer$log_textLengthCN1Ans = log(mydata_answer$textLengthCN1Ans + 1)
    mydata_answer$log_textLengthCN = log(mydata_answer$textLengthCN + 1)
    
    mydata_answer$answer_timing <- as.Date(format(as.Date(mydata_answer$date), "%Y-%m-%d"))
    mydata_answer$answer_age <- as.integer(as.Date(mydata_answer$crawldate) - as.Date(mydata_answer$date))
    mydata_answer$answer_age_power2 <- mydata_answer$answer_age^2
    mydata_answer$answer_age_power3 <- mydata_answer$answer_age^3
    
    mydata_answer <- calculate_time_info(mydata_answer, "date", "_answer")
    
    return(mydata_answer)
  }
  
  # ========== 9. 应用变量更新 ==========
  mydata_answer_original <- update_variables(mydata_answer_original, tag_path)
  mydata_answer_original <- mutate(mydata_answer_original, treatment = preAI)
  
  # ========== 10. 切分各类子集 ==========
  mydata_answer_full <- mydata_answer_original %>%
    filter(askTime >= as.Date("2022-01-01"))
  
  mydata_answer <- mydata_answer_original %>%
    filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2024-12-30"))
  
  mydata_answer_before <- mydata_answer_full %>%
    filter(askTime >= as.Date("2023-05-13") & askTime <= as.Date("2023-09-12"))
  
  mydata_answer$after <- 1
  mydata_answer_before$after <- 0
  
  mydata_answer_isAI <- mydata_answer %>% filter(preAI == 1)
  mydata_answer_isnotAI <- mydata_answer %>% filter(preAI == 0)
  
  # ========== 11. 合并子集 ==========
  mydata_answer_beforeNcontrol <- bind_rows(mydata_answer_isnotAI, mydata_answer_before)
  mydata_answer_beforeNafter   <- bind_rows(mydata_answer, mydata_answer_before)
  
  mydata_answer_beforeNcontrol <- mydata_answer_beforeNcontrol %>% mutate(
    age_que_power2 = age_que^2,
    age_que_power3 = age_que^3
  )
  mydata_answer_beforeNafter <- mydata_answer_beforeNafter %>% mutate(
    age_que_power2 = age_que^2,
    age_que_power3 = age_que^3
  )
  
  # ========== 12. 返回所有 DataFrame ==========
  return(list(
    mydata_answer_original       = mydata_answer_original,
    mydata_answer_full           = mydata_answer_full,
    mydata_answer                = mydata_answer,
    mydata_answer_before         = mydata_answer_before,
    mydata_answer_isAI           = mydata_answer_isAI,
    mydata_answer_isnotAI        = mydata_answer_isnotAI,
    mydata_answer_beforeNcontrol = mydata_answer_beforeNcontrol,
    mydata_answer_beforeNafter   = mydata_answer_beforeNafter
  ))
}


# 一次性执行获取所有 DataFrame
result_ans <- load_and_process_answer_data(mydata_AI_full)



mydata_answer_original       <- result_ans$mydata_answer_original
mydata_answer_full           <- result_ans$mydata_answer_full
mydata_answer                <- result_ans$mydata_answer
mydata_answer_before         <- result_ans$mydata_answer_before
mydata_answer_isAI           <- result_ans$mydata_answer_isAI
mydata_answer_isnotAI        <- result_ans$mydata_answer_isnotAI
mydata_answer_beforeNcontrol <- result_ans$mydata_answer_beforeNcontrol
mydata_answer_beforeNafter   <- result_ans$mydata_answer_beforeNafter



mydata_answer_firstHumanAns = mydata_answer %>% filter(cmnTimeID == 1)
mydata_answer_secondAns = mydata_answer %>% filter(
  (treatment == 1 & cmnTimeID == 1)|(treatment==0 & cmnTimeID == 2))




# 简单检查
summary(mydata_answer_full$age_que)
summary(mydata_answer_isAI$preAI)
summary(mydata_answer_isnotAI$preAI)




omit_vars <- c(
  "log_textLengthCN_ask", "IimgNum_ask", "IaNum_ask", "IblockquoteNum_ask", "ItableNum_ask",
  "lingComp_score", "techJargon_score", "difficulty_score",
  "category1", "category2", "category3", "category4", "category5", "category6", "category7", "category8", "category9",
  "log_age", "log_askBefore", "log_resBefore", "log_accumRep_ask",
  "accumGold_ask", "accumSilver_ask", "accumCopper_ask",
  "asker_acceptedBefore_allsite_1m", "asker_nActivityBeforeAsk_allsite_1m", "asker_nActivityBeforeResp_allsite_1m", "asker_nActivityBeforeComment_allsite_1m",
  "asker_acceptedBefore_allsite_2m", "asker_nActivityBeforeAsk_allsite_2m", "asker_nActivityBeforeResp_allsite_2m", "asker_nActivityBeforeComment_allsite_2m",
  "asker_acceptedBefore_allsite_3m", "asker_nActivityBeforeAsk_allsite_3m", "asker_nActivityBeforeResp_allsite_3m", "asker_nActivityBeforeComment_allsite_3m"
)

omit_pattern <- paste(omit_vars, collapse = "|")


































mydata_AI <- mydata_AI %>% mutate(
  ans1_ans2_similarity = ifelse(treatment ==1, ai_human1_similarity, human1_human2_similarity))
# Merge AISimWithAccept from question panel (question-level variable)
question_sim <- mydata_AI %>% dplyr::select(questionURL, AISimWithAccept, AISimWithGT__claude_opus_4_7, AISimWithGT__deepseek_v4_pro, human1SimWithAccept, human1SimWithGT__claude_opus_4_7, human1SimWithGT__deepseek_v4_pro)
mydata_answer <- mydata_answer %>%
  left_join(question_sim, by = "questionURL")
summary(mydata_AI$AISimWithAccept)
summary(mydata_AI$AISimWithGT__claude_opus_4_7)
summary(mydata_AI$AISimWithGT__deepseek_v4_pro)
# Create AISimWithAccept fillna variable
mydata_answer = mydata_answer %>% mutate(
  AISimWithAccept_fillna = ifelse(treatment == 1, AISimWithAccept, 0),
  AISimWithOpus47_fillna = ifelse(treatment == 1, AISimWithGT__claude_opus_4_7, 0),
  AISimWithDeepseek_fillna = ifelse(treatment == 1, AISimWithGT__deepseek_v4_pro, 0)
)
mydata_AI = mydata_AI %>% mutate(
  AISimWithAccept_fillna = ifelse(treatment == 1, AISimWithAccept, 0),
  AISimWithOpus47_fillna = ifelse(treatment == 1, AISimWithGT__claude_opus_4_7, 0),
  AISimWithDeepseek_fillna = ifelse(treatment == 1, AISimWithGT__deepseek_v4_pro, 0)
)
summary(mydata_AI$AISimWithAccept_fillna)
summary(mydata_AI$AISimWithOpus47_fillna)

mydata_AI <- mydata_AI %>% mutate(
    answer_que_within7day_other = ifelse(treatment==0, pmax(answer_que_within7day - 1, 0), answer_que_within7day),
    log_answer_que_within7day_other = log(answer_que_within7day_other + 1),
    has_other_answer = ifelse(answer_que_within7day_other>0, 1, 0)
)
summary(mydata_AI$answer_que_within7day)
summary(mydata_AI$answer_que_within7day_other)


# 生成1Ans变量
mydata_AI <- mydata_AI %>% mutate(
    SimWithAccept1Ans = ifelse(treatment == 1, AISimWithAccept, human1SimWithAccept),
    SimWithOpus1Ans = ifelse(treatment == 1, AISimWithGT__claude_opus_4_7, human1SimWithGT__claude_opus_4_7),
    SimWithDeepseek1Ans = ifelse(treatment == 1, AISimWithGT__deepseek_v4_pro, human1SimWithGT__deepseek_v4_pro)
)
summary(mydata_AI$AISimWithAccept_fillna)
summary(mydata_AI$SimWithAccept1Ans)
summary(mydata_AI$SimWithOpus1Ans)
summary(mydata_AI$SimWithDeepseek1Ans)
mydata_AI_has_ans1_ans2_similarity = mydata_AI %>% filter(!is.na(ans1_ans2_similarity))
summary(mydata_AI_has_ans1_ans2_similarity$AISimWithAccept_fillna)
summary(mydata_AI_has_ans1_ans2_similarity$SimWithAccept1Ans)
mydata_answer = mydata_answer %>% mutate(
  qualityAI_fillna = ifelse(treatment == 1, quality1Ans, 0),
  log_textLengthCNAI_fillna = ifelse(treatment == 1, log_textLengthCN1Ans, 0),
  SimWithAccept1Ans = ifelse(treatment == 1, AISimWithAccept, human1SimWithAccept),
  SimWithOpus1Ans = ifelse(treatment == 1, AISimWithGT__claude_opus_4_7, human1SimWithGT__claude_opus_4_7),
  SimWithDeepseek1Ans = ifelse(treatment == 1, AISimWithGT__deepseek_v4_pro, human1SimWithGT__deepseek_v4_pro)
)

mydata_answer_firstHumanAns = mydata_answer %>% filter(cmnTimeID == 1)
mydata_answer_secondAns = mydata_answer %>% filter(
  (treatment == 1 & cmnTimeID == 1)|(treatment==0 & cmnTimeID == 2))



mydata_survival <- mydata_AI %>%
  mutate(
    nohumananswer = ifelse(answer_que==0,1,0),
    human_answer_event = 1 - nohumananswer,
    censor_time = age_que,
    wait1Resp_surv = ifelse(human_answer_event == 1, wait1Resp_original, censor_time),
    wait1Resp_surv = ifelse(wait1Resp_surv <= 0, 0.001, wait1Resp_surv),
    dayofyear = as.factor(dayofyear),
    # 需要修改
    nosecondhuman = ifelse(ifelse(treatment==1, answer_que, answer_que-1)<2,1,0),
    second_human_answer_event = 1 - nosecondhuman,
    censor_time = age_que,
    wait2Ans_original = ifelse(treatment==1, wait1Resp_original, wait2Resp_original),
    wait2Ans_surv = ifelse(second_human_answer_event == 1, wait2Ans_original, censor_time),
    wait2Ans_surv = ifelse(wait2Ans_surv <= 0, 0.001, wait1Resp_surv),
    dayofyear = as.factor(dayofyear)
  )
mydata_survival$surv_human_answer <- with(mydata_survival, Surv(wait1Resp_surv, human_answer_event))
mydata_survival$surv_second_answer <- with(mydata_survival, Surv(wait2Ans_surv, second_human_answer_event))
library(lfe)
library(survival)
library(texreg)
summary(mydata_survival$surv_human_answer)
summary(mydata_survival$wait2Ans_surv)




##############################################
######## 260527 Setup 1 + AISimWithOpus47_fillna
##############################################
models_setup1 <- list()
models_setup1[["DV: # human answers"]] <- felm(log_answer_que_within7day ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models_setup1[[" "]]  <- felm(log_answer_que_within7day ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
mydata_survival$surv_human_answer <- with(mydata_survival, Surv(wait1Resp_surv, human_answer_event))
models_setup1[["DV: harzard first human answer"]] <- coxph(surv_human_answer ~ treatment + strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models_setup1[["  "]] <- coxph(surv_human_answer ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)+ strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
print(screenreg(models_setup1,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))
summary(mydata_survival$surv_human_answer)


##############################################
######## 260527 Setup 2 + AISimWithOpus47_fillna
##############################################
models_setup2 <- list()
models_setup2[["DV: # other answers"]] <- felm(log_answer_que_within7day_other ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models_setup2[[" "]] <- felm(log_answer_que_within7day_other ~ treatment+treatment*(log_textLengthCN1Ans + SimWithOpus1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models_setup2[["DV: harzard second answer"]] <- coxph(surv_second_answer ~ treatment + strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models_setup2[["  "]] <- coxph(surv_second_answer ~ treatment+treatment*(log_textLengthCN1Ans + SimWithOpus1Ans)+ strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models_setup2[["DV: ans1_ans2_similarity"]] <- felm (ans1_ans2_similarity ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models_setup2[["   "]] <- felm (ans1_ans2_similarity ~ treatment+treatment*(log_textLengthCN1Ans + SimWithOpus1Ans )
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
print(screenreg(models_setup2,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))


# library(ggplot2); library(dplyr)

# # 通用：在给定子集上，按 mod_len / mod_opus 的 mean 二分，算 dv 的均值±SE
# raw_group_plot <- function(data, dv, mod_len, mod_opus, title, ylab, fname,
#                            subset_expr = NULL) {
#   d <- data
#   if (!is.null(subset_expr)) d <- d[with(d, eval(parse(text = subset_expr))), ]
  
#   build <- function(df, mod, lo_lab, hi_lab) {
#     df <- df[!is.na(df[[mod]]) & !is.na(df[[dv]]), ]
#     df$grp <- ifelse(df[[mod]] > mean(df[[mod]]), hi_lab, lo_lab)
#     df %>% group_by(grp) %>%
#       summarise(mean = mean(.data[[dv]]), sd = sd(.data[[dv]]),
#                 n = n(), se = sd / sqrt(n), .groups = "drop")
#   }
  
#   out <- bind_rows(build(d, mod_len,  "len_low",  "len_high"),
#                    build(d, mod_opus, "opus_low", "opus_high"))
#   out$x <- c(len_low = 0.9, len_high = 1.0, opus_low = 1.1, opus_high = 1.2)[out$grp]
#   print(out)
  
#   p <- ggplot(out, aes(x = x, y = mean, shape = grp)) +
#     geom_errorbar(aes(ymin = mean - se, ymax = mean + se), width = 0.02) +
#     geom_point(size = 3) +
#     scale_shape_manual(
#       values = c(len_low = 2, len_high = 17, opus_low = 0, opus_high = 15),
#       breaks = c("len_high","len_low","opus_high","opus_low"),
#       labels = c("high length","low length","high Opus","low Opus")) +
#     scale_x_continuous(limits = c(0.8, 1.3), breaks = NULL) +
#     labs(title = title, x = NULL, y = ylab) +
#     theme_classic() +
#     theme(legend.position = c(0.98, 0.98), legend.justification = c(1, 1),
#           legend.title = element_blank(),
#           legend.background = element_rect(fill = "white", colour = "black"))
  
#   ggsave(fname, p, width = 5, height = 4, dpi = 200)
#   p
# }

# # ---- Setup 1：treatment 组、且 AI 变量非零 ----
# sub1 <- "treatment==1 & log_textLengthCNAI_fillna>0 & AISimWithOpus47_fillna>0"

# raw_group_plot(mydata_AI, "log_answer_que_within7day",
#                "log_textLengthCNAI_fillna", "AISimWithOpus47_fillna",
#                "Setup 1: # human answers (log)", "mean log(# human answers)",
#                "fig1_raw.png", subset_expr = sub1)

# raw_group_plot(mydata_survival, "human_answer_event",
#                "log_textLengthCNAI_fillna", "AISimWithOpus47_fillna",
#                "Setup 1: first human answer (event rate)", "P(event)",
#                "fig2_raw.png", subset_expr = sub1)

# # ---- Setup 2：treatment 组（先不分 control） ----
# sub2 <- "treatment==1"

# raw_group_plot(mydata_AI, "log_answer_que_within7day_other",
#                "log_textLengthCN1Ans", "SimWithOpus1Ans",
#                "Setup 2: # other answers (log)", "mean log(# other answers)",
#                "fig3_raw.png", subset_expr = sub2)

# raw_group_plot(mydata_survival, "second_answer_event",   # 如事件变量名不同请改
#                "log_textLengthCN1Ans", "SimWithOpus1Ans",
#                "Setup 2: second answer (event rate)", "P(event)",
#                "fig4_raw.png", subset_expr = sub2)

# raw_group_plot(mydata_AI, "ans1_ans2_similarity",
#                "log_textLengthCN1Ans", "SimWithOpus1Ans",
#                "Setup 2: ans1–ans2 similarity", "mean similarity",
#                "fig5_raw.png", subset_expr = sub2)











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
    baseline    = 1,   # ○ 空心圆
    length_low  = 2,   # △ 空心三角
    length_high = 17,  # ▲ 实心三角
    opus_low    = 0,   # □ 空心方块
    opus_high   = 15   # ■ 实心方块
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
      legend.position      = c(0.98, 0.98),
      legend.justification = c(1, 1),
      legend.title         = element_blank(),
      legend.background    = element_rect(fill = "white", color = "black",
                                          linewidth = 0.4),
      legend.key           = element_rect(fill = "white"),
      legend.text          = element_text(size = 8),
      plot.title           = element_text(size = 10, face = "bold"),
      axis.title.y         = element_text(size = 9),
      axis.text            = element_text(size = 9)
    )
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








































































##############################################
######## 260527 Setup 1 + AISimWithDeepseek_fillna
##############################################
models <- list()
models[["DV: # human answers"]] <- felm(log_answer_que_within7day ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[[" "]] <- felm(log_answer_que_within7day ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithDeepseek_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: harzard first human answer"]] <- coxph(surv_human_answer ~ treatment + strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models[["  "]] <- coxph(surv_human_answer ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithDeepseek_fillna)+ strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models[["Iexperience_m2"]] <- felm (Iexperience_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithDeepseek_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns
)
models[["Iinsight_m2"]] <- felm (Iinsight_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithDeepseek_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns
)
models[["Ialternative_m2"]] <- felm (Ialternative_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithDeepseek_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns
)
models[["DV: human1_human2_similarity"]] <- felm (human1_human2_similarity ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["    "]] <- felm (human1_human2_similarity ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithDeepseek_fillna )
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "Projects/MISQ/MISQ round 2/analysis/outputs/explore260527_SimWithDeepseek-Setup1.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
)

##############################################
######## 260527 Setup 2 + AISimWithDeepseek_fillna
##############################################
models <- list()
models[["DV: # other answers"]] <- felm(log_answer_que_within7day_other ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[[" "]] <- felm(log_answer_que_within7day_other ~ treatment+treatment*(log_textLengthCN1Ans + SimWithDeepseek1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: harzard second answer"]] <- coxph(surv_second_answer ~ treatment + strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models[["  "]] <- coxph(surv_second_answer ~ treatment+treatment*(log_textLengthCN1Ans + SimWithDeepseek1Ans)+ strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models[["Iexperience_m2"]] <- felm (Iexperience_m2 ~ treatment + treatment*(log_textLengthCN1Ans + SimWithDeepseek1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_secondAns
)
models[["Iinsight_m2"]] <- felm (Iinsight_m2 ~ treatment + treatment*(log_textLengthCN1Ans + SimWithDeepseek1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_secondAns
)
models[["Ialternative_m2"]] <- felm (Ialternative_m2 ~ treatment + treatment*(log_textLengthCN1Ans + SimWithDeepseek1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_secondAns
)
models[["DV: ans1_ans2_similarity"]] <- felm (ans1_ans2_similarity ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["   "]] <- felm (ans1_ans2_similarity ~ treatment+treatment*(log_textLengthCN1Ans + SimWithDeepseek1Ans )
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "Projects/MISQ/MISQ round 2/analysis/outputs/explore260527_SimWithDeepseek-Setup2.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
)
















































# 对于mydata_AI_human1_human2_handleanchor（human1_human2变量），只要一个questionURL的resp_id==1/2的answerer任何一个的is_accept_similarity_anchor为1，那么就不包含这个数据
# 首先提取出mydata_answer的resp_id==1/2的数据里面任何一个的is_accept_similarity_anchor为1，的questionURL
# 从mydata_AI里面去除这个questionURL的问题，得到mydata_AI_human1_human2_handleanchor
mydata_answer_firstHumanAns_handleanchor <- filter(mydata_answer_firstHumanAns, is_accept_similarity_anchor != 1)

anchor_questionURL <- unique(
  mydata_answer$questionURL[
    mydata_answer$resp_id %in% c(1, 2) &
    mydata_answer$is_accept_similarity_anchor == 1
  ]
)
mydata_AI_human1_human2_handleanchor <- mydata_AI[
  !(mydata_AI$questionURL %in% anchor_questionURL),
]

# 对于mydata_AI_ans1_ans2_handleanchor（ans1_ans2_similarity变量）
# 首先提取出mydata_answer里面treatment==1的，且resp_id==1的数据里面任何一个的is_accept_similarity_anchor为1，的treatment_questionURL
# 然后提取出mydata_answer里面treatment==0的，且resp_id==1/2的数据里面任何一个的is_accept_similarity_anchor为1，的control_questionURL
# 从mydata_AI里面去除这些treatment_questionURL和control_questionURL的问题，得到mydata_AI_ans1_ans2_handleanchor
mydata_answer_secondAns_handleanchor <- filter(mydata_answer_secondAns, is_accept_similarity_anchor != 1)

treatment_questionURL <- unique(
  mydata_answer$questionURL[
    mydata_answer$treatment == 1 &
    mydata_answer$resp_id == 1 &
    mydata_answer$is_accept_similarity_anchor == 1
  ]
)
control_questionURL <- unique(
  mydata_answer$questionURL[
    mydata_answer$treatment == 0 &
    mydata_answer$resp_id %in% c(1, 2) &
    mydata_answer$is_accept_similarity_anchor == 1
  ]
)
mydata_AI_ans1_ans2_handleanchor <- mydata_AI[
  !(mydata_AI$questionURL %in% c(treatment_questionURL, control_questionURL)),
]


##############################################
######## 260527 Setup 1 + AISimWithAccept_fillna (Accepted Anchor handled)
##############################################
models <- list()
models[["DV: # human answers"]] <- felm(log_answer_que_within7day ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[[" "]] <- felm(log_answer_que_within7day ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithAccept_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: harzard first human answer"]] <- coxph(surv_human_answer ~ treatment + strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models[["  "]] <- coxph(surv_human_answer ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithAccept_fillna)+ strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models[["Iexperience_m2"]] <- felm (Iexperience_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithAccept_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns_handleanchor
)
models[["Iinsight_m2"]] <- felm (Iinsight_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithAccept_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns_handleanchor
)
models[["Ialternative_m2"]] <- felm (Ialternative_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithAccept_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns_handleanchor
)
models[["DV: human1_human2_similarity"]] <- felm (human1_human2_similarity ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_human1_human2_handleanchor
)
models[["    "]] <- felm (human1_human2_similarity ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithAccept_fillna )
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_human1_human2_handleanchor
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "Projects/MISQ/MISQ round 2/analysis/outputs/explore260527_handleanchor_SimWithAccept-Setup1.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
)

##############################################
######## 260527 Setup 2 + AISimWithAccept_fillna (Accepted Anchor handled)
##############################################
models <- list()
models[["DV: # other answers"]] <- felm(log_answer_que_within7day_other ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[[" "]] <- felm(log_answer_que_within7day_other ~ treatment+treatment*(log_textLengthCN1Ans + SimWithAccept1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: harzard second answer"]] <- coxph(surv_second_answer ~ treatment + strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models[["  "]] <- coxph(surv_second_answer ~ treatment+treatment*(log_textLengthCN1Ans + SimWithAccept1Ans)+ strata(dayofyear)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
      data = mydata_survival, ties = "efron"
)
models[["Iexperience_m2"]] <- felm (Iexperience_m2 ~ treatment + treatment*(log_textLengthCN1Ans + SimWithAccept1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_secondAns_handleanchor
)
models[["Iinsight_m2"]] <- felm (Iinsight_m2 ~ treatment + treatment*(log_textLengthCN1Ans + SimWithAccept1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_secondAns_handleanchor
)
models[["Ialternative_m2"]] <- felm (Ialternative_m2 ~ treatment + treatment*(log_textLengthCN1Ans + SimWithAccept1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_secondAns_handleanchor
)
models[["DV: ans1_ans2_similarity"]] <- felm (ans1_ans2_similarity ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_ans1_ans2_handleanchor
)
models[["   "]] <- felm (ans1_ans2_similarity ~ treatment+treatment*(log_textLengthCN1Ans + SimWithAccept1Ans )
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_ans1_ans2_handleanchor
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "Projects/MISQ/MISQ round 2/analysis/outputs/explore260527_handleanchor_SimWithAccept-Setup2.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
)













