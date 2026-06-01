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




mydata_AI_isAI <- mydata_AI %>% filter(treatment == 1)
mydata_AI_isNOTAI <- mydata_AI %>% filter(treatment == 0)


## Overall Means and Standard Deviations (Setup1)
mean(mydata_AI$log_textLengthCNAI_fillna, na.rm = TRUE)
sd(mydata_AI$log_textLengthCNAI_fillna, na.rm = TRUE)
mean(mydata_AI$AISimWithOpus47_fillna, na.rm = TRUE)
sd(mydata_AI$AISimWithOpus47_fillna, na.rm = TRUE)


mean(mydata_AI_isAI$log_textLengthCNAI_fillna, na.rm = TRUE)
sd(mydata_AI_isAI$log_textLengthCNAI_fillna, na.rm = TRUE)

mean(mydata_AI_isAI$AISimWithOpus47_fillna, na.rm = TRUE)
sd(mydata_AI_isAI$AISimWithOpus47_fillna, na.rm = TRUE)


## Overall Means and Standard Deviations by Treatment Group (Setup2)
mean(mydata_AI$log_textLengthCN1Ans, na.rm = TRUE)
sd(mydata_AI$log_textLengthCN1Ans, na.rm = TRUE)
mean(mydata_AI$SimWithOpus1Ans, na.rm = TRUE)
sd(mydata_AI$SimWithOpus1Ans, na.rm = TRUE)

mean(mydata_AI_isAI$log_textLengthCN1Ans, na.rm = TRUE)
sd(mydata_AI_isAI$log_textLengthCN1Ans, na.rm = TRUE)
mean(mydata_AI_isNOTAI$log_textLengthCN1Ans, na.rm = TRUE)
sd(mydata_AI_isNOTAI$log_textLengthCN1Ans, na.rm = TRUE)

mean(mydata_AI_isAI$SimWithOpus1Ans, na.rm = TRUE)
sd(mydata_AI_isAI$SimWithOpus1Ans, na.rm = TRUE)
mean(mydata_AI_isNOTAI$SimWithOpus1Ans, na.rm = TRUE)
sd(mydata_AI_isNOTAI$SimWithOpus1Ans, na.rm = TRUE)



# Variable	Mean and SD			Min	Max
# 	All samples	Treatment group	Control group		
# question length (number of Chinese characters)	86.809	84.233	89.272	0	2702
# 	-113.981	-89.347	-133.323		
# number of human-generated answers received by a question	1.293	1.209	1.372	0	8
# 	-1.166	-1.133	-1.192		
# percentage of questions that received at least one answer	0.761	0.724	0.795	0	1
# 	-0.427	-0.447	-0.404		
# percentage of questions that have an answer “accepted” by the questioner	0.322	0.293	0.35	0	1
# 	-0.467	-0.455	-0.477		
# average number of net likes received by all the answers to a question	0.489	0.436	0.536	-3	14
# 	-1.096	-1.041	-1.14		
# reputation scores of the questioner at the time the question was posted	378.337	334.484	420.267	-3	28800
# 	-1135.056	-695.343	-1433.522		



models <- list()
models[["netlikeNum"]] <- felm (netlikeNum ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_secondAns
)
models[[" "]] <- felm (Iinsight_m2 ~ treatment+treatment*(log_textLengthCN1Ans + SimWithOpus1Ans)
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | answer_timing | 0 | 0, data = mydata_answer_secondAns
)
print(screenreg(models,
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
))

# 构建变量——has1Ans
mydata_AI$has1Ans <- ifelse(mydata_AI$answer_que_within7day >= 1, 1, 0)
mydata_AI$has1Ans_other <- ifelse(mydata_AI$answer_que_within7day_other >= 1, 1, 0)
models <- list()
models[["answerNum"]] <- felm(log_answer_que_within7day ~ has1Ans*treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask + asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["answerNum_other"]] <- felm(log_answer_que_within7day_other ~ has1Ans_other*treatment
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

