"""
临时脚本：修复 question 和 answer intermediates
- 从 Archive 复制原始 CSV
- 标准化 index: question_id, answer_id, resp_id
- 生成 MISQ 版本
"""

import pandas as pd
import os

# 路径定义
ARCHIVE_DIR = "/Users/dylanchen/Desktop/geek-community/Archive"
FEATURES_DIR = "/Users/dylanchen/Desktop/geek-community/panel_factory/data/features"

# 输入文件
question_archive = os.path.join(ARCHIVE_DIR, "result_question_robustness_LLM.csv")
answer_archive = os.path.join(ARCHIVE_DIR, "result_answer_robustness_LLM.csv")

# 输出文件
question_intermediate = os.path.join(FEATURES_DIR, "question_intermediate.csv")
answer_intermediate = os.path.join(FEATURES_DIR, "human_answer_intermediate.csv")
question_intermediate_misq = os.path.join(FEATURES_DIR, "question_intermediate_MISQ.csv")
answer_intermediate_misq = os.path.join(FEATURES_DIR, "human_answer_intermediate_MISQ.csv")

print("=" * 60)
print("Step 1: 读取 Archive 文件")
print("=" * 60)

# 读取原始数据
df_question = pd.read_csv(question_archive, low_memory=False)
df_answer = pd.read_csv(answer_archive, low_memory=False)

# 转换 cmnID 为数值类型
df_question['cmnID'] = pd.to_numeric(df_question['cmnID'], errors='coerce')
df_answer['cmnID'] = pd.to_numeric(df_answer['cmnID'], errors='coerce')

print(f"Question rows: {len(df_question)}")
print(f"Answer rows: {len(df_answer)}")

print("\n" + "=" * 60)
print("Step 2: 标准化 index")
print("=" * 60)

# Question intermediate: 只保留 cmnID == 0 的行
df_question_clean = df_question[df_question['cmnID'] == 0].copy()
print(f"Question rows after filtering cmnID==0: {len(df_question_clean)}")

# 转换 date 为 datetime 用于排序
df_question_clean['date'] = pd.to_datetime(df_question_clean['date'], errors='coerce')

# 按 date 排序并生成 question_id
df_question_clean = df_question_clean.sort_values('date').reset_index(drop=True)
df_question_clean['question_id'] = range(1, len(df_question_clean) + 1)

# Answer intermediate: 只保留 human answers (cmnID > 0)
df_answer_clean = df_answer[df_answer['cmnID'] > 0].copy()
print(f"Answer rows after filtering cmnID>0: {len(df_answer_clean)}")

# 转换 date 为 datetime 用于排序
df_answer_clean['date'] = pd.to_datetime(df_answer_clean['date'], errors='coerce')

# 按 date 排序并生成 answer_id 和 resp_id
df_answer_clean = df_answer_clean.sort_values('date').reset_index(drop=True)
df_answer_clean['answer_id'] = range(1, len(df_answer_clean) + 1)
df_answer_clean['resp_id'] = range(1, len(df_answer_clean) + 1)

# 将 question_id merge 到 answer
question_url_to_id = df_question_clean.set_index('questionURL')['question_id'].to_dict()
df_answer_clean['question_id'] = df_answer_clean['questionURL'].map(question_url_to_id)

print(f"Answer rows with valid question_id: {df_answer_clean['question_id'].notna().sum()}")

print("\n" + "=" * 60)
print("Step 3: 保存原始版本 intermediates")
print("=" * 60)

df_question_clean.to_csv(question_intermediate, index=False)
df_answer_clean.to_csv(answer_intermediate, index=False)

print(f"Saved: {question_intermediate}")
print(f"Saved: {answer_intermediate}")

print("\n" + "=" * 60)
print("Step 4: 筛选 MISQ 数据")
print("=" * 60)

# MISQ 筛选规则: ask == 1 且 date >= 2023-01-01
df_question_clean['date'] = pd.to_datetime(df_question_clean['date'], errors='coerce')
misq_questions = df_question_clean[
    (df_question_clean['ask'] == 1) &
    (df_question_clean['date'] >= '2023-01-01')
].copy()

print(f"MISQ questions: {len(misq_questions)}")

# 获取 MISQ questionURL 集合
misq_question_urls = set(misq_questions['questionURL'])

# 筛选对应的 answers
misq_answers = df_answer_clean[
    df_answer_clean['questionURL'].isin(misq_question_urls)
].copy()

print(f"MISQ answers: {len(misq_answers)}")

print("\n" + "=" * 60)
print("Step 5: 保存 MISQ 版本 intermediates")
print("=" * 60)

misq_questions.to_csv(question_intermediate_misq, index=False)
misq_answers.to_csv(answer_intermediate_misq, index=False)

print(f"Saved: {question_intermediate_misq}")
print(f"Saved: {answer_intermediate_misq}")

print("\n" + "=" * 60)
print("完成!")
print("=" * 60)

# 输出描述性统计
print("\n描述性统计:")
print(f"- 原始 question intermediate: {len(df_question_clean)} rows")
print(f"- 原始 answer intermediate: {len(df_answer_clean)} rows")
print(f"- MISQ question intermediate: {len(misq_questions)} rows")
print(f"- MISQ answer intermediate: {len(misq_answers)} rows")
