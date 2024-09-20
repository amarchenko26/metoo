import os
from pathlib import Path
import glob
import getpass
import spacy
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm 
from collections import Counter
import nltk
from nltk.util import ngrams

'''
1. Remove filler and stop words. Stem words. Use spacy or nltk.
2. Create a list of 200 most frequent words. Perhaps look at bigrams or trigrams. Perhaps remove words that appear too frequently. Manually inspect list of 200 words, perhaps remove top 50 if they don't have anything to do with SH.
2b. Make Word cloud  
3. Ask Chat GPT to group words into topics. Create 4-5 big groups. 
4. Calculate frequency of each group in each document normalized by the length of the document.
5. Can do sentiment analysis on each group -- take each sentence that has each word, calculate the sentiment of that sentence. a "rolling window" around each word.
'''

# Load NLTK dependencies
nltk.download('punkt')

# Load the small English language model in spaCy with lemmatization
nlp = spacy.load("en_core_web_sm")

# Extract the text from the text file, returning only the cleaned single string
def extract_text(input_path: str) -> str:
    '''Extract text from a .txt file and clean it.'''
    try:
        with open(input_path, "r", encoding="utf-8", errors="replace") as text_file:
            file = text_file.readlines()
            file = [element for element in file if element.strip()]  # removes empty lines
            # Do some light cleaning of the text file
            for i in range(len(file)):
                file[i] = file[i].replace('‘', "'").replace('’', "'").replace("£", "E").replace("€", "E")
                if file[i].startswith("'"):
                    file[i] = file[i].replace("'", '')
            file_str = "".join(file).replace("\n", "")
        return file_str
    except Exception as e:
        print(f"Error reading {input_path}: {e}")
        return ""

def remove_fillers_stopwords(text):
    '''Remove filler, stop words, and lemmatize words using spaCy.'''
    try:
        doc = nlp(text)
        # Lemmatize words and remove stop words and punctuation
        filtered_tokens = [
            token.lemma_.lower() for token in doc 
            if not token.is_stop and not token.is_punct
        ]
        # Join filtered tokens back into a string
        filtered_text = " ".join(filtered_tokens)
        return filtered_text
    except Exception as e:
        print(f"Error cleaning text: {e}")
        return ""

def process_file(txt_path):
    """Function to process a single file."""
    text = extract_text(txt_path)
    filtered_text = remove_fillers_stopwords(text)
    
    # Filter only texts that contain the word "sex"
    if "sex" in filtered_text:
        filename = os.path.basename(txt_path)
        return filename, filtered_text
    return None, None  # Return None for texts that don't contain "sex"

if __name__ == "__main__":
    # Load spaCy model
    nlp = spacy.load("en_core_web_sm")
    
    # Get all .txt files in the directory
    txt_files = glob.glob(str(txt_directory / "*.txt"))

    clean_texts = {}

    # Initialize tqdm progress bar with the total number of text files
    with tqdm(total=len(txt_files), desc="Processing texts", unit="file") as pbar:
        with ThreadPoolExecutor(max_workers=4) as executor:  # Use threads instead of processes
            futures = {executor.submit(process_file, txt_path): txt_path for txt_path in txt_files}
            
            for future in as_completed(futures):
                txt_path = futures[future]
                try:
                    filename, filtered_text = future.result()
                    if filename:
                        clean_texts[filename] = filtered_text
                except Exception as e:
                    print(f"Error processing file {txt_path}: {e}")
                
                # Update the progress bar for each completed file
                pbar.update(1)

    # Now only analyze the texts that contain the word "sex"
    all_words = []
    for text in clean_texts.values():
        all_words.extend(text.split())

    # Count word frequencies (for unigrams)
    word_freq = Counter(all_words)
    top_200_words = word_freq.most_common(200)

    # Print the top 200 most common words
    print("\nTop 200 Most Frequent Words:")
    for word, freq in top_200_words:
        print(f"{word}: {freq}")

    # Perform bigram and trigram analysis
    def get_ngrams(texts, n):
        all_ngrams = []
        for text in texts:
            tokens = nltk.word_tokenize(text)
            ngrams_list = list(ngrams(tokens, n))
            all_ngrams.extend(ngrams_list)
        return all_ngrams

    # Get bigrams and trigrams
    bigrams = get_ngrams(clean_texts.values(), 2)
    trigrams = get_ngrams(clean_texts.values(), 3)

    # Count the frequency of bigrams and trigrams
    bigram_freq = Counter(bigrams)
    trigram_freq = Counter(trigrams)

    # Get the top 50 bigrams and trigrams
    top_50_bigrams = bigram_freq.most_common(1000)
    top_50_trigrams = trigram_freq.most_common(1000)

    # Print the top 50 bigrams
    print("\nTop 50 Most Frequent Bigrams:")
    for bigram, freq in top_50_bigrams:
        print(f"{bigram}: {freq}")

    # Print the top 50 trigrams
    print("\nTop 50 Most Frequent Trigrams:")
    for trigram, freq in top_50_trigrams:
        print(f"{trigram}: {freq}")


from collections import defaultdict
from fuzzywuzzy import process, fuzz

# Create the n-gram representation of the document
def generate_ngrams(text, n):
    words = text.split()
    ngrams = [' '.join(words[i:i + n]) for i in range(len(words) - n + 1)]
    return ngrams

# Extract severity rankings from the text file
def txt_to_severity_list(text: str) -> tuple[list, int]:
    # Get the total number of words in the document
    total_words = len(text.split())

    # List of sexual harassment-related words in ascending order of severity
    word_list = [
        # Mild Severity
        "Inappropriate behavior", "Lewd comments", "Unwelcome behavior", 
        "Unwanted attention", "Disrespect", "Catcalling", 
        "Unwanted jokes", "Unprofessional conduct",

        # Moderate Severity
        "Unwanted contact", "Offensive language", "Objectification", 
        "Intimidation", "Bullying", "Verbal abuse", 
        "Hostile work environment", "Unsolicited advances", 
        "Cyber harassment", "Uncomfortable touching", 
        "Derogatory remarks", "Invasion of space",

        # High Severity
        "Harassment", "Coercion", "Boundary violation", "Stalking", 
        "Exploitation", "Sexual advances", "Discrimination", 
        "Retaliation", "Misconduct", "Quid pro quo", 
        "Predatory behavior",

        # Severe/Criminal Severity
        "Groping", "Non-consensual", "Sexual exploitation", 
        "Threats", "Invasion of privacy", "Power dynamics", 
        "Trauma", "Victimization", "Harasser", "Sexual misconduct",

        # Extreme Severity (Criminal acts)
        "Sexual harassment", "Workplace harassment", 
        "Gender-based violence", "Sexual violence", 
        "Abuse", "Sexual abuse", "Sexual assault", 
        "Assault", "Rape"
    ]
    
    match_list = []
    
    # Iterate through the list of sexual harassment-related words
    for i, word in enumerate(word_list):
        word_to_find = word.lower()
        severity_word_tokens = word_to_find.split()
        severity_word_len = len(severity_word_tokens)
        
        # Create n-grams from the text to match the length of the word
        txt_ngrams = generate_ngrams(text.lower(), severity_word_len)
        
        # Fuzzy match the word against n-grams in the text
        matches = process.extract(word_to_find, txt_ngrams, scorer=fuzz.ratio, limit=None)
        
        # Set a threshold to filter fuzzy matches
        threshold = 75
        probable_matches = [match for match in matches if match[1] >= threshold]

        # Store the word, severity ranking (i+1), and number of matches
        match_tuple = (word, i+1, len(probable_matches))
        match_list.append(match_tuple)
    
    return match_list, total_words

# Now, apply the function to each document in clean_texts
severity_results = {}

for filename, text in clean_texts.items():
    matches, total_words = txt_to_severity_list(text)
    severity_results[filename] = {
        'matches': matches,
        'total_words': total_words
    }

# Example of how to print the severity results for each file
for filename, result in severity_results.items():
    print(f"File: {filename}")
    print(f"Total Words: {result['total_words']}")
    print("Severity Matches:")
    for match in result['matches']:
        word, severity_level, count = match
        if count > 0:
            print(f"  {word} (Severity Level {severity_level}): {count} occurrence(s)")
    print("\n")






# # get the charge number from the inputted case document as a list of strings
# def get_charge_no(text: str):
#     charge_no = " "
#     for line in text:
#         # clean line
#         lowercase = line.lower()
#         lowercase = lowercase.replace("-","")
#         no_spaces = lowercase.replace(" ","")
#         # find the right line
#         if "charge" in no_spaces:
#             charge_ind = no_spaces.find("charge")
#             line_end = no_spaces[charge_ind + 6:]
#             charge_no_match = re.search(r'\d', line_end)
#             charge_no_ind = charge_no_match.start() if charge_no_match else -1
#             if charge_no_ind == -1:
#                 return " "
#             else:
#                 # get the charge number
#                 charge_no = line_end[charge_no_ind:charge_no_ind+10]
#                 charge_no = charge_no.replace("\n","")
#                 return charge_no.upper()
#     return charge_no
    

# # Extract severity rankings from the text file
# def txt_to_severity_list(text : str) -> tuple[list, int]:
#     # Get the total number of words in the document
#     total_words = text.split()

#     # List of sexual harassment-related words in ascending order of severity
#     word_list = ["Inappropriate behavior", "Lewd comments", "Unwelcome behavior",
#                 "Unwanted attention", "Disrespect", "Catcalling", 
#                 "Unwanted contact", "Legal action",
#                 "Offensiveness", "Objectification", "Intimidation", "Bullying",
#                 "Verbal abuse", "Hostile work environment", "Cyber harassment",
#                 "Harassment", "Coercion", "Boundary violation", "Stalking",
#                 "Exploitation", "Sexual advances", "Discrimination",
#                 "Retaliation", "Misconduct", "Sexual misconduct", "Quid pro quo",
#                 "Predatory behavior", "Groping", "Non-consensual",
#                 "Sexual exploitation", "Threats", "Invasion of privacy", "Trauma",
#                 "Power dynamics", "Survivor", "Victimization", "Harasser", 
#                 "Human rights", "Workplace harassment", "Sexual harassment", 
#                 "Gender-based violence", "Sexual violence", 
#                 "Abuse", "Sexual abuse", "Sexual assault", "Assault", "Rape"]
    
#     match_list = []
#     for i in range(len(word_list)):
#         word = word_list[i]
#         word_to_find = word

#         # Set threshold - what constitutes a match in the fuzzy match scheme
#         threshold = 75

#         # Find out how many words are in the token being checked
#         severity_word_tokens = word.split()
#         severity_word_len = len(severity_word_tokens)

#         # Get a list of n-length segments of the text, where n is the length of the word being checked
#         txt_ngrams = generate_ngrams(text, severity_word_len)

#         # Search for the word in the document
#         matches = process.extract(word_to_find, txt_ngrams, scorer=fuzz.ratio, limit=None)

#         # Filter matches based on the threshold
#         probable_matches = [match for match in matches if match[1] >= threshold]

#         # 3-tuple of the word, its ranking, and the amount of that word in the text
#         match_tuple = (word, i+1, len(probable_matches))
#         match_list.append(match_tuple)
#         i += 1
    
#     return match_list, len(total_words)

# # Create the n-gram representation of the document
# def generate_ngrams(text, n):
#     words = text.split()
#     ngrams = [' '.join(words[i:i + n]) for i in range(len(words) - n + 1)]
#     return ngrams

# # calculate severity score for all txt files
# def get_sev_ranking(match_list) -> tuple[float, float]:
#     severity_ranking = 0
#     total_ranking_words = 0
#     for item in match_list:
#         severity_ranking += item[1]*item[2]
#         total_ranking_words += item[2]
    
#     return severity_ranking, total_ranking_words

# # normalize severity score
# def novel_sev_ranking_list(ranking_list : list):
#     return_list = []
#     max_num = max(ranking_list)
#     # for each case
#     for ind in range(len(ranking_list)):
#         # get the severity ranking for that case
#         num = ranking_list[ind] / max_num
#         # format it into a list
#         sev = str(num)
#         return_list.append(sev)
#     return return_list


# # VADER sentiment analysis
# # On a scale of [1, -1] - larger values in either direction are more severe/intense
# # Positive values are positive sentiment, negative values are negative sentiment
# def sentiment_analysis(text : str):
#     # Get sentiment scores
#     sentiment = sia.polarity_scores(text)
#     return sentiment


# def create_csv_severity():
#     # output csv
#     sev_normalized_list = []
#     # Charge number list
#     charge_no_list = []
#     year_list = []

#     sentiment_analysis_list = []

#     for filename in os.listdir(txt_directory):
#         if filename.endswith(".txt"):
#             txt_path = os.path.join(txt_directory, filename)

#             head, tail = os.path.split(txt_path)
            

#             # get the case date
#             year = os.path.splitext(tail)[0].replace('"','')[-4:]
#             # if the case is from before 2010, we don't want to do anything with it
#             if int(year) >= 2010:
#                 # get the text of the file
#                 text, text_list = extract_text(txt_path)
#                 print("Processing", txt_path)
#                 # get the charge number from the text
#                 charge_no = get_charge_no(text_list)
#                 # format charge number properly
#                 charge_no = charge_no[:4] + "-" + charge_no[4:6] + "-" + charge_no[6:]
#                 if charge_no != " ":
#                     charge_yr = charge_no[:4]
#                     try:
#                         if int(charge_yr) >= 2010:
#                             # if there is a complainant and charge number after 2010, add to the list
#                             charge_no_list.append(charge_no)
#                             year_list.append(year)

#                             # get the severity ranking using novel 
#                             sev_list, total_txt_words = txt_to_severity_list(text)
#                             sev_number, total_matches = get_sev_ranking(sev_list)
#                             # If there is one or more match
#                             if total_matches != 0:
#                                 # calculate severity
#                                 # normalized by the number of words in the txt file and by the number of matches found
#                                 severity_ranking_normalized = (sev_number / total_matches)
#                             # if zero matches, set the severity score to 0
#                             else:
#                                 severity_ranking_normalized = 0
#                             sev_normalized_list.append(severity_ranking_normalized)

#                             # get the severity ranking using sentiment analysis
#                             polarity = sentiment_analysis(text)["compound"]
#                             sentiment_analysis_list.append(polarity)
#                         else:
#                             print("pre-2010")
#                     except ValueError:
#                         print("invalid charge number")
#             else:
#                 print("pre-2010")
    
#     # get the manual severity ranking, normalizing so the fina number is between 0 and 1
#     sev_ranking_list = novel_sev_ranking_list(sev_normalized_list)

#     return_data = "Charge #,severity_manual,severity_sentiment\n"
#     for ind in range(len(charge_no_list)):
#         return_data +=  '"' + charge_no_list[ind] + '"' + "," + str(sev_ranking_list[ind]) + "," + str(sentiment_analysis_list[ind]) + "\n"

#     return return_data


# # combine the csvs
# def combine_csvs(input_data):
#     # Read the raw state CSV
#     df1 = pd.read_csv(root + "/raw/" + state + "/il_raw_cases_gender.csv")
    
#     # convert the return_data into a pandas dataframe
#     # Use StringIO to convert the string to a file-like object
#     csv_file = io.StringIO(input_data)
#     # Read the CSV string into a DataFrame
#     df2 = pd.read_csv(csv_file)

#     # merge the dataframes on the common "Charge #" column
#     merged_df = pd.merge(df1, df2, on='Charge #', how='left')
#     # convert all non-Numpy NaN values to np NaN; will be replaced later with blank values
#     merged_df = merged_df.replace(['NaN'], np.nan)

#     # Save the merged data frame to a new CSV file
#     output_path = root + "/raw/" + state + "/il_raw_cases_gender_severity.csv"

#     merged_df.to_csv(output_path, 
#                         index=False,        # Do not write row names (index)
#                         header=True,        # Write out the column names
#                         na_rep='NA',        # Missing data representation
#     )

#     # convert all NA values into missing values
#     with open(output_path, "r") as csv_file:
#         severity_file = csv_file.read()
#         severity_file = severity_file.replace("NA","")

#     # Write the CSV to a new file
#     with open(output_path, "w") as text_file:
#             text_file.write(severity_file)


# def preprocess_text(text: str):
#     # Tokenize, remove stopwords, and return cleaned text
#     return [word for word in nltk.word_tokenize(text.lower()) if word.isalnum() and word not in stop_words]


# def topic_modeling():
#     # Read the raw state CSV
#     df_orig = pd.read_csv(root + "/raw/" + state + "/il_raw_cases_gender_severity.csv")
#     # List of all the charge numbers in the original csv (to be used for preprocessing)
#     charge_no_list = df_orig['Charge #'].tolist()
#     basis_list = df_orig['Basis'].tolist()
#     #
#     file_date_list = df_orig['File Date'].dropna().tolist()
#     file_date_list = [datetime.strptime(date, "%m/%d/%y") for date in file_date_list]

#     documents = []
#     metoo_date = datetime(2017, 10, 15)
#     pre_metoo_documents = []
#     post_metoo_documents = []
#     charge_nos = []
#     for filename in os.listdir(txt_directory):
#         if filename.endswith('.txt'):
#             txt_path = os.path.join(txt_directory, filename)
#             # get the text of the file
#             text, text_list = extract_text(txt_path)
#             print("Processing", txt_path)
#             # get the charge number from the text
#             charge_no = get_charge_no(text_list)
#             # format charge number properly
#             charge_no = charge_no[:4] + "-" + charge_no[4:6] + "-" + charge_no[6:]
#             charge_nos.append(charge_no)

#             # Cut out all documents that aren't in the spreadsheet
#             if charge_no in charge_no_list:
#                 # Cut out all documents that aren't sh cases
#                 charge_no_ind = charge_no_list.index(charge_no)
#                 basis = basis_list[charge_no_ind]
#                 file_date = file_date_list[charge_no_ind]
#                 try:
#                     if "HAR" in basis:
#                         documents.append(preprocess_text(text))
#                         if file_date > metoo_date:
#                             post_metoo_documents.append(preprocess_text(text))
#                         else:
#                             pre_metoo_documents.append(preprocess_text(text))
#                 except TypeError:
#                     print("missing")



#     # # LDA
#     # # Create a dictionary and a corpus
#     # dictionary = corpora.Dictionary(documents)
#     # corpus = [dictionary.doc2bow(doc) for doc in documents]
#     # # Set number of topics
#     # num_topics = 3  # You can adjust this number
#     # # Create LDA model
#     # lda_model = LdaModel(corpus, num_topics=num_topics, id2word=dictionary, passes=50)
#     # # Print the topics
#     # print("\nLDA distribution")
#     # for idx, topic in lda_model.print_topics(-1):
#     #     print(f"Topic {idx}: {topic} \n")


#     # LDA with further trimmed docs
    
#     # words to keep - relevant to the topic of sexual harassment
#     keep_words = ['inappropriate', 'behavior', 'lewd', 'comments', 'comment', 'unwelcome', 
#                   'unwanted', 'attention', 'disrespect', 'catcall', 'contact',
#                   'action', 'offensive', 'offensiveness', 'objectify', 'objectification',
#                   'intimidate', 'intimidation', 'bully', 'bullying', 'verbal', 'abuse',
#                   'hostile', 'enviornment', 'cyber', 'harassment', 'coercion', 'coerce',
#                   'violate', 'violation', 'boundary', 'stalking', 'exploit', 
#                   'exploitation', 'sexual', 'advance', 'advances', 'discriminate',
#                   'retaliate', 'retaliation', 'misconduct', 'quid', 'pro', 'quo',
#                   'predatory', 'predator', 'grope', 'groping', 'non-consensual',
#                   'threat', 'invasion', 'invade', 'trauma', 'power', 'dynamic',
#                   'survivor', 'victim', 'assault', 'rape', 'email', 'virtual',
#                   'online', 'touch']
    
#     # only keep the words we want
#     docs = [[word for word in doc if word in keep_words] for doc in documents]
#     pre_metoo_docs = [[word for word in doc if word in keep_words] for doc in pre_metoo_documents]
#     post_metoo_docs = [[word for word in doc if word in keep_words] for doc in post_metoo_documents]
    
#     # LDA models
#     dictionary = corpora.Dictionary(docs)
#     corpus = [dictionary.doc2bow(doc) for doc in docs]
#     # Set number of topics
#     num_topics = 3
#     # Create LDA model
#     lda_model1 = LdaModel(corpus, num_topics=num_topics, id2word=dictionary, passes=50)
#     # Print the topics
#     output = ""
#     print("LDA distribution with trimmed docs")
#     for idx, topic in lda_model1.print_topics(-1):
#         print(f"Topic {idx}: {topic} \n")
#         topic_list = topic.replace(" ","").split("+")
#         topics = "".join(["," + topic for topic in topic_list])
#         output += "group " + str(idx) + " overall" + str(topics) + "\n"
#     output += " , \n"

#     dictionary = corpora.Dictionary(pre_metoo_docs)
#     corpus = [dictionary.doc2bow(doc) for doc in pre_metoo_docs]
#     # Create LDA model
#     lda_model2 = LdaModel(corpus, num_topics=num_topics, id2word=dictionary, passes=50)
#     # Print the topics
#     print("LDA distribution with trimmed docs - Pre MeToo")
#     for idx, topic in lda_model2.print_topics(-1):
#         print(f"Topic {idx}: {topic} \n")
#         topic_list = topic.replace(" ","").split("+")
#         topics = "".join(["," + topic for topic in topic_list])
#         output += "group " + str(idx) + " pre" + str(topics) + "\n"
#     output += " , \n"

#     dictionary = corpora.Dictionary(post_metoo_docs)
#     corpus = [dictionary.doc2bow(doc) for doc in post_metoo_docs]
#     # Create LDA model
#     lda_model3 = LdaModel(corpus, num_topics=num_topics, id2word=dictionary, passes=50)
#     # Print the topics
#     print("LDA distribution with trimmed docs - Post MeToo")
#     for idx, topic in lda_model3.print_topics(-1):
#         print(f"Topic {idx}: {topic} \n")
#         topic_list = topic.replace(" ","").split("+")
#         topics = "".join(["," + topic for topic in topic_list])
#         output += "group " + str(idx) + " post" + str(topics) + "\n"
#     output += " , \n , \n"

#     # Output the results to a spreadsheet
#     output_path = root + "/raw/" + state + "/il_lda_outputs.csv"
#     # Write the CSV to a new file
#     with open(output_path, "a") as output_file:
#         output_file.write(output)


    


# # create the severity rankings
# # severity_data = create_csv_severity()

# # add to the Illinois data
# # combine_csvs(severity_data)

# topic_modeling()