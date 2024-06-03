#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue May 28 10:45:02 2024

@author: anyamarchenko
"""

import os
import getpass
import fitz  # PyMuPDF
import pytesseract
from PIL import Image
import io

# Get current user ID
userid = getpass.getuser()
if userid == "anyamarchenko":
    root = "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data"
elif userid == "maggie":
    root = "/Users/maggie/Dropbox (Brown)/metoo_data"
elif userid == "jacobhirschhorn":
    root = "/Users/jacobhirschhorn/Dropbox (Brown)/metoo_data"

# Directory containing the PDFs
pdf_directory = root + "/raw/PA/PA_PDFs"

# Directory to save the extracted text files
output_directory = root + "/raw/PA/PA_extracted"

# type "which tesseract" into command line to get path for tesseract install
pytesseract.pytesseract.tesseract_cmd = r'/opt/homebrew/bin/tesseract'

# Function to perform OCR on a PDF and save the text to a file
def ocr_pdf_to_text(pdf_path, output_path):
    # Open the PDF file
    pdf_document = fitz.open(pdf_path)
    text_content = ""

    # Iterate through each page in the PDF
    for page_num in range(pdf_document.page_count):
        page = pdf_document.load_page(page_num)
        pix = page.get_pixmap()
        
        # Convert pixmap to PIL image
        img = Image.open(io.BytesIO(pix.tobytes()))

        # Perform OCR on the image
        text = pytesseract.image_to_string(img)
        text_content += text + "\n"

    # Save the extracted text to a file
    with open(output_path, "w", encoding="utf-8") as text_file:
        text_file.write(text_content)


# Iterate through each PDF file in the directory
for filename in os.listdir(pdf_directory):
    if filename.endswith(".pdf"):
        pdf_path = os.path.join(pdf_directory, filename)
        output_path = os.path.join(output_directory, f"{os.path.splitext(filename)[0]}.txt")
        
        # Perform OCR on the PDF and save the text
        print("Processing", pdf_path)
        ocr_pdf_to_text(pdf_path, output_path)

print("OCR process completed for all PDFs.")

