# -*- coding: utf-8 -*-

__author__ = 'Rob'


# Imports
import numpy as np
import pandas as pd
import glob
#import scrapereiv


# Script
print('Enter search criteria to match')
suburbs = ['Ormond']
#suburbs = ['Mordialloc']
#classification = ['house', 'townhouse', 'unit']
#classification = ['house', 'townhouse']
classification = ['house']
#suburbs = input('Suburbs: ').split(',')
#classification = input('Classification: ').split(',')
bedrooms = [2,3]
#bedrooms = [3]
#bedrooms = input('Bedrooms: ').split(',')
#price_max = np.float64(input('Max price: '))
price_max = np.float64(2000000.)

# Find all *.csv
files_csv = glob.glob('*.csv')
#files_csv = ['scrape_2015-09-12.csv', 'scrape_2015-09-19.csv']
col_names = ['Suburb', 'Address', 'Classification', 'Bedrooms', 'Price', 'Year sale', 'Month sale', 'Day sale', 'Method sale', 'Agent', 'URL']
#col_dtype = []

# Main loop
matches = pd.DataFrame(columns=col_names)
for csv in files_csv:
    dfcsv = pd.read_csv(csv, header=None, names=col_names)
        
    sub_match = dfcsv['Suburb'] == suburbs[0]
    for suburb in suburbs[1:]:
        sub_match = sub_match | (dfcsv['Suburb'] == suburb)
    
    br_match = dfcsv['Bedrooms'] == np.int32(bedrooms[0])
    for br in bedrooms[1:]:
        br_match = br_match | (dfcsv['Bedrooms'] == np.int32(br))

    cl_match = dfcsv['Classification'] == classification[0]
    for cl in classification[1:]:
        cl_match = cl_match | (dfcsv['Classification'] == cl)

    price_match = dfcsv['Price'] <= price_max
    
    csv_matches = dfcsv[sub_match & br_match & cl_match & price_match]
    matches = matches.append(csv_matches)
