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

Our study investigates internal GenAI’s impact on two outcomes: answerer participation and answer innovation.

For answerer participation, we distinguish between two behavioral margins. The first concerns human participation after a question is posted. Here, we examine all human answers that the question subsequently receives. We use two dependent variables. The first is the logarithm of the number of human-generated answers a question receives within 7 days of posting. We focus on the 7-day window because most answer activity occurs shortly after posting, which limits the influence of long-tail observations. The second dependent variable captures the hazard of receiving the first human answer. A lower hazard indicates slower human participation.

The second participation margin concerns human responses after the first answer has already appeared. Here, the dependent variables shift from question-level participation after posting to post-first-answer participation. We therefore examine the logarithm of the number of following answers received within 7 days and the hazard of receiving the second answer.

For answer innovation, our main outcome is the similarity between the first answer and the second answer. This similarity-based measure captures whether later human answerers differentiate their contributions from the answer already displayed on the page, therefore captures the answer innovation. We then examine three more specific directions of differentiation: whether the answer contains personal experiences, opinionated insights, and alternative solutions. To quantify these dimensions, we use an LLM to rate answers on a 0-10 scale for the presence of each element and convert the scores into binary indicators, where 0 denotes absence and any positive score denotes presence.

Because our theory also concerns how answerers respond to answer quality, we further introduce interaction analyses using two quality proxies. The first is answer length, which captures how substantively developed an answer appears. The second is similarity with LLM, which captures how close an observed answer is to a benchmark answer generated by a strong LLM. Specifically, we use Opus 4.7 to generate benchmark answers because it is the strongest model for the technical question-answering context we study. A higher similarity with LLM indicates that the focal answer more closely resembles what a state-of-the-art model would provide and thus serves as a proxy for answer quality.

## 4.3. Econometric Models

To examine how AI-generated answers shape subsequent answerer participation, we organize the empirical analysis around the answer sequence shown in Figure 3. Figure 3 motivates two related setups that focus on different behavioral margins. In Setup 1, the AI-generated answer is treated as part of the initial question-side condition, so the empirical focus is on all human answers that arrive after the question is posted. In Setup 2, the focal comparison shifts to the identity of the first answer itself. As Figure 3 shows, Setup 2 excludes the first answer itself from the dependent variable and focuses only on the answers that come after it. The key distinction from Setup 1 is therefore the dependent variable: instead of examining all human answers to the question, we examine only post-first-answer responses. More importantly, Setup 2 captures a direct competition setting between AI and human answers by asking whether later participation and innovation differ when the first answer is AI rather than human.

We first consider Setup 1, in which the AI-generated answer is treated as part of the initial question-side stimulus. In this setup, the platform condition differs at the moment the question becomes visible: some questions are accompanied by an AI answer, whereas others are not. The outcome of interest is then the full set of human answers that follow. As Figure 3 illustrates, Setup 1 tracks all subsequent human participation after the question is posted and asks whether attaching an AI answer changes how many human answers arrive and how quickly the first human answer appears.

For answerer participation in Setup 1, we estimate:

```text
answererParticipation_i = β0 + β1 AI_i + β2 (AI_i × quality_i) + X_iγ + questionTiming_i + ε_i        (1)
```

where `i` indexes questions. `answererParticipation_i` is measured either as the logarithm of the number of human answers received within 7 days or as the hazard of receiving the first human answer. `AI_i` indicates treatment assignment (`1` if the question has an AI-generated answer, `0` otherwise). `quality_i` captures the quality of the AI-generated answer and is measured using its length and its similarity with LLM (with 0 filled for control group). `X_i` includes question characteristics, questioner characteristics, and question type controls, while `questionTiming_i` captures question posting date fixed effects. For the hazard specification, we estimate a Cox proportional hazards model:

```text
h(t|X) = h0s(t) exp[β1 AI_i + β2 (AI_i × quality_i) + X_iγ + questionTiming_i + ε_i]
```

where the baseline hazard is allowed to vary across posting days through stratification. A lower hazard ratio indicates slower arrival of the first human answer.

We next consider Setup 2, in which the first answer becomes the focal reference point. Here, the first answer can be either AI-generated or human-generated, and the empirical question is how later contributors react to that first visible answer. By conditioning on the presence of a first answer and then comparing whether that answer is AI or human, Setup 2 isolates the competition between AI and human answers more directly. The dependent variables are therefore redefined around what happens after the first answer appears rather than after the question is posted. Specifically, we examine the logarithm of the number of following answers within 7 days and the hazard of receiving the second answer. We also interact `AI_i` with the quality of the first answer.

For answer innovation, we estimate:

```text
answerInnovation_i = β0 + β1 AI_i + β2 (AI_i × quality1Ans_i) + X_iγ + questionTiming_i + ε_i        (2)
```

where `answerInnovation_i` is measured in two layers. We first examine whether later human answers exhibit innovation at all, using the similarity between the first answer and the second answer. A lower similarity indicates greater differentiation from the existing answer. We then examine the direction of that innovation through three more specific outcomes: whether the later answer contains personal experiences, opinionated insights, and alternative solutions. In other words, the logic is first to assess whether later human answers become more differentiated, and then to examine how that differentiation occurs in substantive terms. The interaction terms test whether human innovation varies with the quality of the focal answer already displayed on the page.

## 4.4. Endogeneity and Random Assignment

Our empirical strategy depends critically on the random assignment of questions to treatment and control groups. To validate this assignment, we conduct t-tests and examine standardized differences (Austin, 2009) across pre-assignment variables including questioner characteristics (reputation scores and gold, silver, bronze medal counts, total questions asked, total answers provided, account age), questioner platform activity in the 1, 2, and 3 months prior to the experiment (number of accepted answers, answers provided, questions asked, and comments posted), and question content features (length measured by Chinese character count, presence of multimedia elements such as photos, hyperlinks, tables, and block quotes). We also employ a large language model (LLM) to evaluate question characteristics, including linguistic complexity, technical jargon use, and difficulty (P. Li et al., 2024). Details about measure generation appear in Online Appendix B. We also account for question categories and the timing of question posting.

Online Appendix Table A1 presents balance check results demonstrating excellent balance across groups. All t-tests yield statistically insignificant results (`p-values > 0.05`), indicating no significant differences in pre-treatment variables. All standardized differences fall well below the `0.10` threshold, with absolute values ranging from `0.003` to `0.061`.

Additionally, regression-based balance checks in Online Appendix Table A2 provide both an omnibus test of overall balance and coefficient-level diagnostics for individual covariates. This analysis accounts for question categories and posting timing. The results consistently confirm successful random assignment.

# 5. RESULTS

## 5.1. Summary Statistics

Table 2 reports summary statistics of our main variables. Questions in our sample average 86.809 Chinese characters and receive an average of 1.293 human-generated answers. On average, all answers associated with a question receive 0.489 net likes, while the similarity between the second answer and the first answer averages 0.420.

The treatment group exhibits notable differences from the control group. Treated questions are slightly shorter on average (84.233 vs. 89.272 Chinese characters) and receive fewer human-generated answers (1.209 vs. 1.372). They also receive fewer net likes across answers (0.436 vs. 0.536). At the same time, the treatment group also shows a higher average similarity between the second answer and the first answer than the control group (0.432 vs. 0.397). We note that this descriptive difference does not account for answer quality heterogeneity or other controls.

The table also summarizes the quality-related variables used in our interaction analyses. For treated questions, the AI-generated answer has an average logged length of 5.676 and an average similarity with LLM of 0.555. The first answer, whether AI-generated or human-generated, has an average logged length of 4.662 in the full sample, with a higher mean in the treatment group than in the control group (5.676 vs. 3.443). Likewise, the similarity between the first answer and LLM averages 0.506 overall and is higher in the treatment group (0.555 vs. 0.445).

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

Tables 3 and 4 report the effects of AI-generated answers on answerer participation across the two econometric setups. Consistent with Figure 3, Setup 1 examines all human answers to a question after the question is posted, whereas Setup 2 examines only the answers that arrive after the first answer has already appeared.

Table 3 reports Setup 1. In Column 1, where answerer participation is measured as the logarithm of the number of human answers received within 7 days, AI-generated answers significantly reduce subsequent human participation (`β = -0.046`, `p < 0.001`). This estimate implies that attaching an AI-generated answer to the question lowers the supply of subsequent human answers.

We next examine whether this participation effect depends on the quality of the AI-generated answer. Our motivation is that users may not respond only to the presence of AI, but also to how strong the displayed AI answer appears. We therefore interact the AI indicator with two quality proxies: answer length and similarity with LLM. Length captures how substantively developed the AI answer appears. Similarity with LLM captures how close the AI answer is to a benchmark answer produced by a state-of-the-art model, which we interpret as a proxy for answer quality. As shown in Column 2, the interaction between AI and AI answer length is negative and significant (`β = -0.045`, `p < 0.01`), indicating that longer AI answers further suppress subsequent human participation. By contrast, the interaction between AI and similarity with LLM is statistically insignificant (`β = -0.038`, `n.s.`).

Columns 3 and 4 of Table 3 turn to answer timing using a Cox proportional hazards model. Here the dependent variable is the hazard of receiving the first human answer. We estimate `coxph(surv_human_answer ~ treatment + treatment:(log_textLengthCNAI_fillna + AISimWithOpus47_fillna) + strata(dayofyear), ties = "efron")`, which stratifies the baseline hazard by question posting day and uses Efron’s method to handle tied event times. In Column 3, AI-generated answers significantly reduce the hazard of receiving the first human answer (`β = -0.145`, `p < 0.001`), implying slower human entry. In Column 4, the interaction between AI and AI answer length is again negative and significant (`β = -0.227`, `p < 0.001`), whereas the interaction with similarity with LLM remains insignificant (`β = 0.056`, `n.s.`). Taken together, Table 3 suggests that AI-generated answers reduce answerer participation both in the number of human answers and in the speed with which the first human answer arrives, and that these participation-reducing effects are especially pronounced when the AI answer is longer.

Table 4 reports Setup 2, where we compare post-first-answer dynamics depending on whether the first answer is AI-generated or human-generated. The key difference from Setup 1 is that the dependent variables now focus only on later contributions after the first answer appears. In Column 1, when the first answer is AI-generated, the number of following answers within 7 days is significantly higher (`β = 0.347`, `p < 0.001`). Column 3 shows a similar pattern for the timing outcome: the hazard of receiving the second answer is significantly higher when the first answer is AI-generated (`β = 0.713`, `p < 0.001`). Thus, conditional on the first answer already being present, an AI first answer is associated with more active subsequent participation than a human first answer.

Columns 2 and 4 further show that this Setup 2 effect varies with the quality of the first answer. In Column 2, the main effect of first-answer length is negative (`β = -0.026`, `p < 0.05`), and the interaction between AI and first-answer length is also negative (`β = -0.058`, `p < 0.05`). This pattern indicates that although AI as the first answer attracts more following participation on average, that participation advantage narrows when the AI first answer is longer. In Column 4, first-answer length again reduces the hazard of receiving the second answer (`β = -0.208`, `p < 0.001`), but the interaction with AI is not statistically significant. Similarity with LLM and its interaction with AI are statistically insignificant in both columns. Overall, Tables 3 and 4 together show that AI-generated answers discourage human participation when attached to the question at the outset, but once the first answer is already on the page, an AI first answer elicits more subsequent participation than a human first answer, especially when that first answer is not overly extensive.

## 5.3. Answer Innovation

We next examine how human answerers adjust the content of their responses. Our central interest is answer innovation, which we conceptualize as differentiation from the answer that is already displayed on the page. We begin with a similarity-based measure and then turn to more specific differentiation dimensions.

Table 5 reports the similarity-based results. In Column 1, the coefficient on `AI_i` is positive and significant (`β = 0.029`, `p < 0.01`), which by itself would suggest that when the first answer is AI-generated, the second answer becomes more similar rather than more differentiated. However, we do not treat this main effect as our preferred interpretation because it pools together AI first answers of very different quality. A later human answer may look more similar simply because some AI first answers are short, generic, or low quality and thus provide a weak benchmark for strategic differentiation.

For this reason, Column 2 introduces the same quality-based interaction logic as in the participation analysis. We interact the AI indicator with first-answer length and with similarity with LLM. The latter is especially important here because it captures whether the first answer resembles a benchmark answer produced by a state-of-the-art LLM and therefore whether it represents a high-quality reference point from which later human answerers may want to differentiate. Consistent with this argument, the main effect of similarity with LLM is strongly positive (`β = 0.494`, `p < 0.001`), indicating that higher-quality first answers generally induce more overlap in the second answer. Crucially, however, the interaction between AI and similarity with LLM is negative and significant (`β = -0.109`, `p < 0.05`). This result shows that when the first answer is AI-generated and also closely resembles the LLM benchmark, the second human answer becomes less similar to it. In other words, human answerers differentiate more strongly when facing a higher-quality AI answer. By contrast, the interaction between AI and first-answer length is small and statistically insignificant (`β = 0.002`, `n.s.`).

Taken together, the similarity-based evidence suggests that the unconditional positive coefficient on `AI_i` in Column 1 is not the most informative estimate for understanding human adaptation. The more revealing result comes from the interaction specification in Column 2: high-quality AI answers induce greater differentiation by later human answerers. This pattern is consistent with our argument that answerers strategically respond to strong AI content not by copying it, but by moving away from it.

Table 6 examines three more specific directions of answer innovation. AI-generated answers significantly increase the likelihood that subsequent human answers contain personal experiences (`β = 0.030`, `p < 0.01`), opinionated insights (`β = 0.024`, `p < 0.05`), and alternative solutions (`β = 0.016`, `p < 0.05`). These results complement the similarity-based evidence by showing how differentiation occurs in practice. Rather than merely reducing textual overlap with AI-generated answers, human answerers appear to contribute content that is more experiential, more interpretive, and more solution-diverse. Together, Tables 5 and 6 indicate that although AI-generated answers can crowd out participation, they also induce the human answers that do appear to become more differentiated along dimensions in which human contributors retain comparative advantages.
