# Artifact:    feature/user_activity_experience
# Grain:       user_activity
# Merge Keys:  userURL, date
#
# Inputs:
#   - all_activities.csv
#
# Output:      data/features/user_activity_experience.csv
#   - Index: userURL, date, activity_type
#   - Core: askBefore, resBefore, acceptedBefore, acceptBefore, commentBefore, netlikeBefore, commentOthersBefore, badgeBefore, ratioAcceptAsk, ratioCommentBadge, firstPart, age, daysSinceLastAct, nPayback, nPaybackAsk, nPaybackResp, nPaybackComment
#   - Derived: acceptedTop/Bottom{5/10/15/20}pct, netlikeTop{5/10/15/20}pct, ratioAcceptAskTop/Bottom{5/10/15/20}pct, master/senior/loose/strict/preferdiscussTop{5/10/15/20}pct
#
# Logic:
#   - 计算 cumulative counts (*Before): askBefore, resBefore, acceptedBefore, acceptBefore, commentBefore, netlikeBefore, commentOthersBefore
#   - 计算 derived ratios: badgeBefore, ratioAcceptAsk, ratioCommentBadge
#   - 计算 percentile indicators: acceptedTop/Bottom{5/10/15/20}pct, netlikeTop{5/10/15/20}pct, ratioAcceptAskTop/Bottom{5/10/15/20}pct
#   - 计算 expert indicators: master/senior/loose/strict/preferdiscussTop{5/10/15/20}pct
#   - 计算 user age: firstPart, age, daysSinceLastAct
#   - 计算 payback metrics: nPayback, nPaybackAsk, nPaybackResp, nPaybackComment

import os
import pandas as pd
import numpy as np
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS
from utils.aggregation import (
    calculate_user_experience_cumulative,
    calculate_derived_experience_metrics,
    calculate_expert_indicators,
    calculate_user_age_metrics,
    calculate_payback_metrics
)

INPUT_CSV = os.path.join(ARTIFACT_PATHS["raw"].replace("raw", "features"), "all_activities.csv")
OUTPUT_CSV = os.path.join(ARTIFACT_PATHS["raw"].replace("raw", "features"), "user_activity_experience.csv")
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build() -> pd.DataFrame:
    """
    Build user_activity_experience feature table.

    Returns:
        DataFrame: User activity experience metrics at user_activity grain
    """
    print("=" * 80)
    print("Building user_activity_experience feature")
    print("=" * 80)

    # Check if input file exists
    if not os.path.exists(INPUT_CSV):
        raise FileNotFoundError(f"Input file not found: {INPUT_CSV}")

    # Load all_activities
    print(f"\nLoading all_activities from: {INPUT_CSV}")
    all_activities = pd.read_csv(INPUT_CSV)
    print(f"Loaded {len(all_activities):,} rows")

    # Step 1: Calculate cumulative *Before columns
    print("\n[1/5] Calculating cumulative *Before columns...")
    df = calculate_user_experience_cumulative(all_activities)
    print(f"  Generated columns: {[col for col in df.columns if 'Before' in col]}")

    # Step 2: Calculate derived experience metrics
    print("\n[2/5] Calculating derived experience metrics...")
    df = calculate_derived_experience_metrics(df)
    print(f"  Generated columns: badgeBefore, ratioAcceptAsk, ratioCommentBadge, etc.")

    # Step 3: Calculate expert indicators (includes percentile indicators)
    print("\n[3/5] Calculating expert indicators and percentile indicators...")
    df = calculate_expert_indicators(df)
    print(f"  Generated expert indicators: master, senior, loose, strict, preferdiscuss")

    # Step 4: Calculate user age metrics
    print("\n[4/5] Calculating user age metrics...")
    grouped_results = []
    for name, group in tqdm(df.groupby('userURL'), desc='Calculating user age metrics'):
        group = calculate_user_age_metrics(group)
        grouped_results.append(group)
    df = pd.concat(grouped_results).reset_index(drop=True)
    print(f"  Generated columns: firstPart, age, daysSinceLastAct")

    # Step 5: Calculate payback metrics
    print("\n[5/5] Calculating payback metrics...")
    grouped_results = []
    for name, group in tqdm(df.groupby('userURL'), desc='Calculating payback metrics'):
        group = calculate_payback_metrics(group, all_activities)
        grouped_results.append(group)
    df = pd.concat(grouped_results).reset_index(drop=True)
    print(f"  Generated columns: nPayback, nPaybackAsk, nPaybackResp, nPaybackComment")

    # Add user_activity_ prefix to column names (except merge keys)
    print("\n[6/6] Renaming columns with user_activity_ prefix...")
    rename_dict = {}
    for col in df.columns:
        if col not in ['userURL', 'date', 'ask', 'answer', 'accepted', 'accept', 'comment', 'netlikeNum', 'commentOthers']:
            rename_dict[col] = f'user_activity_{col}'
    df = df.rename(columns=rename_dict)

    # Save output
    print(f"\nSaving to: {OUTPUT_CSV}")
    df.to_csv(OUTPUT_CSV, index=False)
    print(f"Saved {len(df):,} rows × {len(df.columns)} columns")

    # Print summary statistics
    print("\n" + "=" * 80)
    print("Summary Statistics")
    print("=" * 80)

    key_metrics = [
        'user_activity_askBefore',
        'user_activity_resBefore',
        'user_activity_acceptedBefore',
        'user_activity_badgeBefore',
        'user_activity_ratioAcceptAsk',
        'user_activity_age',
        'user_activity_nPayback'
    ]

    for metric in key_metrics:
        if metric in df.columns:
            print(f"\n{metric}:")
            print(f"  min:  {df[metric].min():.2f}")
            print(f"  max:  {df[metric].max():.2f}")
            print(f"  mean: {df[metric].mean():.2f}")
            print(f"  median: {df[metric].median():.2f}")

    print("\n" + "=" * 80)
    print("Build completed successfully")
    print("=" * 80)

    return df


if __name__ == "__main__":
    build()
