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
from nltk.corpus import stopwords
from gensim import corpora
from gensim.models import LdaModel
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation
from datetime import datetime



# Download the VADER lexicon
nltk.download('vader_lexicon')

# Initialize the VADER sentiment analyzer
sia = SentimentIntensityAnalyzer()

# Download NLTK stopwords
nltk.download('stopwords')
# Initialize stopwords
stop_words = set(stopwords.words('english'))



# Get current user ID
userid = getpass.getuser()
if userid == "anyamarchenko":
    root = "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data"
elif userid == "maggie":
    root = "/Users/maggie/Brown Dropbox/Maggie Jiang/metoo_data"
elif userid == "jacobhirschhorn":
    root = "/Users/jacobhirschhorn/Brown Dropbox/Jacob Hirschhorn/metoo_data"

state = "IL"

# Directory containing the .txt files
txt_directory = root + "/raw/" + state + "/" + state + "_extracted"

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

# get the charge number from the inputted case document as a list of strings
def get_charge_no(text: str):
    charge_no = " "
    for line in text:
        # clean line
        lowercase = line.lower()
        lowercase = lowercase.replace("-","")
        no_spaces = lowercase.replace(" ","")
        # find the right line
        if "charge" in no_spaces:
            charge_ind = no_spaces.find("charge")
            line_end = no_spaces[charge_ind + 6:]
            charge_no_match = re.search(r'\d', line_end)
            charge_no_ind = charge_no_match.start() if charge_no_match else -1
            if charge_no_ind == -1:
                return " "
            else:
                # get the charge number
                charge_no = line_end[charge_no_ind:charge_no_ind+10]
                charge_no = charge_no.replace("\n","")
                return charge_no.upper()
    return charge_no
    

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
        # format it into a list
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


def create_csv_severity():
    # output csv
    sev_normalized_list = []
    # Charge number list
    charge_no_list = []
    year_list = []

    sentiment_analysis_list = []

    for filename in os.listdir(txt_directory):
        if filename.endswith(".txt"):
            txt_path = os.path.join(txt_directory, filename)

            head, tail = os.path.split(txt_path)
            

            # get the case date
            year = os.path.splitext(tail)[0].replace('"','')[-4:]
            # if the case is from before 2010, we don't want to do anything with it
            if int(year) >= 2010:
                # get the text of the file
                text, text_list = extract_text(txt_path)
                print("Processing", txt_path)
                # get the charge number from the text
                charge_no = get_charge_no(text_list)
                # format charge number properly
                charge_no = charge_no[:4] + "-" + charge_no[4:6] + "-" + charge_no[6:]
                if charge_no != " ":
                    charge_yr = charge_no[:4]
                    try:
                        if int(charge_yr) >= 2010:
                            # if there is a complainant and charge number after 2010, add to the list
                            charge_no_list.append(charge_no)
                            year_list.append(year)

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
                            sev_normalized_list.append(severity_ranking_normalized)

                            # get the severity ranking using sentiment analysis
                            polarity = sentiment_analysis(text)["compound"]
                            sentiment_analysis_list.append(polarity)
                        else:
                            print("pre-2010")
                    except ValueError:
                        print("invalid charge number")
            else:
                print("pre-2010")
    
    # get the manual severity ranking, normalizing so the fina number is between 0 and 1
    sev_ranking_list = novel_sev_ranking_list(sev_normalized_list)

    return_data = "Charge #,severity_manual,severity_sentiment\n"
    for ind in range(len(charge_no_list)):
        return_data +=  '"' + charge_no_list[ind] + '"' + "," + str(sev_ranking_list[ind]) + "," + str(sentiment_analysis_list[ind]) + "\n"

    return return_data


# combine the csvs
def combine_csvs(input_data):
    # Read the raw state CSV
    df1 = pd.read_csv(root + "/raw/" + state + "/il_raw_cases_gender.csv")
    
    # convert the return_data into a pandas dataframe
    # Use StringIO to convert the string to a file-like object
    csv_file = io.StringIO(input_data)
    # Read the CSV string into a DataFrame
    df2 = pd.read_csv(csv_file)

    # merge the dataframes on the common "Charge #" column
    merged_df = pd.merge(df1, df2, on='Charge #', how='left')
    # convert all non-Numpy NaN values to np NaN; will be replaced later with blank values
    merged_df = merged_df.replace(['NaN'], np.nan)

    # Save the merged data frame to a new CSV file
    output_path = root + "/raw/" + state + "/il_raw_cases_gender_severity.csv"

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


def preprocess_text(text: str):
    # Tokenize, remove stopwords, and return cleaned text
    return [word for word in nltk.word_tokenize(text.lower()) if word.isalnum() and word not in stop_words]


def topic_modeling():
    # Read the raw state CSV
    df_orig = pd.read_csv(root + "/raw/" + state + "/il_raw_cases_gender_severity.csv")
    # List of all the charge numbers in the original csv (to be used for preprocessing)
    charge_no_list = df_orig['Charge #'].tolist()
    basis_list = df_orig['Basis'].tolist()
    #
    file_date_list = df_orig['File Date'].dropna().tolist()
    file_date_list = [datetime.strptime(date, "%m/%d/%y") for date in file_date_list]

    documents = []
    metoo_date = datetime(2017, 10, 15)
    pre_metoo_documents = []
    post_metoo_documents = []
    charge_nos = []
    for filename in os.listdir(txt_directory):
        if filename.endswith('.txt'):
            txt_path = os.path.join(txt_directory, filename)
            # get the text of the file
            text, text_list = extract_text(txt_path)
            print("Processing", txt_path)
            # get the charge number from the text
            charge_no = get_charge_no(text_list)
            # format charge number properly
            charge_no = charge_no[:4] + "-" + charge_no[4:6] + "-" + charge_no[6:]
            charge_nos.append(charge_no)

            # Cut out all documents that aren't in the spreadsheet
            if charge_no in charge_no_list:
                # Cut out all documents that aren't sh cases
                charge_no_ind = charge_no_list.index(charge_no)
                basis = basis_list[charge_no_ind]
                file_date = file_date_list[charge_no_ind]
                try:
                    if "HAR" in basis:
                        documents.append(preprocess_text(text))
                        if file_date > metoo_date:
                            post_metoo_documents.append(preprocess_text(text))
                        else:
                            pre_metoo_documents.append(preprocess_text(text))
                except TypeError:
                    print("missing")



    # # LDA
    # # Create a dictionary and a corpus
    # dictionary = corpora.Dictionary(documents)
    # corpus = [dictionary.doc2bow(doc) for doc in documents]
    # # Set number of topics
    # num_topics = 3  # You can adjust this number
    # # Create LDA model
    # lda_model = LdaModel(corpus, num_topics=num_topics, id2word=dictionary, passes=50)
    # # Print the topics
    # print("\nLDA distribution")
    # for idx, topic in lda_model.print_topics(-1):
    #     print(f"Topic {idx}: {topic} \n")


    # LDA with further trimmed docs
    
    # words to keep - relevant to the topic of sexual harassment
    keep_words = ['inappropriate', 'behavior', 'lewd', 'comments', 'comment', 'unwelcome', 
                  'unwanted', 'attention', 'disrespect', 'catcall', 'contact',
                  'action', 'offensive', 'offensiveness', 'objectify', 'objectification',
                  'intimidate', 'intimidation', 'bully', 'bullying', 'verbal', 'abuse',
                  'hostile', 'enviornment', 'cyber', 'harassment', 'coercion', 'coerce',
                  'violate', 'violation', 'boundary', 'stalking', 'exploit', 
                  'exploitation', 'sexual', 'advance', 'advances', 'discriminate',
                  'retaliate', 'retaliation', 'misconduct', 'quid', 'pro', 'quo',
                  'predatory', 'predator', 'grope', 'groping', 'non-consensual',
                  'threat', 'invasion', 'invade', 'trauma', 'power', 'dynamic',
                  'survivor', 'victim', 'assault', 'rape', 'email', 'virtual',
                  'online', 'touch']
    
    # only keep the words we want
    docs = [[word for word in doc if word in keep_words] for doc in documents]
    pre_metoo_docs = [[word for word in doc if word in keep_words] for doc in pre_metoo_documents]
    post_metoo_docs = [[word for word in doc if word in keep_words] for doc in post_metoo_documents]
    
    # LDA models
    dictionary = corpora.Dictionary(docs)
    corpus = [dictionary.doc2bow(doc) for doc in docs]
    # Set number of topics
    num_topics = 3
    # Create LDA model
    lda_model1 = LdaModel(corpus, num_topics=num_topics, id2word=dictionary, passes=50)
    # Print the topics
    output = ""
    print("LDA distribution with trimmed docs")
    for idx, topic in lda_model1.print_topics(-1):
        print(f"Topic {idx}: {topic} \n")
        topic_list = topic.replace(" ","").split("+")
        topics = "".join(["," + topic for topic in topic_list])
        output += "group " + str(idx) + " overall" + str(topics) + "\n"
    output += " , \n"

    dictionary = corpora.Dictionary(pre_metoo_docs)
    corpus = [dictionary.doc2bow(doc) for doc in pre_metoo_docs]
    # Create LDA model
    lda_model2 = LdaModel(corpus, num_topics=num_topics, id2word=dictionary, passes=50)
    # Print the topics
    print("LDA distribution with trimmed docs - Pre MeToo")
    for idx, topic in lda_model2.print_topics(-1):
        print(f"Topic {idx}: {topic} \n")
        topic_list = topic.replace(" ","").split("+")
        topics = "".join(["," + topic for topic in topic_list])
        output += "group " + str(idx) + " pre" + str(topics) + "\n"
    output += " , \n"

    dictionary = corpora.Dictionary(post_metoo_docs)
    corpus = [dictionary.doc2bow(doc) for doc in post_metoo_docs]
    # Create LDA model
    lda_model3 = LdaModel(corpus, num_topics=num_topics, id2word=dictionary, passes=50)
    # Print the topics
    print("LDA distribution with trimmed docs - Post MeToo")
    for idx, topic in lda_model3.print_topics(-1):
        print(f"Topic {idx}: {topic} \n")
        topic_list = topic.replace(" ","").split("+")
        topics = "".join(["," + topic for topic in topic_list])
        output += "group " + str(idx) + " post" + str(topics) + "\n"
    output += " , \n , \n"

    # Output the results to a spreadsheet
    output_path = root + "/raw/" + state + "/il_lda_outputs.csv"
    # Write the CSV to a new file
    with open(output_path, "a") as output_file:
        output_file.write(output)


    


# create the severity rankings
# severity_data = create_csv_severity()

# add to the Illinois data
# combine_csvs(severity_data)

topic_modeling()