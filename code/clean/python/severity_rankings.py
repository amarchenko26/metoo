import os
import getpass
import io
import re
from rapidfuzz import process, fuzz
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer
import pandas as pd
import pyreadstat
import numpy as np


# Get current user ID
userid = getpass.getuser()
if userid == "anyamarchenko":
    root = "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data"
elif userid == "maggie":
    root = "/Users/maggie/Dropbox (Brown)/metoo_data"
elif userid == "jacobhirschhorn":
    root = "/Users/jacobhirschhorn/Dropbox (Brown)/metoo_data"

# Download the VADER lexicon
nltk.download('vader_lexicon')

# Initialize the VADER sentiment analyzer
sia = SentimentIntensityAnalyzer()




# Extract the text from the text file
def extract_text(input_path : str) -> tuple[str, list[str]]:
    with open(input_path, "r") as text_file:
        file = text_file.readlines()
        
        file = [element for element in file if element != "\n"]
        # Do some light cleaning of the text file
        for i in range(len(file)):
            file[i] = file[i].replace('‘', "'")
            file[i] = file[i].replace('’', "'")
            file[i] = file[i].replace("£", "E")
            file[i] = file[i].replace("€", "E")
            if file[i][0] == "'":
                file[i] = file[i].replace("'", '')

        file_str = "\n".join(file)

    file_str = file_str.replace("\n", "")

    return file_str, file

# Get the case ID for RI files
def get_RI_case_id(file : list[str]):
    case_id = ""
    for line in file:
        # Get the right line
        if line[:4] == "RICH":
            split_line = line.split()
            # Find the ID within that line
            for i in range(len(split_line)):
                numbers = r'[0-9]'
                if re.search(numbers, split_line[i][0]):
                    case_id += split_line[i]
                    if re.search(numbers, split_line[i+1][0]):
                        case_id += split_line[i+1]
                    elif re.search(numbers, split_line[i+2][0]):
                        case_id += split_line[i+1]
                        case_id += split_line[i+2]
                    # Remove any commas
                    case_id = case_id.replace(',', '')
                    break
    return case_id

# Get the respondent for PA files
def get_PA_resp_org(tail: str):
    resp_org = '"'
    tail = tail.replace(".txt", "")
    split_tail = tail.split()
    trigger = 0
    for word in split_tail:
        if trigger == 1:
            resp_org += word
            resp_org += " "
        if word == "v":
            trigger = 1
    resp_org = resp_org[:-1] + '"'

    # Ensure all cases have the right resp_org
    if trigger == 0:
        resp_org = '"Joe Darrah, Inc. d/b/a J & K Salvage"'
    if resp_org == '"Hertzler Pt 1"':
        resp_org = '"Hertzler"'
    elif resp_org == '"Slippery Rock State College Pt 1"' or resp_org == '"Slippery Rock State College Pt 2"':
        resp_org = '"Slippery Rock State College"'
    
    return resp_org

# Extract severity rankings from the text file
def txt_to_severity_list(text : str) -> tuple[list, int]:
    # Get the total number of words in the document
    total_words = text.split()

    # List of sexual harassment-related words in ascending order of severity
    word_list = ["Inappropriate behavior", "Lewd comments", "Unwelcome behavior",
                "Unwanted attention", "Disrespect", "Catcalling", 
                "Unwanted contact", "Legal action",
                "Offensiveness", "Objectification", "Intimidation", "Bullying",
                "Verbal abuse", "Hostile work environment", "Cyber harassment",
                "Harassment", "Coercion", "Boundary violation", "Stalking",
                "Exploitation", "Sexual advances", "Discrimination",
                "Retaliation", "Misconduct", "Sexual misconduct", "Quid pro quo",
                "Predatory behavior", "Groping", "Non-consensual",
                "Sexual exploitation", "Threats", "Invasion of privacy", "Trauma",
                "Power dynamics", "Survivor", "Victimization", "Harasser", 
                "Human rights", "Workplace harassment", "Sexual harassment", 
                "Gender-based violence", "Sexual violence", 
                "Abuse", "Sexual abuse", "Sexual assault", "Assault", "Rape"]
    

    match_list = []
    for i in range(len(word_list)):
        word = word_list[i]
        word_to_find = word

        # Set threshold - what constitutes a match in the fuzzy match scheme
        threshold = 75

        # Find out how many words are in the token being checked
        severity_word_tokens = word.split()
        severity_word_len = len(severity_word_tokens)

        # Get a list of n-length segments of the text, where n is the length of the word being checked
        txt_ngrams = generate_ngrams(text, severity_word_len)

        # Search for the word in the document
        matches = process.extract(word_to_find, txt_ngrams, scorer=fuzz.ratio, limit=None)

        # Filter matches based on the threshold
        probable_matches = [match for match in matches if match[1] >= threshold]

        # 3-tuple of the word, its ranking, and the amount of that word in the text
        match_tuple = (word, i+1, len(probable_matches))
        match_list.append(match_tuple)
        i += 1
    
    return match_list, len(total_words)


# Create the n-gram representation of the document
def generate_ngrams(text, n):
    words = text.split()
    ngrams = [' '.join(words[i:i + n]) for i in range(len(words) - n + 1)]
    return ngrams

# calculate severity score for all txt files
def get_sev_ranking(match_list) -> tuple[float, float]:
    severity_ranking = 0
    total_ranking_words = 0
    for item in match_list:
        severity_ranking += item[1]*item[2]
        total_ranking_words += item[2]
    
    return severity_ranking, total_ranking_words

# normalize severity score
def novel_sev_ranking_list(ranking_list : list):
    return_list = []
    max_num = max(ranking_list)
    # for each case
    for ind in range(len(ranking_list)):
        # get the severity ranking for that case
        num = ranking_list[ind] / max_num
        # format it into a csv row
        sev = str(num)
        return_list.append(sev)
    return return_list


# VADER sentiment analysis
# On a scale of [1, -1] - larger values in either direction are more severe/intense
# Positive values are positive sentiment, negative values are negative sentiment
def sentiment_analysis(text : str):
    # Get sentiment scores
    sentiment = sia.polarity_scores(text)
    return sentiment


# Create the severity rankings, based on what state is passed in
def create_csv_severity(state : str):
    # Directory containing the .txt files
    txt_directory = root + "/raw/" + state + "/" + state + "_extracted"

    # output csv
    sev_normalized_list = []
    # ID list - file_date for RI, respondent for PA
    id_list = []
    name_list = []
    sentiment_analysis_list = []

    PA_extras = ["Goetz v Norristown Area School District", "PHRC", "Henley v CWOPA SCSC", 
                "Jones v City of Philadelphia et al", "Lee & Yokely v Walnut Garden Apartments Inc",
                 "Brown v Hertzlert Pt 2"]
    RI_extras = ["WASHINGTON DAMAGES", "JOBE DAMAGES", "ZABALA CORRECTION"]
    combined_extras = PA_extras + RI_extras

    for filename in os.listdir(txt_directory):
        if filename.endswith(".txt"):
            txt_path = os.path.join(txt_directory, filename)

            head, tail = os.path.split(txt_path)

            marker = 0
            if ("RICHR Response to APRA Request" in tail) or ("pa_raw_cases" in tail):
                marker = 1
            for case in combined_extras:
                if (case in tail):
                    marker = 1

            if marker != 1:
                # Get the CSV data from the txt
                print("Processing", txt_path)
                # get the text of the file
                text, text_list = extract_text(txt_path)

                # If state is RI, get the case ID
                if state == "RI":
                    file_date = get_RI_case_id(text_list)
                    id_list.append(file_date)
                # Else if state is PA, get the respondent
                elif state == "PA":
                    resp_org = get_PA_resp_org(tail)
                    id_list.append(resp_org)


                # get the severity ranking using novel 
                sev_list, total_txt_words = txt_to_severity_list(text)
                sev_number, total_matches = get_sev_ranking(sev_list)
                # If there is one or more match
                if total_matches != 0:
                    # calculate severity
                    # normalized by the number of words in the txt file and by the number of matches found
                    severity_ranking_normalized = (sev_number / total_matches)
                # if zero matches, set the severity score to 0
                else:
                    severity_ranking_normalized = 0
                name_list.append(tail)
                sev_normalized_list.append(severity_ranking_normalized)

                # get the severity ranking using sentiment analysis
                polarity = sentiment_analysis(text)["compound"]
                sentiment_analysis_list.append(polarity)

    # get the manual severity ranking
    sev_ranking_list = novel_sev_ranking_list(sev_normalized_list)


    # combine all parts together
    if state == "RI":
        csv_format_list = ["case_id,severity_manual,severity_sentiment\n"]
    elif state == "PA":
        csv_format_list = ["ind,severity_manual,severity_sentiment\n"]


    for num in range(len(sev_ranking_list)):
        if state == "RI":
            row = id_list[num] + "," + str(sev_ranking_list[num]) + "," + str(sentiment_analysis_list[num]) + "\n"
        elif state == "PA":
            row = str(num) + "," + str(sev_ranking_list[num]) + "," + str(sentiment_analysis_list[num]) + "\n"

        csv_format_list.append(row)



    # join into a string
    return_data = "".join(csv_format_list)
    
    # combine the data with the raw CSV file

    # Read the raw state CSV
    df1 = pd.read_csv(root + "/raw/" + state + "/" + state + "_raw_cases.csv")

    # convert the return_data into a pandas dataframe
    # Use StringIO to convert the string to a file-like object
    csv_file = io.StringIO(return_data)

    # Read the CSV string into a DataFrame
    df2 = pd.read_csv(csv_file)

    # Merge the data frames on a common column: id for RI, resp_org for PA
    if state == "RI":
        merged_df = pd.merge(df1, df2, on='case_id', how='left')
    elif state == "PA":
        merged_df = pd.merge(df1, df2, on='ind', how='left')

    # convert all non-Numpy NaN values to np NaN; will be replaced later with blank values
    merged_df = merged_df.replace(['NaN'], np.nan)


    # Save the merged data frame to a new CSV file
    output_path = root + "/raw/" + state + "/" + state + "_raw_cases_severity.csv"

    merged_df.to_csv(output_path, 
                     index=False,        # Do not write row names (index)
                     header=True,        # Write out the column names
                     na_rep='NA',        # Missing data representation
    )

    # convert all NA values into missing values
    with open(output_path, "r") as csv_file:
        severity_file = csv_file.read()
        severity_file = severity_file.replace("NA","")

    # Write the CSV to a new file
    with open(output_path, "w") as text_file:
            text_file.write(severity_file)



create_csv_severity("PA")
create_csv_severity("RI")