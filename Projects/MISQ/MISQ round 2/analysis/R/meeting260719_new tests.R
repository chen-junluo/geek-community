##############################################
######## expertise interaction
##############################################
mydata_answer_firstHumanAns_reputation = mydata_answer_firstHumanAns %>% filter(!is.na(acceptedBefore_within_all))
summary(mydata_answer_firstHumanAns_reputation$acceptedBefore_within_all)
# 改名为acceptedBefore_within_all_firsthuman之后 merge到对应的mydata_AI上面去 按照questionURL
mydata_answer_firstHumanAns_reputation <- mydata_answer_firstHumanAns_reputation %>% rename(acceptedBefore_within_all_firsthuman = acceptedBefore_within_all)
mydata_AI <- mydata_AI %>% left_join(mydata_answer_firstHumanAns_reputation %>% dplyr::select(questionURL, acceptedBefore_within_all_firsthuman), by = "questionURL")


median_diff <- median(mydata_AI$acceptedBefore_within_all_firsthuman, na.rm = TRUE)
mean_diff <- mean(mydata_AI$acceptedBefore_within_all_firsthuman, na.rm = TRUE)
mydata_AI$expertise_high <- ifelse(mydata_AI$acceptedBefore_within_all_firsthuman >= mean_diff, 1, 0)
mydata_AI_low  <- mydata_AI[mydata_AI$acceptedBefore_within_all_firsthuman < mean_diff, ]
mydata_AI_high <- mydata_AI[mydata_AI$acceptedBefore_within_all_firsthuman >=  mean_diff, ]
# 把两个data拼到一起变成一个data，搞一个group indicator
mydata_AI_high = mydata_AI_high %>% mutate(group = "high")
mydata_AI_low = mydata_AI_low %>% mutate(group = "low")
mydata_AI_combined <- bind_rows(mydata_AI_high, mydata_AI_low)
mydata_AI_combined$group <- factor(mydata_AI_combined$group, levels = c("high", "low"))


mydata_AI$rookie <- ifelse(mydata_AI$acceptedBefore_within_all_firsthuman < median_diff, 1, 0)

models <- list()                                                                                                                                                                                                                                                                                                                                                                                                                                           
models[["DV: human 1 quality"]] <- felm (human1SimWithGT__claude_opus_4_7 ~ AISimWithOpus47_fillna*rookie
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))



##############################################
######## viewsNum interaction
##############################################
models <- list()                                                                                                                                                                                                                                                                                                                                                                                                                                           
models[["DV: human 1 quality"]] <- felm (human1SimWithGT__claude_opus_4_7 ~ AI+AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)*views_que
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))


##############################################
######## effort/composition time mediation
##############################################
# AI quality应该正向预测human answerer的effort/composition time
# 如果mediation成立，你就构造了一条比较完整的行为链：高质量AI → 更多effort/更长构思时间 → 更高人类答案质量。
# Knowledge spillover（Explanation C）同样可能预测更长的阅读时间，但它不应该显著预测写作阶段的时间投入。如果你能把"阅读AI答案的时间"和"写自己答案的时间"分开，两者之间的差异就很有诊断价值。

models <- list()
models[["DV: fist human length (effort)"]] <- felm(log_textLengthCN_firsthuman ~ AI + AI:(log_textLengthCNAI_fillna + AIcomprehensiveness_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))



mydata_answer_firstHumanAns_length = mydata_answer_firstHumanAns %>% filter(!is.na(textLengthCN))
summary(mydata_answer_firstHumanAns_length$textLengthCN)
# 改名为textLengthCN_firsthuman之后 merge到对应的mydata_AI上面去 按照questionURL
mydata_answer_firstHumanAns_length <- mydata_answer_firstHumanAns_length %>% rename(textLengthCN_firsthuman = textLengthCN)
mydata_AI <- mydata_AI %>% left_join(mydata_answer_firstHumanAns_length %>% dplyr::select(questionURL, textLengthCN_firsthuman), by = "questionURL")
# log textLengthCN_firsthuman
mydata_AI <- mydata_AI %>% mutate(log_textLengthCN_firsthuman = log(textLengthCN_firsthuman + 1))

# 计算log_textLengthCNAI和AISimWithOpus47的相关系数，看看是否有多重共线性问题
mydata_AI <- mydata_AI %>% mutate(log_textLengthCNAI = log(textLengthCNAI + 1))
cor(mydata_AI$log_textLengthCNAI, mydata_AI$AISimWithOpus47, use = "complete.obs")


models <- list()
models[["DV: fist human length (effort)"]] <- felm(log_textLengthCN_firsthuman ~ AI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: fist human length (effort) "]] <- felm(log_textLengthCN_firsthuman ~ AI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_high
)
models[["DV: fist human length (effort)  "]] <- felm(log_textLengthCN_firsthuman ~ AI+AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI_high
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))
# =============================================================================================
#                               DV: fist human length (effort)  DV: fist human length (effort) 
# ---------------------------------------------------------------------------------------------
# AI                               0.074                          -1.439 ***                   【facing AI, not to replicate breadth】
#                                 (0.050)                         (0.369)                      
# AI:log_textLengthCNAI_fillna                                     0.324 ***                   【reference point/length work in quality stage】
#                                                                 (0.060)                      
# AI:AISimWithOpus47_fillna                                       -0.582 *                     【facing AI, not to replicate breadth】
#                                                                 (0.237)                      
# ---------------------------------------------------------------------------------------------
# Num. obs.                     2748                            2739                           
# F statistic (full model)         1.907                           2.097                       
# F (full model): p-value          0.000                           0.000                       
# F statistic (proj model)         4.051                           4.830                       
# F (proj model): p-value          0.000                           0.000                       
# =============================================================================================
# *** p < 0.001; ** p < 0.01; * p < 0.05; . p < 0.1


# 【改成全答案长度】
mydata_answer_firstHumanAns_length = mydata_answer_firstHumanAns %>% filter(!is.na(textLength))
summary(mydata_answer_firstHumanAns_length$textLength)
# 改名为textLength_firsthuman之后 merge到对应的mydata_AI上面去 按照questionURL
mydata_answer_firstHumanAns_length <- mydata_answer_firstHumanAns_length %>% rename(textLength_firsthuman = textLength)
mydata_AI <- mydata_AI %>% left_join(mydata_answer_firstHumanAns_length %>% dplyr::select(questionURL, textLength_firsthuman), by = "questionURL")
# log textLength_firsthuman
mydata_AI <- mydata_AI %>% mutate(log_textLength_firsthuman = log(textLength_firsthuman + 1))

models <- list()
models[["DV: fist human length (effort)"]] <- felm(log_textLength_firsthuman ~ AI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: fist human length (effort) "]] <- felm(log_textLength_firsthuman ~ AI+AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))


# 【改成代码长度】
mydata_answer_firstHumanAns_length = mydata_answer_firstHumanAns %>% filter(!is.na(codeLength))
summary(mydata_answer_firstHumanAns_length$codeLength)
# 改名为codeLength_firsthuman之后 merge到对应的mydata_AI上面去 按照questionURL
mydata_answer_firstHumanAns_length <- mydata_answer_firstHumanAns_length %>% rename(codeLength_firsthuman = codeLength)
mydata_AI <- mydata_AI %>% left_join(mydata_answer_firstHumanAns_length %>% dplyr::select(questionURL, codeLength_firsthuman), by = "questionURL")
# log codeLength_firsthuman
mydata_AI <- mydata_AI %>% mutate(log_codeLength_firsthuman = log(codeLength_firsthuman + 1))

models <- list()
models[["DV: fist human length (effort)"]] <- felm(log_codeLength_firsthuman ~ AI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: fist human length (effort) "]] <- felm(log_codeLength_firsthuman ~ AI+AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))




##############################################
######## 10 dimensions
##############################################
# Competitive bar-raising有一个非常具体的预测：人类answerer应该在AI表现最强的维度上提升最多，因为那正是competitive bar最高的地方

# mydata_answer_firstHumanAns_clarity = mydata_answer_firstHumanAns %>% filter(!is.na(clarity_m2))
# summary(mydata_answer_firstHumanAns_clarity$clarity_m2)
# # 改名为clarity_m2_firsthuman之后 merge到对应的mydata_AI上面去 按照questionURL
# mydata_answer_firstHumanAns_clarity <- mydata_answer_firstHumanAns_clarity %>% rename(clarity1human = clarity_m2)
# mydata_AI <- mydata_AI %>% left_join(mydata_answer_firstHumanAns_clarity %>% dplyr::select(questionURL, clarity1human), by = "questionURL")
# mydata_AI <- mydata_AI %>% mutate(
#     clarityAI_fillna = ifelse(treatment == 1, clarity1Ans, 0)
# )
# models <- list()       
# models[["DV: clarity1human"]] <- felm (clarity1human ~ AI+AI:(log_textLengthCNAI_fillna + clarityAI_fillna)
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | dayofyear | 0 | 0, data = mydata_AI)
# print(screenreg(models,
#           stars = c(0.1, 0.05, 0.01, 0.001),
#           digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
#           include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
#           include.groups = FALSE, single.row = FALSE,
#           omit.coef = omit_pattern
# ))
library(dplyr)
library(lfe)
library(texreg)

dims <- c(
  "clarity",
  "readability",
  "accuracy",
  "relevance",
  "detail",
  "experience",
  "insight",
  "innovative",
  "alternative",
  "storytelling"
)

for (dim in dims) {
  score_var <- paste0(dim, "_m2")
  human_var <- paste0(dim, "1human")
  ai_fillna_var <- paste0(dim, "AI_fillna")

  tmp <- mydata_answer_firstHumanAns %>%
    filter(!is.na(.data[[score_var]]))

  summary(tmp[[score_var]])

  tmp <- tmp %>%
    rename(!!human_var := all_of(score_var))

  mydata_AI <- mydata_AI %>%
    left_join(
      tmp %>% dplyr::select(questionURL, all_of(human_var)),
      by = "questionURL"
    )

  mydata_AI <- mydata_AI %>%
    mutate(
      !!ai_fillna_var := ifelse(treatment == 1, .data[[paste0(dim, "1Ans")]], 0)
    )
}

omit_pattern <- "log_textLengthCN_ask|IimgNum_ask|IaNum_ask|IblockquoteNum_ask|ItableNum_ask|lingComp_score|techJargon_score|difficulty_score|category1|category2|category3|category4|category5|category6|category7|category8|category9|log_age|log_askBefore|log_resBefore|log_accumRep_ask|accumGold_ask|accumSilver_ask|accumCopper_ask|asker_acceptedBefore_allsite_1m|asker_nActivityBeforeAsk_allsite_1m|asker_nActivityBeforeResp_allsite_1m|asker_nActivityBeforeComment_allsite_1m|asker_acceptedBefore_allsite_2m|asker_nActivityBeforeAsk_allsite_2m|asker_nActivityBeforeResp_allsite_2m|asker_nActivityBeforeComment_allsite_2m|asker_acceptedBefore_allsite_3m|asker_nActivityBeforeAsk_allsite_3m|asker_nActivityBeforeResp_allsite_3m|asker_nActivityBeforeComment_allsite_3m"

models <- list()

models[["DV: clarity1human"]] <- felm(
  clarity1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)
models[["DV: readability1human"]] <- felm(
  readability1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

models[["DV: accuracy1human"]] <- felm(
  accuracy1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

models[["DV: relevance1human"]] <- felm(
  relevance1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

models[["DV: detail1human"]] <- felm(
  detail1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

models[["DV: experience1human"]] <- felm(
  experience1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

models[["DV: insight1human"]] <- felm(
  insight1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

models[["DV: innovative1human"]] <- felm(
  innovative1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

models[["DV: alternative1human"]] <- felm(
  alternative1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

models[["DV: storytelling1human"]] <- felm(
  storytelling1human ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
  + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
  + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
  + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
  + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m
  + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m
  + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
  | dayofyear | 0 | 0,
  data = mydata_AI
)

print(
  screenreg(
    models,
    stars = c(0.1, 0.05, 0.01, 0.001),
    digits = 3,
    dcolumn = TRUE,
    threeparttable = TRUE,
    fontsize = "tiny",
    include.fstatistic = TRUE,
    include.adjrs = FALSE,
    include.rsquared = FALSE,
    robust = TRUE,
    include.groups = FALSE,
    single.row = FALSE,
    omit.coef = omit_pattern
  )
)


table(mydata_AI$readabilityAI_fillna)
table(mydata_AI$accuracyAI_fillna)
table(mydata_AI$relevanceAI_fillna)
table(mydata_AI$experienceAI_fillna)
table(mydata_AI$experience1human)

table(mydata_AI$readability1human)
