"""
Created on Sun Jul 28 19:07:50 2024

@author: jacobhirschhorn
"""

import getpass
import requests
from bs4 import BeautifulSoup
import certifi
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import time

# Set up the WebDriver using Chrome
service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service)



userid = getpass.getuser()
if userid == "anyamarchenko":
    root = "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data"
elif userid == "maggie":
    root = "/Users/maggie/Dropbox (Brown)/metoo_data"
elif userid == "jacobhirschhorn":
    root = "/Users/jacobhirschhorn/Dropbox (Brown)/metoo_data"

headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }

# Get the BeautifulSoup lxml version of a website page given a link, used in get_mi_pdfs
def get_site(link : str) -> BeautifulSoup:
    # Fetch the webpage
    response = requests.get(link, headers=headers)
    response.raise_for_status()  # Raises HTTPError for bad responses (4xx and 5xx)
    html_content = response.text
    soup = BeautifulSoup(html_content, 'lxml')
    return soup

# error codes if the pdf fails to download or be accessed
error_codes = []
# Download all pdfs from a list of pdfs, given a list of pdfs for a state
def download_pdfs(link_list : list[tuple[str, str]], state : str):
    # Download all pdfs
    for pdf_tuple_ind in range(len(link_list)):
        print(link_list[pdf_tuple_ind])
        if state == "MI":
            response = requests.get(link_list[pdf_tuple_ind][0], headers=headers)
        if state == "IL":
            response = requests.get(link_list[pdf_tuple_ind][0], headers=headers)
        if state == "AK":
            response = requests.get(link_list[pdf_tuple_ind][0], headers=headers, verify=False)
        # Check if the request was successful
        if response.status_code == 200:
            # Open a file in binary write mode
            with open(root + '/raw/' + state + '/' + state + '_PDFs/' + link_list[pdf_tuple_ind][1] + '.pdf', 'wb') as file:
                # Write the content of the response to the file
                file.write(response.content)
            print("PDF downloaded successfully.")
        else:
            print(f"Failed to download PDF, status code: {response.status_code}")
            error_codes.append((link_list[pdf_tuple_ind][0], response.status_code))


# Download Michigan PDFs
def get_mi_pdfs():
    mi_soup = get_site('https://www.michigan.gov/mdcr/commission/documents/decisions')
    section = mi_soup.find('div', class_='accordion-file-list__link-section')
    if section:
        # link_list conatins a list of tuples: (link, text)
        mi_link_list = []
        # Extract all links
        links = section.find_all('a')
        for link in links:
            href = link.get('href')
            text = link.text
            text = str(text).replace("\r\n                            ", "")
            text = text.replace("    Download\n", "")
            text = text.replace("            ", "")
            if "v." in text:
                mi_link_list.append((f"https://www.michigan.gov/{href}", text))

        download_pdfs(mi_link_list, "MI")
    else:
        print("Section not found")

# Download Alaska PDFs
def get_ak_pdfs():
    link_start = 'https://humanrights.alaska.gov/public-hearing-cases/decisions/?frm-page-158='
    
    for i in range(1,16):
        # get the proper page
        driver.get(link_start + str(i))
        # Extract page content with BeautifulSoup
        html = driver.page_source
        ak_soup = BeautifulSoup(html, 'html.parser')

        ak_link_list = []
        # get the links
        table = ak_soup.find('div', class_='member-detail')
        
        headers = table.find_all('h3')
        cases = table.find_all('ul')
        assert(len(headers) == len(cases))
        for i in range(len(headers)):
            # get the name of the case
            name = headers[i].text.replace("/","-")
            # ge the link to the decision
            dec_link = headers[i].find_all('a')
            dec_href = dec_link[0].get('href')
            dec_text = name + " Decision"
            # get the link to the case document
            items = cases[i].find_all('li')
            link_home = items[-1]
            link = link_home.find_all('a')
            case_href = link[0].get('href')
            case_text = name + " Case"

            ak_link_list.append((dec_href, dec_text))
            ak_link_list.append((case_href, case_text))
    
        download_pdfs(ak_link_list, "AK")

# Download Illinois PDFs
def get_il_pdfs():
    link_start = 'https://hrc.illinois.gov/decision.html'
    # use the webdriver to ge tthe webpage
    driver.get(link_start)

    for i in range(526):
        # Wait for the page to load
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "DataTables_Table_0"))
        )
        # Extract page content with BeautifulSoup
        html = driver.page_source
        il_soup = BeautifulSoup(html, 'html.parser')

        # find the data table
        data_table = il_soup.find('table', id='DataTables_Table_0')
        il_link_list = []

        if data_table:
            # Find all rows in the table body
            rows = data_table.find('tbody').find_all('tr')
            # Iterate through each row
            for row in rows:
                # Extract columns (cells) in each row
                cols = row.find_all('td')
                # Find the link in the first column
                links = cols[0].find_all('a')
                for link in links:
                    # Get the link and name of the case
                    href = link.get('href')
                    text = link.text.replace("/","-")
                    date = cols[3].text.replace("/","")
                    text += " " + date
                    il_link_list.append((f"https://hrc.illinois.gov{href}", text))

        download_pdfs(il_link_list, "IL")

        # Go to the next page
        if not go_to_next_page(driver):
            break

# Helper function to click "Next" and load the next page, used in get_il_pdfs
def go_to_next_page(driver):
    try:
        # Make sure the "next" button has loaded
        next_button = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.CLASS_NAME, "paginate_button.next"))
        )
        # Click on the "next" button
        next_button.click()
        return True
    except Exception as e:
        print("No more pages or an error occurred:", e)
        return False





# get_mi_pdfs()
# get_ak_pdfs()
# get_il_pdfs()
