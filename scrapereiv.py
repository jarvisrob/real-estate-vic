__author__ = 'Rob'

# Imports
import argparse
import requests
from bs4 import BeautifulSoup


class SuburbContainer:
    def __init__(self):
        self.suburbs = []
        self.nsuburbs = 0

    def append(self, suburb):
        self.suburbs = self.suburbs + [suburb]
        self.nsuburbs += 1

    def write_csv_all(self, filename):
        file = open(filename, 'w')
        file.writelines("Suburb,AddressLine,Classification,NumberOfBedrooms,Price,OutcomeDate,Outcome,Agent,WebUrl" + "\n")
        for suburb in self:
            for realty in suburb:
                file.writelines(realty.csv_line(suburb.name) + '\n')
        print('All realties in suburb container written as csv to file:', filename)
        file.close()

    def __iter__(self):
        for suburb in self.suburbs:
            yield suburb

    def __getitem__(self, idx):
        return self.suburbs[idx]


class Suburb:
    def __init__(self, name):
        self.name = name
        self.realties = []
        self.nrealties = 0

    def append(self, realty):
        self.realties = self.realties + [realty]
        self.nrealties += 1

    def __iter__(self):
        for realty in self.realties:
            yield realty

    def __getitem__(self, idx):
        return self.realties[idx]


class Realty:
    def __init__(self, addr, br, price, classification, method_sale, year_sale, month_sale, day_sale, agent,
                 weblink=''):
        self.addr = addr
        self.br = br
        self.price = price
        self.classification = classification
        self.method_sale = method_sale
        self.year_sale = year_sale
        self.month_sale = month_sale
        self.day_sale = day_sale
        self.agent = agent
        self.weblink = weblink

    def full_details(self):
        return str(self.addr) + ', ' + str(self.br) + ' bedroom ' + str(self.classification).lower() + ', ' \
            + str(self.method_sale).lower() + ' for $' + self.price_str() \
            + ' on ' + self.date_sale() + ', with agent ' + str(self.agent)

    def date_sale(self):
        return str(self.year_sale) + '-' + str(self.month_sale).zfill(2) + '-' + str(self.day_sale).zfill(2)

    def price_str(self):
        if self.price is None:
            return ""
        else:
            return str(self.price)

    def csv_line(self, suburb_name):
        return '"' + suburb_name + '","' + self.addr + '","' + self.classification.lower() + '",' + str(self.br) + ',' \
            + self.price_str() + ',' + self.date_sale() \
            + ',"' + self.method_sale.lower() + '","' + self.agent + '","' + self.weblink + '"'


def parse_suburb_name(suburb_element):
#    name_raw = suburb_element.div.h2.string
#    return name_raw.partition(' Sales &')[0]
    return suburb_element["data-id"]


def find_realty_body(suburb_element):
    # next_sibling is often the \n character, so keep going until find the tag
#    candidate = suburb_element.next_sibling
#    while candidate == '\n':
#        candidate = candidate.next_sibling
#    return candidate.tbody
    return suburb_element.table.tbody


def check_is_more_results(realty_body):
    button = realty_body.find_all('img', src="/portalimages/portal/propertydata/pd-view-more-results-button.png")
    if not button:
        return [False, '']
    else:
        relurl = button[0].parent['href']
        return [True, relurl]


def find_realty_rows(realty_body):
#    realty_table_element = realty_body.find_all('table')[0]
#    rows = realty_table_element.find_all('tr')
#    rows.pop(0)  # remove heading row
    return realty_body.find_all("tr")


def find_realty_body_on_more_page(url, suburb_name):
    response = requests.get(url)
    soup = BeautifulSoup(response.content, 'lxml')
    print('Soup collected for', suburb_name, 'at', url)
    suburb_element = soup.find_all('div', 'pd-content-heading-dark')[0]
    return find_realty_body(suburb_element)


# def find_realty_elements(suburb_element):
#     candidate = suburb_element.next_sibling
#     while candidate == '\n':
#         candidate = candidate.next_sibling
#     realty_table_element = candidate.find_all('table')[0]
#     rows = realty_table_element.find_all('tr')
#     rows.pop(0)  # remove heading row
#     return rows


def parse_realty_data(data):

    # First <td> is address
    # Check to see if there is a web link for the realty, and if so then collect it
    td_weblink = data[0].find_all('a')
    if not td_weblink:
        weblink = ''
        td_addr = data[0].span.string.strip()
    else:
        weblink = td_weblink[0]['href']
        td_addr = td_weblink[0].span.string.strip()
    addr = ' '.join(td_addr.split())

    # Next <td> is number of bedrooms
    td_br = data[1].string
    if not td_br:
        br = 0
    elif td_br == '-' or td_br == "":
        br = 0
    else:
        br = int(td_br.strip())

    # Next <td> is price
    td_price = data[2].string.strip()
    if td_price == 'undisclosed':
        price = None
    elif td_price == '$undisclosed':
        price = None
    else:
        price = int(td_price.replace('$', '').replace(',', ''))

    # Next <td> is classification
    classification = data[3].string.strip()

    # Next <td> is method of sale
    method_sale = data[4].string.strip()

    # Next <td> is date of sale
    td_date_sale = data[5].string.strip()
    [day_str, month_str, year_str] = td_date_sale.split('/')
    day_sale = int(day_str)
    month_sale = int(month_str)
    year_sale = int(year_str)

    # Next (and final) <td> is agent
    agent = data[6].string.strip()

    # Return parsing results
    return [addr, br, price, classification, method_sale, year_sale, month_sale, day_sale, agent, weblink]


def main():

    # Argument parser
    parser = argparse.ArgumentParser()
    parser.add_argument("outfile", help="File name to write output")
    args = parser.parse_args()

    # Base url
    baseurl = 'http://www.realestateview.com.au'
    midurl = '/propertydata/auction-results/victoria/'

    # Start with 'M' suburbs, but later extend to all suburbs A-Z
    atoz = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U',
            'V', 'W', 'X', 'Y', 'Z']
    # atoz = ['M']

    # Create the suburb container
    suburb_container = SuburbContainer()

    for letter in atoz:
        url = baseurl + midurl + letter

        # Obtain page html and convert to soup
        response = requests.get(url)
        soup = BeautifulSoup(response.content, "html.parser")
        print('Soup collected for', letter, 'at', url)

        # Locate the suburb
        suburb_soup = soup.find_all('div', "suburb-list-item show-list")

        # Commence parsing
        print('Parsing commenced ...')
        for suburb_element in suburb_soup:

            # parse out suburb name
            suburb = Suburb(name=parse_suburb_name(suburb_element))
            print(suburb.name)

            # Find the body of the realty table for this suburb element and check for 'View more results' button
            realty_body = find_realty_body(suburb_element)
#            [ismore, relurl] = check_is_more_results(realty_body)

            # If there are more results, then obtain realty_body from THAT page instead
#            if ismore:
#                realty_body = find_realty_body_on_more_page(baseurl + relurl, suburb.name)

            # Parse out the rows of realty data
            rows = find_realty_rows(realty_body)

            # For each row, parse out the realties and append to suburb
            for row in rows:
                realty_data = row.find_all("td")
                [addr, br, price, classification, method_sale, year_sale, month_sale, day_sale, agent, weblink] \
                    = parse_realty_data(realty_data)
                realty = Realty(addr, br, price, classification, method_sale, year_sale, month_sale, day_sale, agent,
                                weblink)
                print(realty.full_details())
                suburb.append(realty)

            # Append the suburb to the suburb container
            suburb_container.append(suburb)
            print(suburb.name, 'parsed:', str(suburb.nrealties), 'realties found')

        # Parsing complete
        print('... Parsing complete:', str(suburb_container.nsuburbs), 'suburbs found')

    # Write results to file
    #filename = input('Enter file name to write results: ')
    suburb_container.write_csv_all(args.outfile)


if __name__ == '__main__':
    main()
