# Artifact:    feature/human_answer_content_metrics
# Grain:       human_answer
# Merge Keys:  questionURL, cmnID
#
# Inputs:
#   - human_answer_intermediate.csv
#   - cmn_content.csv
#
# Output:      data/features/human_answer_content_metrics.csv
#   - Index: questionURL, cmnID
#   - Core: human_answer_textLength, human_answer_textLengthCN, human_answer_codeLength, human_answer_imgNum, human_answer_brNum, human_answer_codeNum, human_answer_inlinecodeNum, human_answer_interlinecodeNum, human_answer_hrefNum, human_answer_aNum, human_answer_boldNum, human_answer_italicNum, human_answer_ulNum, human_answer_olNum, human_answer_liNum, human_answer_blockquoteNum, human_answer_hrNum, human_answer_tableNum
#   - Derived: —
#
# Logic:
#   - Merge human_answer_intermediate 与 `cmn_content` 获取 human-answer HTML content
#   - 复用 `utils.text_processing.process_cmn_content_metrics()` 提取 canonical content metrics
#   - builder 层统一添加单层 `human_answer_` prefix，不输出 double-prefixed legacy columns

import os
import pandas as pd
import numpy as np
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS
from utils.text_processing import process_cmn_content_metrics

OUTPUT_CSV = os.path.join(ARTIFACT_PATHS["raw"].replace("raw", "features"), "human_answer_content_metrics.csv")
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build() -> pd.DataFrame:
    """Build human_answer_content_metrics feature table."""

    # Load human_answer_intermediate to get questionURL and cmnID
    human_answer_path = os.path.join(ARTIFACT_PATHS["raw"].replace("raw", "features"), "human_answer_intermediate.csv")
    print(f"Loading human_answer_intermediate from {human_answer_path}...")
    human_answer = pd.read_csv(human_answer_path, encoding='utf-8-sig')
    print(f"Loaded {len(human_answer):,} human answers")

    # Load cmn_content to get HTML content
    cmn_content_path = os.path.join(ARTIFACT_PATHS["raw"], "cmn_content.csv")
    print(f"Loading cmn_content from {cmn_content_path}...")
    cmn_content = pd.read_csv(cmn_content_path, encoding='utf-8-sig')
    print(f"Loaded {len(cmn_content):,} content records")

    # Merge to get content for human answers
    print("Merging human_answer with cmn_content...")
    df = human_answer[['questionURL', 'cmnID']].merge(
        cmn_content[['questionURL', 'cmnID', 'content']],
        on=['questionURL', 'cmnID'],
        how='left'
    )
    print(f"After merge: {len(df):,} records")

    # Check for missing content
    missing_content = df['content'].isna().sum()
    if missing_content > 0:
        print(f"Warning: {missing_content:,} human answers have missing content")

    # Extract content metrics
    print("Extracting content metrics...")
    metrics_list = []
    for idx, row in tqdm(df.iterrows(), total=len(df), desc="Processing content"):
        metrics = process_cmn_content_metrics(row['content'])
        metrics_list.append(metrics)

    # Convert to DataFrame
    metrics_df = pd.DataFrame(metrics_list)

    # Add human_answer_ prefix to all columns
    metrics_df.columns = ['human_answer_' + col for col in metrics_df.columns]

    # Add merge keys
    result = pd.concat([
        df[['questionURL', 'cmnID']],
        metrics_df
    ], axis=1)

    # Save
    print(f"Saving to {OUTPUT_CSV}...")
    result.to_csv(OUTPUT_CSV, index=False, encoding='utf-8-sig')
    print(f"Saved {len(result):,} records with {len(result.columns)} columns")

    return result


if __name__ == "__main__":
    df = build()

    # Print summary statistics
    print("\n" + "="*80)
    print("SUMMARY STATISTICS")
    print("="*80)

    # Text length metrics
    print("\nText Length Metrics:")
    for col in ['human_answer_textLength', 'human_answer_textLengthCN', 'human_answer_codeLength']:
        if col in df.columns:
            print(f"\n{col}:")
            print(f"  min:  {df[col].min():.0f}")
            print(f"  max:  {df[col].max():.0f}")
            print(f"  mean: {df[col].mean():.2f}")
            print(f"  median: {df[col].median():.0f}")

    # Formatting elements
    print("\nFormatting Elements (mean counts):")
    formatting_cols = [col for col in df.columns if any(x in col for x in ['Num', 'Length'])]
    for col in sorted(formatting_cols):
        if col not in ['human_answer_textLength', 'human_answer_textLengthCN', 'human_answer_codeLength']:
            mean_val = df[col].mean()
            nonzero_pct = (df[col] > 0).mean() * 100
            print(f"  {col}: {mean_val:.2f} (nonzero: {nonzero_pct:.1f}%)")

    # Sample rows with high formatting
    print("\n" + "="*80)
    print("SAMPLE: Answers with rich formatting (high imgNum + codeNum + tableNum)")
    print("="*80)
    df['formatting_score'] = (
        df['human_answer_imgNum'].fillna(0) +
        df['human_answer_codeNum'].fillna(0) +
        df['human_answer_tableNum'].fillna(0)
    )
    sample = df.nlargest(3, 'formatting_score')[['questionURL', 'cmnID',
                                                   'human_answer_textLength',
                                                   'human_answer_imgNum',
                                                   'human_answer_codeNum',
                                                   'human_answer_tableNum']]
    print(sample.to_string(index=False))
