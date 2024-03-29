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

virtualenv_create(envname = "python_environment", python = "python3")
virtualenv_install("python_environment", packages = c("pandas", "lxml", "bs4", "requests"))
reticulate::use_virtualenv("python_environment", required = TRUE)
reticulate::source_python("src/virginia.py", convert = TRUE)
reticulate::source_python("src/philadelphia.py", convert = TRUE)


#######################################################

donor_cleaner <- function(input_data_path, state_fin) {
  ### Collect ABBA-friendly names

  good_names <- c(
    "donation_date", "donation_amount", "full_name", "addr1",
    "city", "state", "zip", "full_address", "first_name", "middle_name",
    "last_name", "addr2", "phone1", "phone2", "email1", "email2"
  )

  ### These states have dumb and broken data formats

  if (state_fin == "VA") {
    temp_data <- virginia(input_data_path) %>% as_tibble()
  } else if (state_fin == "KS") {
    temp_data <- kansas(input_data_path) %>% as_tibble()
  } else if (state_fin == "MO") {
    temp_data <- missouri(input_data_path) %>% as_tibble()
  } else if (state_fin == "PHIL") {
    temp_data <- philadelphia(input_data_path) %>% as_tibble()
  } 

  ### These states have a non-tabular first row

  else if (state_fin == "GA" | state_fin == "NM" | state_fin == "WV" | state_fin == "AR") {
    temp_data <- read_csv(input_data_path, skip = 1) %>% as_tibble()
  }

  ### Arizona has a formatting issue, amongst its *other* problems

  else if (state_fin == "AZ") {
    temp_data <- read.csv(input_data_path, fileEncoding = "UTF-16LE") %>% as_tibble()
  }
  
  ### DC also has a formatting issue and needs a skip
  
  else if (state_fin == "DC") {
    temp_data <- read_csv(input_data_path, 
                          skip = 1, locale = readr::locale(encoding = "UTF-16LE")) %>% as_tibble()
  }

  ### These states use .TXT files

  else if (state_fin == "MA" | state_fin == "MI" | state_fin == "FL") {
    temp_data <- read_delim(input_data_path,
      delim = "\t", escape_double = FALSE,
      trim_ws = TRUE
    )
  } else if (state_fin == "MT") {
    temp_data <- read_delim(input_data_path,
      delim = "|", escape_double = FALSE, trim_ws = TRUE
    )
  } else if (state_fin == "MD") {
    temp_data <- rvest::read_html(input_data_path) %>% html_table()
    temp_data <- temp_data[[1]] %>% as_tibble()
    colnames(temp_data) <- temp_data[1,]
    temp_data <- slice(temp_data, -1)
  }
  
  else if (state_fin == "TX"){
    
    temp_data <- read_csv(input_data_path, skip = 4) 
  }

  ### These states use standard .CSVs

  else {
    temp_data <- read_csv(input_data_path) %>% as_tibble()
    # temp_data <- temp_data %>% clean_names()
  }

  ###### state-level transforms

  if (state_fin == "IL") {
    temp_data <- temp_data %>% rename(
      "full_name" = "ContributedBy",
      "donation_amount" = "Amount",
      "donation_date" = "RcvdDate",
      "addr1" = "Address1",
      "addr2" = "Address2",
      "state" = "State",
      "city" = "City",
      "zip" = "Zip"
    )

  } else if (state_fin == "AL") {
    temp_data <- temp_data %>% rename(
      "full_name" = "Contributor",
      "donation_amount" = "Amount",
      "donation_date" = "ContributionDate",
      "zip" = "ZipCode"
    )

    temp_data <- temp_data %>%
      separate("CityState", c("city", "state"), sep = ",") %>%
      mutate(full_address = "NULL")
  } else if (state_fin == "AR") {
    temp_data <- temp_data %>% clean_names()
    
    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_payee",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "full_address" = "address"
    )
    
    temp_data <- temp_data %>% 
      mutate(donation_amount = gsub("\\$", "", donation_amount))
    
  } else if (state_fin == "ATL") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "donation_amount" = "amount",
      "donation_date" = "date",
      "full_address" = "contributor_address"
    )


    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount)) %>%
      mutate(city = gsub("([A-Z]{2})|\\d{5}", "", full_address)) %>%
      mutate(state = str_extract(full_address, "[A-Z]{2}")) %>%
      mutate(zip = str_extract(full_address, "\\d{5}")) %>%
      mutate(full_address = "NULL")
  } else if (state_fin == "AK") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "first_name" = "first_name",
      "last_name" = "last_business_name",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "full_address" = "address",
      "zip" = "zip"
    )

    temp_data$donation_amount <- as.numeric(gsub("\\$", "", temp_data$donation_amount))
  } else if (state_fin == "AZ") {
    temp_data <- temp_data %>% rename(
      "full_name" = "TransactionName",
      "donation_amount" = "Amount",
      "donation_date" = "TransactionDate",
      "city" = "City",
      "state" = "State",
      "zip" = "ZipCode"
    )

  } else if (state_fin == "CA") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "donation_amount" = "amount",
      "donation_date" = "start_date",
      "state" = "contributor_state",
      "city" = "contributor_city",
      "zip" = "contributor_zip_code"
    )


    temp_data$zip <- str_extract(temp_data$zip, "\\d{5}")
    temp_data <- temp_data %>% filter(zip >= 5)
  } else if (state_fin == "CO") {
    
    
    temp_data <- temp_data %>% rename(
      "full_name" = "Contributor",
      "donation_amount" = "Amount",
      "donation_date" = "ContributionDate"
    )

    temp_data <- temp_data %>%
      separate("CityState", c("city", "state"), sep = ",") %>%
      mutate(full_address = "NULL") %>% 
      mutate_if(is.character, trimws) %>% 
      filter(is.na(city) == F) %>% 
      filter(state != "" | state != " " | is.na(state) == F)
  } else if (state_fin == "CT") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "donation_amount" = "amount",
      "donation_date" = "transaction_date"
    )

  } else if (state_fin == "DC") {
    temp_data <- temp_data %>% clean_names()
    
    temp_data <- temp_data %>% rename(
      "first_name" = "contributor_first_name",
      "last_name" = "contributor_last_name",
      "addr1" = "number_and_street",
      "donation_amount" = "amount",
      "donation_date" = "receipt_date"
    )
    
    temp_data <- temp_data %>% 
      mutate(donation_amount = str_remove(donation_amount, "\\$"))
    
  } else if (state_fin == "DE") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "addr1" = "contributor_address_line_1",
      "addr2" = "contributor_address_line_2",
      "donation_amount" = "contribution_amount",
      "donation_date" = "contribution_date",
      "state" = "contributor_state",
      "city" = "contributor_city",
      "zip" = "contributor_zip"
    )
  
  } else if (state_fin == "DET") {
    temp_data <- temp_data %>% clean_names()
    
    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "full_address" = "contributor_address",
      "donation_amount" = "contribution_amount",
      "donation_date" = "transaction_date"
    )

   
  } else if (state_fin == "FEC") {
    temp_data <- temp_data %>% rename(
      "first_name" = "contributor_first_name",
      "last_name" = "contributor_last_name",
      "addr1" = "contributor_street_1",
      "addr2" = "contributor_street_2",
      "donation_amount" = "contribution_receipt_amount",
      "donation_date" = "contribution_receipt_date",
      "state" = "contributor_state",
      "city" = "contributor_city",
      "zip" = "contributor_zip"
    )


    temp_data <- temp_data %>%
      mutate(donation_date = gsub("-", "/", donation_date)) %>% 
      mutate(zip  = substr(zip, start = 1, stop = 5))
  } else if (state_fin == "FL") {
    
    temp_data <- temp_data %>% clean_names()
    
    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "addr1" = "address",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "addr1" = "address"
    )

    
    temp_data <- temp_data %>% 
      #unite(full_address, addr1, city_state_zip, sep = " ") %>% 
      mutate(city = word(city_state_zip, 1, sep = ",")) %>% 
      mutate(state = word(city_state_zip, 2, sep = ",")) %>% 
      mutate(zip = str_extract(state, "\\d{5}")) %>%
      mutate(state = str_extract(state, "[A-Z]{2}")) %>% 
      mutate(addr1 = "") %>% 
      mutate(first_name = word(full_name, 2, sep = " ")) %>% 
      mutate(last_name = word(full_name, 1, sep = " ")) %>% 
      mutate(full_name = "") %>% 
      mutate(first_name = str_replace_all(first_name, "[^[:alpha:]]", "")) %>% 
      mutate(last_name = str_replace_all(last_name, "[^[:alpha:]]", ""))
    
    
  } else if (state_fin == "GA") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_payee",
      "donation_amount" = "contribution_amount",
      "donation_date" = "transaction_date"
    )

    temp_data <- temp_data %>%
      mutate(addr1 = word(contributor_address, 1, sep = ",,|,")) %>%
      mutate(city = word(contributor_address, 2, sep = ",,|,")) %>%
      mutate(state = word(contributor_address, 3, sep = ",,|,")) %>%
      mutate(zip = str_extract(contributor_address, "\\d{5}")) %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount)) %>%
      mutate(city = ifelse(str_detect(city, "\\d+") == TRUE, "NULL", city))
  } else if (state_fin == "GA_old") {
    temp_data <- temp_data %>% clean_names()
    
    temp_data <- temp_data %>% mutate(last_name = str_remove(last_name, "Mr.|Ms.|Mrs.|Dr.")) %>% 
      mutate(last_name = str_remove(last_name, "[.,]")) %>% 
      mutate(last_name = str_trim(last_name)) %>% 
      mutate(state = str_trim(state))

    temp_data <- temp_data %>% rename(
      "donation_amount" = "cash_amount",
      "donation_date" = "date",
      "addr1" = "address"
    )

  } else if (state_fin == "HI") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "addr1" = "address_1",
      "addr2" = "address_2",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "zip" = "zip_code",
    )


  } else if (state_fin == "IA") {
    temp_data <- temp_data %>% clean_names()


    temp_data <- temp_data %>% rename(
      "full_name" = "contributed_by_name",
      "addr1" = "contributed_by_address1",
      "addr2" = "contributed_by_address2",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "city" = "contributed_by_city",
      "state" = "contributed_by_state",
      "zip" = "contributed_by_zip"
    )

    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount))
  } else if (state_fin == "IN") {
    temp_data <- temp_data %>% rename(
      "donation_amount" = "Amount",
      "donation_date" = "ContributionDate",
      "full_name" = "Contributor"
    )


    temp_data <- temp_data %>%
      separate("CityState", c("city", "state"), sep = ",")
  } else if (state_fin == "ID") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "from_name",
      "full_address" = "from_address",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "state" = "from_state",
      "city" = "from_city",
      "zip" = "from_zip"
    )

    temp_data <- temp_data %>% mutate(donation_date = as.Date(donation_date))
  } else if (state_fin == "KS") {

    temp_data <- temp_data %>%
      mutate_if(is.list, as.character)
    
  } else if (state_fin == "KY") {
    temp_data <- temp_data %>% rename(
      "first_name" = "ContributorFirstName",
      "last_name" = "ContributorLastName",
      "addr1" = "Address1",
      "addr2" = "Address2",
      "donation_amount" = "Amount",
      "donation_date" = "ReceiptDate",
      "state" = "State",
      "city" = "City",
      "zip" = "Zip"
    )
    
    temp_data <- temp_data %>% 
      mutate(donation_date = gsub(" 00:00:00", "", donation_date))
  } else if (state_fin == "LA") {
    temp_data <- temp_data %>% rename(
      "full_name" = "ContributorName",
      "addr1" = "ContributorAddr1",
      "addr2" = "ContributorAddr2",
      "donation_amount" = "ContributionAmt",
      "donation_date" = "ContributionDate",
      "state" = "ContributorState",
      "city" = "ContributorCity",
      "zip" = "ContributorZip"
    )

    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
  } else if (state_fin == "LA_C") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "first_name" = "contributor_first_name",
      "last_name" = "contributor_last_business_name",
      "donation_amount" = "amount_received",
      "donation_date" = "contribution_date",
      "city" = "contributor_city",
      "state" = "contributor_state",
      "zip" = "contributor_zip"
    )


  } else if (state_fin == "MA") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "first_name" = "first_name",
      "last_name" = "name",
      "addr1" = "address",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "zip" = "zip_code"
    )



    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
    temp_data <- temp_data %>%
      mutate(last_name = gsub("\\d+|\\(|\\)|-", "", last_name)) %>%
      mutate(zip = str_extract(zip, "\\d{5}"))
  } else if (state_fin == "MD") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "full_address" = "contributor_address",
      "donation_amount" = "contribution_amount",
      "donation_date" = "contribution_date"
    )
  
    temp_data <- temp_data %>% 
      mutate(first_name = word(full_name, 2, sep = ",") %>% trimws()) %>% 
      mutate(last_name = word(full_name, 1, sep = ",")) %>% 
      mutate(full_name = "") %>% 
      mutate(addr1 = word(full_address, 1, sep = ",")) %>% 
      mutate(addr2 = ifelse(str_count(full_address, ",") == 3, word(full_address, 2, sep = ","), 
                           "")) %>% 
      mutate(city = ifelse(str_count(full_address, ",") == 2, word(full_address, 2, sep = ","), 
                           word(full_address, 3, sep = ","))) %>% 
      mutate(state = ifelse(str_count(full_address, ",") == 2, word(full_address, 3, sep = ","), 
                           word(full_address, 4, sep = ","))) %>% 
      mutate(zip = str_extract(state, "\\d{5}")) %>% 
      mutate(state = str_extract(state, "[A-Z]{2}")) %>% 
      mutate(full_address = "")
    
    
  } else if (state_fin == "MI") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "first_name" = "contributor_first_name_max_len_20",
      "last_name" = "contributor_last_name_organization_max_len_36",
      "full_address" = "contributor_address_max_len_61",
      "donation_amount" = "amount_of_contribution_max_len_13",
      "donation_date" = "date_of_contribution_max_len_10",
      "zip" = "contributor_zip_max_len_10",
      "state" = "contributor_state_max_len_2",
      "city" = "contributor_city_max_len_20"
    )



    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
    temp_data <- temp_data %>%
      mutate(last_name = gsub("\\d+|\\(|\\)|-", "", last_name)) %>%
      mutate(zip = str_extract(zip, "\\d{5}"))
  } else if (state_fin == "MN") {
    temp_data <- temp_data %>% rename(
      "full_name" = "Contributor",
      "addr1" = "Address_Line_1",
      "donation_amount" = "Amount",
      "donation_date" = "Receipt_date",
      "state" = "State",
      "city" = "City",
      "zip" = "Zip_Code"
    )


  } else if (state_fin == "MT") {
      temp_data <- temp_data %>% clean_names()
      
      temp_data <- temp_data %>% rename(
        "full_name" = "contributor_name",
        "addr1" = "contributor_address",
        "donation_amount" = "amount",
        "donation_date" = "date_paid"
      )
      

      
      temp_data <- temp_data %>%
        mutate(city = word(contributor_city_state_zip, 1, sep = " ")) %>%
        mutate(state = word(contributor_city_state_zip, 2, sep = " ")) %>% 
        mutate(zip = str_extract(contributor_city_state_zip, "\\d{5}")) %>%
        mutate(contributor_city_state_zip = '')
    } else if (state_fin == "ME") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor",
      "full_address" = "address",
      "donation_amount" = "amount",
      "donation_date" = "date"
    )



    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount)) %>%
      mutate(zip = str_extract(full_address, "\\d{5}")) %>%
      mutate(state = str_extract(word(full_address, -1, sep = ","), "[A-Z]+")) %>%
      mutate(city = word(full_address, -2, sep = ",")) %>%
      mutate(full_address = word(full_address, 1, sep = ","))
    
    
    
    }else if (state_fin == "MO") {
      temp_data <- temp_data %>% clean_names()
      
      temp_data <- temp_data %>% rename(
        "first_name" = "contributor_first_name",
        "last_name" = "contributor_last_name",
        "addr1" = "address1",
        "donation_amount" = "contribution_amount",
        "donation_date" = "contribution_date"
      )
      
      temp_data <- temp_data %>%
        mutate(donation_amount = gsub("\\$", "", donation_amount)) %>% 
        mutate_if(is.list, as.character) %>% 
        mutate(across(where(is.character), ~ gsub("NaN", "", .)))
      
      
    }else if (state_fin == "NC") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "name",
      "addr1" = "street_line_1",
      "addr2" = "street_line_2",
      "donation_amount" = "amount",
      "donation_date" = "date_occured",
      "zip" = "zip_code"
    )



    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
    temp_data <- temp_data %>% 
      mutate(zip = str_extract(zip, "\\d{5}")) %>% 
      filter(full_name != "Aggregated Individual Contribution") %>% 
      filter(full_name != "Aggregated Non-Media Expenditure") %>%
      mutate_at(c("full_name", "addr1", "city"), str_to_title)
  } else if (state_fin == "ND") {
    temp_data <- temp_data %>% rename(
      "full_name" = "Contributor",
      "addr1" = "Street",
      "donation_amount" = "Amount",
      "donation_date" = "Date",
      "state" = "State",
      "city" = "City",
      "zip" = "Zip"
    )



    temp_data <- temp_data %>%
      mutate(donation_amount = as.numeric(gsub("\\$|,", "", donation_amount))) %>%
      mutate(full_name = gsub(",", "", full_name)) %>%
      mutate(full_name = ifelse(full_name == "", "Null", full_name))
  } else if (state_fin == "NE") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_or_source",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "full_address" = "city_state"
    )


    temp_data <- temp_data %>%
      separate("full_address", c("city", "state"), sep = ",") %>%
      mutate(full_address = "NULL")
  } else if (state_fin == "NJ") {
    temp_data <- temp_data %>% rename(
      "first_name" = "FirstName",
      "last_name" = "LastName",
      "middle_name" = "MI",
      "addr1" = "Street",
      "donation_amount" = "ContributionAmount",
      "donation_date" = "ContributionDate",
      "state" = "State",
      "city" = "City",
      "zip" = "ZIP"
    )



    temp_data <- temp_data %>% mutate(full_name = ifelse(first_name == "", NonIndName, ""))
  } else if (state_fin == "NM") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_payee",
      "donation_amount" = "contribution_amount",
      "donation_date" = "transaction_date",
      "full_address" = "contributor_address"
    )


    
    temp_data <- temp_data %>%
      mutate(full_address = str_replace(full_address, ",,", ",")) %>% 
      mutate(donation_amount = as.numeric(gsub("\\$|,", "", donation_amount))) %>% 
      mutate(full_name = str_replace(full_name, "  ", " "))
  } else if (state_fin == "NYC") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "name",
      "full_address" = "strname",
      "donation_amount" = "amnt",
      "donation_date" = "date"
    )



    temp_data <- temp_data %>%
      mutate(full_address = replace_na("NULL"))
  } else if (state_fin == "NY") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "full_address" = "contributor_address",
      "donation_amount" = "amount",
      "donation_date" = "contribution_date",
      "state" = "contributor_state",
      "city" = "contributor_city",
      "zip" = "contributor_zip"
    )


    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
  } else if (state_fin == "RI") {
    temp_data <- temp_data %>% rename(
      "first_name" = "FirstName",
      "last_name" = "LastName",
      "donation_amount" = "Amount",
      "donation_date" = "ReceiptDate",
      "full_address" = "Address"
    )



    temp_data <- temp_data %>%
      mutate(city = word(CityStZip, sep = ",")) %>%
      mutate(zip = ifelse(str_detect(CityStZip, ".*[0-9].*") == TRUE,
        as.integer(word(CityStZip, -1, sep = " ")), ""
      )) %>%
      mutate(state = ifelse(str_detect(CityStZip, ".*[0-9].*") == FALSE,
        word(CityStZip, -1, sep = " "), word(CityStZip, -2, sep = " ")
      ))
  } else if (state_fin == "OH") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "first_name" = "contributor_first_name",
      "last_name" = "contributor_last_name",
      "middle_name" = "contributor_middle_name",
      "full_name" = "contributor_non_individual",
      "full_address" = "address",
      "donation_amount" = "amount",
      "donation_date" = "contribution_date"
    )



    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
  } else if (state_fin == "OK") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "full_address" = "city_state"
    )


    temp_data <- temp_data %>%
      separate("full_address", c("city", "state"), sep = ",") %>%
      mutate(full_address = "NULL") %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount))
  } else if (state_fin == "OR") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_payee",
      "addr1" = "addr_line1",
      "addr2" = "addr_line2",
      "donation_amount" = "amount",
      "donation_date" = "tran_date",
      "state" = "state",
      "city" = "city",
      "zip" = "zip"
    )


  } else if (state_fin == "PHIL") {
    
    

  } else if (state_fin == "SC") {
    temp_data <- temp_data %>% rename(
      "full_name" = "CONTRIBUTOR",
      "full_address" = "ADDRESS",
      "donation_amount" = "AMOUNT",
      "donation_date" = "CONTRIBUTION_DATE",
      "state" = "STATE",
      "city" = "CITY",
      "zip" = "ZIP"
    )


    temp_data <- temp_data %>%
      mutate(donation_amount = as.integer(donation_amount))
  } else if (state_fin == "TN") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "full_address" = "contributor_address",
      "donation_amount" = "amount",
      "donation_date" = "date"
    )

    temp_data <- temp_data %>%
      mutate(donation_amount = gsub("\\$", "", donation_amount)) %>%
      mutate(full_address = as.character(full_address)) %>%
      mutate(full_address = trimws(full_address)) %>%
      mutate(zip = word(full_address, -1, sep = ",")) %>%
      mutate(state = word(full_address, -2, sep = ",")) %>%
      mutate(city = word(full_address, -3, sep = ",")) %>%
      mutate(full_address = word(full_address, 1, -4))
    
    
  } else if (state_fin == "TX") {
    
    temp_data <- temp_data %>% clean_names()
    
    temp_data <- temp_data %>% rename(
      "donation_amount" = "amount",
      "donation_date" = "date"
    )
    
    temp_data <- temp_data %>% 
      mutate(first_name = trimws(word(contributor_name, 2, sep = ","))) %>% 
      mutate(last_name = trimws(word(contributor_name, 1, sep = ","))) %>% 
      mutate(zip = word(zip, sep = "-"))
    
  } else if (state_fin == "UT") {
    temp_data <- temp_data %>% rename(
      "full_name" = "NAME",
      "addr1" = "ADDRESS1",
      "addr2" = "ADDRESS2",
      "donation_amount" = "TRAN_AMT",
      "donation_date" = "TRAN_DATE",
      "state" = "CITY",
      "city" = "STATE",
      "zip" = "ZIP"
    )


    temp_data <- temp_data %>% filter(addr1 != "")
  } else if (state_fin == "VA") {
    temp_data <- temp_data %>% clean_names()


    temp_data <- temp_data %>% rename(
      "addr1" = "line1",
      "addr2" = "line2",
      "donation_amount" = "amount",
      "donation_date" = "transaction_date",
      "state" = "state",
      "city" = "city",
      "zip" = "zip_code"
    )

    temp_data <- temp_data %>%
      mutate_if(is.list, as.character)
  } else if (state_fin == "VT") {
    temp_data <- temp_data %>% clean_names()


    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "full_address" = "contributor_address",
      "donation_amount" = "amount",
      "donation_date" = "transaction_date"
    )

  } else if (state_fin == "WA") {
    
    temp_data <- temp_data %>%
      filter(contributor_category == 'Individual')
    
    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "addr1" = "contributor_address",
      "donation_amount" = "amount",
      "donation_date" = "receipt_date",
      "city" = "contributor_city",
      "state" = "contributor_state",
      "zip" = "contributor_zip"
    )

    temp_data <- temp_data %>%
     # mutate(donation_date = as.character(gsub("UTC", "", donation_date)))
      mutate(full_name = sub(" ", ", ", full_name, fixed = TRUE)) %>% 
      mutate(donation_date = substr(donation_date, 1, 10))
  } else if (state_fin == "WI") {
    temp_data <- temp_data %>% rename(
      "full_name" = "ContributorName",
      "addr1" = "AddressLine1",
      "addr2" = "AddressLine2",
      "donation_amount" = "ContributionAmount",
      "donation_date" = "TransactionDate",
      "state" = "StateCode",
      "city" = "City",
      "zip" = "Zip"
    )


  } else if (state_fin == "WV") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_recipient",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "full_address" = "address"
    )

    temp_data$donation_amount <- as.numeric(gsub("\\$|,", "", temp_data$donation_amount))
    temp_data <- temp_data %>% 
      filter(is.na(full_address) == F | full_address %in% c("", " "))
    
  } else if (state_fin == "WY") {
    temp_data <- temp_data %>% clean_names()

    temp_data <- temp_data %>% rename(
      "full_name" = "contributor_name",
      "donation_amount" = "amount",
      "donation_date" = "date",
      "full_address" = "city_state_zip"
    )


    temp_data <- temp_data %>%
      mutate(city = word(full_address, 1, sep = ",")) %>%
      mutate(zip = str_extract(full_address, "\\d{5}")) %>%
      mutate(state = word(full_address, 2, sep = ",")) %>%
      mutate(state = str_extract(state, "[A-Z]{2}")) %>%
      mutate(full_name = gsub("\\([A-Za-z]+\\)", "", full_name)) %>%
      mutate(full_address = "NULL")
  }

######### ABBA transforms
  
# Get name cols
  
  name_cols <- c("first_name", "last_name", "full_name")
  
# Add the missing names with empty data
  
  for (abba_col in good_names){
    if (abba_col %in% colnames(temp_data) == FALSE){
      #new_col <- paste0(abba_col)
      temp_data <- temp_data %>% 
        add_column(!!abba_col := "")
    }
  }

# Select only the names we want to keep
  temp_data <- temp_data %>% select(good_names)
  
# Ensure donations aren't in bad format
  temp_data <- temp_data %>%
    mutate(donation_amount = gsub("\\.\\d{2}", "", donation_amount)) %>% # remove decimals
    mutate(donation_amount = as.integer(gsub(",", "", donation_amount))) %>% #integers only
    filter(!is.na(donation_amount) & donation_amount > 0) %>% # remove NA or 0 
    mutate(across(c(first_name, last_name, full_name), ~replace_na(.,""))) %>% # for ABBA rows counts

  return(temp_data)
}
