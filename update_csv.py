# import argparse
import glob
import pandas as pd
import csv



# # Argument parser
# parser = argparse.ArgumentParser()
# parser.add_argument("outfile", help="File name to write output")
# args = parser.parse_args()



# files_csv = glob.glob('*.csv')
files_csv = ["scrape_2015-09-12.csv", "scrape_2015-09-19.csv", "scrape_2015-09-20.csv"]

# file_out = open('all_records.csv', 'a')
# file_out.writelines('Suburb, Address, Type, NumberOfBedrooms, Price, Year, Month, Day, Outcome, Agent, Website\n')


for file_name in files_csv:
    df = pd.read_csv(file_name, header=None)
    df.columns = ["Suburb", "AddressLine", "Classification", "NumberOfBedrooms", "Price", "Year", "Month", "Day", "Outcome", "Agent", "WebUrl"]
    df["Year"] = df["Year"].map(str)
    df["Month"] = df["Month"].map(str)
    df["Day"] = df["Day"].map(str)
    df["OutcomeDate"] = df["Year"] + "-" + df["Month"].str.zfill(2) + "-" + df["Day"].str.zfill(2)
    df = df[["Suburb", "AddressLine", "Classification", "NumberOfBedrooms", "Price", "OutcomeDate", "Outcome", "Agent", "WebUrl"]]
    df.to_csv("mod_" + file_name, index=False, quoting=csv.QUOTE_NONNUMERIC)



    # with open(file_name) as file:
    #     records = file.readlines()
    # file_out.writelines(records)

