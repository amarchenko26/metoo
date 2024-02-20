#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Feb 20 18:18:46 2024

@author: anyamarchenko
"""

import pandas as pd

cases = pd.read_csv("data/raw/cases.csv")

###############################################################################
# Identify SH cases
###############################################################################

cases['sh'] = cases['Allegations'].str.contains('Sexual Harassment', case=False, na=False).astype(int) #case=False parameter makes the search case-insensitive, and na=False treats NaN values as False.

cases['sex_cases'] = cases['Allegations'].str.contains('Title VII / Sex‐Female', case=False, na=False).astype(int) #case=False parameter makes the search case-insensitive, and na=False treats NaN values as False.

total_sh_cases = cases['sh'].sum()
print("Total cases of Sexual Harassment:", total_sh_cases)

total_sex_cases = cases['sex_cases'].sum()
print("Total cases brought under Title VII / Sex‐Female:", total_sex_cases)


###############################################################################
# Identify SH cases straddling MeToo
###############################################################################

# Step 1: Convert 'Court Filing Date' and 'Resolution Date' to datetime format
cases['Court Filing Date'] = pd.to_datetime(cases['Court Filing Date'])
cases['Resolution Date'] = pd.to_datetime(cases['Resolution Date'])


def count_filtered_cases(cases_df, filter_col, court_filing_before, resolution_after):
    """
    Count the number of cases matching specific criteria.

    Parameters:
    - cases_df: DataFrame containing the cases data.
    - filter_col: The column to filter by (e.g., 1 for cases with Sexual Harassment).
    - court_filing_before: The cutoff date (as a string in 'YYYY-MM-DD' format) for filtering 'Court Filing Date' before this date.
    - resolution_after: The cutoff date (as a string in 'YYYY-MM-DD' format) for filtering 'Resolution Date' after this date.

    Returns:
    - The number of cases matching the criteria.
    """
    
    # Filter cases based on the provided criteria
    filtered_cases = cases_df[
        (cases_df[filter_col] == 1) &
        (cases_df['Court Filing Date'] < pd.Timestamp(court_filing_before)) &
        (cases_df['Resolution Date'] > pd.Timestamp(resolution_after))
    ]
    
    # Return the number of filtered cases
    return print("Number of cases matching criteria:", len(filtered_cases))


num_filtered_cases = count_filtered_cases(
    cases_df = cases, 
    filter_col = 'sh', 
    court_filing_before = '2017-10-01', 
    resolution_after = '2017-10-01'
)

count_filtered_cases(
    cases_df = cases, 
    filter_col = 'sex_cases', 
    court_filing_before = '2017-10-01', 
    resolution_after = '2017-10-01'
)


count_filtered_cases(
    cases_df = cases, 
    filter_col = 'sex_cases', 
    court_filing_before = '2017-10-01', 
    resolution_after = '2018-01-01'
)


# SH cases that happened and resolved before 2017 = 309
len(cases[
        (cases['sh'] == 1) &
        (cases['Court Filing Date'] < pd.Timestamp('2017-10-01')) &
        (cases['Resolution Date'] < pd.Timestamp('2017-10-01'))
    ])
    
# SH cases that happened and resolved AFTER 2017 = 105
len(cases[
        (cases['sh'] == 1) &
        (cases['Court Filing Date'] > pd.Timestamp('2017-10-01')) &
        (cases['Resolution Date'] > pd.Timestamp('2017-10-01'))
    ])







