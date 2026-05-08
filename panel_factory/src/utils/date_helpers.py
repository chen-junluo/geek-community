"""
Date and time processing utilities.

Extracted from Archive/round2_parser_for_panel.ipynb cells 66-82.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta


def calculate_time_diff(date1, date2, unit='hours'):
    """
    Calculate time difference between two dates.

    Args:
        date1: Earlier datetime
        date2: Later datetime
        unit: 'hours', 'days', 'minutes', or 'seconds'

    Returns:
        float: Time difference in specified unit
    """
    if pd.isna(date1) or pd.isna(date2):
        return np.nan

    date1 = pd.to_datetime(date1)
    date2 = pd.to_datetime(date2)

    diff = date2 - date1

    if unit == 'hours':
        return diff.total_seconds() / 3600
    elif unit == 'days':
        return diff.total_seconds() / (3600 * 24)
    elif unit == 'minutes':
        return diff.total_seconds() / 60
    elif unit == 'seconds':
        return diff.total_seconds()
    else:
        raise ValueError(f"Unknown unit: {unit}")


def filter_by_date_range(df, date_col, start_date, end_date):
    """
    Filter DataFrame by date range.

    Args:
        df: DataFrame
        date_col: Name of date column
        start_date: Start date (inclusive)
        end_date: End date (inclusive)

    Returns:
        DataFrame: Filtered DataFrame
    """
    df = df.copy()
    df[date_col] = pd.to_datetime(df[date_col])

    if start_date is not None:
        df = df[df[date_col] >= start_date]
    if end_date is not None:
        df = df[df[date_col] <= end_date]

    return df


def generate_time_fields(date_series):
    """
    Generate time-related fields from date series.

    Args:
        date_series: pandas Series of datetime

    Returns:
        DataFrame: Time fields (hourofday, dayofweek, monthofyear, isHoliday)
    """
    date_series = pd.to_datetime(date_series)

    time_fields = pd.DataFrame({
        'hourofday': date_series.dt.hour,
        'dayofweek': date_series.dt.dayofweek,  # Monday=0, Sunday=6
        'monthofyear': date_series.dt.month,
    })

    # Chinese holidays (simplified - can be extended with workalendar)
    # For now, mark weekends as holidays
    time_fields['isHoliday'] = (time_fields['dayofweek'] >= 5).astype(int)

    return time_fields


def calculate_wait_times(group, ask_time_col='ask_time', date_col='date', preAI_col='preAI'):
    """
    Calculate wait times for answers within a question group.

    Args:
        group: DataFrame group (by questionURL)
        ask_time_col: Column name for question ask time
        date_col: Column name for answer date
        preAI_col: Column name for AI answer indicator

    Returns:
        DataFrame: Group with wait time metrics
    """
    group = group.copy()
    group = group.sort_values(by=date_col).reset_index(drop=True)

    ask_time = group[ask_time_col].iloc[0]

    # Calculate deltawait (time since previous answer)
    group['deltawait'] = group[date_col].diff(1)
    group['deltawait'] = group['deltawait'].apply(lambda x: x.total_seconds() / 3600 if pd.notna(x) else np.nan)

    # Wait times from ask_time
    group['wait_from_ask'] = (group[date_col] - ask_time).apply(lambda x: x.total_seconds() / 3600)

    return group


def aggregate_wait_times(group, ask_time_col='ask_time', date_col='date', preAI_col='preAI'):
    """
    Aggregate wait time metrics for a question.

    Args:
        group: DataFrame group (by questionURL)
        ask_time_col: Column name for question ask time
        date_col: Column name for answer date
        preAI_col: Column name for AI answer indicator

    Returns:
        Series: Aggregated wait time metrics
    """
    group = group.copy()
    group = group.sort_values(by=date_col).reset_index(drop=True)

    ask_time = group[ask_time_col].iloc[0]
    max_date = group[date_col].max()
    num_entries = len(group)

    AI_status = group[preAI_col].sum() if preAI_col in group.columns else 0

    metrics = {}

    # Average wait time (interval-based)
    metrics['avgWt_int'] = (max_date - ask_time).total_seconds() / 3600 / num_entries if num_entries > 0 else np.nan

    # Calculate deltawait
    group['deltawait'] = group[date_col].diff(1)
    group['deltawait'] = group['deltawait'].apply(lambda x: x.total_seconds() / 3600 if pd.notna(x) else np.nan)

    # Average deltawait
    metrics['avgWt_delta'] = group['deltawait'].mean()

    # Metrics excluding AI answers
    if AI_status > 0:
        non_ai_group = group[group[preAI_col] != 1]
        metrics['avgWt_noAI'] = non_ai_group['deltawait'].mean()
        metrics['medianWt_noAI'] = non_ai_group['deltawait'].median()
        metrics['t25Wt_noAI'] = non_ai_group['deltawait'].quantile(0.25)
        metrics['t75Wt_noAI'] = non_ai_group['deltawait'].quantile(0.75)
    else:
        metrics['avgWt_noAI'] = group['deltawait'].mean()
        metrics['medianWt_noAI'] = group['deltawait'].median()
        metrics['t25Wt_noAI'] = group['deltawait'].quantile(0.25)
        metrics['t75Wt_noAI'] = group['deltawait'].quantile(0.75)

    # Overall metrics
    metrics['medianWt'] = group['deltawait'].median()
    metrics['t25Wt'] = group['deltawait'].quantile(0.25)
    metrics['t75Wt'] = group['deltawait'].quantile(0.75)

    return pd.Series(metrics)


def fill_missing_wait_times(df, wait_cols, fill_value=100000, threshold_hours=30*24):
    """
    Fill missing wait times and create indicators.

    Args:
        df: DataFrame
        wait_cols: List of wait time column names (e.g., ['wait1Resp', 'wait2Resp'])
        fill_value: Value to fill missing wait times (default: 100000 hours)
        threshold_hours: Threshold for "longtime" indicator (default: 30 days)

    Returns:
        DataFrame: DataFrame with filled wait times and indicators
    """
    df = df.copy()

    for col in wait_cols:
        original_col = f'{col}_original'

        if original_col not in df.columns:
            continue

        # Fill missing values
        df[col] = df[original_col].fillna(fill_value)

        # Create longtime indicator
        df[f'longtime{col.replace("wait", "")}'] = (df[original_col] > threshold_hours).astype(int)

        # Create noresponse indicator
        df[f'noresponse{col.replace("wait", "")}'] = df[original_col].isna().astype(int)

    return df


def calculate_days_since_post(answer_dates, ask_time):
    """
    Calculate days since post for each answer.

    Args:
        answer_dates: Series of answer dates
        ask_time: Question ask time

    Returns:
        Series: Days since post (1-indexed)
    """
    answer_dates = pd.to_datetime(answer_dates)
    ask_time = pd.to_datetime(ask_time)

    return (answer_dates - ask_time).dt.days + 1


def calculate_answer_cdf_by_day(group, ask_time_col='ask_time', date_col='date', preAI_col='preAI', max_days=150):
    """
    Calculate cumulative distribution of answers by day for a question.

    Args:
        group: DataFrame group (by questionURL)
        ask_time_col: Column name for question ask time
        date_col: Column name for answer date
        preAI_col: Column name for AI answer indicator
        max_days: Maximum days to track (default: 150)

    Returns:
        DataFrame: Daily answer counts and CDF
    """
    group = group.copy()

    AI_status = group[preAI_col].iloc[0] if preAI_col in group.columns else 0
    ask_time = group[ask_time_col].iloc[0]
    base_time = ask_time + pd.Timedelta(minutes=5)

    # Exclude question row (cmnID==0)
    sumRes_df = group.iloc[1:].copy()

    # Total answer count
    if AI_status == 1:
        answerNum = len(sumRes_df) + 1
    else:
        answerNum = len(sumRes_df)

    if answerNum == 0:
        return pd.DataFrame()

    # Calculate days since post
    sumRes_df['days_since_post'] = calculate_days_since_post(sumRes_df[date_col], ask_time)

    # Skip if exceeds max_days
    if sumRes_df['days_since_post'].max() > max_days:
        return pd.DataFrame()

    # Count answers per day
    daily_answers = sumRes_df.groupby('days_since_post').size().reset_index(name='daily_answers')

    # Add AI answer on day 1
    if AI_status == 1:
        if 1 in daily_answers['days_since_post'].values:
            daily_answers.loc[daily_answers['days_since_post'] == 1, 'daily_answers'] += 1
        else:
            daily_answers = pd.concat([
                daily_answers,
                pd.DataFrame({'days_since_post': [1], 'daily_answers': [1]})
            ]).sort_values('days_since_post').reset_index(drop=True)

    # Calculate cumulative answers and CDF
    daily_answers['cumulative_answers'] = daily_answers['daily_answers'].cumsum()
    daily_answers['cdf'] = daily_answers['cumulative_answers'] / answerNum

    # Fill missing days
    max_days_actual = int(daily_answers['days_since_post'].max())
    full_days = pd.DataFrame({'days_since_post': range(1, max_days_actual + 1)})
    daily_answers = full_days.merge(daily_answers, on='days_since_post', how='left')

    # Forward fill CDF
    daily_answers['daily_answers'] = daily_answers['daily_answers'].fillna(0)
    daily_answers['cumulative_answers'] = daily_answers['daily_answers'].cumsum()
    daily_answers['cdf'] = daily_answers['cumulative_answers'] / answerNum

    return daily_answers
