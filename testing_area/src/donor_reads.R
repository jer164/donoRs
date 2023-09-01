donor_reads <- function(input_path){
  
  library(tools)
  library(xml2)
  library(tidyverse)
  library(readxl)
  library(rvest)

  input_ext <- file_ext(input_path)
  if(input_ext == "xlsx"){
    input_enc <- 'excel'
  } else{
    input_enc <- readr::guess_encoding(input_path)
    input_enc <- input_enc$encoding[1]}
  
  if (input_ext == "xml") {
    tmp_cont <- virginia(input_path) %>% as_tibble()
  } else if (input_ext == "html") {
    tmp_cont <- kansas(input_path) %>% as_tibble()
    if (nrow(tmp_cont) == 0){
      tmp_cont <- missouri(input_path) %>% as_tibble()
      if (colnames(tmp_cont)[1] == "X1"){
        tmp_cont <- maryland(input_path) %>% as_tibble()
      }
    }
  } else if (input_ext == "xls"){
    tmp_cont <- read_xls(input_path) 
  } else if (input_ext == "xlsx"){
    tmp_cont <- read_xlsx(input_path)
  } else if (input_ext == "csv" && input_enc != "UTF-16LE") {
    tmp_cont <- read_csv(input_path) %>% as_tibble()
    if (ncol(tmp_cont) == 1){
      tmp_cont <- read_csv(input_path, skip = 1) %>% as_tibble()
    }
    if (colnames(tmp_cont)[1] == "TRANSACTION SEARCH RESULTS"){
      tmp_cont <- read_csv(input_path, skip = 1) %>% as_tibble()
    }
    if (colnames(tmp_cont)[1] == "Texas Ethics Commission"){
      tmp_cont <- read_csv(input_path, skip = 4) %>% as_tibble()
    }
  } else if (input_ext == "csv" && input_enc == "UTF-16LE") {
    tmp_cont <- read_csv(input_path, locale = readr::locale(encoding = "UTF-16LE")) 
    if (ncol(tmp_cont) == 1)
      tmp_cont <- read_csv(input_path, locale = readr::locale(encoding = "UTF-16LE"), skip = 1)
  } else if (input_ext == "txt") {
    if (detect_delim(input_path) == '\t'){
    tmp_cont <- read_delim(input_path,
                           delim = "\t", escape_double = FALSE,
                           trim_ws = TRUE
    )} else {
    tmp_cont <- read_delim(input_path,
                             delim = "|", escape_double = FALSE,
                             trim_ws = TRUE)
    }
  } 
  
  input_cols <- paste(colnames(tmp_cont), collapse = " ")
  state_fin <- get_result(input_ext, input_enc, input_cols, state_list)
  donor_output <- list(tmp_cont, state_fin)
  

  return(donor_output)
  
}
