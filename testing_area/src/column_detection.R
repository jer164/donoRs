#### Testing Column Auto-Detection

library(tidyverse)
library(reticulate)
library(glue)
library(tools)
options(readr.show_col_types = FALSE)

getwd()

source("src/auto_transforms.R")
source("src/detect_delim.R")
source("src/donor_reads.R")
source("src/get_result.R")
load("src/state_list.Rdata")
load("src/headers_list.Rdata")



############# 
# new detection method: dictionary of possible names

wd_path <- getwd()
test_data_path <- glue("{wd_path}/states")
dirs <- list.dirs(test_data_path, full.names = F)
dirs <- dirs[-1]

test_file_path <- list.files(glue("{test_data_path}/FEC"), full.names = T)[1]
test_file_path <- str_to_lower(test_file_path)
tmp_df <- donor_reads(test_file_path)[[1]] %>% clean_names()

### check for colname matches and rename appropriately 

abba_names <- c(
  "donation_date", "donation_amount", "full_name", "addr1",
  "city", "state", "zip", "full_address", "first_name", "middle_name",
  "last_name", "addr2", "phone1", "phone2", "email1", "email2"
)

tmp_col_name_list <- c()

col_finder <- function(input_col) {
  for (row in 1:nrow(headers)){
    if (input_col %in% headers$unique_bad_names[[row]]){
      good_col_name <- headers$correct_name[row]
      print(glue("{input_col} renamed to {good_col_name}"))
      break
    }
    else{
      good_col_name <- input_col
    }
  }
  return(good_col_name)
}
col_renamer <- function(df) {
  for (bad_col in colnames(df)){
    new_col <- col_finder(bad_col)
    if(new_col %in% colnames(df) == F)
    df <- df %>% 
      rename(!!new_col := !!bad_col)
  }
  return(df)
}
abba_formats <- function(df, names_list) {
  
  for (abba_col in names_list){
    if (abba_col %in% colnames(df) == FALSE){
      df <- df %>% 
        add_column(!!abba_col := "")
    }
  }
  df <- df %>% select(all_of(names_list))
  return(df)
}

df_list <- list()
for (state in dirs){
  
  test_file_path <- list.files(glue("{test_data_path}/{state}"), full.names = T)[1]
  test_file_path <- str_to_lower(test_file_path)
  tmp_df <- donor_reads(test_file_path)[[1]] %>% clean_names()
  tmp_df <- tmp_df %>% col_renamer() %>% abba_formats(abba_names)
  df_list[[state]] <- tmp_df
  
}

#############################
### Build function to find column-name characteristics

# location_col_chars <- c("state", "city", "address", "address 2", "zip")
# name_col_chars <- c("full name", "first", "last", "middle")
# amount_col_chars <- c("amount")
# date_col_chars <- c("date")
# chars_list <- list(location_col_chars, name_col_chars, amount_col_chars, date_col_chars)

# state_cols_test <- list()
#
# for (state in dirs){
#
#   print(glue("Working on {state}"))
#
#   test_file_path <- list.files(glue("{test_data_path}/{state}"), full.names = T)[1]
#   test_file_path <- str_to_lower(test_file_path)
#
#   tmp_test <- donor_reads(test_file_path)
#   temp_data <- tmp_test[[1]]
#   state_source <- tmp_test[[2]]
#
#
#   matching_columns_indices <- c()
#   for (items in chars_list) {
#
#     for (chars in items){
#
#     matching_columns_indices <- c(matching_columns_indices, grep(chars, colnames(temp_data), ignore.case = TRUE))
#
#     }
#
#
#   }
#
#   matched_cols <- colnames(temp_data)[matching_columns_indices]
#   test_subset <- temp_data %>% select(all_of(matched_cols))
#
#   spec_date_chars <- c("receipt", "cont")
#
#   if (length(grep(date_col_chars, colnames(test_subset), ignore.case = TRUE) > 0)){
#
#     date_col_ind <- grep(date_col_chars, colnames(test_subset), ignore.case = TRUE)
#
#     for (char in spec_date_chars){
#
#       incorrect_date_cols <- grep(char, colnames(test_subset)[date_col_ind], ignore.case = TRUE, invert = T, value = T)
#
#     }
#   }
#
#   red_test_subset <- test_subset %>% select(-all_of(incorrect_date_cols))
#   final_cols <- colnames(red_test_subset)
#   state_cols_test[[paste(final_cols, collapse = " ")]] <- state_source
#
#   Sys.sleep(0.1)
# }
#############################


