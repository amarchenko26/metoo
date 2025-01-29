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



with pdfplumber.open(f'{split_pdf_dir}/split_5.pdf') as pdf:
    page = pdf.pages[70]
    # Try a bounding box
    print(page.width, page.height)
    test_bbox = (1060, 0, 1328, page.height) # (left, top, right, bottom)
    cropped = page.within_bbox(test_bbox)
    print(cropped.extract_text())


with pdfplumber.open(f'{split_pdf_dir}/split_2.pdf') as pdf:
    page = pdf.pages[4]
    # Try a bounding box
    test_bbox = (1328, 0, page.width, page.height) # (left, top, right, bottom)
    cropped = page.within_bbox(test_bbox)
    print(cropped.extract_text())

with pdfplumber.open(f'{split_pdf_dir}/split_2.pdf') as pdf:
    page = pdf.pages[0]
    print("Number of lines found:", len(page.lines))
    for i, ln in enumerate(page.lines):
        print(i, ln)


import os
import re
import pandas as pd
import pdfplumber

def extract_tables_from_split_pdfs_dynamic(split_pdf_dir, output_csv_path):
    """
    Extract and parse PDF tables with proper alignment of basis/acts with metadata rows
    """
    def clean_text(text):
        return ' '.join(text.split())

    JURISDICTION_REGEX = re.compile(
        r'(.*?)(\S*mploy\w+|Hous\w+|Educ\w+|Public\sAccomm\w+)(.*)',
        re.IGNORECASE
    )
    SPECIAL_EXCEPTION_PATTERN = re.compile(
        r'(?i)Serve Order After Hearing:\s*Dismissing'
    )

    def parse_row(row_text):
        """
        Parse only the main metadata: Case ID, Dates, Case Name, Closing Acts, Jurisdiction.
        """
        row_text = clean_text(row_text)
        parsed_data = {
            "Case ID": "",
            "Date Filed": "",
            "Closing Date": "",
            "Case Name": "",
            "Closing Acts": "",
            "Jurisdiction": ""
        }

        # 1) Case ID
        m_id = re.search(r'^(\d{7,8})', row_text)
        if m_id:
            parsed_data["Case ID"] = m_id.group(1)

        # 2) Dates
        dates = re.findall(r'\d{2}/\d{2}/\d{4}', row_text)
        if len(dates) >= 1:
            parsed_data["Date Filed"] = dates[0]
        if len(dates) >= 2:
            parsed_data["Closing Date"] = dates[1]

            # Grab "Case Name" between date1 and date2
            date1_index = row_text.find(dates[0])
            date2_index = row_text.find(dates[1])
            if date1_index != -1 and date2_index != -1:
                end_of_date1 = date1_index + len(dates[0])
                case_name_sub = row_text[end_of_date1:date2_index]
                parsed_data["Case Name"] = case_name_sub.strip()

            # Remainder after second date => "Closing Acts" and "Jurisdiction"
            remainder_start = row_text.find(dates[1]) + len(dates[1])
            remainder = row_text[remainder_start:].strip()

            # Special exception
            if SPECIAL_EXCEPTION_PATTERN.search(remainder):
                jur_match = JURISDICTION_REGEX.search(remainder)
                if jur_match:
                    parsed_data["Closing Acts"] = jur_match.group(1).strip()
                    parsed_data["Jurisdiction"] = jur_match.group(2).strip()
                else:
                    parsed_data["Closing Acts"] = remainder
            else:
                # Normal path
                jur_match = JURISDICTION_REGEX.search(remainder)
                if jur_match:
                    parsed_data["Closing Acts"] = jur_match.group(1).strip()
                    parsed_data["Jurisdiction"] = jur_match.group(2).strip()
                else:
                    parsed_data["Closing Acts"] = remainder

        # Debug
        print("Parsed main row (no Basis/Acts here):")
        for k, v in parsed_data.items():
            print(f"  {k}: {v}")
        print("-"*80)

        return parsed_data

    def should_skip_row(line):
        """
        If line does NOT start with 7 or 8 digits, treat it as continuation.
        """
        return not re.match(r'^\d{7,8}', line.strip())

    # Bounding boxes
    BASIS_BBOX = (1060, 0, 1328, 612)  # (x0, y0, x1, y1) page.height = 612
    ACTS_BBOX  = (1328, 0, 2160, 612)  # (x0, y0, x1, y1) page.width = 2160

    def slice_rows_in_bbox(page, bbox):
        """
        Gather horizontal lines within 'bbox', sort them by y0 ascending,
        then slice from one line's y0 to the next line's y0.
        """
        (x0, y0, x1, y1) = bbox

        # 1) Gather lines that intersect this bbox
        lines_in_bbox = []
        for ln in page.lines:
            lx0, ly0, lx1, ly1 = ln["x0"], ln["y0"], ln["x1"], ln["y1"]
            # Check if it's essentially horizontal
            if abs(ly1 - ly0) < 1e-3:
                # Check if line is within vertical range
                if ly0 >= y0 and ly0 <= y1:
                    # Check horizontal overlap
                    if not (lx1 < x0 or lx0 > x1):
                        lines_in_bbox.append(ln)

        # Sort lines by y0 ascending
        lines_in_bbox.sort(key=lambda l: l["y0"])

        all_rows = []
        current_bottom = y0

        # 2) Slice row by row
        for i, ln in enumerate(lines_in_bbox, start=1):
            line_y = ln["y0"]
            if line_y > current_bottom:
                print(f"[DEBUG] Row slice {i}: from y={current_bottom} up to y={line_y}")
                row_crop = page.within_bbox((x0, current_bottom, x1, line_y))
                extracted = (row_crop.extract_text() or "").strip()
                print(" -> Extracted text:\n", extracted)
                print("-" * 40)
                if extracted:
                    all_rows.append(extracted)
                current_bottom = line_y

        # After the last line, slice up to the top of bbox
        if current_bottom < y1:
            print(f"[DEBUG] Final row slice from y={current_bottom} up to y={y1}")
            row_crop = page.within_bbox((x0, current_bottom, x1, y1))
            extracted = (row_crop.extract_text() or "").strip()
            print(" -> Extracted text:\n", extracted)
            print("=" * 40)
            if extracted:
                all_rows.append(extracted)

        return all_rows

    # Main processing
    metadata_rows = []
    current_page_metadata = []
    current_page_basis = []
    current_page_acts = []

    split_pdf_files = sorted(
        [f for f in os.listdir(split_pdf_dir) if f.lower().endswith('.pdf')]
    )

    for split_pdf_file in split_pdf_files:
        pdf_path = os.path.join(split_pdf_dir, split_pdf_file)
        print(f"Processing file: {split_pdf_file}")
        
        with pdfplumber.open(pdf_path) as pdf:
            for page_index, page in enumerate(pdf.pages, start=1):
                print(f"\n--- PAGE {page_index} ---")
                
                # Reset page-specific trackers
                current_page_metadata = []
                current_page_basis = []
                current_page_acts = []

                # 1) Extract metadata rows for this page
                full_text = page.extract_text() or ""
                current_row = ""
                for line in full_text.split('\n'):
                    line = line.strip()
                    if should_skip_row(line):
                        current_row += " " + line
                    else:
                        if current_row.strip():
                            parsed = parse_row(current_row)
                            if parsed["Case ID"]:  # Only add rows with valid Case IDs
                                current_page_metadata.append(parsed)
                        current_row = line
                
                # Handle last row of page
                if current_row.strip():
                    parsed = parse_row(current_row)
                    if parsed["Case ID"]:
                        current_page_metadata.append(parsed)

                # 2) Extract basis rows for this page
                basis_rows = [row.strip() for row in slice_rows_in_bbox(page, BASIS_BBOX) if row.strip()]
                # Remove empty rows and normalize whitespace
                current_page_basis = [row for row in basis_rows if row]

                # 3) Extract acts rows for this page
                acts_rows = [row.strip() for row in slice_rows_in_bbox(page, ACTS_BBOX) if row.strip()]
                # Remove empty rows and normalize whitespace
                current_page_acts = [row for row in acts_rows if row]

                # 4) Align and merge the rows for this page
                num_valid_rows = len(current_page_metadata)
                
                # Debug output for row counts
                print(f"\nPage {page_index} row counts before alignment:")
                print(f"Metadata rows: {len(current_page_metadata)}")
                print(f"Basis rows: {len(current_page_basis)}")
                print(f"Acts rows: {len(current_page_acts)}")

                # Trim or pad basis/acts to match number of metadata rows
                current_page_basis = (current_page_basis[:num_valid_rows] + 
                                    [""] * (num_valid_rows - len(current_page_basis)))
                current_page_acts = (current_page_acts[:num_valid_rows] + 
                                   [""] * (num_valid_rows - len(current_page_acts)))

                # Merge the aligned rows
                for i in range(num_valid_rows):
                    merged = current_page_metadata[i].copy()
                    merged["Basis"] = current_page_basis[i] if i < len(current_page_basis) else ""
                    merged["Acts"] = current_page_acts[i] if i < len(current_page_acts) else ""
                    
                    # Debug output for merged row
                    print(f"\nMerged row {i+1}:")
                    print(f"Case ID: {merged['Case ID']}")
                    print(f"Basis: {merged['Basis']}")
                    print(f"Acts: {merged['Acts']}")
                    
                    metadata_rows.append(merged)

    # Save to CSV
    df = pd.DataFrame(metadata_rows)
    if not df.empty:
        df.to_csv(output_csv_path, index=False)
        print(f"\nData extracted and saved to {output_csv_path}")
        print(f"Total rows processed: {len(metadata_rows)}")
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
  