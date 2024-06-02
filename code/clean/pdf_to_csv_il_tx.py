#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jun  2 17:50:55 2024

@author: maggie
"""

import pdfplumber
import pandas as pd

## Illinois

file_path = '/Users/maggie/Dropbox (Brown)/metoo_data/raw/IL/JIang FOIA documentation 5.31.24.pdf'

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

# Save the final DataFrame to a CSV file
output_csv_path = '/Users/maggie/Dropbox (Brown)/metoo_data/raw/IL/il_raw_cases.csv'
final_df.to_csv(output_csv_path, index=False)

# Print completion message
print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")

## Texas

file_path = '/Users/maggie/Dropbox (Brown)/metoo_data/raw/tx/Housing_Discrimination_Cases_from_1_June_2010_-_1_June_2023.pdf'

# Initialize an empty list to store all tables
all_tables = []

with pdfplumber.open(file_path) as pdf:
    headers = None
    for page_number, page in enumerate(pdf.pages, start=1):
        # Extract tables
        tables = page.extract_tables()
        for table_number, table in enumerate(tables, start=1):
            try:
                if headers is None:
                    # Extract headers from the first table of the first page
                    headers = table[0]
                # Convert table to DataFrame and use extracted headers
                df = pd.DataFrame(table[1:], columns=headers)
                all_tables.append(df)
                print(f"Extracted table {table_number} from page {page_number}")
            except Exception as e:
                print(f"Error processing table {table_number} on page {page_number}: {e}")

# Concatenate all DataFrames in the list into a single DataFrame
try:
    final_df = pd.concat(all_tables, ignore_index=True)
    # Save the final DataFrame to a CSV file
    output_csv_path = '/Users/maggie/Dropbox (Brown)/metoo_data/raw/TX/tx_raw_cases.csv'
    final_df.to_csv(output_csv_path, index=False)
    print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")
except Exception as e:
    print(f"Error concatenating DataFrames: {e}")
    