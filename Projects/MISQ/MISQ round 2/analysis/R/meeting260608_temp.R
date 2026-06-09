





models <- list()
models[["DV: ans1_ans2_similarity"]] <- felm (ans1_ans2_similarity ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["   "]] <- felm (ans1_ans2_similarity ~ treatment+treatment*(log_textLengthCN1Ans + quality1Ans )
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




##############################################
######## 260526 Setup 1 + AISimWithOpus47_fillna
##############################################
models <- list()
# models[["DV: # human answers"]] <- felm(log_answer_que_within7day ~ treatment
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | dayofyear | 0 | 0, data = mydata_AI
# )
# models[[" "]] <- felm(log_answer_que_within7day ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | dayofyear | 0 | 0, data = mydata_AI
# )
# mydata_survival$surv_human_answer <- with(mydata_survival, Surv(wait1Resp_surv, human_answer_event))
# models[["DV: harzard first human answer"]] <- coxph(surv_human_answer ~ treatment + strata(dayofyear)
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
#       data = mydata_survival, ties = "efron"
# )
# models[["  "]] <- coxph(surv_human_answer ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)+ strata(dayofyear)
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m,
#       data = mydata_survival, ties = "efron"
# )
# models[["Iexperience_m2"]] <- felm (Iexperience_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns
# )
# models[["Iinsight_m2"]] <- felm (Iinsight_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns
# )
# models[["Ialternative_m2"]] <- felm (Ialternative_m2 ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna)
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
#       | answer_timing | 0 | 0, data = mydata_answer_firstHumanAns
# )


models <- list()
models[["DV: ans1_ans2_similarity"]] <- felm (ans1_ans2_similarity ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["   "]] <- felm (ans1_ans2_similarity ~ treatment+treatment*(log_textLengthCN1Ans + quality1Ans )
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


## AI -> human 1 quality

models <- list()
models[["DV: human1SimWithGT__claude_opus_4_7"]] <- felm (human1SimWithGT__claude_opus_4_7 ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["    "]] <- felm (human1SimWithGT__claude_opus_4_7 ~ treatment+treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna )
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





## 几级专家的分析，quality1Ans变成




## Setup2 opus quality 增加reputation
##############################################
######## 260526 Setup 2 + AISimWithOpus47_fillna
##############################################
models <- list()
models[["DV: # other answers"]] <- felm(log_answer_que_within7day_other ~ AI + log_expert_continues
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: # other answers "]] <- felm(log_answer_que_within7day_other ~ AI+log_expert_continues+log_textLengthCN1Ans + SimWithOpus1Ans
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: ans1_ans2_similarity"]] <- felm (ans1_ans2_similarity ~ AI + log_expert_continues
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["DV: ans1_ans2_similarity "]] <- felm (ans1_ans2_similarity ~ AI+log_expert_continues+log_textLengthCN1Ans + SimWithOpus1Ans
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 5, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))
summary(mydata_AI$expert_continues)


# ==============================
# Table 9. Comparing the effects of different human expertise levels with the AI source effect
# ==============================
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
models <- list()

models[["answerNum"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
      + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + quality1Ans + log_textLengthCN1Ans
      | dayofyear | 0 | tagURL, data = mydata_AI)
models[["linear"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
      + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + quality1Ans + log_textLengthCN1Ans
      + expert_continues
      | dayofyear | 0 | tagURL, data = mydata_AI)
# models[["quadratic"]] <- felm (log_answer_que_within7day ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
#       + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + quality1Ans + log_textLengthCN1Ans
#       + expert_continues + expert_continues_power2
#       | dayofyear | 0 | tagURL, data = mydata_AI)
models[["cubic"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
      + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + quality1Ans + log_textLengthCN1Ans
      + expert_continues + expert_continues_power2 + expert_continues_power3
      | dayofyear | 0 | tagURL, data = mydata_AI)
# models[["expo"]] <- felm (log_answer_que_within7day ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
#       + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + quality1Ans + log_textLengthCN1Ans
#       + log_expert_continues
#       | dayofyear | 0 | tagURL, data = mydata_AI)
# models[["gold"]] <- felm (log_answer_que_within7day ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
#       + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + quality1Ans + log_textLengthCN1Ans
#       + gold_continues
#       | dayofyear | 0 | tagURL, data = mydata_AI)
# models[["silver"]] <- felm (log_answer_que_within7day ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
#       + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + quality1Ans + log_textLengthCN1Ans
#       + silver_continues
#       | dayofyear | 0 | tagURL, data = mydata_AI)
# models[["bronze"]] <- felm (log_answer_que_within7day ~ preAI
#       + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
#       + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
#       + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
#       + quality1Ans + log_textLengthCN1Ans
#       + bronze_continues
#       | dayofyear | 0 | tagURL, data = mydata_AI)
models[["AI_equal_expert"]] <- felm (log_answer_que_within7day ~ preAI
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask
      + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + quality1Ans + log_textLengthCN1Ans
      + AI_equal_expert
      | dayofyear | 0 | tagURL, data = mydata_AI)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust=T,
          include.groups = FALSE, single.row = FALSE,
))