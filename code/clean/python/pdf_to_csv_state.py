import getpass
import PyPDF2
import pdfplumber
import tabula
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


# Step 2: Read in Smaller Files using tabula
def convert_and_append_pdfs_to_csv(split_pdf_dir, output_csv_path, columns):
    all_dfs = []

    # Get a sorted list of PDFs
    pdf_files = sorted(f for f in os.listdir(split_pdf_dir) if f.lower().endswith('.pdf'))

    # Define the expected column order
    expected_columns = [
        "case_id", "date_filed", "case_name",
        "closing_date", "closing_acts",
        "jurisdiction", "basis", "acts"
    ]

    for pdf_file in pdf_files:
        pdf_path = os.path.join(split_pdf_dir, pdf_file)
        print(f"Processing {pdf_file}")

        # Read PDF into a list of DataFrames
        list = tabula.read_pdf(
            input_path = pdf_path,
            pages="all",
            stream=True,  
            guess=False,
            columns=columns,
            multiple_tables=False,
            pandas_options={'header': None}  # Tell tabula not to use first row as header
        )

        # Tabula returns a list of dataframes, so need to get the first one (the only one)
        df = list[0] if list else None

        print(f"Extracted {len(df.columns)} columns from {pdf_path}")
        print(df.shape)

        # Delete the first unnamed column
        del df[0]

        # Assign correct column names
        df.columns = expected_columns

        all_dfs.append(df)

    if all_dfs:
        final_df = pd.concat(all_dfs, ignore_index=True)
        final_df.to_csv(output_csv_path, index=False)
        print(f"Successfully saved extracted data to {output_csv_path}")
    else:
        print("No valid data found in any PDFs.")

# Example usage
columns = [0, 160, 250, 670, 730, 950, 1050, 1328]  # 7 cut points → 8 columns
convert_and_append_pdfs_to_csv(split_pdf_dir, output_csv_path, columns)










column_coords = {
    'case_id':      {'x0': 0, 'x1': 160},          # Fill in your values
    'date_filed':   {'x0': 160, 'x1': 250},     # Fill in your values
    'case_name':    {'x0': 250, 'x1': 670},      # Fill in your values
    'closing_date': {'x0': 670, 'x1': 750},   # Fill in your values
    'closing_acts': {'x0': 730, 'x1': 956},   # Fill in your values
    'jurisdiction': {'x0': 950, 'x1': 1050},  # Fill in your values
    'basis':        {'x0': 1060, 'x1': 1328},        # Fill in your values
    'acts':         {'x0': 1328, 'x1': 2160}          # Fill in your values
}


print(f"New York data has been successfully extracted to {output_csv_path}")

# with pdfplumber.open(f'{split_pdf_dir}/split_2.pdf') as pdf:
#     page = pdf.pages[4]
#     print(page.width) 
#     # Try a bounding box
#     test_bbox = (1328, 0, page.width, page.height) # (left, top, right, bottom)
#     cropped = page.within_bbox(test_bbox)
#     print(cropped.extract_text())




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
  