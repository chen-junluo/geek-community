import os
import pandas as pd
import numpy as np
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS
from utils.text_processing import process_cmn_content_metrics, process_question_content_metrics, calculate_goodAI

OUTPUT_CSV = os.path.join(ARTIFACT_PATHS["raw"].replace("raw", "features"), "question_content_metrics.csv")
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


QUESTION_PREFIX = "question_"
PREAI_PREFIX = "question_preAI_"


def _prefix_metrics(metrics: dict, prefix: str) -> dict:
    return {f"{prefix}{key}": value for key, value in metrics.items()}


def build() -> pd.DataFrame:
    """Build question content metrics feature table."""

    cmn_content_path = os.path.join(ARTIFACT_PATHS["raw"], "cmn_content.csv")
    df_question = pd.read_csv(cmn_content_path, encoding="utf-8-sig")
    df_question = df_question.loc[df_question["cmnID"] == 0, ["questionURL", "content"]].drop_duplicates(subset=["questionURL"])
    print(f"Loaded question rows from cmn_content: {len(df_question)} rows")

    ai_content_path = os.path.join(ARTIFACT_PATHS["raw"], "question_ai_content.csv")
    df_ai = pd.read_csv(ai_content_path, encoding="utf-8-sig")
    print(f"Loaded question_ai_content: {len(df_ai)} rows")

    df = df_question.merge(
        df_ai[["questionURL", "preAI-content"]],
        on="questionURL",
        how="left",
    )
    print(f"Merged data: {len(df)} rows")

    print("Calculating question-side content metrics...")
    question_metrics = []
    for _, row in tqdm(df.iterrows(), total=len(df), desc="Question content"):
        metrics = {"questionURL": row["questionURL"]}
        metrics.update(_prefix_metrics(process_cmn_content_metrics(row["content"]), QUESTION_PREFIX))
        question_metrics.append(metrics)
    df_question_metrics = pd.DataFrame(question_metrics)

    print("Calculating AI-side content metrics...")
    ai_metrics = []
    for _, row in tqdm(df.iterrows(), total=len(df), desc="AI content"):
        metrics = {"questionURL": row["questionURL"]}
        metrics.update(process_question_content_metrics(row["preAI-content"], prefix=PREAI_PREFIX))
        ai_metrics.append(metrics)
    df_ai_metrics = pd.DataFrame(ai_metrics)

    df_final = df_question_metrics.merge(df_ai_metrics, on="questionURL", how="left")

    print("Calculating question_goodAI...")
    df_final["question_goodAI"] = df_final.apply(
        lambda row: calculate_goodAI(row, prefix=PREAI_PREFIX),
        axis=1,
    )

    df_final.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"\nSaved to: {OUTPUT_CSV}")
    print(f"Output shape: {df_final.shape}")
    print(f"\nColumns: {list(df_final.columns)}")

    print("\n=== Descriptive Statistics ===")
    numeric_cols = df_final.select_dtypes(include=[np.number]).columns
    print(df_final[numeric_cols].describe())

    return df_final


if __name__ == "__main__":
    build()
