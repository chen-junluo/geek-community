# ============================================================
# revision round 1: robustness - alternative specifcations
# ============================================================
models <- list()
models[["baseline"]] <- felm(
  log_answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)
# models[["questioner FE"]] <- felm (log_answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | dayofyear + userURL_ask | 0 | 0, data = mydata_AI)
library(lme4)
library(reformulas)
models[["random effect"]] <- lmer(
  log_answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
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
  answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
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
  answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
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
  answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
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





# 提取出mydata_AI的questionURL对应的userURL_ask，merge到mydata_answer_firstHumanAns中
library(dplyr)

lookup <- mydata_AI %>%
  dplyr::select(questionURL, userURL_ask) %>%
  dplyr::distinct(questionURL, .keep_all = TRUE)

mydata_answer_firstHumanAns <- mydata_answer_firstHumanAns %>%
  dplyr::left_join(lookup, by = "questionURL")
  
models <- list()
models[["baseline"]] <- felm(
  quality ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_answer_firstHumanAns
)
models[["random effect"]] <- lmer(
  quality ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
    + factor(dayofyear)
    + (1 | userURL_ask),   # questioner 随机效应
  data = mydata_answer_firstHumanAns,
  REML = TRUE
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))






# ============================================================
# revision round 1: robustness - changing time frame
# ============================================================
mydata_AI_within30 <- mydata_AI %>%
  filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2023-10-13"))
mydata_AI_within60 <- mydata_AI %>%
  filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2023-11-13"))
mydata_AI_within90 <- mydata_AI %>%
  filter(askTime >= as.Date("2023-09-13") & askTime <= as.Date("2023-12-13"))




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
models[["DV-all"]] <- felm (log_answer_que ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
models[["DV-3day"]] <- felm (log_answer_que_within3day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
models[["DV-7day"]] <- felm (log_answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
models[["DV-14day"]] <- felm (log_answer_que_within14day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
models[["within30"]] <- felm (log_answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_within30)
models[["within60"]] <- felm (log_answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_within60)
models[["within90"]] <- felm (log_answer_que_within7day ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
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




mydata_answer_within30 <- mydata_answer_firstHumanAns %>%
  filter(date >= as.Date("2023-09-13") & date <= as.Date("2023-10-13"))
mydata_answer_within60 <- mydata_answer_firstHumanAns %>%
  filter(date >= as.Date("2023-09-13") & date <= as.Date("2023-11-13"))
mydata_answer_within90 <- mydata_answer_firstHumanAns %>%
  filter(date >= as.Date("2023-09-13") & date <= as.Date("2023-12-13"))

models <- list()
models[["within30"]] <- felm (quality ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_answer_within30)
models[["within60"]] <- felm (quality ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_answer_within60)
models[["within90"]] <- felm (quality ~ AI+AI:(log_textLengthCNAI_fillna + qualityAI_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_answer_within90)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
          ))
