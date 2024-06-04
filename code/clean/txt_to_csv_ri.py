import os
import getpass
import io
import re


# Get current user ID
userid = getpass.getuser()
if userid == "anyamarchenko":
    root = "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/metoo_data"
elif userid == "maggie":
    root = "/Users/maggie/Dropbox (Brown)/metoo_data"
elif userid == "jacobhirschhorn":
    root = "/Users/jacobhirschhorn/Dropbox (Brown)/metoo_data"


# State name
state = "RI"

# Directory containing the .txt files
txt_directory = root + "/raw/" + state + "/" + state + "_extracted"


def txt_to_csv(input_path : str):
    resp_org = ""
    case_id = ""
    file_date = ""
    res_date = ""
    relief = 0
    basis = ""
    jurisdiction = "employment"

    with open(input_path, "r") as text_file:
        file = text_file.readlines()
        for i in range(len(file)):
            if i >= len(file):
                break
            if file[i][0] == "'":
                file[i] = file[i][1:]
            if file[i] == "\n":
                file = file[:i] + file[i+1:]
            

    # Get case ID
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
                    break
    
    # Get the respondent organization/person
    for i in range(20):
        if "DECISION AND ORDER" in file[i]:
            resp_org = '"' + file[i+1][:-1] + '"'

    # Get the resolution date
    head, tail = os.path.split(input_path)
    res_date += tail.split()[0]

    # Get the relief
    damages_trigger = 0
    for i in range(len(file)):
        # Find the right line
        if file[i][:-1] == "ORDER":
            damages_trigger = 1
        if damages_trigger == 1:
            if "$" in file[i]:
                line = file[i].split()
                # Convert the relief to a number
                for token in line:
                    if token[0] == "$":
                        no_commas = token.replace(",","")
                        relief += int(float(no_commas[1:]))

    # Get the basis
    disc_trigger = 0
    for i in range(len(file)):
        # Find the right line
        if "discriminat" in file[i]:
            disc_trigger = 1
        if disc_trigger == 1:
            if "because" in file[i]:
                basis = '"'
                basis += file[i]
                basis += file[i+1]
                basis += file[i+2]
                basis += '"'
                break
    
    # Get the file date
    for i in range(len(file)):
        # Find the right line
        if file[i][:-1] == "INTRODUCTION":
            split_line = file[i+1].split(",")
            file_date = '"' + split_line[0].split()[1] + ' ' + split_line[0].split()[2] + ' '
            file_date += split_line[1] + '"'
            break

    # Combine all the information
    csv_line = tail + ',' + resp_org + ',' + case_id + ',' + file_date + ',' + res_date + ',' + str(relief) + ',' + basis + ',' + jurisdiction + '\n'
    return csv_line
    

csv = "path,resp_org,case_id,file_date,res_date,relief,basis,jurisdiction\n"
# Iterate through each PDF file in the directory
for filename in os.listdir(txt_directory):
    if filename.endswith(".txt"):
        txt_path = os.path.join(txt_directory, filename)
        
        # Get the CSV data from the txt
        print("Processing", txt_path)
        csv_line = txt_to_csv(txt_path)
        csv += csv_line

# Directory to save the extracted csv file - TODO: Maybe don't need?
output_path = root + "/raw/" + state + "/" + state + "_raw_cases.csv"


# Wrtie the CSV to a new file
with open(output_path, "w") as text_file:
        text_file.write(csv)

