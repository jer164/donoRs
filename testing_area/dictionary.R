### Script for dictionary

library(tidyverse)
library(glue)
library(hash)

source("/Users/jacksonrudoff/donoRs/testing_area/src/kansas.R")
source("/Users/jacksonrudoff/donoRs/testing_area/src/missouri.R")

virtualenv_create(envname = "python_environment", python = "python3")
virtualenv_install("python_environment", packages = c("pandas", "lxml", "bs4", "requests"))
reticulate::use_virtualenv("python_environment", required = TRUE)
reticulate::source_python("/Users/jacksonrudoff/donoRs/testing_area/src/virginia.py", convert = TRUE)



### Grab folders

path <- getwd()
dirs <- list.dirs(path, full.names = F)
dirs <- dirs[-1]
state_list <- list()

for (state in dirs){
  
  state_dir <- glue("{path}/{state}")
  input_path <- list.files(state_dir, full.names = T)[1]
  
  if (state == "VA") {
    tmp_cont <- virginia(input_path) %>% as_tibble()
  } else if (state == "KS") {
    tmp_cont <- kansas(input_path) %>% as_tibble()
  } else if (state == "MO") {
    tmp_cont <- missouri(input_path) %>% as_tibble()
  } else if (state == "NM" | state == "WV" | state == "AR") {
    tmp_cont <- read_csv(input_path, skip = 1) %>% as_tibble()
  } else if (state == "DC") {
    tmp_cont <- read_csv(input_path, 
                         skip = 1, locale = readr::locale(encoding = "UTF-16LE")) %>% as_tibble()
  } else if (state == "MA" | state == "MI" | state == "FL") {
    tmp_cont <- read_delim(input_path,
                           delim = "\t", escape_double = FALSE,
                           trim_ws = TRUE
    )
  } else if (state == "MT") {
    tmp_cont <- read_delim(input_path,
                           delim = "|", escape_double = FALSE, trim_ws = TRUE
    )
  } else if (state == "MD") {
    tmp_cont <- rvest::read_html(input_path) %>% html_table()
    tmp_cont <- tmp_cont[[1]] %>% as_tibble()
    colnames(tmp_cont) <- tmp_cont[1,]
    tmp_cont <- slice(tmp_cont, -1)
  } else if (state == "TX"){
    tmp_cont <- read_csv(input_path, skip = 4) 
  } else if (state == "OR"){
    tmp_cont <- read_xls(input_path) 
  } else if (state == "SC"){
    tmp_cont <- read_xlsx(input_path)
  } else if (state == "AZ") {
    tmp_cont <- read_csv(input_path, locale = readr::locale(encoding = "UTF-16LE")) 
  } else{
    tmp_cont <- read_csv(input_path)
  }
  
  input_ext <- str_to_lower(file_ext(input_path))
  tmp_cols <- paste(colnames(tmp_cont), collapse = " ")
  if(input_ext == "xlsx"){
    tmp_enc <- 'excel'
  } else{
  tmp_enc <- guess_encoding(input_path)
  tmp_enc <- tmp_enc$encoding[1]
  }
  state_list[[paste(input_ext, tmp_enc, tmp_cols)]] <- state
  
}

#test_path <- "/Users/jacksonrudoff/donoRs/testing_area/states/AL/James_Donors_AL.csv"
#test_file <- read_csv("/Users/jacksonrudoff/donoRs/testing_area/states/AL/James_Donors_AL.csv")

#test_ext <- file_ext(test_path)
#test_cols <- paste(colnames(test_file), collapse = " ")
#if(input_ext == "xlsx"){
#  tmp_enc <- 'excel'
#} else{
#  test_enc <- guess_encoding(test_path)
#  test_enc <- test_enc$encoding[1]}

#### FUNCTION TO GET VALUE MATCHES

get_result <- function(ext, enc, cols, key_list) {
  key <- paste(ext, enc, cols)
  if (key %in% names(key_list)) {
    return(key_list[[key]])
  } else {
    return(NULL)  # Return NULL or any other default value if not found
  }
}


save(state_list, file = "/Users/jacksonrudoff/donoRs/DonorCleanerApp_test/src/state_list.Rdata")

















