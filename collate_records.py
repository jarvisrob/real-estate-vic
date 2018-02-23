# Imports
import pandas as pd
import glob
import argparse
import csv

# Argument parser
parser = argparse.ArgumentParser()
parser.add_argument("path_name", help="Path and file pattern to collate")
parser.add_argument("out_file", help="File name to write output")
args = parser.parse_args()

# Opening description
print("\nCollating records at: " + args.path_name)

# Get list of all data files
file_list = glob.glob(args.path_name)

# Read all data files into data frame
print("\nCollecting into data frame ...")
df = pd.read_csv(file_list[0])
print("Start with: " + file_list[0])
if len(file_list) > 1:
    for file_name in file_list[1:]:
        df_new = pd.read_csv(file_name)
        df = pd.concat([df, df_new], ignore_index=True)
        print("Appended: " + file_name)
print("... Data frame collection complete")

# Write dataframe to outfile
df.to_csv(args.out_file, index=False, quoting=csv.QUOTE_NONNUMERIC)
print("\nOutput written to: " + args.out_file)
print("\nScript complete\n")
