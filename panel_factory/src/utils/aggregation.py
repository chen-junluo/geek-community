"""
Aggregation utilities for calculating cumulative metrics and percentiles.

Extracted from Archive/round2_parser_for_panel.ipynb cells 34-50.
"""

import pandas as pd
import numpy as np
from tqdm import tqdm


def aggregate_by_group(df, group_cols, agg_dict):
    """
    Generic aggregation function.

    Args:
        df: DataFrame
        group_cols: List of columns to group by
        agg_dict: Dictionary of {column: aggregation_function}

    Returns:
        DataFrame: Aggregated DataFrame
    """
    return df.groupby(group_cols).agg(agg_dict).reset_index()


def calculate_percentiles(df, group_col, value_col, percentiles):
    """
    Calculate percentiles for a value column within groups.

    Args:
        df: DataFrame
        group_col: Column to group by
        value_col: Column to calculate percentiles for
        percentiles: List of percentiles (e.g., [0.05, 0.10, 0.95])

    Returns:
        DataFrame: Percentile values
    """
    return df.groupby(group_col)[value_col].quantile(percentiles).unstack()


def cumulative_sum_by_group(df, group_col, value_cols, date_col):
    """
    Calculate cumulative sum by group, sorted by date.

    Args:
        df: DataFrame
        group_col: Column to group by (e.g., 'userURL')
        value_cols: List of columns to calculate cumulative sum for
        date_col: Date column for sorting

    Returns:
        DataFrame: DataFrame with cumulative sum columns
    """
    df = df.copy()
    df = df.sort_values(by=[group_col, date_col])

    for col in value_cols:
        df[f'{col}_cumsum'] = df.groupby(group_col)[col].cumsum()

    return df


def calculate_cumulative_before(group, value_cols):
    """
    Calculate cumulative values BEFORE each row (excluding current row).

    Args:
        group: DataFrame group
        value_cols: List of columns to calculate cumulative values for

    Returns:
        DataFrame: Group with *Before columns
    """
    group = group.copy()
    group = group.sort_values(by='date')

    for col in value_cols:
        group[f'{col}Before'] = group[col].cumsum() - group[col]

    return group


def calculate_user_experience_cumulative(all_activities):
    """
    Calculate cumulative user experience metrics from all_activities.

    Args:
        all_activities: DataFrame with columns [userURL, date, ask, answer, accepted, accept, comment, netlikeNum, commentOthers]

    Returns:
        DataFrame: User experience with cumulative *Before columns
    """
    all_activities = all_activities.copy()
    all_activities['date'] = pd.to_datetime(all_activities['date']).dt.tz_localize(None)

    value_cols = ['ask', 'answer', 'accepted', 'accept', 'comment', 'netlikeNum', 'commentOthers']

    grouped_results = []
    for name, group in tqdm(all_activities.groupby('userURL'), desc='Calculating cumulative values'):
        group = calculate_cumulative_before(group, value_cols)
        grouped_results.append(group)

    result = pd.concat(grouped_results).reset_index(drop=True)

    # Rename columns
    result = result.rename(columns={
        'askBefore': 'askBefore',
        'answerBefore': 'resBefore',
        'acceptedBefore': 'acceptedBefore',
        'acceptBefore': 'acceptBefore',
        'commentBefore': 'commentBefore',
        'netlikeNumBefore': 'netlikeBefore',
        'commentOthersBefore': 'commentOthersBefore',
    })

    return result


def calculate_derived_experience_metrics(df):
    """
    Calculate derived user experience metrics.

    Args:
        df: DataFrame with *Before columns

    Returns:
        DataFrame: DataFrame with derived metrics
    """
    df = df.copy()

    # Badge score
    df['badgeBefore'] = (
        df['askBefore'] +
        df['resBefore'] +
        df['acceptedBefore'] * 15 +
        df['acceptBefore'] * 2 +
        df['commentBefore'] +
        df['netlikeBefore'] * 10
    )
    df['badgeBefore'] = df['badgeBefore'].apply(lambda x: max(x, 1))

    # Ratios
    df['ratioAcceptAsk'] = df['acceptBefore'] / (df['askBefore'] + 1)
    df['ratioCommentBadge'] = df['commentBefore'] / (df['badgeBefore'] + 1)
    df['ratioCommentOthersResp'] = df['commentOthersBefore'] / (df['resBefore'] + 1)
    df['ratioAcceptedResp'] = df['acceptedBefore'] / (df['resBefore'] + 1)
    df['ratioNetlikeResp'] = df['netlikeBefore'] / (df['resBefore'] + 1)

    return df


def calculate_percentile_indicators(df, value_col, percentiles=[5, 10, 15, 20], top=True):
    """
    Calculate percentile indicators for a value column.

    Args:
        df: DataFrame sorted by date
        value_col: Column to calculate percentiles for
        percentiles: List of percentile thresholds
        top: If True, calculate top percentiles; if False, calculate bottom percentiles

    Returns:
        DataFrame: DataFrame with percentile indicator columns
    """
    df = df.copy()
    df = df.sort_values(by='date')

    # Initialize columns
    for pct in percentiles:
        if top:
            df[f'{value_col}Top{pct}pct'] = 0
        else:
            df[f'{value_col}Bottom{pct}pct'] = 0

    # Track latest records per user
    latest_records = {}

    for index, row in tqdm(df.iterrows(), total=df.shape[0], desc=f"Processing {value_col} percentiles"):
        # Update latest record
        latest_records[row['userURL']] = row[value_col]

        # Get all unique values up to this point
        unique_values = list(latest_records.values())

        # Calculate percentiles
        for pct in percentiles:
            if top:
                threshold = np.percentile(unique_values, 100 - pct)
                df.at[index, f'{value_col}Top{pct}pct'] = int(row[value_col] > threshold)
            else:
                threshold = np.percentile(unique_values, pct)
                df.at[index, f'{value_col}Bottom{pct}pct'] = int(row[value_col] < threshold)

    return df


def calculate_expert_indicators(df):
    """
    Calculate expert indicators (master, senior, loose, strict, preferdiscuss).

    Args:
        df: DataFrame with user experience metrics

    Returns:
        DataFrame: DataFrame with expert indicator columns
    """
    df = df.copy()

    # Calculate percentile indicators for key metrics
    df = calculate_percentile_indicators(df, 'acceptedBefore', percentiles=[5, 10, 15, 20], top=True)
    df = calculate_percentile_indicators(df, 'netlikeBefore', percentiles=[5, 10, 15, 20], top=True)
    df = calculate_percentile_indicators(df, 'ratioAcceptAsk', percentiles=[5, 10, 15, 20], top=True)
    df = calculate_percentile_indicators(df, 'ratioAcceptAsk', percentiles=[5, 10, 15, 20], top=False)
    df = calculate_percentile_indicators(df, 'ratioCommentBadge', percentiles=[5, 10, 15, 20], top=True)

    # Rename to expert indicators
    for pct in [5, 10, 15, 20]:
        df[f'masterTop{pct}pct'] = df[f'acceptedBeforeTop{pct}pct']
        df[f'seniorTop{pct}pct'] = df[f'netlikeBeforeTop{pct}pct']
        df[f'looseTop{pct}pct'] = df[f'ratioAcceptAskTop{pct}pct']
        df[f'strictTop{pct}pct'] = df[f'ratioAcceptAskBottom{pct}pct']
        df[f'preferdiscussTop{pct}pct'] = df[f'ratioCommentBadgeTop{pct}pct']

    return df


def calculate_user_age_metrics(group):
    """
    Calculate user age and activity recency metrics.

    Args:
        group: DataFrame group (by userURL)

    Returns:
        DataFrame: Group with age metrics
    """
    group = group.copy()
    group = group.sort_values(by='date')

    # First participation date
    group['firstPart'] = group['date'].iloc[0]

    # Age (days since first participation)
    group['age'] = (group['date'] - group['firstPart']).dt.days

    # Days since last activity
    group['daysSinceLastAct'] = group['date'].diff().fillna(pd.Timedelta(days=0)).dt.days

    return group


def calculate_payback_metrics(group, all_activities):
    """
    Calculate payback metrics for askers.

    Args:
        group: DataFrame group (by userURL)
        all_activities: DataFrame with all user activities

    Returns:
        DataFrame: Group with payback metrics
    """
    group = group.copy()

    # Initialize columns
    group['nPayback'] = 0
    group['nPaybackAsk'] = 0
    group['nPaybackResp'] = 0
    group['nPaybackComment'] = 0
    group['nPaybackCommentAsker'] = 0
    group['nPaybackCommentResponder'] = 0
    group['nPaybackCommentOthers'] = 0
    group['nActivityBefore'] = 0
    group['nActivityBeforeAsk'] = 0
    group['nActivityBeforeResp'] = 0
    group['nActivityBeforeComment'] = 0

    # Process each question
    for index, question in group[group['ask'] == 1].iterrows():
        question_date = question['date']
        question_user = question['userURL']

        # Activities within 30 days after question
        answers_within_month = all_activities[
            (all_activities['userURL'] == question_user) &
            (all_activities['date'] > question_date) &
            (all_activities['date'] <= question_date + pd.Timedelta(days=30))
        ]

        # Activities within 30 days before question
        answers_before_month = all_activities[
            (all_activities['userURL'] == question_user) &
            (all_activities['date'] < question_date) &
            (all_activities['date'] >= question_date - pd.Timedelta(days=30))
        ]

        # Calculate payback metrics
        if not answers_within_month.empty:
            group.at[index, 'nPayback'] = len(answers_within_month)
            group.at[index, 'nPaybackAsk'] = answers_within_month['ask'].sum()
            group.at[index, 'nPaybackResp'] = answers_within_month['answer'].sum()
            group.at[index, 'nPaybackComment'] = answers_within_month['comment'].sum()
            group.at[index, 'nPaybackCommentAsker'] = answers_within_month['commentAsker'].sum()
            group.at[index, 'nPaybackCommentResponder'] = answers_within_month['commentResponder'].sum()
            group.at[index, 'nPaybackCommentOthers'] = answers_within_month['commentOthers'].sum()

        # Calculate activity before metrics
        if not answers_before_month.empty:
            group.at[index, 'nActivityBefore'] = len(answers_before_month)
            group.at[index, 'nActivityBeforeAsk'] = answers_before_month['ask'].sum()
            group.at[index, 'nActivityBeforeResp'] = answers_before_month['answer'].sum()
            group.at[index, 'nActivityBeforeComment'] = answers_before_month['comment'].sum()

    return group


def aggregate_answers_to_question(cmn_df, question_df, agg_metrics):
    """
    Aggregate answer-level metrics to question-level.

    Args:
        cmn_df: DataFrame with answer-level data
        question_df: DataFrame with question-level data
        agg_metrics: Dictionary of {column: aggregation_function}

    Returns:
        DataFrame: Question-level aggregated metrics
    """
    # Filter to answers only (cmnID > 0)
    answers = cmn_df[cmn_df['cmnID'] > 0].copy()

    # Aggregate by questionURL
    aggregated = answers.groupby('questionURL').agg(agg_metrics).reset_index()

    # Merge with question_df
    result = question_df.merge(aggregated, on='questionURL', how='left')

    return result


def calculate_stratified_aggregation(cmn_df, stratify_col, agg_metrics):
    """
    Calculate aggregation stratified by a categorical column.

    Args:
        cmn_df: DataFrame with answer-level data
        stratify_col: Column to stratify by (e.g., 'masterTop10pct')
        agg_metrics: Dictionary of {column: aggregation_function}

    Returns:
        DataFrame: Stratified aggregated metrics
    """
    # Filter to answers only
    answers = cmn_df[cmn_df['cmnID'] > 0].copy()

    # Stratify
    stratified_groups = answers.groupby(['questionURL', stratify_col])

    # Aggregate
    aggregated = stratified_groups.agg(agg_metrics).reset_index()

    # Pivot to wide format
    result = aggregated.pivot(index='questionURL', columns=stratify_col, values=list(agg_metrics.keys()))

    # Flatten column names
    result.columns = [f'{col}_{stratify_col}{val}' for col, val in result.columns]
    result = result.reset_index()

    return result
