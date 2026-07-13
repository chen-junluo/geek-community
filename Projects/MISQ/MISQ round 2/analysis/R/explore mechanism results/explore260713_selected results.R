suppressPackageStartupMessages({
  library(dplyr)
  library(lfe)
  library(texreg)
})

source("Projects/MISQ/MISQ round 2/analysis/R/explore mechanism results/mechanism_preprocessing.R")
prepared <- prepare_mechanism_data(getwd())
mydata_AI <- prepared$analysis_question

controls <- c(
  "log_textLengthCN_ask", "IimgNum_ask", "IaNum_ask", "IblockquoteNum_ask", "ItableNum_ask",
  "lingComp_score", "techJargon_score", "difficulty_score", paste0("category", 1:9),
  "log_age", "log_askBefore", "log_resBefore", "log_accumRep_ask", "accumGold_ask",
  "accumSilver_ask", "accumCopper_ask", paste0("asker_acceptedBefore_allsite_", 1:3, "m"),
  unlist(lapply(1:3, function(m) paste0(
    "asker_nActivityBefore", c("Ask", "Resp", "Comment"), "_allsite_", m, "m"
  )))
)
omit_pattern <- paste(controls, collapse = "|")
subgroup_formula <- as.formula(paste(
  "human1SimWithGT__claude_opus_4_7 ~ AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna) +",
  paste(controls, collapse = " + "), "| dayofyear | 0 | 0"
))
interaction_formula <- as.formula(paste(
  "human1SimWithGT__claude_opus_4_7 ~ (AI + AI:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna))* group +",
  paste(controls, collapse = " + "), "| dayofyear | 0 | 0"
))

# 1. acceptedBefore: high = above median; low = zero; strict excludes values equal to median
median_acceptedBefore <- median(mydata_AI$acceptedBefore_within_all_firsthuman, na.rm = TRUE)
summary(mydata_AI$acceptedBefore_within_all_firsthuman)

mydata_AI_acceptedBefore_median_low <- mydata_AI %>%
  filter(acceptedBefore_within_all_firsthuman == 0) %>%
  mutate(group = "low")
mydata_AI_acceptedBefore_median_high <- mydata_AI %>%
  filter(acceptedBefore_within_all_firsthuman > median_acceptedBefore) %>%
  mutate(group = "high")
mydata_AI_acceptedBefore_median_combined <- bind_rows(
  mydata_AI_acceptedBefore_median_low,
  mydata_AI_acceptedBefore_median_high
) %>%
  mutate(group = factor(group, levels = c("low", "high")))

models_acceptedBefore_median <- list()
models_acceptedBefore_median[["Low: zero"]] <- felm(
  subgroup_formula,
  data = mydata_AI_acceptedBefore_median_low
)
models_acceptedBefore_median[["High: > median"]] <- felm(
  subgroup_formula,
  data = mydata_AI_acceptedBefore_median_high
)
# models_acceptedBefore_median[["Pooled interaction"]] <- felm(
#   interaction_formula,
#   data = mydata_AI_acceptedBefore_median_combined
# )
print(screenreg(
  models_acceptedBefore_median,
  stars = c(0.1, 0.05, 0.01, 0.001),
  digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
  include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
  include.groups = FALSE, single.row = FALSE,
  omit.coef = omit_pattern
))

# 2. AISimWithOpus47_fillna: high = above mean; low = zero; strict excludes values equal to mean
mydata_AI$AISimWithOpus47 <- ifelse(
  (mydata_AI$AISimWithOpus47_fillna)==0,
  NA,
  mydata_AI$AISimWithOpus47_fillna
)
mean_AISim <- mean(mydata_AI$AISimWithOpus47, na.rm = TRUE)
summary(mydata_AI$AISimWithOpus47)

mydata_AI_AISim_low <- mydata_AI %>%
  filter(AISimWithOpus47_fillna < mean_AISim) %>%
  mutate(group = "low")
mydata_AI_AISim_high <- mydata_AI %>%
  filter(AISimWithOpus47_fillna > mean_AISim | is.na(AISimWithOpus47)) %>%
  mutate(group = "high")
mydata_AI_AISim_combined <- bind_rows(mydata_AI_AISim_low, mydata_AI_AISim_high) %>%
  mutate(group = factor(group, levels = c("low", "high")))

models_AISim <- list()
models_AISim[["Low: < mean"]] <- felm(subgroup_formula, data = mydata_AI_AISim_low)
models_AISim[["High: > mean"]] <- felm(subgroup_formula, data = mydata_AI_AISim_high)
# models_AISim[["Pooled interaction"]] <- felm(interaction_formula, data = mydata_AI_AISim_combined)
print(screenreg(
  models_AISim,
  stars = c(0.1, 0.05, 0.01, 0.001),
  digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
  include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
  include.groups = FALSE, single.row = FALSE,
  omit.coef = omit_pattern
))

# 3. tagNum: three common splits in one model list
median_tagNum <- median(mydata_AI$tagNum, na.rm = TRUE)
mean_tagNum <- mean(mydata_AI$tagNum, na.rm = TRUE)
summary(mydata_AI$tagNum)

mydata_AI_tagNum_median_low <- mydata_AI %>%
  filter(tagNum < median_tagNum) %>%
  mutate(group = "low")
mydata_AI_tagNum_median_high <- mydata_AI %>%
  filter(tagNum > median_tagNum) %>%
  mutate(group = "high")
mydata_AI_tagNum_median_combined <- bind_rows(
  mydata_AI_tagNum_median_low,
  mydata_AI_tagNum_median_high
) %>%
  mutate(group = factor(group, levels = c("low", "high")))

mydata_AI_tagNum_mean_low <- mydata_AI %>%
  filter(tagNum < mean_tagNum) %>%
  mutate(group = "low")
mydata_AI_tagNum_mean_high <- mydata_AI %>%
  filter(tagNum > mean_tagNum) %>%
  mutate(group = "high")
mydata_AI_tagNum_mean_combined <- bind_rows(
  mydata_AI_tagNum_mean_low,
  mydata_AI_tagNum_mean_high
) %>%
  mutate(group = factor(group, levels = c("low", "high")))

mydata_AI_tagNum_extreme_low <- mydata_AI %>%
  filter(tagNum == 1) %>%
  mutate(group = "low")
mydata_AI_tagNum_extreme_high <- mydata_AI %>%
  filter(tagNum >= 3) %>%
  mutate(group = "high")
mydata_AI_tagNum_extreme_combined <- bind_rows(
  mydata_AI_tagNum_extreme_low,
  mydata_AI_tagNum_extreme_high
) %>%
  mutate(group = factor(group, levels = c("low", "high")))

models_tagNum <- list()
models_tagNum[["Median: low"]] <- felm(subgroup_formula, data = mydata_AI_tagNum_median_low)
models_tagNum[["Median: high"]] <- felm(subgroup_formula, data = mydata_AI_tagNum_median_high)
models_tagNum[["Median: interaction"]] <- felm(interaction_formula, data = mydata_AI_tagNum_median_combined)
models_tagNum[["Mean: low"]] <- felm(subgroup_formula, data = mydata_AI_tagNum_mean_low)
models_tagNum[["Mean: high"]] <- felm(subgroup_formula, data = mydata_AI_tagNum_mean_high)
models_tagNum[["Mean: interaction"]] <- felm(interaction_formula, data = mydata_AI_tagNum_mean_combined)
models_tagNum[["1 vs 3-5: low"]] <- felm(subgroup_formula, data = mydata_AI_tagNum_extreme_low)
models_tagNum[["1 vs 3-5: high"]] <- felm(subgroup_formula, data = mydata_AI_tagNum_extreme_high)
models_tagNum[["1 vs 3-5: interaction"]] <- felm(interaction_formula, data = mydata_AI_tagNum_extreme_combined)
print(screenreg(
  models_tagNum,
  stars = c(0.1, 0.05, 0.01, 0.001),
  digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
  include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
  include.groups = FALSE, single.row = FALSE,
  omit.coef = omit_pattern
))
