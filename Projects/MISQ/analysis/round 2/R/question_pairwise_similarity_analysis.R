library(readr)
library(dplyr)
library(stringr)
library(lubridate)
library(lfe)
library(texreg)
library(tidyr)

# ========== 1. load question-level panel ==========
load_question_pairwise_data <- function(
  data_path = "/Users/dylanchen/Desktop/geek-community/panel_factory/data/panels/question_panel.csv",
  tag_path = "/Users/dylanchen/Desktop/geek-community/panel_factory/data/raw/tagName_classified_GBK.csv",
  ai_start = as.Date("2023-09-13"),
  ai_end = as.Date("2024-12-30")
) {
  mydata <- read_csv(data_path, show_col_types = FALSE)

  mydata$askTime <- as.Date(mydata$askTime)
  mydata$crawldate <- as.Date(mydata$crawldate)
  mydata$age_que <- as.integer(mydata$crawldate - mydata$askTime)
  mydata$treatment <- mydata$preAI

  tag_df <- read.csv(tag_path, header = TRUE, sep = ",",
                     fileEncoding = "GBK", stringsAsFactors = FALSE)
  tag_df$tagName <- tidyr::replace_na(tag_df$tagName, "NA")

  mydata$tagName <- str_extract(mydata$tagURL, "(?<=/t/).*(?=/questions)")
  mydata$tagName <- URLdecode(mydata$tagName)
  mydata <- left_join(mydata, tag_df, by = "tagName")

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

  mydata <- mydata %>%
    mutate(
      dayofyear = as.Date(format(askTime, "%Y-%m-%d")),
      log_textLengthCN_ask = log(textLengthCN_ask + 1),
      log_age = log(age + 1),
      log_askBefore = log(askBefore + 1),
      log_resBefore = log(resBefore + 1),
      log_accumRep_ask = log(accumRep_ask + 4),
      IimgNum_ask = as.integer(imgNum_ask > 0),
      IaNum_ask = as.integer(aNum_ask > 0),
      IblockquoteNum_ask = as.integer(blockquoteNum_ask > 0),
      ItableNum_ask = as.integer(tableNum_ask > 0),
      log_textLengthCN1Ans = log(textLengthCN1Ans + 1)
    ) %>%
    filter(askTime >= ai_start & askTime <= ai_end)

  mydata
}

# ========== 2. controls ==========
base_controls <- paste(
  c(
    "log_textLengthCN_ask", "IimgNum_ask", "IaNum_ask", "IblockquoteNum_ask", "ItableNum_ask",
    "lingComp_score", "techJargon_score", "difficulty_score",
    paste0("category", 1:9),
    "log_age", "log_askBefore", "log_resBefore", "log_accumRep_ask",
    "accumGold_ask", "accumSilver_ask", "accumCopper_ask",
    "asker_acceptedBefore_allsite_1m", "asker_nActivityBeforeAsk_allsite_1m",
    "asker_nActivityBeforeResp_allsite_1m", "asker_nActivityBeforeComment_allsite_1m",
    "asker_acceptedBefore_allsite_2m", "asker_nActivityBeforeAsk_allsite_2m",
    "asker_nActivityBeforeResp_allsite_2m", "asker_nActivityBeforeComment_allsite_2m",
    "asker_acceptedBefore_allsite_3m", "asker_nActivityBeforeAsk_allsite_3m",
    "asker_nActivityBeforeResp_allsite_3m", "asker_nActivityBeforeComment_allsite_3m"
  ),
  collapse = " + "
)

# ========== 3. run models ==========
run_pairwise_models <- function(df) {
  models <- list()

  formula_base <- as.formula(
    paste0(
      "human_pairwise_similarity_mean ~ treatment + ",
      base_controls,
      " | dayofyear | 0 | 0"
    )
  )

  formula_interact <- as.formula(
    paste0(
      "human_pairwise_similarity_mean ~ treatment*(log_textLengthCN1Ans + quality1Ans) + ",
      base_controls,
      " | dayofyear | 0 | 0"
    )
  )

  models[["DV: human_pairwise_similarity_mean"]] <- felm(formula_base, data = df)
  models[["DV + interactions"]] <- felm(formula_interact, data = df)

  models
}

# ========== 4. output ==========
print_pairwise_table <- function(models, omit_pattern = NULL) {
  print(screenreg(
    models,
    stars = c(0.1, 0.05, 0.01, 0.001),
    digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
    include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE,
    robust = TRUE, include.groups = FALSE, single.row = FALSE,
    omit.coef = omit_pattern
  ))
}

# ========== 5. main ==========
mydata_pairwise <- load_question_pairwise_data()

# sample restriction:
# treatment: 至少 2 个 human answers
# control: 删除第一个 human answer 后，至少 2 个 human answers remaining => 原始至少 3 个
mydata_pairwise_analysis <- mydata_pairwise %>%
  filter(!is.na(human_pairwise_similarity_mean))

omit_pattern <- paste(
  c(
    "log_textLengthCN_ask", "IimgNum_ask", "IaNum_ask", "IblockquoteNum_ask", "ItableNum_ask",
    "lingComp_score", "techJargon_score", "difficulty_score",
    paste0("category", 1:9),
    "log_age", "log_askBefore", "log_resBefore", "log_accumRep_ask",
    "accumGold_ask", "accumSilver_ask", "accumCopper_ask",
    "asker_acceptedBefore_allsite_1m", "asker_nActivityBeforeAsk_allsite_1m",
    "asker_nActivityBeforeResp_allsite_1m", "asker_nActivityBeforeComment_allsite_1m",
    "asker_acceptedBefore_allsite_2m", "asker_nActivityBeforeAsk_allsite_2m",
    "asker_nActivityBeforeResp_allsite_2m", "asker_nActivityBeforeComment_allsite_2m",
    "asker_acceptedBefore_allsite_3m", "asker_nActivityBeforeAsk_allsite_3m",
    "asker_nActivityBeforeResp_allsite_3m", "asker_nActivityBeforeComment_allsite_3m"
  ),
  collapse = "|"
)

models <- run_pairwise_models(mydata_pairwise_analysis)
print_pairwise_table(models, omit_pattern)
