# CLAUDE.md

- 本文件服务于 `Projects/MISQ/` 目录内的长期 project context。
- 在该目录内工作时，除遵守上层 `CLAUDE.md` 与 `Projects/CLAUDE.md` 外，还应优先参考本文件记录的 paper context、revision logic 与 interpretation boundaries。
- 本文件重点不是通用 coding rules，而是保存这个 `MISQ` project 的研究设定、理论转向与结果口径，避免后续反复口头重建。

---
## 1. Project identity and research question

- 这是一个面向 `MISQ` 的 revise-and-resubmit project；当前已收到 `Major Revision` decision，`Projects/MISQ/MISQ round 2/` 主要承接 round-2 analysis、meeting materials 与 writeup。
- 研究场景：基于 `SegmentFault` 的 randomized field experiment，识别 platform-specific internal `GenAI` 对社区人类用户行为的 causal impact。
  - 核心环境特征：平台内置 AI 已上线，但 external general-purpose AI（如 `ChatGPT`）在研究场景中也已广泛可得。
  - 因而 paper 的识别重点不是“有没有 AI”，而是“平台内置、带有 platform-specific identity 的 internal AI”如何重塑社区内 human behavior。
- 主要受影响对象：
  - `answerers`：是否参与回答、投入多少 effort、最终回答质量、是否采取 differentiation strategy。
  - `viewers`：如何评价人类回答，尤其是对 human answers 的 recognition / net likes。
  - `questioners`：retention、dialogue 等 downstream engagement 是否受影响。
- 核心 paper question：当技术社区平台引入 internal `GenAI` answerer 后，在 external AI 已普及的条件下，它会如何改变 human contributors 与 other users 的行为、认知与互动结构？

---
## 2. Round-1 main results and prior framing

- round 1 的主结论是：internal `GenAI` overall crowds out human answers，并改变 viewers 对 human answers 的评价。
- 原 `H1`：AI reduces human answer supply。
  - 理论基础：dual-process theories，主要借助 `ELM` / `Heuristic-Systematic Model`。
  - 原机制分解：
    - `Content Effect`，约 `26%`：AI answer 的高质量、全面性使 human effort 显得 redundant，偏 `central route`。
    - `Position Effect`，约 `20%`：AI 几乎瞬时占据 first-answer position，压缩 human first responders 的机会，横跨两条 route。
    - `Source Effect`，约 `54%`：仅由 AI source label 带来的 deterrence，独立于 content 与 position，偏 `peripheral route` / automation bias。
  - 关键经验事实：即便同时控制 content quality 与 position，AI coefficient 仍显著为负；而高声誉 human answerer 并不能产生同等 deterrence，说明存在 AI-specific illusion of authority。
- 原 `H2`：AI reduces viewer recognition of human answers，体现为对 human answers 的 `net likes` 下降。
  - 已排除机制：
    - `attention diversion`：comments 未下降。
    - `quality degradation`：answerer expertise 与 answer quality 未下降。
  - 支持机制：`Elevated Expectations`，基于 `Expectation Disconfirmation Theory`。
    - 当 first answer quality 处于 top `25%` 时，AI 对 human-answer `net likes` 的负向作用显著。
    - 当 quality 处于 bottom `25%` 时，该效应消失。
- 正向 adaptation：human answerers 在 AI presence 下更倾向做 differentiation。
  - `Sentence-BERT` similarity 显著下降。
  - 三个由 `LLM` 评分的维度上升：更多 personal experiences、opinionated insights、alternative solutions。
- null effects：questioner retention、questioner-answerer dialogue、question viewership 未发现显著变化。

---
## 3. Round-2 theoretical pivot and current main story

- round 2 的 aggregate result 仍保留一个核心事实：AI overall reduces the number of human answers。
- 但理论核心已经改变：不再把 AI source 直接解释为 deterrence，而是改成 `AI has two roles simultaneously`。
  - Role 1：AI is a competitor perceived as weak。
    - 当 answerers 只看到 AI label 时，初始直觉不是“被吓退”，而是“this is weak, I can beat it”。
    - 这是 fast, identity-based competitive response；不要求先读内容。
    - 该逻辑尤其适用于 expert community setting：`SegmentFault` 是 human experts 的 territory。
  - Role 2：AI content creates real competitive pressure。
    - 一旦 answerers 开始处理 AI 实际写了什么，content 的长度与质量就会带来 concrete competition。
    - content signal 可以 reinforce，也可以 override 初始的 weak-competitor perception。
- 这两个 role 发生在不同 timescale，并对应两个 decision stages：
  - Decision 1：`should I participate?`
    - 属于 fast decision，对应 `System 1`。
    - 主要看 fast signal，尤其是 `length`。
    - 逻辑：answerer 不需要精读，只需 glance 一眼，就能从篇幅判断“space 是否已被占据”。
  - Decision 2：`how much effort should I invest?`
    - 属于 slow decision，对应 `System 2`。
    - 主要看 slow signal，尤其是 `quality`。
    - 逻辑：只有在已经决定回答后，answerer 才会认真评估 AI answer 到底写得多好，并据此调整自身 effort。
- round-2 的核心 theoretical mapping：
  - `length` 主要作用于 participation，而不是 human answer quality。
  - `quality` 主要作用于 effort / human answer quality，而不是 entry participation。
  - 因而不同 signal 通过不同 cognitive channel 起作用，不能再把 source、length、quality 混成一个单一 crowd-out story。

---
## 4. Round-2 hypotheses and interpretation rules

- 当前 round-2 四个 hypotheses 的标准口径如下；后续写作、汇报、结果解读默认以此为准，除非用户明确要求改写。
- `H1`：AI presence increases human contribution。
  - 解释口径：pure label effect 是 positive，不是 negative。
  - 直觉机制：AI label 先触发“weak competitor / easy win” perception，激发 human experts 进入并证明自己更强。
- `H2`：Longer AI answers attenuate `H1`，并可将净效应从 positive 翻转为 negative。
  - 解释口径：`length` 是 fast heuristic，长答案意味着 space 已被占据、entry barrier 变高。
  - aggregate negative effect 的解释：不是 label 本身 discourages humans，而是因为平台上的 AI answers 平均很长，所以 negative length effect dominates。
- `H3`：AI presence decreases first human answer quality。
  - 解释口径：如果 answerer 仅把 AI 当成 weak competitor，则会产生 complacency，因而 effort 下滑、质量下降。
- `H4`：High AI quality reverses `H3`。
  - 解释口径：`quality` 是 slow signal；一旦 answerer 认真读完并意识到 AI actually good，weak-competitor assumption 被打破，真实 competitive pressure 提升 human effort 与 answer quality。
- 使用这些 hypotheses 时的 boundary：
  - 不要把 `AI main effect` 机械地解释为 unconditional effect；它通常是 interaction model 下在 moderator 取零时的 conditional effect。
  - 讨论 `AI main effect` 为正时，必须同时提醒：这是在 `AI length = 0` 或 low-signal benchmark 下的 pure label effect，不代表 sample-average effect 为正。
  - 讨论 answer-quality regressions 时，要明确区分 `participation margin` 与 `effort / quality margin`，避免把两个 decision stage 混写。

---
## 5. Round-2 main empirical claims to preserve

- 当前 presentation 里的主结果表解释口径：
  - Column `1`：复现旧结论，AI reduces the number of human answers；coefficient 约 `-0.046`，highly significant。
  - Column `2`：加入 interaction 后，AI main effect 转正，约 `0.226`，significant。
    - 含义：当 `AI length = 0` 时，pure label effect 鼓励 human entry。
    - 同时，`AI × length` 为负，约 `-0.045`，significant。
    - 含义：随着 AI answer 变长，participation effect 快速转负；在 mean AI length 附近，net effect 已为 negative。
  - Column `3`：以 `first human answer quality` 为 DV 时，AI average effect 约为 zero。
  - Column `4`：加入 quality interaction 后，AI main effect 约 `-0.12`，marginally significant；`AI × AI quality` 约 `0.35`，highly significant。
    - 含义：低-quality benchmark 下存在 complacency effect；高 AI quality 则触发 stronger human effort，逆转质量下降。
- 后续在 `MISQ` 文件夹里工作时，若涉及 theory memo、meeting slides、analysis notes、result narration，应默认保留以下 narrative hierarchy：
  - aggregate fact 没变：AI overall crowds out human answers。
  - decomposition 变了：crowd-out 并非来自单纯 negative AI label effect，而是 `positive label effect + negative length effect` 叠加后的 net outcome。
  - quality side 不是单向 negative，而是 `weak-competitor complacency` 与 `high-quality competitive arousal` 的 conditional balance。
- 当前 story 的关键词优先级：
  - `internal GenAI`、`platform-specific AI`、`weak competitor perception`、`competitive response`、`fast vs slow signals`、`System 1 / System 2`、`participation margin`、`effort margin`。
  - 除非用户要求回到 round-1 framing，否则不要默认再把 `source effect = deterrence` 作为主叙事。

---
## User-Specific Rules

- 若用户在 `Projects/MISQ/` 下要求我“总结项目”“回忆这篇 paper 在讲什么”“解释 current story”，默认优先依据本文件给出 answer，而不是重新从零扫描全部 meeting materials。
- 若用户让我生成 `slides`、theory memo、results narration、revision notes：
  - 先检查任务使用的是 round 1 还是 round 2 framing。
  - 如未特别说明，默认采用 round 2 framing。
  - 如需对比两轮 framing，必须明确标注 `round 1` 与 `round 2`，避免混淆。
- 若用户让我做新的 analysis interpretation：
  - 默认先判断该结果属于 `participation margin` 还是 `effort / quality margin`。
  - 默认先判断驱动 signal 属于 `label`、`length` 还是 `quality`。
  - 解释时优先服务当前 revision story，而不是回到旧的 automation-bias-only narrative。
