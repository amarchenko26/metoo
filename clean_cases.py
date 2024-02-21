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
print("Total cases in data:", len(cases))

cases['sh'] = cases['Allegations'].str.contains('Sexual Harassment', case=False, na=False).astype(int) #case=False parameter makes the search case-insensitive, and na=False treats NaN values as False.
cases['sex_cases'] = cases['Allegations'].str.contains('Title VII / Sex‐Female', case=False, na=False).astype(int) #case=False parameter makes the search case-insensitive, and na=False treats NaN values as False.

total_sh_cases = cases['sh'].sum()
print("Total cases of Sexual Harassment:", total_sh_cases)

total_sex_cases = cases['sex_cases'].sum()
print("Total cases brought under Title VII / Sex‐Female:", total_sex_cases)


###############################################################################
# Clean columns
###############################################################################

# Convert 'Court Filing Date' and 'Resolution Date' to datetime format
cases['Court Filing Date'] = pd.to_datetime(cases['Court Filing Date'])
cases['Resolution Date'] = pd.to_datetime(cases['Resolution Date'])

# Remove the dollar sign and commas from the 'Relief' column
cases['Relief'] = cases['Relief'].str.replace('[$,]', '', regex=True)

# Convert to numeric, coercing errors to NaN, and immediately fill NaNs with 0
cases['Relief'] = pd.to_numeric(cases['Relief'], errors='coerce').fillna(0).astype(int)



###############################################################################
# Identify SH cases straddling MeToo
###############################################################################

def filter_cases(cases_df, filter_col, condition, filing_date=None, resolution_date=None, comparison='both'):
    """
    Filter cases based on various criteria.

    Parameters:
    - cases_df: DataFrame containing the cases data.
    - filter_col: The column to filter by (e.g., 'sh' for cases with Sexual Harassment).
    - condition: The condition to match in the filter_col (e.g., 1 for cases that match).
    - filing_date: The cutoff date for 'Court Filing Date'. A tuple of ('before'/'after', date).
    - resolution_date: The cutoff date for 'Resolution Date'. A tuple of ('before'/'after', date).
    - comparison: 'both' for cases meeting both dates criteria, 'either' for cases meeting at least one.

    Returns:
    - Filtered DataFrame.
    """
    filtered_cases = cases_df[cases_df[filter_col] == condition]
    
    if filing_date:
        operator, date = filing_date
        if operator == 'before':
            filtered_cases = filtered_cases[filtered_cases['Court Filing Date'] < pd.Timestamp(date)]
        elif operator == 'after':
            filtered_cases = filtered_cases[filtered_cases['Court Filing Date'] > pd.Timestamp(date)]
    
    if resolution_date:
        operator, date = resolution_date
        if operator == 'before':
            filtered_cases = filtered_cases[filtered_cases['Resolution Date'] < pd.Timestamp(date)]
        elif operator == 'after':
            filtered_cases = filtered_cases[filtered_cases['Resolution Date'] > pd.Timestamp(date)]
    
    return filtered_cases

def count_cases(filtered_cases):
    """
    Count the number of cases in the filtered DataFrame.

    Parameters:
    - filtered_cases: DataFrame of filtered cases.

    Returns:
    - Count of cases.
    """
    return len(filtered_cases)

def calculate_average(filtered_cases, column_name):
    """
    Calculate the average of a specified column in the filtered DataFrame.

    Returns:
    - Average value of the specified column.
    """
    average_value = filtered_cases[column_name].mean()
    return round(average_value)

# Count straddling SH cases
filtered_cases = filter_cases(cases, 'sh', 1, ('before', '2017-10-01'), ('after', '2017-10-01'))
print("Number of SH cases straddling Oct 2017:", count_cases(filtered_cases))

# Count straddling Sex-based cases
filtered_cases = filter_cases(cases, 'sex_cases', 1, ('before', '2017-10-01'), ('after', '2017-10-01'))
print("Number of Title VII / Sex‐Femalecases straddling Oct 2017:", count_cases(filtered_cases))

# Count SH cases before
filtered_cases = filter_cases(cases, 'sh', 1, ('before', '2017-10-01'), ('before', '2017-10-01'))
print("Number of SH cases started and resolved before Oct 2017:", count_cases(filtered_cases))

# Count SH cases after
filtered_cases = filter_cases(cases, 'sh', 1, ('after', '2017-10-01'), ('after', '2017-10-01'))
print("Number of SH cases started and resolved after Oct 2017:", count_cases(filtered_cases))

# Calculate relief before a certain date
filtered_cases_before = filter_cases(cases, 'sh', 1, ('before', '2017-10-01'), ('before', '2017-10-01'))
relief_before = calculate_average(filtered_cases_before, 'Relief')
print("Mean relief $ for SH if case resolved before October 2017:", relief_before)

# Calculate relief after a certain date
filtered_cases_after = filter_cases(cases, 'sh', 1, ('after', '2017-10-01'), ('after', '2017-10-01'))
relief_after = calculate_average(filtered_cases_after, 'Relief')
print("Mean relief $ for SH if case resolved after October 2017:", relief_after)


# Calculate the duration in days between filing and resolution
cases['Duration'] = (cases['Resolution Date'] - cases['Court Filing Date']).dt.days

# Filter cases based on the condition (where 'ConditionColumn' equals 1)
filtered_cases = cases[cases['sh'] == 1]

# Now apply the date filters for before and after October 1, 2017
before_oct_1_2017 = filtered_cases[filtered_cases['Court Filing Date'] < pd.Timestamp('2017-10-01')]
after_oct_1_2017 = filtered_cases[filtered_cases['Court Filing Date'] > pd.Timestamp('2017-10-01')]

# Calculate the mean duration for each period
mean_duration_before = before_oct_1_2017['Duration'].mean()
mean_duration_after = after_oct_1_2017['Duration'].mean()

print(f"Mean duration for SH cases, before October 1, 2017: {mean_duration_before} days")
print(f"Mean duration for SH cases, after October 1, 2017: {mean_duration_after} days")