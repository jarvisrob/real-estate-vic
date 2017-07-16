
import glob


files_csv = glob.glob('*.csv')

file_out = open('all_records.csv', 'a')
file_out.writelines('Suburb, Address, Type, NumberOfBedrooms, Price, Year, Month, Day, Outcome, Agent, Website\n')
for file_name in files_csv:
    with open(file_name) as file:
        records = file.readlines()
    file_out.writelines(records)

