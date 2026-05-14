# Variable Name Mapping

## Treatment & Interactions
treatment → Treatment
treatment:log_textLengthCNAI_fillna → Treatment × AI Length (log)
treatment:qualityAI_fillna → Treatment × AI Quality
treatment:AISimWithAcceptAI_fillna → Treatment × AI Sim w/ Accept

## Dependent Variables
experience_m2 → Experience
Iexperience_m2 → Experience Binary
insight_m2 → Insight
Iinsight_m2 → Insight Binary
alternative_m2 → Alternative

## Question Features
log_textLengthCN_ask → Question Length (log)
IimgNum_ask → Image Count
IaNum_ask → Link Count
IblockquoteNum_ask → Blockquote Count
ItableNum_ask → Table Count
lingComp_score → Linguistic Complexity
techJargon_score → Technical Jargon
difficulty_score → Difficulty Score

## Question Categories
category1 → Category 1
category2 → Category 2
category3 → Category 3
category4 → Category 4
category5 → Category 5
category6 → Category 6
category7 → Category 7
category8 → Category 8
category9 → Category 9

## Asker Features
log_age → Asker Age (log)
log_askBefore → Prior Questions (log)
log_resBefore → Prior Answers (log)
log_accumRep_ask → Accumulated Reputation (log)
accumGold_ask → Gold Badges
accumSilver_ask → Silver Badges
accumCopper_ask → Copper Badges
asker_acceptedBefore_allsite_1m → Accepted Answers (1m)
asker_nActivityBeforeAsk_allsite_1m → Questions (1m)
asker_nActivityBeforeResp_allsite_1m → Answers (1m)
asker_nActivityBeforeComment_allsite_1m → Comments (1m)
asker_acceptedBefore_allsite_2m → Accepted Answers (2m)
asker_nActivityBeforeAsk_allsite_2m → Questions (2m)
asker_nActivityBeforeResp_allsite_2m → Answers (2m)
asker_nActivityBeforeComment_allsite_2m → Comments (2m)
asker_acceptedBefore_allsite_3m → Accepted Answers (3m)
asker_nActivityBeforeAsk_allsite_3m → Questions (3m)
asker_nActivityBeforeResp_allsite_3m → Answers (3m)
asker_nActivityBeforeComment_allsite_3m → Comments (3m)

## AI Features
log_textLengthCNAI_fillna → AI Length (log, fillNA)
qualityAI_fillna → AI Quality (fillNA)
AISimWithAccept → AI Sim w/ Accept
AISimWithAcceptAI_fillna → AI Sim w/ Accept (fillNA)
