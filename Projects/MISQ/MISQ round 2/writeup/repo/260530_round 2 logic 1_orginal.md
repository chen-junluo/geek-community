# 4. EMPIRICAL ANALYSIS

## 4.1. SegmentFault and a Randomized Field Experiment on Internal GenAI

Our study examines data from SegmentFault, a prominent Chinese technical Q&A community specializing in IT and software development. Founded in 2012, SegmentFault serves nearly 7 million users and facilitates knowledge exchange across web/mobile development, AI, cloud computing, and cybersecurity. As of April 2024, the platform contains over 310,000 technical questions with 1.9 answers per question on average. Among global technical Q&A communities, SegmentFault ranks sixth in questions asked, third in answers provided, and first in answer-to-question ratio. It constitutes an essential resource for Chinese developers, programmers, and IT engineers who seek knowledge, solutions, and collaboration opportunities.

SegmentFault’s ecosystem relies on user-generated content and interactions. Members pose questions, provide answers, participate in discussions, and express approval through “accept” or “like” actions. The operations team reviews user-contributed solutions before publishing them. Features enhancing engagement include comment sections for each answer, a voting system enabling questioners to “accept” answers while viewers upvote or downvote, and a reputation system rewarding members with points and medals based on contribution quantity and quality.

Our study leverages a randomized field experiment conducted by SegmentFault. Beginning September 13, 2023, the platform conducted an A/B test of its internal GenAI. Each newly posted question was randomly assigned to either the treatment group (receiving an AI-generated answer) or the control group (receiving no AI answer). Each question received an independent random assignment upon posting, with no systematic variation by questioner characteristics, time periods, or other factors. This question-level randomization offers a unique opportunity to investigate how internal GenAI affects user behaviors and community dynamics in the presence of external GenAI. Online Appendix A provides detailed background information.

**Figure 2. Illustration of treatment and control questions**

Figure 2 illustrates differences between “treated questions” (with AI answers) and “control questions” (without). While the platform records precise timestamps for human answers, it omits this for AI answers. We observe that AI answers appear within five minutes of question posting, substantially faster than human answers, which arrive after an average nine-hour delay. Consequently, AI answers typically occupy the first position for treated questions. AI answers also differ from human answers because they cannot receive endorsements from questioners or votes from viewers.

Community members can provide answers regardless of the presence of an AI-generated answer. When an AI-generated answer exists, viewers typically see this content before human-generated answers. The platform initially displays only two lines of AI-generated content on the question page. Viewers can access the complete answer via a “View More” button, which triggers a pop-up window labeled “AI Answers” with a disclaimer that alerts users to potential errors or inaccuracies and indicates the content is for reference only.

We crawled data from SegmentFault in February 2024. Our main analyses focus on the 150-day window from September 2023 (when the field experiment began) to February 2024. We collected all questions posted during this timeframe. Our dataset comprises 3,613 questions posted by 1,404 unique users during this 150-day window, averaging 24 new questions daily. AI-generated answers appeared in 1,766 questions (48.9% of total). We also collect other posts when necessary for mechanism analysis or posthoc analysis.

The platform assigns each question a tag as a content summary. Based on 384 unique tags, we classify questions into ten categories: web and mobile development, software design and architecture, cloud computing, databases, computer networks and systems, AI and machine learning, development tools and environment, programming languages, career and professional development, and other. “Web and mobile development” is the largest category, accounting for 57.5% of questions.

## 4.2. Main Variables of Interest

Our study investigates internal GenAI’s impact on human answer supply and innovation (of human answers). For answer supply, the change of users’ paraticipation probability will be reflected in the time-difference between each answers. A smaller pararticipation probability will lead to longer time delay and lower total number of answers. Thus, we analyze the number of human-provided answers per question, primarily measuring answers received within 7 days of posting (when approximately 80% of questions receive all answers). This approach mitigates potential outliers from long-tail effects where some questions continue receiving answers long after posting. We also examine total human answers for robustness.

To examine specific innovations that might be brought by answerers, we identify three areas where humans potentially have unique advantages: incorporation of personal experiences, expression of opinionated insights, and suggestion of alternative solutions. To quantify these dimensions, we use an LLM that we instruct to rate answers on a scale of 0-10 for the presence of personal experiences, opinionated insights, and alternative solutions. Given the prevalence of zero scores, we dichotomize these variables, categorizing answers scoring 0 as not containing the element and all others as containing it. Using the specification from Equation 2, we regress these binary outcomes on treatment status.

## 4.3. Econometric Models

To examine AI-generated answers’ impact on human answerers, as illustrated in Figure 4, we consider two parallel econometric setups. The first setup consider having us not having the AI answer as the exongenous shock and inspect the change in 1st human answers’ timing and innovation. The second setup considers the 1st answer’s impact on the second answer, where the 1st answer can be either human answer or AI answer.

**Figure 3. Econometric Setup**

Under the setup, we build two models and estimate:

```text
answererParticipation_i = β0 + β1 AI_i + X_iγ + questionTiming_i + ε_i        (1)
```

where `i` indexes questions, `answerFreq_i` is answer frequency as measured by two variables, `answerNum_i` is the logarithm of human answers received by question `i` within 7 days. `1stanswerTime_i` measures the time between question and first human answers received by question `i`. `AI_i` indicates treatment assignment (`1` if the question has AI-generated answer, `0` otherwise), `X_i` includes control variables (questioner characteristics, question content, and question type), and `questionTiming_i` captures question posting date fixed effects. The coefficient `β1` captures the effect of AI-generated answers on the supply of human answers.

To examine where human show different response to AI-generated answers’ vs. Human generated answers, we consider AI answer as a same role of human answers as illustrated in Figure 4 and estimate:

```text
answerInnovation_i = β0 + β1 AI_i + X_iγ + questionTiming_i + ε_i        (1)
```

where `i` indexes questions, `answerInnovation_i` is answer innovation as measured by the similarity between the first answer and second answer. `AI_i` indicates treatment assignment (`1` if the question has AI-generated answer, `0` otherwise), `X_i` includes control variables (questioner characteristics, question content, and question type), and `questionTiming_i` captures question posting date fixed effects. The coefficient `β1` captures the effect of AI-generated answers on the supply of human answers.

## 4.4. Endogeneity and Random Assignment

Our empirical strategy depends critically on the random assignment of questions to treatment and control groups. To validate this assignment, we conduct t-tests and examine standardized differences (Austin, 2009) across pre-assignment variables including questioner characteristics (reputation scores and gold, silver, bronze medal counts, total questions asked, total answers provided, account age), questioner platform activity in the 1, 2, and 3 months prior to the experiment (number of accepted answers, answers provided, questions asked, and comments posted), and question content features (length measured by Chinese character count, presence of multimedia elements such as photos, hyperlinks, tables, and block quotes). We also employ a large language model (LLM) to evaluate question characteristics, including linguistic complexity, technical jargon use, and difficulty (P. Li et al., 2024). Details about measure generation appear in Online Appendix B. We also account for question categories and the timing of question posting.

Online Appendix Table A1 presents balance check results demonstrating excellent balance across groups. All t-tests yield statistically insignificant results (`p-values > 0.05`), indicating no significant differences in pre-treatment variables. All standardized differences fall well below the `0.10` threshold, with absolute values ranging from `0.003` to `0.061`.

Additionally, regression-based balance checks in Online Appendix Table A2 provide both an omnibus test of overall balance and coefficient-level diagnostics for individual covariates. This analysis accounts for question categories and posting timing. The results consistently confirm successful random assignment.

# 5. RESULTS

## 5.1. Summary Statistics

Table 2 reports summary statistics of our data. Questions in our sample average 86.809 Chinese characters and receive an average of 1.293 human answers, with 76.1% of questions receiving at least one answer. Questioners “accept” answers for 32.2% of all questions.

The treatment group exhibits notable differences from the control group. It receives fewer human answers (1.209 vs. 1.372) and has a lower proportion of accepted answers (29.3% vs. 35.0%). On question pages, viewers can upvote or downvote answers, with the page displaying net likes (upvotes minus downvotes) for each answer. Answers in our sample average 0.489 net likes, with the treatment group receiving fewer (0.436 vs. 0.536).

SegmentFault employs a reputation system where users accumulate reputation scores based on their contributions. Reputation scores in our sample range from -3 to 28,800, with an average of 378.337. This average roughly corresponds to 10 questions, each receiving about 2 upvotes.

**Table 2. Descriptive statistics of main variables**

| Variable | All samples | Treatment group | Control group | Min | Max |
| --- | ---: | ---: | ---: | ---: | ---: |
| question length (number of Chinese characters) | 86.809 | 84.233 | 89.272 | 0.000 | 2702.000 |
|  | (113.981) | (89.347) | (133.323) |  |  |
| number of human-generated answers received by a question | 1.293 | 1.209 | 1.372 | 0.000 | 8.000 |
|  | (1.166) | (1.133) | (1.192) |  |  |
| similarity between the second answer to the first answer | 0.420 | 0.432 | 0.397 | -0.048 | 0.991 |
|  | (0.181) | (0.175) | (0.188) |  |  |
| average number of net likes received by all the answers to a question | 0.489 | 0.436 | 0.536 | -3.000 | 14.000 |
|  | (1.096) | (1.041) | (1.140) |  |  |
| log of length for AI-generated answer (with 0 filled for control group) | 2.774 | 5.676 | 0.000 | 0.000 | 6.977 |
|  | (2.864) | (0.556) | (0.000) |  |  |
| similarity between AI-generated answer and LLM (with 0 filled for control group) | 0.271 | 0.555 | 0.000 | 0.000 | 0.891 |
|  | (0.297) | (0.152) | (0.000) |  |  |
| log of length for the first answer | 4.662 | 5.676 | 3.443 | 0.000 | 7.912 |
|  | (1.489) | (0.556) | (1.338) |  |  |
| similarity between the first answer and LLM | 0.506 | 0.555 | 0.445 | -0.090 | 0.911 |
|  | (0.177) | (0.152) | (0.187) |  |  |

**Notes:**
1. Columns 2-4 present the means of the main variables, with the standard deviations shown in parentheses below each mean.
2. The minimum question length of 0 represents questions where users posted content solely through images without accompanying text. These cases comprise 2.71% of our sample (98 out of 3,613 observations). Our main results remain unchanged when these observations are excluded.

## 5.2. Answerer Participation

Table 3 presents our main findings on AI-generated answers’ impact on participation.

Answer Supply (Columns 1-4). We progressively add controls, moving from a baseline model without covariates and question timing FE (Column 1) to models with question timing FE (Column 2) to question characteristics (Column 3) to questioner characteristics (Column 4). AI-generated answers significantly reduce human answer supply across all specifications. Our preferred specification (Column 4) includes the full set of controls, which improves the precision of treatment effect estimation by reducing residual variance. This specification shows that AI-generated answers cause a statistically significant 4.6% decrease in human answers (`β = -0.046`, `p < 0.001`).

**Table 3. The impact of AI-generated answers on the answer supply and viewer recognition**

|  | (1) | (2) | (3) | (4) |
| --- | ---: | ---: | ---: | ---: |
| DV: | log of the number of human answers provided within 7 days (`answerNum_i`) |  | harzard first human answer (`harzardFirstHuman_i`) |  |
| `AI_i` | -0.046 *** | 0.226 ** | -0.145 *** | 1.113 *** |
|  | (0.011) | (0.085) | (0.042) | (0.314) |
| `AI_i * AILength_i` |  | -0.045 ** |  | -0.227 *** |
|  |  | (0.014) |  | (0.052) |
| `AI_i * AISimWithLLM_i` |  | -0.038 |  | 0.056 |
|  |  | (0.051) |  | (0.197) |
| question controls | √ | √ | √ | √ |
| questioner controls | √ | √ | √ | √ |
| question timing FE | √ | √ | √ | √ |
| N | 3,613 | 3,603 | 3,613 | 3,603 |

**Notes:**
1. `*** p < 0.001`; `** p < 0.01`; `* p < 0.05`.
2. Question timing FE indicates the date on which the question was posted.
3. Answer timing FE indicates the date on which the answer was posted.
4. We log-transformed `answerNum_i` but not `netlikeNum_ij` because `netlikeNum_ij` contains negative values (net likes can be negative when downvotes exceed upvotes), which precludes log-transformation.

AI label is a negative signal of quality. Length is a positive siginal of quality.

**Table 4. The impact of AI-generated answers on the answer supply and viewer recognition**

|  | (1) | (2) | (3) | (4) |
| --- | ---: | ---: | ---: | ---: |
| DV: | log of the number of following answers provided within 7 days (`answerNum_i`) |  | harzard second answer (`harzardSecondAns_i`) |  |
| `AI_i` | 0.347 *** | 0.684 *** | 0.713 *** | 1.239 * |
|  | (0.016) | (0.139) | (0.081) | (0.544) |
| `length1Ans_i` |  | -0.026 * |  | -0.208 *** |
|  |  | (0.010) |  | (0.052) |
| `simWithLLM1Ans_i` |  | -0.025 |  | -0.063 |
|  |  | (0.071) |  | (0.364) |
| `AI_i * length1Ans_i` |  | -0.058 * |  | -0.073 |
|  |  | (0.024) |  | (0.097) |
| `AI_i * simWithLLM1Ans_i` |  | -0.033 |  | -0.050 |
|  |  | (0.105) |  | (0.477) |
| question controls | √ | √ | √ | √ |
| questioner controls | √ | √ | √ | √ |
| question timing FE | √ | √ | √ | √ |
| N | 3,613 | 3,173 | 3,613 | 3,173 |

## 5.3. Answer Innovation

Our analysis reveals two key challenges facing human answerers in online Q&A communities influenced by internal GenAI: a decreased answer supply due to diminished perceived value of human contributions and elevated quality expectations from viewers. This raises the question: How do human answerers respond to these challenges?

We posit that human answerers may adopt differentiation strategies to distinguish their contributions from AI-generated content. This approach is particularly viable in technical domains for two reasons. First, the structured nature of technical questions—typically concise with code snippets—enables answerers to anticipate and customize responses based on established norms (Calefato et al., 2018). Second, AI-generated answers create an opportunity for humans to provide complementary insights that demonstrate their unique value through domain expertise and contextual understanding.

To investigate whether people differentiate their answers in the presence of AI-generated answers, we measure text similarity between first and second answers using Sentence-BERT architecture (Reimers & Gurevych, 2019). In the treatment group, the first answer is AI-generated. In the control group, the first answer is human-generated. In this setting, the similarity score between the first and second questions reflects how much the human answerer adjust their response if the first question changes from human answer to AI answer.

As shown in Table 16, when the first answer is AI-generated, the similarity between the first and second answers decreases significantly (`β = -0.034`, `p < 0.001`), representing a 0.202 standard deviation change. One potential concern is that text length might systematically influence similarity calculations. As the first AI answer in the treatment group tends to be lengthy compared to the first human answer in the control group, we control for LLM-enabled content quality ratings and the first answer length in Column 2. This adjustment reveals an even stronger effect (`β = -0.132`, `p < 0.001`). This finding confirms that human answerers do differentiate their answers in the presence of AI-generated answers.

The results, reported in Columns 3-5 of Table 16, indicate that AI-generated answers significantly increase the likelihood of human answers containing personal experiences (`β = 0.030`, `p < 0.01`), opinionated insights (`β = 0.024`, `p < 0.05`) and alternative solutions (`β = 0.016`, `p < 0.05`). These findings suggest that human answerers can leverage their experiential knowledge and unique cognitive abilities to adjust their responses to complement or diverge from AI-generated answers.

**Table 5. Human answerers’ response to AI-generated answers**

|  | (1) | (2) |
| --- | ---: | ---: |
| DV: | similarity between the fisrt answer and the second answer |  |
| `AI_i` | 0.029 ** | 0.008 |
|  | (0.009) | (0.055) |
| `length1Ans_i` |  | 0.005 |
|  |  | (0.005) |
| `simWithLLM1Ans_i` |  | 0.494 *** |
|  |  | (0.038) |
| `AI_i * length1Ans_i` |  | 0.002 |
|  |  | (0.010) |
| `AI_i * simWithLLM1Ans_i` |  | -0.109 * |
|  |  | (0.049) |
| question controls | √ | √ |
| questioner controls | √ | √ |
| question timing FE | √ | √ |
| N | 1,913 | 1,888 |

**Notes:**
1. `*** p < 0.001`; `** p < 0.01`; `* p < 0.05`.
2. Question timing FE indicates the date on which the question was posted.

**Table 6. Human answerers’ response to AI-generated answers**

|  | (3) | (4) | (5) |
| --- | ---: | ---: | ---: |
| DV: | whether the answer contains personal experience | whether the answer contains opinionated insights | whether the answer contains alternative solutions |
| `AI_i` | 0.030** | 0.024* | 0.016* |
|  | (0.011) | (0.010) | (0.008) |
| question timing FE | √ | √ | √ |
| controls | √ | √ | √ |
| N | 4,634 | 4,634 | 4,634 |

**Notes:**
1. `*** p < 0.001`; `** p < 0.01`; `* p < 0.05`.
2. Question timing FE indicates the date on which the question was posted.
