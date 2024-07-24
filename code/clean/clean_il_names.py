#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jul 15 16:48:01 2024

@author: anyamarchenko
"""

import pandas as pd
import getpass
from gender_guesser.detector import Detector
from pathlib import Path

# Determine user and set root path
userid = getpass.getuser()
if userid == "anyamarchenko":
    root = Path("/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data")
elif userid == "maggie":
    root = Path("/Users/maggie/Dropbox (Brown)/metoo_data")
elif userid == "jacobhirschhorn":
    root = Path("/Users/jacobhirschhorn/Dropbox (Brown)/metoo_data")
else:
    raise ValueError("User not recognized")

# Set file path
file_path = root / 'raw/IL/il_raw_cases.csv'

il_data = pd.read_csv(file_path)

# Initialize the gender detector
d = Detector()

# Function to extract the first name
def extract_first_name(name):
    if pd.isna(name) or not isinstance(name, str):
        return None
    parts = name.split()
    if len(parts) == 0:
        return None
    if len(parts) > 1 and len(parts[-1]) == 1:  # Check for middle initial
        return parts[-2]
    return parts[-1]

# Extract first names
il_data['First_Name'] = il_data['CP Name'].apply(extract_first_name)


# Function to detect gender with additional checks
def detect_gender(name):
    if pd.isna(name):
        return 'unknown'
    # Convert to title case (first letter capitalized, rest lowercase)
    name = name.title()
    gender = d.get_gender(name)
    if gender == 'andy':
        return 'unknown' # andy used for ambiguous names
    elif gender == 'male' or gender == 'mostly_male':
        return '0'
    elif gender == 'female' or gender == 'mostly_female':
        return '1'
    else:
        return 'unknown'

# Apply gender detection to the First_Name column
il_data['victim_f'] = il_data['First_Name'].apply(detect_gender)

# Print the first few rows to verify the results
print(il_data[['CP Name', 'First_Name', 'victim_f']].head(10))

# Count the gender distribution
gender_counts = il_data['victim_f'].value_counts()
print("\nGender Distribution:")
print(gender_counts)

# Optionally, save the updated DataFrame to a new CSV file
output_file_path = root / 'raw/IL/il_raw_cases_gender.csv'
il_data.to_csv(output_file_path, index=False)
