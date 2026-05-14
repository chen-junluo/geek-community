#!/usr/bin/env python3
"""
Regression Reports Generator - Example Usage

This script demonstrates how to use the regression-reports skill.
Modify the html_files list to match your actual HTML output files.
"""

import sys
import os

# Add skill directory to path
skill_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, skill_dir)

from generate_report_from_html import main, create_regression_table, parse_html_table, load_variable_mapping
from docx import Document

def generate_custom_report(html_files, output_path, mapping_file):
    """
    Generate a custom regression report

    Args:
        html_files: List of dicts with keys: file, title, sample, dv, iv
        output_path: Path to save the Word document
        mapping_file: Path to variable mapping file
    """
    mapping = load_variable_mapping(mapping_file)
    doc = Document()
    doc.add_heading('Regression Analysis Results', level=0)

    for idx, html_info in enumerate(html_files, 1):
        print(f"Processing: {html_info['file']}")
        table_data = parse_html_table(html_info['file'])

        if table_data:
            create_regression_table(
                doc,
                table_data,
                mapping,
                table_num=idx,
                section_title=html_info['title'],
                sample_desc=html_info['sample'],
                dv_type=html_info['dv'],
                iv_desc=html_info['iv']
            )
            print(f"  ✓ Table {idx} created")
        else:
            print(f"  ✗ Failed to parse table")

    doc.save(output_path)
    print(f"\nReport saved to: {output_path}")

if __name__ == "__main__":
    # Example: Customize this for your project
    workspace_root = "/Users/dylanchen/Desktop/geek-community"

    html_files = [
        {
            'file': f'{workspace_root}/Projects/MISQ/analysis/round 2/outputs/meeting260505_innovation_allhumananswer.html',
            'title': '260505开会做的分析（强调DV是连续型）',
            'sample': 'All human answers',
            'dv': 'Experience (M2, continuous), Insight (M2, continuous), Alternative (M2, continuous)',
            'iv': 'Treatment, Treatment × AI Length (log), Treatment × AI Quality'
        },
        # Add more tables here...
    ]

    output_path = f'{workspace_root}/Projects/MISQ/analysis/round 2/outputs/regression_report.docx'
    mapping_file = f'{workspace_root}/Documents/Notes/variable_mapping.md'

    generate_custom_report(html_files, output_path, mapping_file)
