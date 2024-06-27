import os
import getpass
import io
import re
from rapidfuzz import process, fuzz
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer


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


state = "PA"

# Directory containing the .txt files
txt_directory = root + "/raw/" + state + "/" + state + "_extracted"


def extract_text(input_path : str) -> str:
    with open(input_path, "r") as text_file:
        file = text_file.readlines()
        
        file = [element for element in file if element != "\n"]
             
        for i in range(len(file)):
            file[i] = file[i].replace('‘', "'")
            file[i] = file[i].replace('’', "'")
            file[i] = file[i].replace("£", "E")
            if file[i][0] == "'":
                file[i] = file[i].replace("'", '')

        file_str = "\n".join(file)

    file_str = file_str.replace("\n", "")

    return file_str


def txt_to_severity_list(text : str) -> tuple[list, int]:
    # Get the total number of words in the document
    total_words = text.split()

    # List of relevant words in ascending order of severity
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
def novel_sev_ranking_list(ranking_list : list, name_list: list):
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



# output csv
sev_normalized_list = []
name_list = []
sentiment_analysis_list = []

for filename in os.listdir(txt_directory):
    if filename.endswith(".txt"):
        txt_path = os.path.join(txt_directory, filename)

        # Get the CSV data from the txt
        print("Processing", txt_path)

        head, tail = os.path.split(txt_path)

        if not ("RICHR Response to APRA Request" in tail):
            # get the text of the file
            text = extract_text(txt_path)
            # get the severity ranking using novel 
            sev_list, total_txt_words = txt_to_severity_list(text)
            sev_number, total_matches = get_sev_ranking(sev_list)
            # If there is one or more match
            if total_matches != 0:
                # calculate the severity two ways
                # 1. normalized by the number of words in the txt file and by the number of matches found
                severity_ranking_normalized = (sev_number / total_matches) / total_txt_words
            # if zero matches, set the severity score to 0
            else:
                severity_ranking_normalized = 0
            name_list.append(tail)
            sev_normalized_list.append(severity_ranking_normalized)

            # get the severity ranking using sentiment analysis
            polarity = sentiment_analysis(text)["compound"]
            sentiment_analysis_list.append(polarity)

# get the novel severity ranking
sev_ranking_list = novel_sev_ranking_list(sev_normalized_list, name_list)


# combine all parts together
csv_format_list = ["name,severity_1,severity_2\n"]
for num in range(len(sev_ranking_list)):
    row = '"' + name_list[num] + '"' + "," + sev_ranking_list[num] + "," + str(sentiment_analysis_list[num]) + "\n"
    csv_format_list.append(row)


# join into a string
return_csv = "".join(csv_format_list)


output_path = "/Users/" + userid + "/Desktop/" + state + "_sevrankings.csv"

# # Write the CSV to a new file
with open(output_path, "w") as text_file:
        text_file.write(return_csv)


