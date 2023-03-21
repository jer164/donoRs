# DonoRs API

Political donors are valuable data. Particularly in the context of a social-graph product or other instance of programmatic campaign development, they provide several identifier variables for other stakeholders or audience targets to be matched on. The problem with donor data is that every state is different in how they provide this data. Many states output clean, well-formatted `.csv` files. But then there are states like Kansas, where the data downloads as `.xls` files that are really an `.html` in disguise. This means that dealing with these files manually is highly time-consuming, and error-prone due to potential hidden symbols and formatting syntax not visible within spreadsheet programs like Excel. 

The DonoRs API provides a programmatic solution to these issues, and allows interested users to integrate auto-formatting of donor files within their pre-processing pipeline. Particularly at [name of my company], this API expedites a critical aspect of data collection for audience research and maximizes the first-degree connections available during the audience creation process. 

## Availability

At present, this API is accessible in two forms:

1. **DonoRs API**
    - A plumbeR API that could be added to a data processing pipeline
    - Outputs `.csv` data that could be streamed into other operations, functions, or data structures
2. **DonorCleaner** [documentation available [here](https://jer164.github.io/donoRs/)]
    - Shiny App available [here](https://jer164.shinyapps.io/DonorCleanerApp/). 
    - This app allows non-technical users to interface with the API, and outputs relevant descriptive statistics 
    - It also includes support for direct querying of the Philadelphia campaign finance site

## Usage

The `DonoRs` API is accessed in the form of `POST` requests, and has one available endpoint: `/donors`. A correctly structured request will contain two parameters:

1. `input_path` (string)
    - Path to a local/hosted file to be formatted 
2. `state` (string)
    - Two letter state abbreviation
    - Determines the schema that the API expects and subsequently transforms

Responses will take the form of `.csv` data. 

Currently, the API can only be used by downloading the source files and hosting it on your local machine through RStudio. More interested users could deploy it within a Docker container.

## Example

The following is a minimal example using a list of 500 donors to Ron DeSantis. This file downloads as a `.txt`, with the only required user intervention being the deletion of an extra quote mark. 

Run the API, and then pass a query with the two parameters defined in the request body:

```
# curl a REST request with two parameters

curl -X POST "http://127.0.0.1:7263/donors?input_path=%2FUsers%2Fjacksonrudoff%2FDocuments%2Fdonor_files%2Fdesantis.txt&state=FL" -H "accept: */*" -d ""
```
We can see that `input_path` is pointing to a local directory on my machine, and `state` is set to **FL**. With the state defined, the API understands both *how* to read in the file, and then what the necessary transformations are. 

The successfull request will take the form of comma-separated data:

```
"donation_date","donation_amount","full_name","addr1","city","state","zip","full_address","first_name","middle_name","last_name","addr2","phone1","phone2","email1","email2"
"06/06/2022",50,"","PO BOX 64","CORTLAND","OH","44410","","STEPHEN","","MARTIN","","","","",""
"09/14/2022",25,"","PO BOX 64","CORTLAND","OH","44410","","STEPHEN","","MARTIN","","","","",""
"09/12/2022",3000,"","P.O. BOX 23627","JACKSONVILLE","FL","32241","","GATE","","","","","","",""
...
```

If we wanted to stream this data within something like a Python environment, we can leverage it using the `requests` library. 

```
import requests
import pandas as pd

# send a request
url = 'http://127.0.0.1:7263/donors'
data = {'input_path': '/Users/jacksonrudoff/Documents/donor_files/desantis.txt', 'state': 'FL'}
response = requests.post(url, json=data)

# write to a temporary object
with open('data.csv', 'wb') as f:
    f.write(response.content)

# read into a dataframe
pd.read_csv('data.csv')

donation_date  donation_amount          city
06/06/2022               50         CORTLAND
09/14/2022               25         CORTLAND
09/12/2022             3000     JACKSONVILLE
08/11/2022               20  SAINT AUGUSTINE
11/02/2022              500  NEW PORT RICHEY
..            ...              ...              ...
08/09/2022               22           STUART
08/09/2022               50           STUART
08/30/2022              100           STUART
10/28/2022              100           STUART
09/05/2018              100           STUART

```
