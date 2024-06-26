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
    csv_line = []

    with open(input_path, "r") as text_file:
        file = text_file.readlines()
        # Make txt file more easily parsed
        for i in range(len(file)):
             if i >= len(file):
                break
             if file[i] == "\n":
                file = file[:i] + file[i+1:]

        for i in range(len(file)):
            file[i] = file[i].replace('‘', "'")
            file[i] = file[i].replace('’', "'")
            if file[i][0] == "'":
                file[i] = file[i].replace("'", '')


    # Get the respondent organization/person
    resp_org = ""
    resp_trigger = 0
    for i in range(20):
        if resp_trigger == 1:
            if "respondent" in file[i].lower():
                resp_org += '"'
                break
            else:
                resp_org += file[i][:-1]
                resp_org += " "

        if "DECISION AND ORDER" in file[i]:
            resp_trigger = 1
            resp_org = '"'
    csv_line.append(resp_org)

    # Get case ID
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
    csv_line.append(case_id)

    # Get the file date
    file_date = ""
    for i in range(len(file)):
        # Find the right line
        if file[i][:-1] == "INTRODUCTION":
            split_line = file[i+1].split(",")
            file_date = '"' + split_line[0].split()[1] + ' ' + split_line[0].split()[2] + ' '
            file_date += split_line[1] + '"'
            break
    csv_line.append(file_date)
    
    # Get the resolution date
    res_date = ""
    head, tail = os.path.split(input_path)
    res_date += tail.split()[0]
    csv_line.append(res_date)

    # Get the relief
    relief = -1
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
    if relief == -1:
         csv_line.append("")
    else:
        csv_line.append(str(relief + 1))

    # Get the basis
    basis = ""
    disc_trigger = 0
    for i in range(len(file)):
        # Find the right line
        if file[i][:-1] == "INTRODUCTION":
            disc_trigger = 1
        if disc_trigger == 1:
            basis_string = file[i][:-1]
            if "age" in basis_string.lower():
                basis += "Age"
            elif "sex" in basis_string.lower():
                basis += "Sex"
            elif "disability" in basis_string.lower():
                basis += "Disability"
            elif "race" in basis_string.lower():
                basis += "Race"
            elif "retaliation" in basis_string.lower():
                basis += "Retaliation"
            elif "religion" in basis_string.lower():
                basis += "Religion"
            elif "nationality" in basis_string.lower():
                basis += "Nationality"
            elif "lgbtq" in basis_string.lower():
                basis += "LGBTQ"
        if basis != "":
            break
        if  file[i][:-1] == "JURISDICTION":
            basis += "Other"
            break
    csv_line.append(basis)

    # Get the jurisdiction
    jurisdiction = "employment"
    csv_line.append(jurisdiction)

    # Get the win variable
    if relief != -1:
        win = 1
    else:
        win = -1
        win_trigger = 0
        for i in range(len(file)):
            if "CONCLUSIONS OF LAW" in file[i]:
                win_trigger = 1
            if win_trigger == 1:
                if "not prove" in file[i]:
                    win = 0
                elif "failed to prove" in file[i]:
                    win = 0
                elif "prove" in file[i]:
                    win = 1
                if "discriminate" in file[i]:
                    break
    if win == -1:
        win = ""
    
    csv_line.append(str(win))
    

    # Get the settle variable
    settle = 0
    settle_trigger = 0
    for i in range(len(file)):
        if file[i][:-1] == "ORDER":
            settle_trigger = 1
        if settle_trigger == 1:
            if "settle " in file[i]:
                settle = 1
    csv_line.append(str(settle))

    # Get the court variable
    court = 0
    court_trigger = 0
    for i in range(len(file)):
        if file[i][:-1] == "ORDER":
            court_trigger = 1
        if court_trigger == 1:
            if "court" in file[i]:
                if ("appelate" in file[i]) or "federal" in file[i]:
                    court = 1
    csv_line.append(str(court))


    # Get the victim_f variable
    victim_f = -1
    for i in range(len(file)):
        if "her " in file[i]:
            victim_f = 1
            break
        if "him " in file[i]:
            victim_f = 0
            break
    if victim_f == -1:
        victim_f = ""
    csv_line.append(str(victim_f))


    # Combine all the information
    csv_line = ",".join(csv_line)
    csv_line += "\n"
    return csv_line
    

csv = "resp_org,case_id,file_date,res_date,relief,basis,jurisdiction,win,settle,court,victim_f\n"
# Iterate through each PDF file in the directory
for filename in os.listdir(txt_directory):
    if filename.endswith(".txt"):
        txt_path = os.path.join(txt_directory, filename)
        
        # Get the CSV data from the txt
        print("Processing", txt_path)
        csv_line = txt_to_csv(txt_path)
        head, tail = os.path.split(txt_path)
        if not ("RICHR Response to APRA Request" in tail):
            csv += csv_line

# Flie to save the extracted csv
output_path = root + "/raw/" + state + "/" + state + "_raw_cases.csv"

# Write the CSV to a new file
with open(output_path, "w") as text_file:
        text_file.write(csv)


