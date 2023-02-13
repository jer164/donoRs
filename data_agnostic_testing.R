data_detector <- function(input_path){
  
  # bring in ABBA-friendly names
  
  good_names <- c("donation_date", "donation_amount",	"full_name", "addr1", 
                  "city",	"state","zip", "full_address", "first_name", "middle_name",	
                  "last_name", "addr2",	"phone1",	"phone2",	"email1",	"email2")
  

  
}


library(readr)
library(tidyverse)
dickens <- read_csv("~//Documents/Data_Projects/donoRs/test_data/dickens_testing.csv")
df_path = "~//Documents/Data_Projects/donoRs/test_data/dickens_testing.csv"
names_detection <- read_csv("~//Documents/Data_Projects/donoRs/test_data/NationalNames.csv", 
                          col_types = cols(Id = col_skip(), Year = col_skip(), 
                                           Gender = col_skip(), Count = col_skip()))

donors <- function(input_path){
  
  df <- read_csv(input_path)

  for (i in 1:ncol(df)){
    
      tmp <- pull(df[i])
      
      ### Address Detection
      
      tmp_result <- str_detect(tmp,"([A-Za-z]+)?,?\\s([A-Za-z]+)?\\s([0-9]+)")
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      else if (sum(tmp_result)/length(tmp_result) > .70) {
        
        tmp_city <- word(tmp, 1, sep = ' ')
        tmp_state <- word(tmp, 2, sep = ' ')
        tmp_zip <- str_extract(tmp,"\\d{5}+")
        
        df <- df %>% 
          rename(addr1 = i) %>% 
          mutate(city = tmp_city) %>% 
          mutate(state = tmp_state) %>% 
          mutate(zip = tmp_zip)
        
        
      }
      
      
      ### Amount Detection
      
      tmp_result <- str_detect(tmp,"\\$")
      
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      else if (sum(tmp_result)/length(tmp_result) > .70) {
        
        df <- df %>% 
          rename(donation_amount = i)
        
        next
        
      }
      
      ### Name Detection
      
      
      ### Exclude Recipient
      
      if (sum(duplicated(tmp)/length(tmp)) > .99){
        
        next
        
      }
      
      ### Search for full_name
      
      tmp_result <- str_detect(tmp, "([A-Za-z]+)\\s([A-Za-z]+)$")
      
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      else if (sum(tmp_result)/length(tmp_result) > .60) {
        
        df <- df %>% 
          rename(full_name = i)
        
        next
        
      }
        
      tmp_result <- str_to_title(na.omit(tmp)) %in% names_detection$Name
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      if ("first_name" %in% colnames(df) == TRUE){
        
        df <- df %>% 
          rename(last_name = i)
        
      }
      
      else if (sum(tmp_result)/length(tmp_result) > .50) {
        
        df <- df %>% 
          rename(first_name = i)
        
        next
        
      }
      
      ### Date detection
      
      if (class(tmp) == 'Date'){
        
        df <- df %>% 
          rename(donation_date = i)
        
      }
      
      
  }
  
  df <- df %>% 
    mutate(donation_amount = gsub("\\$", '', donation_amount))
  
  return(df)

}

test <- donors(df_path)




