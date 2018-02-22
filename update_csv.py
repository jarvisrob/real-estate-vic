import glob
import pandas as pd
import csv
import numpy as np

# Constants
new_file_prefix = "re-vic"

# files_csv = glob.glob('*.csv')
files_csv = ["scrape_2015-09-12.csv", "scrape_2015-09-19.csv", "scrape_2015-09-20.csv"]

# For each csv file
for file_name in files_csv:
    df = pd.read_csv(file_name, header=None)
    # In original csv, there were no headers, so need to add them
    df.columns = ["Suburb", "AddressLine", "Classification", "NumberOfBedrooms", "Price", "Year", "Month", "Day", "Outcome", "Agent", "WebUrl"]
    
    # Merge dates into single column in yyyy-mm-dd format
    df["Year"] = df["Year"].map(str)
    df["Month"] = df["Month"].map(str)
    df["Day"] = df["Day"].map(str)
    df["OutcomeDate"] = df["Year"] + "-" + df["Month"].str.zfill(2) + "-" + df["Day"].str.zfill(2)
    df = df[["Suburb", "AddressLine", "Classification", "NumberOfBedrooms", "Price", "OutcomeDate", "Outcome", "Agent", "WebUrl"]]
    
    # Replace Price = 0 (how undisclosed was handled in original scrape/csv) with NaN
    df["Price"] = df["Price"].replace(0, np.NaN)

    # New file names: re-vic_yyyy-mm-dd.csv (using 2nd element, Python is zero-indexed)
    file_name_parts = file_name.split("_")
    new_file_name = new_file_prefix + "_" + file_name_parts[1]

    # Write to csv with double quotes around non-numeric entries, includes headers by default
    df.to_csv(new_file_name, index=False, quoting=csv.QUOTE_NONNUMERIC)
