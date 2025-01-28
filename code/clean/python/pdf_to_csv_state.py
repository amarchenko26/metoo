import getpass
import PyPDF2
import pdfplumber
import csv
import os
import pandas as pd

userid = getpass.getuser()
if userid == "anyamarchenko":
    root = "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data"
elif userid == "maggie":
    root = "/Users/maggie/Dropbox (Brown)/metoo_data"
elif userid == "jacobhirschhorn":
    root = "/Users/jacobhirschhorn/Dropbox (Brown)/metoo_data"


## New Yrok
input_pdf_path = root + '/raw/NY/Jiang_FOIL_Report__amemnded_with_acts_of_discrimination_column_.pdf'
split_pdf_dir = root + '/raw/NY/split_pdfs'
output_csv_path = root + '/raw/NY/ny_raw_cases.csv'

# Ensure the split directory exists
os.makedirs(split_pdf_dir, exist_ok=True)

# Step 1: Split the Large PDF into Smaller Files
def split_pdf(input_pdf_path, output_dir, pages_per_split=100):
    # Open the large PDF file
    with open(input_pdf_path, "rb") as pdf_file:
        reader = PyPDF2.PdfReader(pdf_file)
        total_pages = len(reader.pages)
        
        # Split the PDF into smaller chunks
        for i in range(0, total_pages, pages_per_split):
            writer = PyPDF2.PdfWriter()
            for j in range(i, min(i + pages_per_split, total_pages)):
                writer.add_page(reader.pages[j])
            
            # Write each chunk to a new file
            split_pdf_path = f"{output_dir}/split_{i // pages_per_split + 1}.pdf"
            with open(split_pdf_path, "wb") as split_pdf_file:
                writer.write(split_pdf_file)
            print(f"Created split PDF: {split_pdf_path}")

import os
import re
import pdfplumber
import pandas as pd
import os
import re
import pdfplumber
import pandas as pd


import os
import re
import pdfplumber
import pandas as pd

def extract_tables_from_split_pdfs_dynamic(split_pdf_dir, output_csv_path):
    """
    This version introduces a new 'Case Name' field to keep multi-line
    case names out of the 'Basis' or 'Acts' columns.
    """

    def clean_text(text):
        return ' '.join(text.split())

    # Loose matching of "employment," "housing," etc., to handle OCR typos
    JURISDICTION_REGEX = re.compile(
        r'(.*?)(\S*mploy\w+|Hous\w+|Educ\w+|Public\sAccomm\w+)(.*)',
        re.IGNORECASE
    )

    # Special-exception trigger (case-insensitive)
    SPECIAL_EXCEPTION_PATTERN = re.compile(
        r'(?i)Serve Order After Hearing:\s*Dismissing'
    )

    def parse_basis_acts(text):
        """
        Splits leftover text into 'Basis' (ending in semicolon)
        and 'Acts' (which does not end in a semicolon).
        """
        text = text.strip()
        last_semicolon_index = text.rfind(';')

        if last_semicolon_index == -1:
            # No semicolon => all goes to Acts
            return ("", text)

        # If text ends in ';', there's no Acts portion
        if last_semicolon_index == len(text) - 1:
            basis = text
            acts = ""
        else:
            # Split at the final semicolon
            basis = text[: last_semicolon_index + 1].strip()
            acts = text[last_semicolon_index + 1 :].strip()

        # Remove any trailing semicolons/spaces in the Basis
        while basis.endswith(';'):
            basis = basis[:-1].rstrip()
        return (basis, acts)

    def parse_row(row_text):
        row_text = clean_text(row_text)
        
        parsed_data = {
            "Case ID": "",
            "Date Filed": "",
            "Closing Date": "",
            "Case Name": "",
            "Closing Acts": "",
            "Jurisdiction": "",
            "Basis": "",
            "Acts": ""
        }

        # 1) Case ID (7 or 8 digits at start of row)
        m_id = re.search(r'^(\d{7,8})', row_text)
        if m_id:
            parsed_data["Case ID"] = m_id.group(1)

        # 2) Find up to two dates
        dates = re.findall(r'\d{2}/\d{2}/\d{4}', row_text)
        if len(dates) >= 1:
            parsed_data["Date Filed"] = dates[0]
        if len(dates) >= 2:
            parsed_data["Closing Date"] = dates[1]
            
            # Now we want to find the substring from the end of Date Filed
            # to the start of Closing Date => "Case Name"
            date1_index = row_text.find(dates[0])
            date2_index = row_text.find(dates[1])
            if date1_index != -1 and date2_index != -1:
                end_of_date1 = date1_index + len(dates[0])
                # 'Case Name' is what's between the two dates
                case_name_sub = row_text[end_of_date1 : date2_index]
                parsed_data["Case Name"] = case_name_sub.strip()

            # 'Remainder' is anything after the second date
            # (plus the length of that date string)
            remainder_start = date2_index + len(dates[1])
            remainder = row_text[remainder_start:].strip()

            # Special exception check
            if SPECIAL_EXCEPTION_PATTERN.search(remainder):
                jur_match = JURISDICTION_REGEX.search(remainder)
                if jur_match:
                    parsed_data["Closing Acts"] = jur_match.group(1).strip()
                    parsed_data["Jurisdiction"] = jur_match.group(2).strip()
                    leftover = jur_match.group(3).strip()
                else:
                    parsed_data["Closing Acts"] = remainder
                    leftover = ""
            else:
                # Normal path
                jur_match = JURISDICTION_REGEX.search(remainder)
                if jur_match:
                    parsed_data["Closing Acts"] = jur_match.group(1).strip()
                    parsed_data["Jurisdiction"] = jur_match.group(2).strip()
                    leftover = jur_match.group(3).strip()
                else:
                    parsed_data["Closing Acts"] = remainder
                    leftover = ""

            # Now parse the leftover as 'Basis' and 'Acts'
            if leftover:
                basis_part, acts_part = parse_basis_acts(leftover)
                parsed_data["Basis"] = basis_part
                parsed_data["Acts"] = acts_part

        # Debug
        print("Parsed row:")
        for k, v in parsed_data.items():
            print(f"  {k}: {v}")
        print("-"*80)

        return parsed_data

    def should_skip_row(line):
        """
        If a line does NOT start with 7 or 8 digits, treat it as a continuation.
        """
        return not re.match(r'^\d{7,8}', line.strip())

    # Iterate all PDF files
    split_pdf_files = sorted(
        [f for f in os.listdir(split_pdf_dir) if f.lower().endswith('.pdf')]
    )
    all_rows = []

    for split_pdf_file in split_pdf_files:
        split_pdf_path = os.path.join(split_pdf_dir, split_pdf_file)
        print(f"Processing: {split_pdf_file}")

        with pdfplumber.open(split_pdf_path) as pdf:
            for page_num, page in enumerate(pdf.pages, start=1):
                print(f"  Page {page_num}")
                text = page.extract_text()
                if not text:
                    continue  # skip blank pages

                current_row = ""
                for line in text.split('\n'):
                    line = line.strip()
                    if should_skip_row(line):
                        # Continuation
                        current_row += " " + line
                    else:
                        # Parse the previous row if we have one
                        if current_row.strip():
                            all_rows.append(parse_row(current_row))
                        # Start a new row
                        current_row = line

                # End of page: parse leftover
                if current_row.strip():
                    all_rows.append(parse_row(current_row))

    # Convert to DataFrame and save
    if all_rows:
        df = pd.DataFrame(all_rows)
        df.to_csv(output_csv_path, index=False)
        print(f"Data extracted and saved to {output_csv_path}")
    else:
        print("No rows found to parse.")

# Run the split and extraction functions
#split_pdf(input_pdf_path, split_pdf_dir)
extract_tables_from_split_pdfs_dynamic(split_pdf_dir, output_csv_path)
print(f"New York data has been successfully extracted to {output_csv_path}")







## California
input_pdf_path = root + '/raw/CA/2017 - 2024 Report  - Final.pdf'
split_pdf_dir = root + '/raw/CA/split_pdfs'
output_csv_path = root + '/raw/CA/ca_raw_cases.csv'

# Ensure the split directory exists
os.makedirs(split_pdf_dir, exist_ok=True)

# Step 1: Split the Large PDF into Smaller Files
def split_pdf(input_pdf_path, output_dir, pages_per_split=100):
    # Open the large PDF file
    with open(input_pdf_path, "rb") as pdf_file:
        reader = PyPDF2.PdfReader(pdf_file)
        total_pages = len(reader.pages)
        
        # Split the PDF into smaller chunks
        for i in range(0, total_pages, pages_per_split):
            writer = PyPDF2.PdfWriter()
            for j in range(i, min(i + pages_per_split, total_pages)):
                writer.add_page(reader.pages[j])
            
            # Write each chunk to a new file
            split_pdf_path = f"{output_dir}/split_{i // pages_per_split + 1}.pdf"
            with open(split_pdf_path, "wb") as split_pdf_file:
                writer.write(split_pdf_file)
            print(f"Created split PDF: {split_pdf_path}")

# Step 2: Extract Tables from Each Split PDF
def extract_tables_from_split_pdfs(split_pdf_dir, output_csv_path):
    # Initialize variables for processing
    headers_written = False  # To ensure headers are written only once

    # Get list of split PDF files
    split_pdf_files = sorted([f for f in os.listdir(split_pdf_dir) if f.endswith('.pdf')])

    for split_pdf_file in split_pdf_files:
        split_pdf_path = os.path.join(split_pdf_dir, split_pdf_file)
        print(f"Processing {split_pdf_file}")

        # Open the split PDF file
        with pdfplumber.open(split_pdf_path) as pdf:
            # Iterate through each page in the split PDF
            for page in pdf.pages:
                # Extract the table from the current page
                table = page.extract_table()
                if table:
                    # Convert the page's table data to a DataFrame
                    df = pd.DataFrame(table[1:], columns=table[0])

                    # Write to CSV, appending each page’s data to avoid memory overload
                    # Only write headers once
                    df.to_csv(output_csv_path, mode='a', header=not headers_written, index=False)
                    headers_written = True  # Ensure headers are only written on the first page

# Run the split and extraction functions
split_pdf(input_pdf_path, split_pdf_dir)
extract_tables_from_split_pdfs(split_pdf_dir, output_csv_path)
print(f"Data has been successfully extracted to {output_csv_path}")

    
## Florida employment

file_path = root + '/raw/FL/Maggie Jiang EMP pdf.pdf'

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
    output_csv_path = root + '/raw/FL/fl_employment_cases.csv'
    final_df.to_csv(output_csv_path, index=False)
    print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")
except Exception as e:
    print(f"Error concatenating DataFrames: {e}")
    
## Florida housing

file_path = root + '/raw/FL/Maggie Jiang HOUSING pdf.pdf'

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
    output_csv_path = root + '/raw/FL/fl_housing_cases.csv'
    final_df.to_csv(output_csv_path, index=False)
    print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")
except Exception as e:
    print(f"Error concatenating DataFrames: {e}")
    
## Florida housing

file_path = root + '/raw/FL/Maggie Jiang HOUSING pdf 2.pdf'

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
    output_csv_path = root + '/raw/FL/fl_housing_cases_2.csv'
    final_df.to_csv(output_csv_path, index=False)
    print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")
except Exception as e:
    print(f"Error concatenating DataFrames: {e}")
    
## Florida PA

file_path = root + '/raw/FL/Maggie Jiang PUBLIC ACCOM.pdf'

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
    output_csv_path = root + '/raw/FL/fl_pa_cases.csv'
    final_df.to_csv(output_csv_path, index=False)
    print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")
except Exception as e:
    print(f"Error concatenating DataFrames: {e}")

## Florida PA

file_path = root + '/raw/FL/Maggie Jiang PUBLIC ACCOM 2.pdf'

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
    output_csv_path = root + '/raw/FL/fl_pa_cases_2.csv'
    final_df.to_csv(output_csv_path, index=False)
    print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")
except Exception as e:
    print(f"Error concatenating DataFrames: {e}")

## Illinois

file_path = root + '/raw/IL/JIang FOIA documentation 5.31.24.pdf'

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
output_csv_path = root + '/raw/IL/il_raw_cases.csv'
final_df.to_csv(output_csv_path, index=False)

# Print completion message
print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")

## Texas

file_path = root + '/raw/TX/Housing_Discrimination_Cases_from_1_June_2010_-_1_June_2023.pdf'

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
    output_csv_path = root + '/raw/TX/tx_raw_cases.csv'
    final_df.to_csv(output_csv_path, index=False)
    print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")
except Exception as e:
    print(f"Error concatenating DataFrames: {e}")
    
## Texas SH
    
file_path = root + '/raw/TX/Sex_Harrassment_Housing_Discrimination_Cases.pdf'

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
    output_csv_path = root + '/raw/TX/tx_sh_cases.csv'
    final_df.to_csv(output_csv_path, index=False)
    print(f"Data has been successfully extracted from {file_path} and written to '{output_csv_path}'")
except Exception as e:
    print(f"Error concatenating DataFrames: {e}")
  