#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Feb 20 17:09:59 2024

@author: anyamarchenko
"""

import pdfplumber
import pandas as pd

file_path = '/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data/raw/DATA - 2010-2022 Resolutions as of 08.25.23.pdf'

# Initialize an empty list to store all tables
all_tables = []

with pdfplumber.open(file_path) as pdf:
    for page in pdf.pages:
        # Extract tables
        tables = page.extract_tables()
        for table in tables:
            # Convert table to DataFrame and append to the list
            df = pd.DataFrame(table[1:], columns=table[0])
            all_tables.append(df)

# Concatenate all DataFrames in the list into a single DataFrame
final_df = pd.concat(all_tables, ignore_index=True)

final_df.to_csv('data/raw/cases.csv', index=False)

