#### Testing Column Auto-Detection

library(tidyverse)
library(reticulate)
library(glue)
library(tools)

setwd("~//Documents/Data_Projects/donoRs/testing_area")

source("src/auto_transforms.R")
source("src/detect_delim.R")
source("src/donor_reads.R")
source("src/get_result.R")
load("src/state_list.Rdata")


wd_path <- getwd()
test_data_path <- "~//Documents/Data_Projects/donoRs/testing_area/states"
dirs <- list.dirs(test_data_path, full.names = F)
dirs <- dirs[-1]



### Build function to find column-name characteristics

location_col_chars <- c("state", "city", "address", "address 2", "zip")
name_col_chars <- c("full name", "first", "last", "middle")
amount_col_chars <- c("amount")
date_col_chars <- c("date")
chars_list <- list(location_col_chars, name_col_chars, amount_col_chars, date_col_chars)

state_cols_test <- list()

for (state in dirs){
  
  test_file_path <- list.files(glue("{test_data_path}/{state}"), full.names = T)[1]
  test_file_path <- str_to_lower(test_file_path)

  tmp_test <- donor_reads(test_file_path)
  temp_data <- tmp_test[[1]]
  state_source <- tmp_test[[2]]
  
  
  matching_columns_indices <- c()
  for (items in chars_list) {
    
    for (chars in items){
      
    matching_columns_indices <- c(matching_columns_indices, grep(chars, colnames(temp_data), ignore.case = TRUE))
    
    }
    
    
  }
  
  matched_cols <- colnames(temp_data)[matching_columns_indices]
  test_subset <- temp_data %>% select(all_of(matched_cols))
  
  spec_date_chars <- c("receipt", "cont")
  
  if (length(grep(date_col_chars, colnames(test_subset), ignore.case = TRUE) > 0)){
    
    date_col_ind <- grep(date_col_chars, colnames(test_subset), ignore.case = TRUE)
    
    for (char in spec_date_chars){
      
      incorrect_date_cols <- grep(char, colnames(test_subset)[date_col_ind], ignore.case = TRUE, invert = T, value = T)
    
    }
  }
  
  red_test_subset <- test_subset %>% select(-all_of(incorrect_date_cols))
  final_cols <- colnames(red_test_subset)
  state_cols_test[[paste(final_cols, collapse = " ")]] <- state_source
  
}




