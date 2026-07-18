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

mydata <- read_csv("/Users/dylanchen/Library/CloudStorage/OneDrive-Personal/data/geek-community/result/result_question_robustness_LLM.csv")
# mydata <- read_csv("/Users/dylanchen/Downloads/result_question_robustness_LLM.csv")

mydata_AI <- mydata %>%
  filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2024-12-30"))
mydata_AI_full <- mydata %>%
  filter(askTime >= as.Date("2022-01-01"))


update_data_fields <- function(df) {
      # squared term
      df$geekAsk_squared <- df$geekAsk^2
      # Indicator

      df$InActivityBeforeAsk      <- log(df$nActivityBeforeAsk + 1)
      df$InActivityBeforeResp      <- log(df$nActivityBeforeResp + 1)
      df$InActivityBeforeComment      <- log(df$nActivityBeforeComment + 1)
      df$InActivityBefore      <- log(df$nActivityBefore + 1)

      columns_to_process <- c('imgNum_ask', 'inlinecodeNum_ask', 'interlinecodeNum_ask', 'boldNum_ask', 'italicNum_ask', 'liNum_ask', 'aNum_ask', 'blockquoteNum_ask', 'hrNum_ask', 'tableNum_ask', 'interlinecodeNum_sumResp', 'aNum_sumResp', 'nFollowup_sumResp', 'nAddKnow_sumResp')
      for (var in columns_to_process) {
      df[[paste0("I", var)]] <- as.integer(df[[var]] > 0)
      }
        columns_to_process <- c('nActivityBeforeAsk', 'nActivityBeforeResp', 'nActivityBeforeComment', 'nActivityBefore', 'nActivityBeforeAsk', 'nPayback', 'nPaybackAsk', 'nPaybackResp', 'nPaybackComment', 'nPaybackCommentAsker', 'nPaybackCommentResponder', 'nPaybackCommentOthers', 'nComment_sumResp', 'nCommentAsker_sumResp', 'nCommentResponder_sumResp', 'nCommentOthers_sumResp', 'nAt_sumResp', 'nAtAsker_sumResp', 'nAtResponder_sumResp', 'nAtOthers_sumResp')
        for (var in columns_to_process) {
          df[[paste0("I", var)]] <- as.integer(df[[var]] > 0)
        }
      df$Ihiddenanswer_que <- as.integer(df$hiddenanswer_que > 0) 
      # 4Type
      df$codeFormatAsk  <- df$IinlinecodeNum_ask + df$IinterlinecodeNum_ask
      df$textFormatAsk <- df$IliNum_ask + df$IboldNum_ask + df$IitalicNum_ask
      df$layoutFormatAsk <- df$IhrNum_ask + df$IblockquoteNum_ask + df$ItableNum_ask
      df$additionalInfo  <- df$IaNum_ask + df$IimgNum_ask

      df$noaccept_gt1Resp = as.integer(df$accepted_gt1Resp==0)
      # log(x+1)
      df$log_wait1Resp_original <- log(df$wait1Resp_original+1)
      df$log_wait2Resp_original <- log(df$wait2Resp_original+1)
      df$log_wait3Resp_original <- log(df$wait3Resp_original+1)
      # df$log_deltawait2Resp_original <- log(df$deltawait2Resp_original+1)
      # df$log_deltawait3Resp_original <- log(df$deltawait3Resp_original+1)
      df$log_waitAccepted_original <- log(df$waitAccepted_original+1)
      df$log_wait1Ans_original     <- log(df$wait1Ans_original+1) 
      df$log_wait2Ans_original     <- log(df$wait2Ans_original+1) 
      df$log_wait3Ans_original     <- log(df$wait3Ans_original+1) 
      df$log_deltawait2Ans_original     <- log(df$deltawait2Ans_original+1) 
      df$log_deltawait3Ans_original     <- log(df$deltawait3Ans_original+1) 

      df$log_wait1Resp <- log(df$wait1Resp+1)
      df$log_wait2Resp <- log(df$wait2Resp+1)
      df$log_wait3Resp <- log(df$wait3Resp+1)
      df$log_waitAccepted <- log(df$waitAccepted+1)
      df$log_wait1Ans     <- log(df$wait1Ans+1) 
      df$log_wait2Ans     <- log(df$wait2Ans+1) 
      df$log_wait3Ans     <- log(df$wait3Ans+1) 
      df$log_deltawait2Ans     <- log(df$deltawait2Ans+1) 
      df$log_deltawait3Ans     <- log(df$deltawait3Ans+1) 
      
      df$log_badgeBefore_1Resp <-log(df$badgeBefore_1Resp+1)
      df$log_acceptedBefore_1Resp <-log(df$acceptedBefore_1Resp+1)
      df$log_accumGold1Ans <-log(df$accumGold1Ans+1)
      df$log_accumSilver1Ans <-log(df$accumSilver1Ans+1)
      df$log_accumCopper1Ans <-log(df$accumCopper1Ans+1)
      df$log_accumRep_ask <-log(df$accumRep_ask+4)
      df$log_accumGold_ask <-log(df$accumGold_ask+1)
      df$log_accumSilver_ask <-log(df$accumSilver_ask+1)
      df$log_accumCopper_ask <-log(df$accumCopper_ask+1)

      df$log_codeLength_sumResp     <- log(df$codeLength_sumResp+1) 
      df$log_textLengthCN_sumResp   <- log(df$textLengthCN_sumResp+1) 
      df$log_textLength_sumResp     <- log(df$textLength_sumResp+1) 
      df$log_answer_que             <- log(df$answer_que+1) 
      df$log_liNum_sumResp             <- log(df$liNum_sumResp+1) 
      df$log_masterTop5pct_sumResp  <- log(df$masterTop5pct_sumResp+1) 
      df$log_masterTop10pct_sumResp <- log(df$masterTop10pct_sumResp+1) 
      df$log_masterTop15pct_sumResp <- log(df$masterTop15pct_sumResp+1) 
      df$log_masterTop20pct_sumResp <- log(df$masterTop20pct_sumResp+1) 
      df$log_seniorTop5pct_sumResp  <- log(df$seniorTop5pct_sumResp+1) 
      df$log_seniorTop10pct_sumResp <- log(df$seniorTop10pct_sumResp+1) 
      df$log_seniorTop15pct_sumResp <- log(df$seniorTop15pct_sumResp+1) 
      df$log_seniorTop20pct_sumResp <- log(df$seniorTop20pct_sumResp+1) 
      df$log_commentOthersBefore_sumResp <- log(df$commentOthersBefore_sumResp+1) 

      df$log_preferdiscussTop5pct_sumResp  <- log(df$preferdiscussTop5pct_sumResp+1) 
      df$log_preferdiscussTop10pct_sumResp  <- log(df$preferdiscussTop10pct_sumResp+1) 
      df$log_preferdiscussTop15pct_sumResp  <- log(df$preferdiscussTop15pct_sumResp+1) 
      df$log_preferdiscussTop20pct_sumResp  <- log(df$preferdiscussTop20pct_sumResp+1) 

      df$log_rookieRespNum_sumResp  <- log(df$rookieRespNum_sumResp+1) 
      df$log_ageAvg_sumResp  <- log(df$ageAvg_sumResp+1)

      df$log_hiddenanswer_que       <- log(df$hiddenanswer_que+1) 

      df$log_neglikeRespNum_sumResp   <- log(df$neglikeRespNum_sumResp+1) 
      df$log_nolikeRespNum_sumResp    <- log(df$nolikeRespNum_sumResp+1) 
      df$log_1likeRespNum_sumResp     <- log(df$`1likeRespNum_sumResp`+1) 
      df$log_3likeRespNum_sumResp     <- log(df$`3likeRespNum_sumResp`+1) 
      df$log_5likeRespNum_sumResp     <- log(df$`5likeRespNum_sumResp`+1) 
      df$log_7likeRespNum_sumResp     <- log(df$`7likeRespNum_sumResp`+1) 
      df$log_10likeRespNum_sumResp     <- log(df$`10likeRespNum_sumResp`+1) 
      df$log_0mdRespNum_sumResp       <- log(df$`0mdRespNum_sumResp`+1) 
      df$log_1mdRespNum_sumResp       <- log(df$`1mdRespNum_sumResp`+1) 
      df$log_2mdRespNum_sumResp       <- log(df$`2mdRespNum_sumResp`+1) 
      df$log_3mdRespNum_sumResp       <- log(df$`3mdRespNum_sumResp`+1) 
      df$log_4mdRespNum_sumResp       <- log(df$`4mdRespNum_sumResp`+1) 
      df$log_5mdRespNum_sumResp       <- log(df$`5mdRespNum_sumResp`+1) 

      df$log_nPayback                <- log(df$nPayback+1) 
      df$log_nPaybackAsk                <- log(df$nPaybackAsk+1) 
      df$log_nPaybackResp                <- log(df$nPaybackResp+1) 
      df$log_nPaybackComment                <- log(df$nPaybackComment+1) 
      df$log_nPaybackCommentAsker                <- log(df$nPaybackCommentAsker+1) 
      df$log_nPaybackCommentResponder                <- log(df$nPaybackCommentResponder+1) 
      df$log_nPaybackCommentOthers                <- log(df$nPaybackCommentOthers+1) 

      df$log_nActivityBeforeAsk      <- log(df$nActivityBeforeAsk + 1)
      df$log_nActivityBeforeResp      <- log(df$nActivityBeforeResp + 1)
      df$log_nActivityBeforeComment      <- log(df$nActivityBeforeComment + 1)
      df$log_nActivityBefore      <- log(df$nActivityBefore + 1)


      df$log_interlinecodeNum_sumResp    <- log(df$interlinecodeNum_sumResp+1)
      df$log_aNum_sumResp                <- log(df$aNum_sumResp+1)
      df$log_nComment_sumResp            <- log(df$nComment_sumResp+1)
      df$log_nCommentAsker_sumResp            <- log(df$nCommentAsker_sumResp+1)
      df$log_nCommentResponder_sumResp            <- log(df$nCommentResponder_sumResp+1)
      df$log_nCommentOthers_sumResp            <- log(df$nCommentOthers_sumResp+2)
      df$log_nAt_sumResp                 <- log(df$nAt_sumResp+1)
      df$log_nAtAsker_sumResp                 <- log(df$nAtAsker_sumResp+1)
      df$log_nAtResponder_sumResp                 <- log(df$nAtResponder_sumResp+1)
      df$log_nAtOthers_sumResp                 <- log(df$nAtOthers_sumResp+4)
      df$log_nFollowup_sumResp           <- log(df$nFollowup_sumResp+1)
      df$log_nAddKnow_sumResp            <- log(df$nAddKnow_sumResp+1)

      df$log_answer_gt1Resp         <- log(df$answer_gt1Resp+1) 
      df$log_hiddenanswer_gt1Resp   <- log(df$hiddenanswer_gt1Resp+1) 
      df$log_masterTop5pct_gt1Resp  <- log(df$masterTop5pct_gt1Resp+1) 
      df$log_masterTop10pct_gt1Resp <- log(df$masterTop5pct_gt1Resp+1) 
      df$log_masterTop15pct_gt1Resp <- log(df$masterTop5pct_gt1Resp+1) 
      df$log_masterTop20pct_gt1Resp <- log(df$masterTop5pct_gt1Resp+1) 
      df$log_seniorTop5pct_gt1Resp  <- log(df$seniorTop5pct_gt1Resp+1) 
      df$log_seniorTop10pct_gt1Resp <- log(df$seniorTop5pct_gt1Resp+1) 
      df$log_seniorTop15pct_gt1Resp <- log(df$seniorTop5pct_gt1Resp+1) 
      df$log_seniorTop20pct_gt1Resp <- log(df$seniorTop5pct_gt1Resp+1) 
      df$log_codeLength_gt1Resp     <- log(df$codeLength_gt1Resp+1) 
      df$log_textLengthCN_gt1Resp   <- log(df$textLengthCN_gt1Resp+1) 
      df$log_textLength_gt1Resp     <- log(df$textLength_gt1Resp+1) 

      df$log_codeLength_2Ans     <- log(df$codeLength_2Ans+1) 
      # df$log_codeLength_gt1Ans     <- log(df$codeLength_gt1Ans+1) 
      df$log_textLength_2Ans     <- log(df$textLength_2Ans+1) 
      # df$log_textLength_gt1Ans     <- log(df$textLength_gt1Ans+1) 
      df$log_textLengthCN_2Ans     <- log(df$textLengthCN_2Ans+1) 
      # df$log_textLengthCN_gt1Ans     <- log(df$textLengthCN_gt1Ans+1) 
      df$log_accepted_2Ans     <- log(df$accepted_2Ans+1) 
      # df$log_accepted_gt1Ans     <- log(df$accepted_gt1Ans+1) 
      df$log_hiddenanswer_2Ans     <- log(df$hiddenanswer_2Ans+1) 
      # df$log_hiddenanswer_gt1Ans     <- log(df$hiddenanswer_gt1Ans+1) 
      df$log_answer_2Ans     <- log(df$answer_2Ans+1) 
      # df$log_answer_gt1Ans     <- log(df$answer_gt1Ans+1) 
      df$log_masterTop5pct_2Ans     <- log(df$masterTop5pct_2Ans+1) 
      # df$log_masterTop5pct_gt1Ans     <- log(df$masterTop5pct_gt1Ans+1) 
      df$log_masterTop10pct_2Ans     <- log(df$masterTop10pct_2Ans+1) 
      # df$log_masterTop10pct_gt1Ans     <- log(df$masterTop10pct_gt1Ans+1) 
      df$log_masterTop15pct_2Ans     <- log(df$masterTop15pct_2Ans+1) 
      # df$log_masterTop15pct_gt1Ans     <- log(df$masterTop15pct_gt1Ans+1) 
      df$log_masterTop20pct_2Ans     <- log(df$masterTop20pct_2Ans+1) 
      # df$log_masterTop20pct_gt1Ans     <- log(df$masterTop20pct_gt1Ans+1) 
      df$log_seniorTop5pct_2Ans     <- log(df$seniorTop5pct_2Ans+1) 
      # df$log_seniorTop5pct_gt1Ans     <- log(df$seniorTop5pct_gt1Ans+1) 
      df$log_seniorTop10pct_2Ans     <- log(df$seniorTop10pct_2Ans+1) 
      # df$log_seniorTop10pct_gt1Ans     <- log(df$seniorTop10pct_gt1Ans+1) 
      df$log_seniorTop15pct_2Ans     <- log(df$seniorTop15pct_2Ans+1) 
      # df$log_seniorTop15pct_gt1Ans     <- log(df$seniorTop15pct_gt1Ans+1) 
      df$log_seniorTop20pct_2Ans     <- log(df$seniorTop20pct_2Ans+1) 
      # df$log_seniorTop20pct_gt1Ans     <- log(df$seniorTop20pct_gt1Ans+1) 

      df$log_textLengthCN_ask <-log(df$textLengthCN_ask+1)
      df$log_codeLength_ask <- log(df$codeLength_ask+1)
      df$log_badgeBefore <- log(df$badgeBefore+1)
      df$log_age <- log(df$age+1)
      df$log_askBefore <- log(df$askBefore+1)
      df$log_resBefore <- log(df$resBefore+1)
      df$log_acceptedBefore <- log(df$acceptedBefore+1)

      df$log_format1Ans <-log(df$format1Ans+1)
      df$log_textLengthCN1Ans <- log(df$textLengthCN1Ans+1)
      df$log_textLength1Ans <- log(df$textLength1Ans+1)
      df$log_codeLength1Ans <- log(df$codeLength1Ans+1)

      df$log_badgeBefore1Ans  <- log(df$badgeBefore1Ans+1)
      df$log_badgeBefore2Ans  <- log(df$badgeBefore2Ans+1)
      df$log_badgeBefore_1Resp <- log(df$badgeBefore_1Resp)
      df$log_acceptedBefore1Ans  <- log(df$acceptedBefore1Ans+1)
      
      df$log_accepted1Ans  <- log(df$accepted1Ans+1)
      df$log_accepted2Ans  <- log(df$accepted2Ans+1)
      # others
      df$response1Resp     <- (1-df$noresponse1Resp) 


      # 检查并替换缺失值为0
      df$`accepted0-inf_sumResp` <- ifelse(is.na(df$`accepted0-inf_sumResp`), 0, df$`accepted0-inf_sumResp`)
      df$`accepted0-100_sumResp` <- ifelse(is.na(df$`accepted0-100_sumResp`), 0, df$`accepted0-100_sumResp`)
      df$`accepted101-200_sumResp` <- ifelse(is.na(df$`accepted101-200_sumResp`), 0, df$`accepted101-200_sumResp`)
      df$`accepted201-300_sumResp` <- ifelse(is.na(df$`accepted201-300_sumResp`), 0, df$`accepted201-300_sumResp`)
      df$`accepted301-400_sumResp` <- ifelse(is.na(df$`accepted301-400_sumResp`), 0, df$`accepted301-400_sumResp`)
      df$`accepted401-500_sumResp` <- ifelse(is.na(df$`accepted401-500_sumResp`), 0, df$`accepted401-500_sumResp`)
      df$`accepted501-600_sumResp` <- ifelse(is.na(df$`accepted501-600_sumResp`), 0, df$`accepted501-600_sumResp`)
      df$`accepted601-700_sumResp` <- ifelse(is.na(df$`accepted601-700_sumResp`), 0, df$`accepted601-700_sumResp`)
      df$`accepted701-800_sumResp` <- ifelse(is.na(df$`accepted701-800_sumResp`), 0, df$`accepted701-800_sumResp`)
      df$`accepted801-900_sumResp` <- ifelse(is.na(df$`accepted801-900_sumResp`), 0, df$`accepted801-900_sumResp`)
      df$`accepted901-1000_sumResp` <- ifelse(is.na(df$`accepted901-1000_sumResp`), 0, df$`accepted901-1000_sumResp`)
      df$`accepted1001-1100_sumResp` <- ifelse(is.na(df$`accepted1001-1100_sumResp`), 0, df$`accepted1001-1100_sumResp`)
      df$`accepted1101-1200_sumResp` <- ifelse(is.na(df$`accepted1101-1200_sumResp`), 0, df$`accepted1101-1200_sumResp`)
      df$`accepted1201-1300_sumResp` <- ifelse(is.na(df$`accepted1201-1300_sumResp`), 0, df$`accepted1201-1300_sumResp`)
      df$`accepted1301-1400_sumResp` <- ifelse(is.na(df$`accepted1301-1400_sumResp`), 0, df$`accepted1301-1400_sumResp`)
      df$`accepted1401-inf_sumResp` <- ifelse(is.na(df$`accepted1401-inf_sumResp`), 0, df$`accepted1401-inf_sumResp`)
      df$`accepted0-5_sumResp` <- ifelse(is.na(df$`accepted0-5_sumResp`), 0, df$`accepted0-5_sumResp`)
      df$`accepted6-55_sumResp` <- ifelse(is.na(df$`accepted6-55_sumResp`), 0, df$`accepted6-55_sumResp`)
      df$`accepted56-290_sumResp` <- ifelse(is.na(df$`accepted56-290_sumResp`), 0, df$`accepted56-290_sumResp`)
      df$`accepted291-1500_sumResp` <- ifelse(is.na(df$`accepted291-1500_sumResp`), 0, df$`accepted291-1500_sumResp`)


      df$`log_accepted0-inf_sumResp` <- log(df$`accepted0-inf_sumResp`+1)
      # accepted245.542471-inf_sumResp
      df$`log_accepted0-100_sumResp` <- log(df$`accepted0-100_sumResp`+1)
      df$`log_accepted101-200_sumResp` <- log(df$`accepted101-200_sumResp`+1)
      df$`log_accepted201-300_sumResp` <- log(df$`accepted201-300_sumResp`+1)
      df$`log_accepted301-400_sumResp` <- log(df$`accepted301-400_sumResp`+1)
      df$`log_accepted401-500_sumResp` <- log(df$`accepted401-500_sumResp`+1)
      df$`log_accepted501-600_sumResp` <- log(df$`accepted501-600_sumResp`+1)
      df$`log_accepted601-700_sumResp` <- log(df$`accepted601-700_sumResp`+1)
      df$`log_accepted701-800_sumResp` <- log(df$`accepted701-800_sumResp`+1)
      df$`log_accepted801-900_sumResp` <- log(df$`accepted801-900_sumResp`+1)
      df$`log_accepted901-1000_sumResp` <- log(df$`accepted901-1000_sumResp`+1)
      df$`log_accepted1001-1100_sumResp` <- log(df$`accepted1001-1100_sumResp`+1)
      df$`log_accepted1101-1200_sumResp` <- log(df$`accepted1101-1200_sumResp`+1)
      df$`log_accepted1201-1300_sumResp` <- log(df$`accepted1201-1300_sumResp`+1)
      df$`log_accepted1301-1400_sumResp` <- log(df$`accepted1301-1400_sumResp`+1)
      df$`log_accepted1401-inf_sumResp` <- log(df$`accepted1401-inf_sumResp`+1)
      df$`log_accepted0-5_sumResp` <- log(df$`accepted0-5_sumResp`+1)
      df$`log_accepted6-55_sumResp` <- log(df$`accepted6-55_sumResp`+1)
      df$`log_accepted56-290_sumResp` <- log(df$`accepted56-290_sumResp`+1)
      df$`log_accepted291-1500_sumResp` <- log(df$`accepted291-1500_sumResp`+1)

      df$log_views_que <- log(df$views_que+1)
      return(df)
}

# mydata        <- update_data_fields(mydata)
# mydata_1y     <- update_data_fields(mydata_1y)
# mydata_5y     <- update_data_fields(mydata_5y)
# mydata_7y     <- update_data_fields(mydata_7y)
# mydata_golden <- update_data_fields(mydata_golden)

mydata_AI <- update_data_fields(mydata_AI)
mydata_AI_full <- update_data_fields(mydata_AI_full)




calculate_time_info <- function(df, askTime_col, suffix = "") {
  # 使用 timeDate 包获取指定年份的节假日列表
  get_holidays <- function(year) {
    holidays <- holidayNYSE(year)
    return(as.Date(holidays@Data))
  }
  
  # 获取数据框中年份的唯一值
  unique_years <- unique(year(as.Date(df[[askTime_col]])))
  
  # 获取所有唯一年份的节假日
  holidays <- unlist(lapply(unique_years, get_holidays))
  
  df <- df %>%
    mutate(
      !!paste0("year", suffix) := format(as.Date(get(askTime_col)), "%Y"),
      !!paste0("monthofyear", suffix) := as.Date(format(as.Date(get(askTime_col)), "%Y-%m-01")),
      !!paste0("dayofyear", suffix) := as.Date(format(as.Date(get(askTime_col)), "%Y-%m-%d")),
      !!paste0("weekofyear", suffix) := floor_date(get(paste0("dayofyear", suffix)), unit = "weeks"),
      !!paste0("weekofmonth", suffix) := week(get(paste0("dayofyear", suffix))) - week(floor_date(get(paste0("dayofyear", suffix)), unit = "month")) + 1,
      #!!paste0("dayofweek", suffix) := wday(get(paste0("dayofyear", suffix)), label = TRUE),
      !!paste0("isHoliday", suffix) := ifelse(get(paste0("dayofyear", suffix)) %in% holidays, 1, 0),
      !!paste0("isWeekend", suffix) := ifelse(wday(get(paste0("dayofyear", suffix))) %in% c(1, 7), 1, 0)  # 1 表示周日，7 表示周六
    )
  
  return(df)
}
mydata_AI <- calculate_time_info(mydata_AI, "askTime", "")
mydata_AI_full <- calculate_time_info(mydata_AI_full, "askTime", "")

mydata_AI$age_que <- as.integer(as.Date(mydata_AI$crawldate)-as.Date(mydata_AI$askTime))
mydata_AI_full$age_que <- as.integer(as.Date(mydata_AI_full$crawldate)-as.Date(mydata_AI_full$askTime))






df <- read.csv("./preAI/script/2024 MS submission/tag classification/tagName_classified_GBK.csv", header = TRUE, sep = ",", fileEncoding = "GBK", stringsAsFactors = FALSE)
df$tagName <- replace_na(df$tagName, "NA") # 文本处理问题，并非恶意增加分类
# summary(is.na(df$tagName))
unique(df$tagName)

mydata_AI$tagName <- str_extract(mydata_AI$tagURL, "(?<=/t/).*(?=/questions)") # 提取/t/和/questions之间的内容
mydata_AI$tagName <- URLdecode(mydata_AI$tagName) # 将提取的内容转化为中文字符
mydata_AI_full$tagName <- str_extract(mydata_AI_full$tagURL, "(?<=/t/).*(?=/questions)") # 提取/t/和/questions之间的内容
mydata_AI_full$tagName <- URLdecode(mydata_AI_full$tagName) # 将提取的内容转化为中文字符


mydata_AI <- left_join(mydata_AI, df, by = c("tagName" = "tagName")) # 使用left_join()函数将mydata_AI和df进行左连接
mydata_AI_full <- left_join(mydata_AI_full, df, by = c("tagName" = "tagName")) # 使用left_join()函数将mydata_AI和df进行左连接
table(mydata_AI$category)
18+37+40+93+114+175+476+545+38+2077
44+68+119+331+270+501+1691+1680+125+7327



mydata_AI$category1 = ifelse(mydata_AI$category=='Web and Mobile Development',1,0)
mydata_AI$category2 = ifelse(mydata_AI$category=='Software Design and Architecture',1,0)
mydata_AI$category3 = ifelse(mydata_AI$category=='DevOps and Cloud Computing',1,0)
mydata_AI$category4 = ifelse(mydata_AI$category=='Databases',1,0)
mydata_AI$category5 = ifelse(mydata_AI$category=='Computer Networks and Systems',1,0)
mydata_AI$category6 = ifelse(mydata_AI$category=='Data Science and Machine Learning',1,0)
mydata_AI$category7 = ifelse(mydata_AI$category=='Development Tools and Environment',1,0)
mydata_AI$category8 = ifelse(mydata_AI$category=='Programming Languages',1,0)
mydata_AI$category9 = ifelse(mydata_AI$category=='Career and Professional Development',1,0)
mydata_AI$category10 = ifelse(mydata_AI$category=='Other',1,0)
mydata_AI$allCategory = mydata_AI$category1 + mydata_AI$category2 + mydata_AI$category3 + mydata_AI$category4 + mydata_AI$category5 + mydata_AI$category6 + mydata_AI$category7 + mydata_AI$category8 + mydata_AI$category9 + mydata_AI$category10
summary(mydata_AI$allCategory)
mydata_AI_full$category1 = ifelse(mydata_AI_full$category=='Web and Mobile Development',1,0)
mydata_AI_full$category2 = ifelse(mydata_AI_full$category=='Software Design and Architecture',1,0)
mydata_AI_full$category3 = ifelse(mydata_AI_full$category=='DevOps and Cloud Computing',1,0)
mydata_AI_full$category4 = ifelse(mydata_AI_full$category=='Databases',1,0)
mydata_AI_full$category5 = ifelse(mydata_AI_full$category=='Computer Networks and Systems',1,0)
mydata_AI_full$category6 = ifelse(mydata_AI_full$category=='Data Science and Machine Learning',1,0)
mydata_AI_full$category7 = ifelse(mydata_AI_full$category=='Development Tools and Environment',1,0)
mydata_AI_full$category8 = ifelse(mydata_AI_full$category=='Programming Languages',1,0)
mydata_AI_full$category9 = ifelse(mydata_AI_full$category=='Career and Professional Development',1,0)
mydata_AI_full$category10 = ifelse(mydata_AI_full$category=='Other',1,0)
mydata_AI_full$allCategory = mydata_AI_full$category1 + mydata_AI_full$category2 + mydata_AI_full$category3 + mydata_AI_full$category4 + mydata_AI_full$category5 + mydata_AI_full$category6 + mydata_AI_full$category7 + mydata_AI_full$category8 + mydata_AI_full$category9 + mydata_AI_full$category10
summary(mydata_AI_full$allCategory)


mydata_AI_isAI <- mydata_AI %>% filter(preAI == 1)
mydata_AI_isnotAI <- mydata_AI %>% filter(preAI != 1)


library(haven)
# 创建一个备份
mydata_export <- mydata_AI
# 获取原始变量名
mydata_export <- mydata_export %>%
  rename(
    # asker_acceptedBefore_allsite 系列（4个：1m, 2m, 3m, all）
    asker_accBef_1m = asker_acceptedBefore_allsite_1m,
    asker_accBef_2m = asker_acceptedBefore_allsite_2m,
    asker_accBef_3m = asker_acceptedBefore_allsite_3m,
    
    # asker_nActivityBeforeAsk_allsite 系列（4个：1m, 2m, 3m, all）
    asker_nActAsk_1m = asker_nActivityBeforeAsk_allsite_1m,
    asker_nActAsk_2m = asker_nActivityBeforeAsk_allsite_2m,
    asker_nActAsk_3m = asker_nActivityBeforeAsk_allsite_3m,
    
    # asker_nActivityBeforeResp_allsite 系列（4个：1m, 2m, 3m, all）
    asker_nActResp_1m = asker_nActivityBeforeResp_allsite_1m,
    asker_nActResp_2m = asker_nActivityBeforeResp_allsite_2m,
    asker_nActResp_3m = asker_nActivityBeforeResp_allsite_3m,
    
    # asker_nActivityBeforeComment_allsite 系列（4个：1m, 2m, 3m, all）
    asker_nActCmt_1m = asker_nActivityBeforeComment_allsite_1m,
    asker_nActCmt_2m = asker_nActivityBeforeComment_allsite_2m,
    asker_nActCmt_3m = asker_nActivityBeforeComment_allsite_3m
  )

original_names <- names(mydata_export)
# 清理变量名函数
clean_stata_names <- function(names) {
  cleaned_names <- names
  # 1. 替换特殊字符为下划线
  cleaned_names <- gsub("[.-]", "_", cleaned_names)
  cleaned_names <- gsub("[^[:alnum:]_]", "_", cleaned_names)
  # 2. 如果以数字开头，添加前缀
  cleaned_names <- ifelse(grepl("^[0-9]", cleaned_names), 
                          paste0("v_", cleaned_names), 
                          cleaned_names)
  # 3. 截断到32个字符
  cleaned_names <- substr(cleaned_names, 1, 32)
  # 4. 处理重复的名称
  duplicated_names <- duplicated(cleaned_names)
  if(any(duplicated_names)) {
    for(i in which(duplicated_names)) {
      # 为重复的名称添加数字后缀
      base_name <- substr(cleaned_names[i], 1, 29)
      cleaned_names[i] <- paste0(base_name, "_", i)
      # 确保不超过32个字符
      cleaned_names[i] <- substr(cleaned_names[i], 1, 32)
    }
  }
  return(cleaned_names)
}
# 应用清理函数
new_names <- clean_stata_names(original_names)
# 重命名变量
names(mydata_export) <- new_names
# 显示变量名的变化（可选，用于检查）
name_mapping <- data.frame(
  original = original_names,
  new = new_names,
  changed = original_names != new_names
)
# 显示被修改的变量名
cat("以下变量名被修改:\n")
print(name_mapping[name_mapping$changed, ])
# 导出为.dta文件
write_dta(mydata_export, "/Users/dylanchen/Library/CloudStorage/OneDrive-Personal/projects/geek-community/panel/mydata_AI.dta")

cat("\n文件已成功导出!")




mydata_answer <- read_csv("/Users/dylanchen/Library/CloudStorage/OneDrive-Personal/data/geek-community/result/result_answer_robustness.csv")
mydata_answer_full <- mydata_answer %>%
  filter(askTime >= as.Date("2022-01-01"))
mydata_answer <- mydata_answer %>%
  filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2024-12-30"))

update_variables <- function(mydata_answer) {
      mydata_answer$log_textLengthCN_ask = log(mydata_answer$textLengthCN_ask+1)
      mydata_answer$log_codeLength_ask = log(mydata_answer$codeLength_ask+1)
      mydata_answer$log_badgeBefore_ask = log(mydata_answer$badgeBefore_ask+1)
      mydata_answer$log_badgeBefore = log(mydata_answer$badgeBefore+1)
      mydata_answer$log_acceptedBefore = log(mydata_answer$acceptedBefore+1)
      mydata_answer$log_commentOthersBefore = log(mydata_answer$commentOthersBefore+1)
      mydata_answer$ratioAcceptedResp_adjusted = (mydata_answer$acceptedBefore+(1.98^2/(2*mydata_answer$resBefore+1))-1) / (mydata_answer$resBefore+(1.98^2)-2)
      mydata_answer$log_ratioAcceptedResp = log(mydata_answer$ratioAcceptedResp+1)
      mydata_answer$log_ratioNetlikeResp = log(mydata_answer$ratioNetlikeResp++4)
      mydata_answer$IimgNum_ask = ifelse(mydata_answer$imgNum_ask>0,1,0)
      mydata_answer$IaNum_ask = ifelse(mydata_answer$aNum_ask>0,1,0)
      mydata_answer$IblockquoteNum_ask = ifelse(mydata_answer$blockquoteNum_ask>0,1,0)
      mydata_answer$ItableNum_ask = ifelse(mydata_answer$tableNum_ask>0,1,0)
      mydata_answer$log_accumRep_ask = log(mydata_answer$accumRep_ask+4)
      mydata_answer$log_accumRep = log(mydata_answer$accumRep+3)

      mydata_answer$log_wait1Ans_original = log(mydata_answer$wait1Ans_original+1)

      mydata_answer$year <- format(as.Date(mydata_answer$askTime), "%Y")
      mydata_answer$monthofyear <- as.Date(format(as.Date(mydata_answer$askTime), "%Y-%m-01"))
      mydata_answer$dayofyear <- as.Date(format(as.Date(mydata_answer$askTime), "%Y-%m-%d"))
      mydata_answer$waitAnswer_power2 <- mydata_answer$waitAnswer^2
      mydata_answer$log_waitAnswer <- log(mydata_answer$waitAnswer+1)
      mydata_answer$log_waitAnswer_power2 <- mydata_answer$log_waitAnswer^2
      mydata_answer$cmnTimeID_power2 <- mydata_answer$cmnTimeID^2

      df <- read.csv("./preAI/script/2024 MS submission/tag classification/tagName_classified_GBK.csv", header = TRUE, sep = ",", fileEncoding = "GBK", stringsAsFactors = FALSE)
      # df
      df$tagName <- replace_na(df$tagName, "NA") # 文本处理问题，并非恶意增加分类
      summary(is.na(df$tagName))
      # unique(df$tagName)
      mydata_answer$tagName <- str_extract(mydata_answer$tagURL, "(?<=/t/).*(?=/questions)") # 提取/t/和/questions之间的内容
      mydata_answer$tagName <- URLdecode(mydata_answer$tagName) # 将提取的内容转化为中文字符
      summary(is.na(mydata_answer$tagName))
      unique(mydata_answer$tagName)
      mydata_answer <- left_join(mydata_answer, df, by = c("tagName" = "tagName")) # 使用left_join()函数将mydata_AI和df进行左连接
      # table(mydata_answer$category)

      summary(mydata_answer$ratioAcceptedResp)
      mydata_answer$highMotivation = ifelse(mydata_answer$ratioAcceptedResp >=0.2977, 1, 0)
      summary(mydata_answer$highMotivation)

      mydata_answer$year <- format(as.Date(mydata_answer$askTime), "%Y")
      mydata_answer$monthofyear <- as.Date(format(as.Date(mydata_answer$askTime), "%Y-%m-01"))
      mydata_answer$dayofyear <- as.Date(format(as.Date(mydata_answer$askTime), "%Y-%m-%d"))
      summary(mydata_answer$log_commentOthersBefore)

      mydata_answer$category1 = ifelse(mydata_answer$category=='Web and Mobile Development',1,0)
      mydata_answer$category2 = ifelse(mydata_answer$category=='Software Design and Architecture',1,0)
      mydata_answer$category3 = ifelse(mydata_answer$category=='DevOps and Cloud Computing',1,0)
      mydata_answer$category4 = ifelse(mydata_answer$category=='Databases',1,0)
      mydata_answer$category5 = ifelse(mydata_answer$category=='Computer Networks and Systems',1,0)
      mydata_answer$category6 = ifelse(mydata_answer$category=='Data Science and Machine Learning',1,0)
      mydata_answer$category7 = ifelse(mydata_answer$category=='Development Tools and Environment',1,0)
      mydata_answer$category8 = ifelse(mydata_answer$category=='Programming Languages',1,0)
      mydata_answer$category9 = ifelse(mydata_answer$category=='Career and Professional Development',1,0)
      mydata_answer$category10 = ifelse(mydata_answer$category=='Other',1,0)
      mydata_answer$allCategory = mydata_answer$category1 + mydata_answer$category2 + mydata_answer$category3 + mydata_answer$category4 + mydata_answer$category5 + mydata_answer$category6 + mydata_answer$category7 + mydata_answer$category8 + mydata_answer$category9 + mydata_answer$category10
      summary(mydata_answer$allCategory)

      mydata_answer$log_textLengthCN1Ans = log(mydata_answer$textLengthCN1Ans+1)
      mydata_answer$log_textLengthCN = log(mydata_answer$textLengthCN+1)

      mydata_answer$answer_timing <- as.Date(format(as.Date(mydata_answer$date), "%Y-%m-%d"))
      mydata_answer$answer_age <- as.integer(as.Date(mydata_answer$crawldate)-as.Date(mydata_answer$date))
      mydata_answer$answer_age_power2 <- mydata_answer$answer_age^2
      mydata_answer$answer_age_power3 <- mydata_answer$answer_age^3

      mydata_answer <- calculate_time_info(mydata_answer, "date", "_answer")
}

# Example usage:
mydata_answer <- update_variables(mydata_answer)
mydata_answer_full <- update_variables(mydata_answer_full)
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
  "log_age", "log_askBefore", "log_resBefore"
)
mydata_answer <- mydata_answer %>%
  left_join(
    mydata_AI_full %>% select(questionURL, all_of(vars_to_add)),
    by = "questionURL"
  )
mydata_answer_full <- mydata_answer_full %>%
  left_join(
    mydata_AI_full %>% select(questionURL, all_of(vars_to_add)),
    by = "questionURL"
  )



library(haven)
# 创建一个备份
mydata_export <- mydata_answer
# 获取原始变量名
mydata_export <- mydata_export %>%
  rename(
    # asker_acceptedBefore_allsite 系列（4个：1m, 2m, 3m, all）
    asker_accBef_1m = asker_acceptedBefore_allsite_1m,
    asker_accBef_2m = asker_acceptedBefore_allsite_2m,
    asker_accBef_3m = asker_acceptedBefore_allsite_3m,
    
    # asker_nActivityBeforeAsk_allsite 系列（4个：1m, 2m, 3m, all）
    asker_nActAsk_1m = asker_nActivityBeforeAsk_allsite_1m,
    asker_nActAsk_2m = asker_nActivityBeforeAsk_allsite_2m,
    asker_nActAsk_3m = asker_nActivityBeforeAsk_allsite_3m,
    
    # asker_nActivityBeforeResp_allsite 系列（4个：1m, 2m, 3m, all）
    asker_nActResp_1m = asker_nActivityBeforeResp_allsite_1m,
    asker_nActResp_2m = asker_nActivityBeforeResp_allsite_2m,
    asker_nActResp_3m = asker_nActivityBeforeResp_allsite_3m,
    
    # asker_nActivityBeforeComment_allsite 系列（4个：1m, 2m, 3m, all）
    asker_nActCmt_1m = asker_nActivityBeforeComment_allsite_1m,
    asker_nActCmt_2m = asker_nActivityBeforeComment_allsite_2m,
    asker_nActCmt_3m = asker_nActivityBeforeComment_allsite_3m
  )

original_names <- names(mydata_export)
# 清理变量名函数
clean_stata_names <- function(names) {
  cleaned_names <- names
  # 1. 替换特殊字符为下划线
  cleaned_names <- gsub("[.-]", "_", cleaned_names)
  cleaned_names <- gsub("[^[:alnum:]_]", "_", cleaned_names)
  # 2. 如果以数字开头，添加前缀
  cleaned_names <- ifelse(grepl("^[0-9]", cleaned_names), 
                          paste0("v_", cleaned_names), 
                          cleaned_names)
  # 3. 截断到32个字符
  cleaned_names <- substr(cleaned_names, 1, 32)
  # 4. 处理重复的名称
  duplicated_names <- duplicated(cleaned_names)
  if(any(duplicated_names)) {
    for(i in which(duplicated_names)) {
      # 为重复的名称添加数字后缀
      base_name <- substr(cleaned_names[i], 1, 29)
      cleaned_names[i] <- paste0(base_name, "_", i)
      # 确保不超过32个字符
      cleaned_names[i] <- substr(cleaned_names[i], 1, 32)
    }
  }
  return(cleaned_names)
}
# 应用清理函数
new_names <- clean_stata_names(original_names)
# 重命名变量
names(mydata_export) <- new_names
# 显示变量名的变化（可选，用于检查）
name_mapping <- data.frame(
  original = original_names,
  new = new_names,
  changed = original_names != new_names
)
# 显示被修改的变量名
cat("以下变量名被修改:\n")
print(name_mapping[name_mapping$changed, ])
# 导出为.dta文件
write_dta(mydata_export, "/Users/dylanchen/Library/CloudStorage/OneDrive-Personal/projects/geek-community/panel/mydata_answer.dta")







# ==============================
# Table 2. Descriptive statistics of main variables
# ==============================
calculate_stats <- function(data, data_AI, data_NoAI, variables) {
  # 创建一个空的数据框来存储结果
  results <- data.frame(
    Variable = character(),
    All_Sample_Mean = numeric(),
    All_Sample_SD = numeric(),
    AI_Sample_Mean = numeric(),
    AI_Sample_SD = numeric(),
    NoAI_Sample_Mean = numeric(),
    NoAI_Sample_SD = numeric(),
    Min = numeric(),
    Max = numeric(),
    stringsAsFactors = FALSE
  )
  
  # 遍历所有变量，计算并添加统计数据到结果数据框
  for (var in variables) {
    if (var %in% names(data)) {
      all_mean <- round(mean(data[[var]], na.rm = TRUE), 3)
      all_sd <- round(sd(data[[var]], na.rm = TRUE), 3)
      ai_mean <- round(mean(data_AI[[var]], na.rm = TRUE), 3)
      ai_sd <- round(sd(data_AI[[var]], na.rm = TRUE), 3)
      noai_mean <- round(mean(data_NoAI[[var]], na.rm = TRUE), 3)
      noai_sd <- round(sd(data_NoAI[[var]], na.rm = TRUE), 3)
      min_val <- round(min(data[[var]], na.rm = TRUE), 3)
      max_val <- round(max(data[[var]], na.rm = TRUE), 3)
      
      # 添加到结果数据框
      results <- rbind(results, data.frame(
        Variable = var,
        All_Sample_Mean = all_mean,
        All_Sample_SD = all_sd,
        AI_Sample_Mean = ai_mean,
        AI_Sample_SD = ai_sd,
        NoAI_Sample_Mean = noai_mean,
        NoAI_Sample_SD = noai_sd,
        Min = min_val,
        Max = max_val
      ))
    } else {
      cat("Variable", var, "not found in the dataset.\n")
    }
  }
  
  return(results)
}

# 更新数据字段
mydata_AI <- update_data_fields(mydata_AI)
mydata_AI_isAI <- mydata_AI %>% filter(preAI == 1)
mydata_AI_isnotAI <- mydata_AI %>% filter(preAI != 1)

# 调用函数计算统计量
variables <- c("textLengthCN_ask", "answer_que", "accumRep_ask", "answer_que_within7day", "response1Resp", "accept", "netlikeNum_sumResp", "accumRep_ask")
results <- calculate_stats(mydata_AI, mydata_AI_isAI, mydata_AI_isnotAI, variables)
print(results)







table(mydata_answer$netlikeNum)

length(mydata_answer$netlikeNum)

3/4670

963/3613







# ============================================================
# revision round 1: main model - gradually adding
# ============================================================
summary(mydata_AI$netlikeAvg_sumResp)
summary(mydata_AI$netlikeNum_sumResp)
models <- list()
models[["nope"]] <- felm (log_answer_que_within7day ~ preAI
      | dayofyear | 0 | 0, data = mydata_AI)
models[["question"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      | dayofyear | 0 | 0, data = mydata_AI)
models[["category"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      | dayofyear | 0 | 0, data = mydata_AI)
models[["questioner"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)

models[["no"]] <- felm (netlikeNum ~ preAI
      | answer_timing | 0 | 0, data = mydata_answer
)
models[["que"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      | answer_timing | 0 | 0, data = mydata_answer
)
models[["cat"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      | answer_timing | 0 | 0, data = mydata_answer
)
models[["quer"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/main model - gradually adding.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)


# ============================================================
# revision round 1: robustness - alternative specifcations
# ============================================================
models <- list()
models[["baseline"]] <- felm(
  log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)
models[["questioner FE"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear + userURL_ask | 0 | 0, data = mydata_AI)
library(lme4)
library(reformulas)
models[["random effect"]] <- lmer(
  log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
    + factor(dayofyear)
    + (1 | userURL_ask),   # questioner 随机效应
  data = mydata_AI,
  REML = TRUE
)
# install.packages(c("pscl", "clubSandwich"))
library(pscl)
library(clubSandwich)
# 2) 你已有的 Poisson FE（计数因变量）
models[["poisson (answerNum)"]] <- feglm(
  answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
  family = "poisson",
  fixef = "dayofyear",   # 固定效应
  data = mydata_AI
)
# 3) Zero-Inflated Poisson (ZIP) —— 计数模型 + 零膨胀通道
# 新增：Zero-Inflated Poisson（仅固定效应，无随机项）
models[["ZIP (answerNum)"]] <- zeroinfl(
  answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
    + factor(dayofyear)    # 日度固定效应
  | 1,                     # 零通道：仅截距；如需让变量影响结构性零，可改为 | preAI + ...
  dist = "poisson",
  data = mydata_AI
)
# 4) Zero-Inflated Negative Binomial (ZINB)
# 新增：Zero-Inflated Negative Binomial（仅固定效应）
models[["ZINB (answerNum)"]] <- zeroinfl(
  answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
    + factor(dayofyear)
  | 1,
  dist = "negbin",
  data = mydata_AI
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/robustness - alternative specification 1.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)

models <- list()
models[["main model"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | 0 | 0 | 0, data = mydata_answer
)
models[["linear age"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + answer_age 
      | 0 | 0 | 0, data = mydata_answer
)
models[["qur age"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + answer_age + answer_age_power2
      | 0 | 0 | 0, data = mydata_answer
)
models[["cubic age"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + answer_age + answer_age_power2 + answer_age_power3
      | 0 | 0 | 0, data = mydata_answer
)
models[["answertiming FE"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer
)
summary(mydata_answer$netlikeNum)
mydata_answer <- mydata_answer %>% 
  mutate(
    netlikeNum_positive = netlikeNum + 3,
    log_netlikeNum_positive = log(netlikeNum_positive + 1)
    )
# models[["answertiming FE"]] <- felm (log_netlikeNum_positive ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | answer_timing | 0 | 0, data = mydata_answer
# )
models[["poisson (netlikeNum)"]] <- feglm(
  netlikeNum_positive ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
  family = "poisson",
  fixef = "answer_timing",   # 固定效应
  data = mydata_answer
)
summary(mydata_answer$netlikeNum_positive)
# models[["netlikeNum_sumResp"]] <- felm (netlikeNum_sumResp ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | dayofyear | 0 | 0, data = mydata_AI)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/robustness - alternative specification 2.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)



# ============================================================
# revision round 1: robustness - changing time frame
# ============================================================
mydata_AI_within30 <- mydata_AI %>%
  filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2023-10-13"))
mydata_AI_within60 <- mydata_AI %>%
  filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2023-11-13"))
mydata_AI_within90 <- mydata_AI %>%
  filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2023-12-13"))

mydata_answer_within30 <- mydata_answer %>%
  filter(date >= as.Date("2023-09-13") & date <= as.Date("2023-10-13"))
mydata_answer_within60 <- mydata_answer %>%
  filter(date >= as.Date("2023-09-13") & date <= as.Date("2023-11-13"))
mydata_answer_within90 <- mydata_answer %>%
  filter(date >= as.Date("2023-09-13") & date <= as.Date("2023-12-13"))


mean(mydata_AI$answer_que_within7day)
sd(mydata_AI$answer_que_within7day)
mydata_AI_isAI <- mydata_AI %>% filter(preAI == 1)
mydata_AI_isnotAI <- mydata_AI %>% filter(preAI == 0)
mean(mydata_AI_isAI$answer_que_within7day)
sd(mydata_AI_isAI$answer_que_within7day)
mean(mydata_AI_isnotAI$answer_que_within7day)
sd(mydata_AI_isnotAI$answer_que_within7day)

mean(mydata_answer$netlikeNum)
sd(mydata_answer$netlikeNum)


models <- list()
models[["DV-all"]] <- felm (log_answer_que ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
models[["DV-3day"]] <- felm (log_answer_que_within3day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
models[["DV-7day"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
models[["DV-14day"]] <- felm (log_answer_que_within14day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
models[["within30"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_within30)
models[["within60"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_within60)
models[["within90"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_within90)
# models[["answertiming FE"]] <- felm (netlikeNum ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | answer_timing | 0 | 0, data = mydata_answer
# )
# models[["M2-30"]] <- felm (netlikeNum ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | answer_timing | 0 | 0, data = mydata_answer_within30
# )
# models[["M2-60"]] <- felm (netlikeNum ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | answer_timing | 0 | 0, data = mydata_answer_within60
# )
# models[["M2-90"]] <- felm (netlikeNum ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | answer_timing | 0 | 0, data = mydata_answer_within90
# )
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/robustness - changing time frame.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)
sumamry(mydata_AI$askTime)




# # 需要的包
# library(lfe)       # felm
# library(dplyr)     # 数据处理
# library(purrr)     # map 循环
# library(broom)     # tidying model summaries
# library(ggplot2)   # 画图
# library(scales)    # 比例轴格式化

# # 可选：设置置信区间水平
# conf_level <- 0.95
# alpha <- 1 - conf_level
# zcrit <- qnorm(1 - alpha/2)

# # 1) 数据按 askTime 排序（确保 askTime 可排序）
# dat <- mydata_AI %>%
#   arrange(askTime)

# # 2) 定义要迭代的样本比例：5% 到 100%
# props <- seq(0.05, 1.00, by = 0.05)

# # 3) 循环估计：对每个比例切片、跑 felm、提取 preAI 系数与置信区间
# results_list <- map(props, function(p) {
#   n_cut <- max(1, floor(nrow(dat) * p))
#   dat_sub <- dat[seq_len(n_cut), , drop = FALSE]

#   # 直接在 felm 中书写多部分公式（含固定效应与聚类）
#   fit <- felm(
#     log_answer_que_within7day ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | dayofyear | 0 | 0,
#     data = dat_sub
#   )

#   coefs <- broom::tidy(fit)  # 包含聚类稳健SE
#   row_preAI <- dplyr::filter(coefs, term == "preAI")

#   if (nrow(row_preAI) == 0) {
#     tibble(
#       prop = p, n = n_cut, term = "preAI",
#       estimate = NA_real_, std.error = NA_real_,
#       conf.low = NA_real_, conf.high = NA_real_
#     )
#   } else {
#     est <- row_preAI$estimate[1]
#     se  <- row_preAI$std.error[1]
#     tibble(
#       prop = p, n = n_cut, term = "preAI",
#       estimate = est, std.error = se,
#       conf.low = est - zcrit * se,
#       conf.high = est + zcrit * se
#     )
#   }
# })

# # 4) 合并为数据框 df
# df <- bind_rows(results_list)

# # 5) 绘图：x 轴为样本比例，y 轴为 preAI 估计与 95% CI
# p <- ggplot(df, aes(x = prop, y = estimate)) +
#   geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
#   geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.2, fill = "#4C78A8") +
#   geom_line(color = "#4C78A8", size = 1) +
#   geom_point(color = "#4C78A8", size = 2) +
#   scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
#   labs(
#     x = "Cumulative sample proportion (askTime: past → present)",
#     y = "Coefficient estimate of preAI with 95% CI",
#     title = "Coefficient stability under rolling sample expansion (preAI)",
#     subtitle = "Cumulative sample from 5% to 100%; felm with cluster-robust SEs (by tagURL)"
#   ) +
#   theme_minimal(base_size = 12)

# # Print to the current device
# print(p)

# # Save as a horizontal (landscape) image: wider than tall
# # Adjust width/height and dpi as needed
# ggplot2::ggsave("preAI/table/2025 MISQ revision round 1/rolling sample robustness.jpg", p, width = 10, height = 6, dpi = 300)

# # 如需用样本量作横轴：
# # p_n <- ggplot(df, aes(x = n, y = estimate)) + ... （同上）




summary(mydata_AI$accumRep_ask)
sd(mydata_AI$accumRep_ask)
# ============================================================
# revision round 1: heterogeneity analysis to test mechanism
# ============================================================
mydata_AI_has1Ans <- mydata_AI %>% filter(!is.na(wait1Ans_original))
mydata_AI_has1Resp <- mydata_AI %>% filter(!is.na(wait1Resp_original))
models <- list()
models[["All sample"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans
)
models[["At least 1 Ans"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans
)
models[["on textLengthCN"]] <- felm (log_textLengthCN1Ans ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
models[["+textLengthCN"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + log_textLengthCN1Ans
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
models[["+qualityMeasures"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + log_textLengthCN1Ans + quality1Ans 
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
models[["+DimensionMeasures"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + log_textLengthCN1Ans + quality1Ans + clarity1Ans + readability1Ans + accuracy1Ans + relevance1Ans + detail1Ans + experience1Ans + insight1Ans + innovative1Ans + alternative1Ans + storytelling1Ans
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
models[["xtextLengthCN"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + preAI*log_textLengthCN1Ans
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
mydata_AI_has1Ans <- mydata_AI_has1Ans %>%
  mutate(meanQualityScore1Ans = (log_textLengthCN1Ans + quality1Ans + clarity1Ans + 
                           readability1Ans + accuracy1Ans + relevance1Ans + 
                           detail1Ans + experience1Ans + insight1Ans + 
                           innovative1Ans + alternative1Ans + storytelling1Ans) / 12)
models[["xmeanQualityScore1Ans"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + preAI*meanQualityScore1Ans
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)

# 1. 准备PCA所需的数据（选择这12个变量）
pca_vars <- c("textLengthCN1Ans", "quality1Ans", "clarity1Ans", 
              "readability1Ans", "accuracy1Ans", "relevance1Ans", 
              "detail1Ans", "experience1Ans", "insight1Ans", 
              "innovative1Ans", "alternative1Ans", "storytelling1Ans")
# 2. 提取这些变量并去除缺失值
pca_data <- mydata_AI_has1Ans %>%
  select(all_of(pca_vars)) %>%
  na.omit()
# 3. 进行PCA分析（标准化数据）
pca_result <- prcomp(pca_data, scale. = TRUE, center = TRUE, rank = 1)
# 4. 查看PCA结果摘要
summary(pca_result)
# install.packages("factoextra")
library(factoextra)
# 5. 查看各主成分的方差解释比例
scree_plot <- fviz_eig(pca_result, addlabels = TRUE)  # 需要factoextra包
print(scree_plot)
# 6. 提取第一主成分分数（通常解释最多方差）
# 注意：这里需要处理原数据中的缺失值
mydata_AI_has1Ans <- mydata_AI_has1Ans %>%
  mutate(
    # 创建一个标识，标记哪些行有完整数据
    complete_case = complete.cases(select(., all_of(pca_vars)))
  )
# 7. 为有完整数据的行计算PC1分数
pc1_scores <- pca_result$x[, 1]
# 8. 将PC1分数添加回原数据集
mydata_AI_has1Ans$qualityScore_PC1 <- NA
mydata_AI_has1Ans$qualityScore_PC1[mydata_AI_has1Ans$complete_case] <- pc1_scores
# 9. 查看变量在PC1上的载荷
loadings_pc1 <- pca_result$rotation[, 1]
print("PC1 Loadings:")
print(sort(loadings_pc1, decreasing = TRUE))

models[["xqualityScore_PC1"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + preAI*qualityScore_PC1
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))




















wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/mechanism - content effect.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)




library(mediation)
# 定义所有中介变量
mediators <- c("log_textLengthCN1Ans", "quality1Ans", "clarity1Ans", 
               "readability1Ans", "accuracy1Ans", "relevance1Ans", 
               "detail1Ans", "experience1Ans", "insight1Ans", 
               "innovative1Ans", "alternative1Ans", "storytelling1Ans")
# 定义协变量
Xnames <- c("log_textLengthCN_ask", "IimgNum_ask", "IaNum_ask", 
            "IblockquoteNum_ask", "ItableNum_ask", "lingComp_score", 
            "techJargon_score", "difficulty_score",
            "category1", "category2", "category3", "category4", 
            "category5", "category6", "category7", "category8", "category9",
            "log_age", "log_askBefore", "log_resBefore", "log_accumRep_ask", 
            "accumGold_ask", "accumSilver_ask", "accumCopper_ask",
            "asker_acceptedBefore_allsite_1m", "asker_nActivityBeforeAsk_allsite_1m", 
            "asker_nActivityBeforeResp_allsite_1m", "asker_nActivityBeforeComment_allsite_1m",
            "asker_acceptedBefore_allsite_2m", "asker_nActivityBeforeAsk_allsite_2m", 
            "asker_nActivityBeforeResp_allsite_2m", "asker_nActivityBeforeComment_allsite_2m",
            "asker_acceptedBefore_allsite_3m", "asker_nActivityBeforeAsk_allsite_3m", 
            "asker_nActivityBeforeResp_allsite_3m", "asker_nActivityBeforeComment_allsite_3m")

# 选择一个主要中介变量，其他作为 alternative mediators
main_mediator <- "log_textLengthCN1Ans"
alt_mediators <- setdiff(mediators, main_mediator)

# 一个命令完成多中介分析
m.med <- multimed(
  outcome = "log_answer_que_within7day",
  med.main = main_mediator,
  med.alt = alt_mediators,     # 向量形式，包含所有其他中介变量
  treat = "preAI",
  covariates = Xnames,
  data = mydata_AI_has1Ans,
  sims = 1000
)

# 查看结果
summary(m.med)


models <- list()
models[["At least 1 Ans"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans
)
models[["on position seeker"]] <- felm (firstAns_is_wantToBeOne_median ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
models[["+firstAns_is_wantToBeOne"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + firstAns_is_wantToBeOne_median
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
mydata_AI_has1Ans <- mutate(mydata_AI_has1Ans, 
      has_high_quality_1Ans = ifelse(quality1Resp >= 6, 1, 0),
      has_high_quality_1Ans = ifelse(answer_que == 0, 0, has_high_quality_1Ans),
)
summary(mydata_AI_has1Ans$has_high_quality_1Ans)
summary(mydata_AI_has1Ans$firstresp_acceptedBefore_within_all)
mydata_AI_has1Ans <- mutate(mydata_AI_has1Ans, 
      has_high_rep_1Ans = ifelse(firstresp_acceptedBefore_within_all >= 3, 1, 0),
      has_high_rep_1Ans = ifelse(is.na(has_high_rep_1Ans), 0, has_high_rep_1Ans),
)
models[["on first expert"]] <- felm (has_high_quality_1Ans ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
models[["+has_high_quality_1Ans"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + has_high_quality_1Ans 
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
total_n <- nrow(mydata_AI_has1Ans)
# 创建交叉表分析两个变量的组合
cross_table <- table(mydata_AI_has1Ans$has_high_quality_1Ans, 
                     mydata_AI_has1Ans$firstAns_is_wantToBeOne_median)
print(cross_table)
models[["on first repu"]] <- felm (has_high_rep_1Ans ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
models[["+has_high_rep_1Ans"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + has_high_rep_1Ans 
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/mechanism - position effect.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)



models <- list()
models[["At least 1 Ans"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans
)
models[["add content"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + log_textLengthCN1Ans + quality1Ans + clarity1Ans + readability1Ans + accuracy1Ans + relevance1Ans + detail1Ans + experience1Ans + insight1Ans + innovative1Ans + alternative1Ans + storytelling1Ans
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans
)
models[["add position"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + log_textLengthCN1Ans + quality1Ans + clarity1Ans + readability1Ans + accuracy1Ans + relevance1Ans + detail1Ans + experience1Ans + insight1Ans + innovative1Ans + alternative1Ans + storytelling1Ans
      + firstAns_is_wantToBeOne_median # + has_high_quality_1Ans + has_high_rep_1Ans
      | dayofyear | 0 | 0, data = mydata_AI_has1Ans
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/mechanism - test source effect.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)




# ==============================
# Table 10. Test for a compositional change or a decline in the underlying quality, or attraction effect
# ==============================
mydata_answer <- mydata_answer %>% mutate(
    log_acceptedBefore_within_1m = log(acceptedBefore_within_1m + 1),
    log_acceptedBefore_within_2m = log(acceptedBefore_within_2m + 1),
    log_acceptedBefore_within_3m = log(acceptedBefore_within_3m + 1),
    log_acceptedBefore_within_all = log(acceptedBefore_within_all + 1)
)
summary(mydata_answer$acceptedBefore_within_all)
summary(mydata_answer$acceptedBefore)


models <- list()
models[["DV: expertise"]] <- felm (log_acceptedBefore_within_all ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | questionURL, data = mydata_answer
)
models[["DV: quality"]] <- felm (quality ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | questionURL, data = mydata_answer
)
models[["DV: textlength"]] <- felm (log_textLengthCN ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | questionURL, data = mydata_answer
)
models[["nComment"]] <- felm (nComment ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/mechanism - 2-1.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)




# ==============================
# Table 11. Test for the mechanism of heightened expectations
# ==============================
mydata_AI_1Ans <- mydata_AI %>% filter(!is.na(quality1Ans))
length(mydata_AI_1Ans$quality1Ans)
summary(mydata_AI_1Ans$quality1Ans)

mydata_AI_AIoutperform <- mydata_AI_1Ans %>% filter(quality1Ans >= 8)
length(mydata_AI_AIoutperform)
summary(mydata_AI_AIoutperform$preAI)
mydata_AI_humanoutperform <- mydata_AI_1Ans %>% filter(quality1Ans <= 6)
length(mydata_AI_humanoutperform)
summary(mydata_AI_humanoutperform$preAI)

# 下面是直接和control group比较
AIoutperform_questionlist <- unique(mydata_AI_AIoutperform$questionURL)
mydata_answer_AIoutperform <- mydata_answer[mydata_answer$questionURL %in% AIoutperform_questionlist, ]
humanoutperform_questionlist <- unique(mydata_AI_humanoutperform$questionURL)
mydata_answer_humanoutperform <- mydata_answer[mydata_answer$questionURL %in% humanoutperform_questionlist, ]


summary(mydata_answer_AIoutperform$preAI)
summary(mydata_answer_humanoutperform$preAI)


models <- list()
# 对于netlikes，如果直接和control比(mydata_answer_AIoutperform)，是human厉害的组netlikes增加；如果匹配后比
# 对于netlikes，如果直接和control比(mydata_answer_AIoutperform)，是human厉害的组netlikes增加；如果匹配后比
models[["netlikes-AIoutperform"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_AIoutperform
)
models[["netlikes-humanoutperform"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_humanoutperform
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE))

summary(models[["netlikes-AIoutperform"]])
summary(models[["netlikes-humanoutperform"]])
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/mechanism - 2-2.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)





# ============================================================
# revision round 1: addtional - what level expert 
# ============================================================
models <- list()
mydata_AI_has1Resp <- mydata_AI %>% filter(!is.na(log_wait1Resp_original))
mydata_AI_has1Ans <- mydata_AI %>% filter(!is.na(log_wait1Ans_original))
summary(mydata_AI$badgeBefore1Ans)
# > summary(mydata_AI$acceptedBefore1Ans)
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#     0.0     6.0    56.0   195.7   290.0  1426.0    2144 
# > summary(mydata_AI$badgeBefore1Ans)
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#       1     271    2537    6873    9933   49363    2144 
mydata_AI$expert_top25 <- ifelse(!is.na(mydata_AI$acceptedBefore1Ans) & (mydata_AI$acceptedBefore1Ans >290), 1, 0)
summary(mydata_AI$expert_top25)
mydata_AI$expert_top25_50  <- ifelse(!is.na(mydata_AI$acceptedBefore1Ans) & (mydata_AI$acceptedBefore1Ans >56) & (mydata_AI$acceptedBefore1Ans <=290), 1, 0)
summary(mydata_AI$expert_top25_50)
mydata_AI$expert_top50_75  <- ifelse(!is.na(mydata_AI$acceptedBefore1Ans) & (mydata_AI$acceptedBefore1Ans >6) & (mydata_AI$acceptedBefore1Ans <=56), 1, 0)
summary(mydata_AI$expert_top50_75)
mydata_AI$expert_top75_100  <- ifelse(!is.na(mydata_AI$acceptedBefore1Ans) & (mydata_AI$acceptedBefore1Ans <=6), 1, 0)
summary(mydata_AI$expert_top75_100)
mydata_AI$expert_continues <- ifelse(is.na(mydata_AI$badgeBefore1Ans), 0, mydata_AI$badgeBefore1Ans)
mydata_AI$expert_continues_power2 <- mydata_AI$expert_continues^2
mydata_AI$expert_continues_power3 <- mydata_AI$expert_continues^3
mydata_AI$log_expert_continues <- ifelse(is.na(mydata_AI$badgeBefore1Ans), 0, mydata_AI$badgeBefore1Ans)
mydata_AI$log_expert_continues_power2 <- mydata_AI$log_expert_continues^2
mydata_AI$log_expert_continues_power3 <- mydata_AI$log_expert_continues^3
mydata_AI$gold_continues <- ifelse(is.na(mydata_AI$accumGold1Ans), 0, mydata_AI$accumGold1Ans)
mydata_AI$silver_continues <- ifelse(is.na(mydata_AI$accumSilver1Ans), 0, mydata_AI$accumSilver1Ans)
mydata_AI$bronze_continues <- ifelse(is.na(mydata_AI$badgeBefore1Ans), 0, mydata_AI$accumCopper1Ans)

mydata_AI$AI_equal_expert <- ifelse(mydata_AI$expert_continues>=48911, 1, 0)


summary(mydata_AI$firstresp_acceptedBefore_within_all)
# > summary(mydata_AI$firstresp_acceptedBefore_within_all)
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#    0.00    0.00    3.00   37.91   32.00  584.00    1028
mydata_AI$accepted_continues <- ifelse(is.na(mydata_AI$firstresp_acceptedBefore_within_all), 0, mydata_AI$firstresp_acceptedBefore_within_all)
mydata_AI$accepted_continues_power2 <- mydata_AI$accepted_continues^2
mydata_AI$accepted_continues_power3 <- mydata_AI$accepted_continues^3
mydata_AI$AI_equal_accepted <- ifelse(mydata_AI$accepted_continues>=584, 1, 0)

models <- list()
models[["answerNum"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + quality1Ans + log_textLengthCN1Ans
      | dayofyear | 0 | 0, data = mydata_AI)
models[["linear (robust)"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + quality1Ans + log_textLengthCN1Ans
      + expert_continues
      | dayofyear | 0 | 0, data = mydata_AI)
models[["cubic (robust)"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + quality1Ans + log_textLengthCN1Ans
      + expert_continues + expert_continues_power2 + expert_continues_power3
      | dayofyear | 0 | 0, data = mydata_AI)
models[["AI_equal_accepted"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + quality1Ans + log_textLengthCN1Ans
      + AI_equal_expert
      | dayofyear | 0 | 0, data = mydata_AI)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/addtional - what level expert .docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)



# ==============================
# Table 12. The impact of AI-generated answers on the unique human knowledge
# ==============================
table(mydata_answer$experience_m2)
table(mydata_answer$insight_m2)
table(mydata_answer$alternative_m2)
table(mydata_answer$storytelling_m2)
mydata_answer$Iclarity_m2 = ifelse(mydata_answer$clarity_m2 >= 1, 1, 0)
mydata_answer$Ireadability_m2 = ifelse(mydata_answer$readability_m2 >= 1, 1, 0)
mydata_answer$Iaccuracy_m2 = ifelse(mydata_answer$accuracy_m2 >= 1, 1, 0)
mydata_answer$Irelevance_m2 = ifelse(mydata_answer$relevance_m2 >= 1, 1, 0)
mydata_answer$Idetail_m2 = ifelse(mydata_answer$detail_m2 >= 1, 1, 0)
mydata_answer$Iexperience_m2 = ifelse(mydata_answer$experience_m2 >= 1, 1, 0)
mydata_answer$Iinsight_m2 = ifelse(mydata_answer$insight_m2 >= 1, 1, 0)
mydata_answer$Iinnovative_m2 = ifelse(mydata_answer$innovative_m2 >= 1, 1, 0)
mydata_answer$Ialternative_m2 = ifelse(mydata_answer$alternative_m2 >= 1, 1, 0)
mydata_answer$Istorytelling_m2 = ifelse(mydata_answer$storytelling_m2 >= 1, 1, 0)


summary(mydata_AI$textSim_firstAns_2Ans)
summary(mydata_AI$textSim_firstAns)
models <- list()
models[["textSim_firstAns_2"]] <- felm (textSim_firstAns_2Ans ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["textSim_firstAns_2 (robust)"]] <- felm (textSim_firstAns_2Ans ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + log_textLengthCN1Ans + quality1Ans 
      | dayofyear | 0 | 0, data = mydata_AI
)
mydata_AI$log_acceptedBefore2Ans <- log(mydata_AI$acceptedBefore2Ans+1)
models[["Iexperience"]] <- felm (Iexperience_m2 ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer
)
models[["Iinsight"]] <- felm (Iinsight_m2 ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer
)
models[["Ialternative"]] <- felm (Ialternative_m2 ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer
)
summary(models[["Iexperience"]])
summary(models[["Iinsight"]])
summary(models[["Ialternative"]])
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/addtional - answerer.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)


# ============================================================
# revision round 1: addtional - longer questioner behavior
# ============================================================
mydata_AI <- mutate(mydata_AI, 
    log_nPayback_1month = log(asker_nPayback_total_1m + 1),
    log_nPayback_2month = log(asker_nPayback_total_2m + 1),
    log_nPayback_3month = log(asker_nPayback_total_3m + 1),
    nFollowup_sumResp = ifelse(is.na(nFollowup_sumResp), 0, nFollowup_sumResp),
    log_nFollowup_sumResp = log(nFollowup_sumResp + 1)
)
summary(mydata_AI$nPayback)
summary(mydata_AI$asker_nPayback_total_1m)

models <- list()
# models[["nPayforward"]] <- felm (log_nPayback ~ preAI +  
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | dayofyear | 0 | 0, data = mydata_AI
# )
models[["nPayforward_1month"]] <- felm (log_nPayback_1month ~ preAI +  
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["nPayforward_2month"]] <- felm (log_nPayback_2month ~ preAI +  
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["nPayforward_3month"]] <- felm (log_nPayback_3month ~ preAI +  
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)

models[["nFollowup"]] <- felm (log_nFollowup_sumResp ~ preAI +  
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_has1Resp
)
models[["viewership"]] <- felm (log_views_que ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)

print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/addtional - longer questioner behavior.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)

























































# ==============================
# Appendix B - LLM-generated content quality rating
# ==============================
models <- list()
models[["AIfail"]] <- felm (quality1Ans ~ 
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + AIfail
      | dayofyear | 0 | 0, data = mydata_AI)
summary(models[["AIfail"]])
models[["netlike"]] <- felm (quality1Ans ~ 
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + netlikeNum_1Resp
      | dayofyear | 0 | 0, data = mydata_AI)
summary(models[["netlike"]])
models[["accepted"]] <- felm (quality1Ans ~ 
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + accepted_1Resp
      | dayofyear | 0 | 0, data = mydata_AI)
summary(models[["accepted"]])
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE))
t.test(mydata_AI$quality1Ans ~ mydata_AI$AIfail)
filtered_data <- mydata_AI %>%
  filter(!is.na(quality1Ans) & !is.na(accepted_1Resp))
t.test(filtered_data$quality1Ans ~ filtered_data$accepted_1Resp)
filtered_data <- mydata_AI %>%
  filter(!is.na(quality1Ans) & !is.na(netlikeNum_1Resp))
cor.test(filtered_data$quality1Ans, filtered_data$netlikeNum_1Resp, method = "pearson")
wordreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          file = "preAI/table/2025 MISQ revision round 1/Appendix C - LLM-generated content quality rating.docx", inline.css = FALSE, doctype = FALSE, html.tag = TRUE, head.tag = TRUE, body.tag = TRUE,
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE)


















# ==============================
# spillover analysis
# ==============================
mydata_AI_nospillover = mydata_AI_full %>% filter(askTime >= as.Date("2023-05-13") & askTime <= as.Date("2023-09-12"))
summary(mydata_AI_nospillover$preAI)
mydata_AI$after <- 1
mydata_AI_nospillover$after <- 0
mydata_AI_isAI <- mydata_AI %>% filter(preAI == 1)
summary(mydata_AI_isAI$preAI)
mydata_AI_isnotAI <- mydata_AI %>% filter(preAI == 0)
summary(mydata_AI_isnotAI$preAI)
mydata_AI_nospillover <- bind_rows(mydata_AI_isnotAI, mydata_AI_nospillover)
summary(mydata_AI_nospillover$preAI)


mydata_answer_nospillover = mydata_answer_full %>% filter(askTime >= as.Date("2023-05-13") & askTime <= as.Date("2023-09-12"))
summary(mydata_answer_nospillover$preAI)
mydata_answer$after <- 1
mydata_answer_nospillover$after <- 0
mydata_answer_isAI <- mydata_answer %>% filter(preAI == 1)
summary(mydata_answer_isAI$preAI)
mydata_answer_isnotAI <- mydata_answer %>% filter(preAI == 0)
summary(mydata_answer_isnotAI$preAI)
mydata_answer_nospillover <- bind_rows(mydata_answer_isnotAI, mydata_answer_nospillover)
summary(mydata_answer_nospillover$preAI)

models <- list()
models[["answerNum_within7day"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age_que
      | 0 | 0 | 0, data = mydata_AI
)
models[["1"]] <- felm (log_answer_que_within7day ~ after
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age_que
      | 0 | 0 | 0, data = mydata_AI_nospillover
)
models[["netlikeNum"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age + age_power2 
      | 0 | 0 | 0, data = mydata_answer
)
models[["2"]] <- felm (netlikeNum ~ after
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age + age_power2 
      | 0 | 0 | 0, data = mydata_answer_nospillover
)
models <- list()
mydata_AI_nospillover <- mydata_AI_nospillover %>% mutate(
       age_que_power2 = age_que**2,
      age_que_power3 = age_que**3,
      )
models[["1"]] <- felm (log_answer_que_within7day ~ after
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age_que + age_que_power2 + age_que_power3
      | 0 | 0 | 0, data = mydata_AI_nospillover
)
models[["2"]] <- felm (netlikeNum ~ after
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + answer_age + answer_age_power2 + answer_age_power3
      | 0 | 0 | 0, data = mydata_answer_nospillover
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))








mydata_AI_nospillover = mydata_AI_full %>% filter(askTime >= as.Date("2023-06-01") & askTime <= as.Date("2023-09-11"))
summary(mydata_AI_nospillover$preAI)
mydata_AI$after <- 1
mydata_AI_nospillover$after <- 0
mydata_AI_isAI <- mydata_AI %>% filter(preAI == 1)
summary(mydata_AI_isAI$preAI)
mydata_AI_isnotAI <- mydata_AI %>% filter(preAI == 0)
summary(mydata_AI_isnotAI$preAI)
mydata_AI_nospillover <- bind_rows(mydata_AI, mydata_AI_nospillover)
summary(mydata_AI_nospillover$preAI)


mydata_answer_nospillover = mydata_answer_full %>% filter(askTime >= as.Date("2023-06-01") & askTime <= as.Date("2023-09-11"))
summary(mydata_answer_nospillover$preAI)
mydata_answer$after <- 1
mydata_answer_nospillover$after <- 0
mydata_answer_isAI <- mydata_answer %>% filter(preAI == 1)
summary(mydata_answer_isAI$preAI)
mydata_answer_isnotAI <- mydata_answer %>% filter(preAI == 0)
summary(mydata_answer_isnotAI$preAI)
mydata_answer_nospillover <- bind_rows(mydata_answer, mydata_answer_nospillover)
summary(mydata_answer_nospillover$preAI)

models <- list()
models[["answerNum_within7day"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age_que
      | 0 | 0 | 0, data = mydata_AI
)
models[["1"]] <- felm (log_answer_que_within7day ~ after*preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age_que
      | 0 | 0 | 0, data = mydata_AI_nospillover
)
models[["netlikeNum"]] <- felm (netlikeNum ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age + age_power2 
      | 0 | 0 | 0, data = mydata_answer
)
models[["2"]] <- felm (netlikeNum ~ after*preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      + age + age_power2 
      | 0 | 0 | 0, data = mydata_answer_nospillover
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
