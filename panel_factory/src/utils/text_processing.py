"""
Text processing utilities for extracting metrics from HTML content.

Extracted from Archive/round2_parser_for_panel.ipynb cells 16-24.
"""

import pandas as pd
import numpy as np
from bs4 import BeautifulSoup


def extract_code_text(html_content):
    """Extract code blocks from HTML content."""
    if not isinstance(html_content, str) or pd.isna(html_content):
        return ""
    soup = BeautifulSoup(html_content, "lxml")
    code_blocks = soup.select("article pre code")
    return " ".join(str(block.get_text()) for block in code_blocks)


def extract_CN_text(html_content):
    """Extract Chinese text from HTML content."""
    if not isinstance(html_content, str) or pd.isna(html_content):
        return ""
    soup = BeautifulSoup(html_content, "lxml")
    text = soup.get_text()
    chinese_chars = [char for char in text if '一' <= char <= '鿿']
    return "".join(chinese_chars)


def extract_full_text(html_content):
    """Extract full text from HTML content."""
    if not isinstance(html_content, str) or pd.isna(html_content):
        return ""
    soup = BeautifulSoup(html_content, "lxml")
    return soup.get_text()


def calculate_code_length(html_content):
    """Calculate total length of code blocks in HTML content."""
    if not isinstance(html_content, str) or pd.isna(html_content):
        return np.nan
    soup = BeautifulSoup(html_content, "lxml")
    code_blocks = soup.select("article pre code")
    return sum(len(str(block)) for block in code_blocks)


def calculate_text_length(html_content):
    """
    Calculate text length and Chinese character count.

    Returns:
        tuple: (text_length, chinese_char_count)
    """
    if not isinstance(html_content, str) or pd.isna(html_content):
        return np.nan, np.nan
    soup = BeautifulSoup(html_content, "lxml")
    text = soup.get_text()
    text_length = len(text)
    chinese_char_count = sum(1 for char in text if '一' <= char <= '鿿')
    return text_length, chinese_char_count


def count_formatting_elements(html_content, prefix=""):
    """
    Count formatting elements (img, br, code, href) in HTML content.

    Args:
        html_content: HTML string
        prefix: Optional prefix for column names (e.g., "preAI-")

    Returns:
        dict: Counts of formatting elements
    """
    if not isinstance(html_content, str) or pd.isna(html_content):
        return {
            f'{prefix}imgNum': np.nan,
            f'{prefix}brNum': np.nan,
            f'{prefix}codeNum': np.nan,
            f'{prefix}inlinecodeNum': np.nan,
            f'{prefix}interlinecodeNum': np.nan,
            f'{prefix}hrefNum': np.nan,
        }

    soup = BeautifulSoup(html_content, "lxml")

    # Count code blocks
    code_blocks = soup.select("article pre code")
    interline_code_num = len(code_blocks)

    # Count inline code (code tags not inside pre)
    all_code_tags = soup.find_all('code')
    inline_code_num = len([tag for tag in all_code_tags if not tag.find_parent('pre')])

    return {
        f'{prefix}imgNum': len(soup.find_all('img')),
        f'{prefix}brNum': len(soup.find_all('br')),
        f'{prefix}codeNum': len(all_code_tags),
        f'{prefix}inlinecodeNum': inline_code_num,
        f'{prefix}interlinecodeNum': interline_code_num,
        f'{prefix}hrefNum': len(soup.find_all('a')),
    }


def count_html_tags(html_content, prefix=""):
    """
    Count HTML formatting tags (bold, italic, lists, etc.).

    Args:
        html_content: HTML string
        prefix: Optional prefix for column names (e.g., "preAI-")

    Returns:
        dict: Counts of HTML tags
    """
    if not isinstance(html_content, str) or pd.isna(html_content):
        return {
            f'{prefix}boldNum': np.nan,
            f'{prefix}italicNum': np.nan,
            f'{prefix}ulNum': np.nan,
            f'{prefix}olNum': np.nan,
            f'{prefix}liNum': np.nan,
            f'{prefix}aNum': np.nan,
            f'{prefix}blockquoteNum': np.nan,
            f'{prefix}hrNum': np.nan,
            f'{prefix}tableNum': np.nan,
        }

    soup = BeautifulSoup(html_content, "lxml")

    return {
        f'{prefix}boldNum': len(soup.find_all('strong')) + len(soup.find_all('b')),
        f'{prefix}italicNum': len(soup.find_all('em')) + len(soup.find_all('i')),
        f'{prefix}ulNum': len(soup.find_all('ul')),
        f'{prefix}olNum': len(soup.find_all('ol')),
        f'{prefix}liNum': len(soup.find_all('li')),
        f'{prefix}aNum': len(soup.find_all('a')),
        f'{prefix}blockquoteNum': len(soup.find_all('blockquote')),
        f'{prefix}hrNum': len(soup.find_all('hr')),
        f'{prefix}tableNum': len(soup.find_all('table')),
    }


def calculate_goodAI(row, prefix="preAI-"):
    """
    Calculate goodAI metric: count of non-zero formatting fields.

    Args:
        row: DataFrame row with formatting columns
        prefix: Prefix used for formatting columns

    Returns:
        int: Count of non-zero formatting fields
    """
    formatting_fields = [
        f'{prefix}imgNum', f'{prefix}brNum', f'{prefix}codeNum',
        f'{prefix}inlinecodeNum', f'{prefix}interlinecodeNum', f'{prefix}hrefNum',
        f'{prefix}boldNum', f'{prefix}italicNum', f'{prefix}ulNum',
        f'{prefix}olNum', f'{prefix}liNum', f'{prefix}aNum',
        f'{prefix}blockquoteNum', f'{prefix}hrNum', f'{prefix}tableNum'
    ]

    count = 0
    for field in formatting_fields:
        if field in row and pd.notna(row[field]) and row[field] > 0:
            count += 1
    return count


def process_question_content_metrics(html_content, prefix="preAI-"):
    """
    Process question content to extract all metrics.

    Args:
        html_content: HTML string
        prefix: Prefix for column names

    Returns:
        dict: All content metrics
    """
    if not isinstance(html_content, str) or pd.isna(html_content):
        return {}

    metrics = {}

    # Text lengths
    text_length, cn_length = calculate_text_length(html_content)
    metrics[f'{prefix}textLength'] = text_length
    metrics[f'{prefix}textLengthCN'] = cn_length

    # Code length
    metrics[f'{prefix}codeLength'] = calculate_code_length(html_content)

    # Formatting elements
    metrics.update(count_formatting_elements(html_content, prefix))

    # HTML tags (from content_withoutcode)
    metrics.update(count_html_tags(html_content, prefix))

    return metrics


def process_cmn_content_metrics(html_content):
    """
    Process answer content to extract all metrics.

    Args:
        html_content: HTML string

    Returns:
        dict: All content metrics (no prefix for answer-level)
    """
    if not isinstance(html_content, str) or pd.isna(html_content):
        return {}

    metrics = {}

    # Text lengths
    text_length, cn_length = calculate_text_length(html_content)
    metrics['textLength'] = text_length
    metrics['textLengthCN'] = cn_length

    # Code length
    metrics['codeLength'] = calculate_code_length(html_content)

    # Formatting elements
    metrics.update(count_formatting_elements(html_content, prefix=""))

    # HTML tags
    metrics.update(count_html_tags(html_content, prefix=""))

    return metrics
