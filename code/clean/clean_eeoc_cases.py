#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Feb 20 18:18:46 2024

@author: anyamarchenko
"""

import pandas as pd
import matplotlib.pyplot as plt
import os
import numpy as np

# Create figures directory if it doesn't exist
#figures_dir = 'figures/'
#if not os.path.exists(figures_dir):
#    os.makedirs(figures_dir)

cases = pd.read_csv("data/raw/EEOC/cases.csv")


###############################################################################
# Identify SH cases
###############################################################################
print("Total cases in data:", len(cases))

cases['sh'] = cases['Allegations'].str.contains('Sexual Harassment', case=False, na=False).astype(int) #case=False makes the search case-insensitive, and na=False treats NaN values as False.
cases['sex_cases'] = cases['Allegations'].str.contains('Title VII / Sex‐Female', case=False, na=False).astype(int) #case=False makes the search case-insensitive, and na=False treats NaN values as False.

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

# Create a new column to indicate cases before or after a certain date
cases['before'] = np.where(cases['Court Filing Date'] < '2017-10-01', 1, 0)

# Calculate the duration in days between filing and resolution
cases['Duration'] = (cases['Resolution Date'] - cases['Court Filing Date']).dt.days

# Remove the dollar sign and commas from the 'Relief' column
cases['Relief'] = cases['Relief'].str.replace('[$,]', '', regex=True)

# Create a new column to indicate missing relief
cases['missing_relief'] = cases['Relief'].isnull().astype(int)

# Convert to numeric, coercing errors to NaN, and fill NaNs with 0
cases['Relief'] = pd.to_numeric(cases['Relief'], errors='coerce').fillna(0).astype(int)


###############################################################################
# Clean unicode characters
###############################################################################

def replace_problematic_characters(df):
    """
    Replace problematic Unicode characters in string columns of a DataFrame.
    """
    replacements = {
        '\u2010': '-',  # Hyphen
        '\u2013': '-',  # En-dash
        '\u2014': '--', # Em-dash
        '\u2018': "'",  # Left single quotation mark
        '\u2019': "'",  # Right single quotation mark
        '\u201C': '"',  # Left double quotation mark
        '\u201D': '"',  # Right double quotation mark
        # Add more replacements as needed
    }
    
    for column in df.select_dtypes(include=['object']):
        for src, target in replacements.items():
            df[column] = df[column].str.replace(src, target, regex=False)
    return df

# Replace problematic characters
cases_clean = replace_problematic_characters(cases)

# Then save to .dta format
cases_clean.to_stata('data/clean/clean_eeoc.dta', version = 117)


###############################################################################
# Save clean cases df
###############################################################################

cases.to_csv('data/clean/clean_eeoc.csv')


cases.to_stata('data/clean/clean_eeoc.dta')

###############################################################################
# Identify SH cases straddling MeToo
###############################################################################

def filter_fun(cases_df, filter_col, condition, filing_date=None, resolution_date=None, comparison='both'):
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
    """
    return len(filtered_cases)

def calculate_average(filtered_cases, column_name):
    """
    Calculate the average of a specified column in the filtered DataFrame.
    """
    average_value = filtered_cases[column_name].mean()
    return round(average_value)

# Count straddling SH cases
filtered_cases = filter_fun(cases, 'sh', 1, ('before', '2017-10-01'), ('after', '2017-10-01'))
print("Number of SH cases straddling Oct 2017:", count_cases(filtered_cases))

# Count straddling Sex-based cases
filtered_cases = filter_fun(cases, 'sex_cases', 1, ('before', '2017-10-01'), ('after', '2017-10-01'))
print("Number of Title VII / Sex‐Femalecases straddling Oct 2017:", count_cases(filtered_cases))

# Count SH cases before
filtered_cases = filter_fun(cases, 'sh', 1, ('before', '2017-10-01'), ('before', '2017-10-01'))
print("Number of SH cases started and resolved before Oct 2017:", count_cases(filtered_cases))

# Count SH cases after
filtered_cases = filter_fun(cases, 'sh', 1, ('after', '2017-10-01'), ('after', '2017-10-01'))
print("Number of SH cases started and resolved after Oct 2017:", count_cases(filtered_cases))


# Calculate all SH relief before a certain date
filtered_cases_before = filter_fun(cases, 'sh', 1, ('before', '2017-10-01'), ('before', '2017-10-01'))
relief_before = calculate_average(filtered_cases_before, 'Relief')
print("Mean relief $ for SH if case resolved before October 2017, with zeroes:", relief_before)

# Calculate all SH relief after 
filtered_cases_after = filter_fun(cases, 'sh', 1, ('after', '2017-10-01'), ('after', '2017-10-01'))
relief_after = calculate_average(filtered_cases_after, 'Relief')
print("Mean relief $ for SH if case resolved after October 2017, with zeroes:", relief_after)


# Calculate all SH relief before a certain date
filtered_cases_before = filter_fun(cases, 'sh', 0, ('before', '2017-10-01'), ('before', '2017-10-01'))
relief_before = calculate_average(filtered_cases_before, 'Relief')
print("Mean relief $ for all non-SH cases if resolved before October 2017:", relief_before)

# Calculate all SH relief after 
filtered_cases_after = filter_fun(cases, 'sh', 0, ('after', '2017-10-01'), ('after', '2017-10-01'))
relief_after = calculate_average(filtered_cases_after, 'Relief')
print("Mean relief $ for all non-SH cases if resolved after October 2017:", relief_after)

# Create new df for sh = 1
sh_cases = cases[cases['sh'] == 1]

# Calculate how frequently relief is missing and sh == 1
missing_relief = sh_cases['missing_relief'].sum()
print(f"Relief is missing for SH cases {missing_relief} times")

# Calculate non-zero relief before 
filtered_cases_before = filter_fun(sh_cases, 'missing_relief', 0, ('before', '2017-10-01'), ('before', '2017-10-01'))
relief_before = calculate_average(filtered_cases_before, 'Relief')
print("Mean relief $ for SH if case resolved before October 2017, no zeroes:", relief_before)

# Calculate non-zero relief after
filtered_cases_after = filter_fun(sh_cases, 'missing_relief', 0, ('after', '2017-10-01'), ('after', '2017-10-01'))
relief_after = calculate_average(filtered_cases_after, 'Relief')
print("Mean relief $ for SH if case resolved after October 2017, no zeroes:", relief_after)

# Now apply the date filters for before and after October 1, 2017
before_oct_1_2017 = sh_cases[sh_cases['Court Filing Date'] < pd.Timestamp('2017-10-01')]
after_oct_1_2017 = sh_cases[sh_cases['Court Filing Date'] > pd.Timestamp('2017-10-01')]

# Calculate the mean duration for each period
mean_duration_before = before_oct_1_2017['Duration'].mean()
mean_duration_after = after_oct_1_2017['Duration'].mean().round(1)

print(f"Mean duration for SH cases, before October 1, 2017: {mean_duration_before} days")
print(f"Mean duration for SH cases, after October 1, 2017: {mean_duration_after} days")

###############################################################################
# Plots
###############################################################################

# Keep all cases with filing date later than 2000
cases = cases[cases['Court Filing Date'] > '2004-01-01']

def plot_column_over_time(dataframe1, dataframe2, date_column, plot_column, title, xlabel, filename):
    """
    Plots the specified column of a DataFrame over time, aggregated by month.
    """   
    # Set the date column as the index
    dataframe1.set_index(date_column, inplace=True)
    dataframe2.set_index(date_column, inplace=True)    

    # Resample the data by month and calculate the mean for the plot column
    monthly_data1 = dataframe1[plot_column].resample('M').mean()
    monthly_data2 = dataframe2[plot_column].resample('M').mean()
    
    # Plotting
    plt.figure(figsize=(10, 6)) # Adjust the size as needed
    monthly_data1.plot(label="All cases")
    monthly_data2.plot(label="SH cases")
    plt.title(title, fontsize=14, pad=20)
    plt.xlabel(xlabel)
    plt.ylabel(plot_column)
    plt.axvline('2017-10-01', color='red', linestyle='--', linewidth=2)
    plt.ylim(0, 6000000) # Adjust the y-axis limits as needed
    plt.legend()
    plt.grid(True)
    
    # Save the plot after it's created
    full_path = f'{figures_dir}{filename}'
    plt.savefig(full_path, format='png')
    plt.show()

    
plot_column_over_time(cases, sh_cases, 'Court Filing Date', 'Relief', "Mean Relief Over Time by Filing Date", "Time", "mean_relief.png")

#plot_column_over_time(cases, 'Court Filing Date', 'Relief', "Number of Cases Over Time by Resolution Date", "Time", "cases_over_time.png")

