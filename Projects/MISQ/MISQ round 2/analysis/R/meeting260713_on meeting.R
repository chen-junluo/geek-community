mydata_AI$AISimWithOpus47_fillna_power2 = mydata_AI$AISimWithOpus47_fillna^2

models <- list()
models[["DV: human 1 quality"]] <- felm (human1SimWithGT__claude_opus_4_7 ~ AI+AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna + AISimWithOpus47_fillna_power2)
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
# =====================================================
#                                   DV: human 1 quality
# -----------------------------------------------------
# AI                                  -0.073           
#                                     (0.084)          
# AI:log_textLengthCNAI_fillna        -0.007           
#                                     (0.013)          
# AI:AISimWithOpus47_fillna           -0.030           
#                                     (0.183)          
# AI:AISimWithOpus47_fillna_power2     0.361 *         
#                                     (0.175)          
# -----------------------------------------------------
# Num. obs.                         2017               
# F statistic (full model)             2.199           
# F (full model): p-value              0.000           
# F statistic (proj model)             5.987           
# F (proj model): p-value              0.000           
# =====================================================
# *** p < 0.001; ** p < 0.01; * p < 0.05; . p < 0.1


mydata_AI <- mydata_AI %>% mutate(
    SimWithAccept1Ans = ifelse(treatment == 1, AISimWithAccept, human1SimWithAccept),
    SimWithOpus1Ans = ifelse(treatment == 1, AISimWithGT__claude_opus_4_7, human1SimWithGT__claude_opus_4_7),
    SimWithOpus2Ans = ifelse(treatment == 1, human1SimWithGT__claude_opus_4_7, human2SimWithGT__claude_opus_4_7),
    SimWithDeepseek1Ans = ifelse(treatment == 1, AISimWithGT__deepseek_v4_pro, human1SimWithGT__deepseek_v4_pro)
)
models <- list()
models[["DV: quality2Ans"]] <- felm (quality2Ans ~ treatment
      + log_textLengthCN_ask + IimgNum_ask + IaNum_ask + IblockquoteNum_ask + ItableNum_ask + lingComp_score + techJargon_score + difficulty_score
      + category1 + category2 + category3 + category4 + category5 + category6 + category7 + category8 + category9
      + log_age + log_askBefore + log_resBefore + log_accumRep_ask + accumGold_ask + accumSilver_ask + accumCopper_ask +  asker_acceptedBefore_allsite_1m + asker_nActivityBeforeAsk_allsite_1m + asker_nActivityBeforeResp_allsite_1m + asker_nActivityBeforeComment_allsite_1m + asker_acceptedBefore_allsite_2m + asker_nActivityBeforeAsk_allsite_2m + asker_nActivityBeforeResp_allsite_2m + asker_nActivityBeforeComment_allsite_2m + asker_acceptedBefore_allsite_3m + asker_nActivityBeforeAsk_allsite_3m + asker_nActivityBeforeResp_allsite_3m + asker_nActivityBeforeComment_allsite_3m
      | dayofyear | 0 | 0, data = mydata_AI
)
models[["   "]] <- felm (quality2Ans ~ treatment+treatment*(log_textLengthCN1Ans + SimWithOpus1Ans )
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
