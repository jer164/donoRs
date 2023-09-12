############## ABBA DONOR CLEANER ###################
#####################################################
#####################################################
# Author: Jackson Rudoff                            #
# Last Dev Period: Summer 2023                      #
#                                                   #
# About:                                            #
# These transformations are intended to auto-format #
# files downloaded from state campaign sites, for   #
# use in ABBA's manual uploaded feature.            #
#####################################################


# Loading Python Source Code
# This app relies on Python code for some of its transformations
# and web-scraping capabilities.

source("src/kansas.R")
source("src/missouri.R")
source("src/abba_formats.R")
source("src/get_result.R")
source("src/detect_delim.R")
source("src/donor_reads.R")
source("src/col_finder.R")
source("src/col_renamer.R")
source("src/recipient_check.R")
load("src/headers_list.Rdata")
load("src/state_list.Rdata")

library(tidyverse)
library(reticulate)
library(tools)
library(janitor)
library(glue)

virtualenv_create(envname = "python_environment", python = "python3")
virtualenv_install("python_environment", packages = c("pandas", "lxml", "bs4", "requests"))
reticulate::use_virtualenv("python_environment", required = TRUE)
reticulate::source_python("src/virginia.py", convert = TRUE)

### Collect ABBA-friendly names

abba_names <- c(
  "donation_date", "donation_amount", "full_name", "addr1",
  "city", "state", "zip", "full_address", "first_name", "middle_name",
  "last_name", "addr2", "phone1", "phone2", "email1", "email2"
)


#######################################################

donor_cleaner <- function(input_data_path) {

  cont_list <- donor_reads(input_data_path)
  temp_data <- cont_list[[1]] %>% clean_names()
  state_fin <- cont_list[[2]]

  temp_data <- temp_data %>% recipient_check()
  temp_data <- temp_data %>% col_renamer()

  ###### state-level transforms

  if (state_fin == "AL") {
    temp_data <- temp_data %>%
      separate("full_address", c("city", "state"), sep = ",") %>%
      mutate(full_address = "")
  } else if (state_fin == "AR") {
    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount))
  } else if (state_fin == "ATL") {
    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount)) %>%
      mutate(city = gsub("([A-Z]{2})|\\d{5}", "", full_address)) %>%
      mutate(state = str_extract(full_address, "[A-Z]{2}")) %>%
      mutate(zip = str_extract(full_address, "\\d{5}")) %>%
      mutate(full_address = "NULL")
  } else if (state_fin == "AK") {
    temp_data$donation_amount <- as.numeric(gsub("\\$", "", temp_data$donation_amount))
  } else if (state_fin == "CA") {
    temp_data$zip <- str_extract(temp_data$zip, "\\d{5}")
    temp_data <- temp_data %>% filter(zip >= 5)
  } else if (state_fin == "CO") {
    temp_data <- temp_data %>%
      separate("full_address", c("city", "state"), sep = ",") %>%
      mutate(full_address = "") %>%
      mutate_if(is.character, trimws) %>%
      filter(is.na(city) == F) %>%
      filter(state != "" | state != " " | is.na(state) == F)
  } else if (state_fin == "DC") {
    temp_data <- temp_data %>%
      mutate(donation_amount = str_remove(donation_amount, "\\$"))
  } else if (state_fin == "FEC") {
    temp_data <- temp_data %>%
      mutate(donation_date = gsub("-", "/", donation_date)) %>%
      mutate(zip = substr(zip, start = 1, stop = 5))
  } else if (state_fin == "FL") {
    temp_data <- temp_data %>%
      mutate(tmp_city = city) %>%
      mutate(city = word(tmp_city, 1, sep = ",")) %>%
      mutate(state = word(tmp_city, 2, sep = ",")) %>%
      mutate(zip = str_extract(state, "\\d{5}")) %>%
      mutate(state = str_extract(state, "[A-Z]{2}")) %>%
      mutate(first_name = word(full_name, 2, sep = " ")) %>%
      mutate(last_name = word(full_name, 1, sep = " ")) %>%
      mutate(full_name = "") %>%
      mutate(first_name = str_replace_all(first_name, "[^[:alpha:]]", "")) %>%
      mutate(last_name = str_replace_all(last_name, "[^[:alpha:]]", ""))
  } else if (state_fin == "IN") {
    temp_data <- temp_data %>%
      separate("CityState", c("city", "state"), sep = ",")
  } else if (state_fin == "ID") {
    temp_data <- temp_data %>% mutate(donation_date = as.Date(donation_date))
  } else if (state_fin == "KY") {
    temp_data <- temp_data %>%
      mutate(donation_date = gsub(" 00:00:00", "", donation_date))
  } else if (state_fin == "LA") {
    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
  } else if (state_fin == "MA") {
    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
    temp_data <- temp_data %>%
      mutate(last_name = gsub("\\d+|\\(|\\)|-", "", last_name)) %>%
      mutate(zip = str_extract(zip, "\\d{5}"))
  } else if (state_fin == "MD") {
    temp_data <- temp_data %>%
      mutate(first_name = word(full_name, 2, sep = ",") %>% trimws()) %>%
      mutate(last_name = word(full_name, 1, sep = ",")) %>%
      mutate(full_name = "") %>%
      mutate(addr1 = word(full_address, 1, sep = ",")) %>%
      mutate(addr2 = ifelse(str_count(full_address, ",") == 3, word(full_address, 2, sep = ","),
        ""
      )) %>%
      mutate(city = ifelse(str_count(full_address, ",") == 2, word(full_address, 2, sep = ","),
        word(full_address, 3, sep = ",")
      )) %>%
      mutate(state = ifelse(str_count(full_address, ",") == 2, word(full_address, 3, sep = ","),
        word(full_address, 4, sep = ",")
      )) %>%
      mutate(zip = str_extract(state, "\\d{5}")) %>%
      mutate(state = str_extract(state, "[A-Z]{2}")) %>%
      mutate(full_address = "")
  } else if (state_fin == "MI") {
    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
    temp_data <- temp_data %>%
      mutate(last_name = gsub("\\d+|\\(|\\)|-", "", last_name)) %>%
      mutate(zip = str_extract(zip, "\\d{5}"))
  } else if (state_fin == "MT") {
    temp_data <- temp_data %>%
      mutate(city = word(contributor_city_state_zip, 1, sep = " ")) %>%
      mutate(state = word(contributor_city_state_zip, 2, sep = " ")) %>%
      mutate(zip = str_extract(contributor_city_state_zip, "\\d{5}"))
  } else if (state_fin == "ME") {
    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount)) %>%
      mutate(zip = str_extract(full_address, "\\d{5}")) %>%
      mutate(state = str_extract(word(full_address, -1, sep = ","), "[A-Z]+")) %>%
      mutate(city = word(full_address, -2, sep = ",")) %>%
      mutate(full_address = word(full_address, 1, sep = ","))
  } else if (state_fin == "MO") {
    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount)) %>%
      mutate(across(where(is.character), ~ gsub("NaN", "", .)))
  } else if (state_fin == "NC") {
    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
    temp_data <- temp_data %>%
      mutate(zip = str_extract(zip, "\\d{5}")) %>%
      filter(full_name != "Aggregated Individual Contribution") %>%
      filter(full_name != "Aggregated Non-Media Expenditure") %>%
      mutate_at(c("full_name", "addr1", "city"), str_to_title)
  } else if (state_fin == "ND") {
    temp_data <- temp_data %>%
      mutate(donation_amount = as.numeric(gsub("\\$|,", "", donation_amount))) %>%
      mutate(full_name = gsub(",", "", full_name)) %>%
      mutate(full_name = ifelse(full_name == "", "Null", full_name))
  } else if (state_fin == "NE") {
    temp_data <- temp_data %>%
      separate("full_address", c("city", "state"), sep = ",") %>%
      mutate(full_address = "NULL")
  } else if (state_fin == "NJ") {
    temp_data <- temp_data %>% mutate(full_name = ifelse(first_name == "", NonIndName, ""))
  } else if (state_fin == "NM") {
    temp_data <- temp_data %>%
      mutate(full_address = str_replace(full_address, ",,", ",")) %>%
      mutate(donation_amount = as.numeric(gsub("\\$|,", "", donation_amount))) %>%
      mutate(full_name = str_replace(full_name, "  ", " "))
  } else if (state_fin == "NYC") {
    temp_data <- temp_data %>%
      mutate(full_address = replace_na("NULL"))
  } else if (state_fin == "NY") {
    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
  } else if (state_fin == "RI") {
    temp_data <- temp_data %>%
      mutate(city = word(CityStZip, sep = ",")) %>%
      mutate(zip = ifelse(str_detect(CityStZip, ".*[0-9].*") == TRUE,
        as.integer(word(CityStZip, -1, sep = " ")), ""
      )) %>%
      mutate(state = ifelse(str_detect(CityStZip, ".*[0-9].*") == FALSE,
        word(CityStZip, -1, sep = " "), word(CityStZip, -2, sep = " ")
      ))
  } else if (state_fin == "OH") {
    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
  } else if (state_fin == "OK") {
    temp_data <- temp_data %>%
      separate("full_address", c("city", "state"), sep = ",") %>%
      mutate(full_address = "NULL") %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount))
  } else if (state_fin == "TN") {
    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount)) %>%
      mutate(full_address = as.character(full_address)) %>%
      mutate(full_address = trimws(full_address)) %>%
      mutate(zip = word(full_address, -1, sep = ",")) %>%
      mutate(state = word(full_address, -2, sep = ",")) %>%
      mutate(city = word(full_address, -3, sep = ",")) %>%
      mutate(full_address = word(full_address, 1, -4))
  } else if (state_fin == "TX") {
    temp_data <- temp_data %>%
      mutate(first_name = trimws(word(full_name, 2, sep = ","))) %>%
      mutate(last_name = trimws(word(full_name, 1, sep = ","))) %>%
      mutate(zip = word(zip, sep = "-"))
  } else if (state_fin == "UT") {
    temp_data <- temp_data %>% filter(addr1 != "")
  } else if (state_fin == "WA") {
    temp_data <- temp_data %>%
      # mutate(donation_date = as.character(gsub("UTC", "", donation_date)))
      mutate(full_name = sub(" ", ", ", full_name, fixed = TRUE)) %>%
      mutate(donation_date = substr(donation_date, 1, 10))
  } else if (state_fin == "WV") {
    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
    temp_data <- temp_data %>%
      filter(is.na(full_address) == F | full_address %in% c("", " "))
  } else if (state_fin == "WY") {
    temp_data <- temp_data %>%
      mutate(tmp_city = city) %>%
      mutate(city = word(tmp_city, 1, sep = ",")) %>%
      mutate(zip = str_extract(tmp_city, "\\d{5}")) %>%
      mutate(state = word(tmp_city, 2, sep = ",")) %>%
      mutate(state = str_extract(state, "[A-Z]{2}")) %>%
      mutate(full_name = gsub("\\([A-Za-z]+\\)", "", full_name))
  }

  ######### ABBA transforms

  # Get name cols

  name_cols <- c("first_name", "last_name", "full_name")

  # Add the missing names with empty data and select only what we want to keep

  temp_data <- temp_data %>% abba_formats(abba_names)
  
  if ((all(is.na(temp_data$first_name)) == F) && (all(is.na(temp_data$first_name)) == F)){
    temp_data <- temp_data %>% 
      mutate(full_name = '')
  }
  
  # Ensure donations aren't in bad format
  temp_data <- temp_data %>%
    mutate(donation_amount = gsub("\\.\\d{2}", "", donation_amount)) %>% # remove decimals
    mutate(donation_amount = as.integer(gsub(",", "", donation_amount))) %>% # integers only
    filter(!is.na(donation_amount) & donation_amount > 0) %>% # remove NA or 0
    mutate(across(where(is.list), as.character))

  return(temp_data)
}
