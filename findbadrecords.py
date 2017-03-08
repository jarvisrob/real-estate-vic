# Find the bad records in the REIV csv scrape files
# These are where extra commas have been introduced because a comma literal was in the
# scraped field. Expect exactly 10 commas per record--check to see if otherwise.
# So far, it appears that commas are only added (as expected).

__author__ = 'Rob'

import glob

files_csv = glob.glob('*.csv')

for file_name in files_csv:
    with open(file_name) as file:
        records = file.readlines()
        record_number = 1
    for record in records:
        n_comma = record.count(",")
        if n_comma != 10:
            print(file_name, ": record =", record_number, ": Number of commas =", n_comma)
        record_number += 1
