# Regression Conventions

## Sample Definitions
- `mydata_answer` → All human answers
- `mydata_answer_firstHumanAns` → First human answer only
- `mydata_AI` → Question-level data (AI treatment)

## Variable Naming Patterns
- `*_fillna` → Filled with 0 for control group
- `I*` prefix → Binary indicator
- `log_*` → Log-transformed
- `accum*` → Accumulated/cumulative measure

## Standard Controls
- Question features: `log_textLengthCN_ask`, `IimgNum_ask`, `IaNum_ask`, `IblockquoteNum_ask`, `ItableNum_ask`, `lingComp_score`, `techJargon_score`, `difficulty_score`
- Question categories: `category1` - `category9`
- Asker features: `log_age`, `log_askBefore`, `log_resBefore`, reputation/badges, activity metrics (1m/2m/3m windows)

## Standard Fixed Effects
- `answer_timing` → Answer timing FE

## Standard SE
- Robust SE, no clustering (third argument = 0 in felm)
