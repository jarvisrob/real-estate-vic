
import glob


files_csv = glob.glob('*.csv')

file_out = open('all_records.csv', 'a')
for file_name in files_csv:
    with open(file_name) as file:
        records = file.readlines()
    file_out.writelines(records)

