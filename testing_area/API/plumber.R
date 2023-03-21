library(plumber)
library(tidyverse)
library(lubridate)
library(janitor)
library(stringr)
library(DT)
library(reticulate)
library(XML)
library(glue)

#* @apiTitle Donors API
#* @apiDescription Interface with the Donor Cleaner to receive .CSVs for ABBA.

#* Input donor file
#* @param input_path
#* @param state
#* @post  /donors

function(input_path, state, res) {
  
  source("api_transforms.R")
  temp_data <- donor_cleaner(input_path, state)
  filename <- file.path(tempdir(), glue("{state}.csv"))
  csv <- write.csv(temp_data, filename, row.names = FALSE)
  include_file(filename, res, 'csv/text')
  
}




