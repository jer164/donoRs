data_detector <- function(input_path){
  
  # bring in ABBA-friendly names
  
  good_names <- c("donation_date", "donation_amount",	"full_name", "addr1", 
                  "city",	"state","zip", "full_address", "first_name", "middle_name",	
                  "last_name", "addr2",	"phone1",	"phone2",	"email1",	"email2")
  

  
}


library(readr)
library(tidyverse)


dickens <- read_csv("~//Documents/Data_Projects/donoRs/test_data/dickens_testing.csv")
sherrod_brown <- read_csv("~//Documents/Data_Projects/donoRs/test_data/sherrod_brown.csv")
eric_adams <- read_csv("~//Documents/Data_Projects/donoRs/test_data/eric_adams_test.csv")
df_path = "~//Documents/Data_Projects/donoRs/test_data/eric_adams_test.csv"
names_detection <- read_csv("~//Documents/Data_Projects/donoRs/test_data/NationalNames.csv", 
                            col_types = cols(Id = col_skip(), Year = col_skip(), 
                                             Gender = col_skip(), Count = col_skip()))

##### Mac Files
eric_adams <- read_csv("~/Documents/donors/donoRs/test_data/eric_adams_test.csv")
df_path = "/Users/jackson/Documents/donor_for_cleaning/kevin_stitt.csv"
names_detection <- read_csv("~/Documents/donors/donoRs/test_data/NationalNames.csv", 
                          col_types = cols(Id = col_skip(), Year = col_skip(), 
                                           Gender = col_skip(), Count = col_skip()))

donors <- function(input_path){
  
  good_names <- c("donation_date", "donation_amount",	"full_name", "addr1", 
                  "city",	"state","zip", "full_address", "first_name", "middle_name",	
                  "last_name", "addr2",	"phone1",	"phone2",	"email1",	"email2")
  
  df <- read_csv(input_path) %>% 
    mutate_all(as.character) %>% 
    mutate(across(everything(), gsub, pattern = "[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]{1,3})?", replacement = ""))

  for (i in 1:ncol(df)){
    
      tmp <- pull(df[i])
      
      ### Address Detection
      
      tmp_result <- str_detect(tmp,"([A-Za-z]+)?,?\\s([A-Za-z]+)?\\s([0-9]+)")
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      if (sum(tmp_result)/length(tmp_result) > .70) {
        
        tmp_city <- word(tmp, 1, sep = ' ')
        tmp_state <- word(tmp, 2, sep = ' ')
        tmp_zip <- str_extract(tmp,"\\d{5}+")
        
        df <- df %>% 
          rename(addr1 = i) %>% 
          mutate(city = tmp_city) %>% 
          mutate(state = tmp_state) %>% 
          mutate(zip = tmp_zip)
        
        next
        
      }
      
      tmp_result <- str_detect(tmp,"[0-9]+\\s([A-Za-z]+( [A-Za-z]+)+)")
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      if (sum(tmp_result)/length(tmp_result) > .70) {
        
        df <- df %>% 
          rename(addr1 = i)
        
        next
        
      }
      
      if (str_detect(colnames(df[i]), "city|City|CITY") == TRUE &
          'city' %in% colnames(df) == FALSE){
        
        df <- df %>% 
          rename(city = i)
        
        next
        
      }
      
      
      if (str_detect(colnames(df[i]), "state|State|STATE") == TRUE & 
          'state' %in% colnames(df) == FALSE){
        
        df <- df %>% 
          rename(state = i)
        
        next
        
        
      }
      
      if (str_detect(colnames(df[i]), "zip|Zip|ZIP") == TRUE & 
          'zip' %in% colnames(df) == FALSE){
        
        df <- df %>% 
          rename(zip = i)
        
        next
        
      }
      
      
      ### Amount Detection
      
      tmp_result <- colnames(df[i])
      
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      else if (str_detect(tmp_result, 'amount|Amount|^AMNT$') == TRUE) {
        
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
      
      tmp_result <- str_detect(tmp, "^([A-Za-z]+)?(\\s|\\,)?\\s([A-Za-z]+)$")
      
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      ### Workaround for Middle Names
      
      if (str_detect(colnames(df[i]), "middle|Middle") == TRUE){
        
        df <- df %>% 
          rename(middle_name = i)
        
        next
        
      }
      
      if (sum(tmp_result)/length(tmp_result) > .60 & 'full_name' %in% colnames(df) == FALSE) {
        
        df <- df %>% 
          rename(full_name = i)
        
        next
        
      }
      
      ### Search for remaining names
        
      tmp_result <- str_to_title(word(na.omit(tmp), 1)) %in% names_detection$Name
      
      if (anyNA(tmp_result) == TRUE){
        
        tmp_result <- replace_na(tmp_result, FALSE)
        
      }
      
      
      if ("first_name" %in% colnames(df) == TRUE &
          str_detect(colnames(df[i]), "last|Last") == TRUE){
        
        df <- df %>% 
          rename(last_name = i)
        
        next
        
      }
      
      else if (sum(tmp_result)/length(tmp_result) > .80 &
               "first_name" %in% colnames(df) == FALSE &
               "full_name" %in% colnames(df) == FALSE){
        
        df <- df %>% 
          rename(first_name = i)
        
        next
        
      }
      
      ### Date detection
      
      tmp_result <- str_extract(tmp, "^([0-9]{4})\\-([0-9]{2})\\-([0-9]{2})$|^([0-9]+)/([0-9]+)/([0-9]{4})$")
      
      
      if (length(unique(tmp_result)) > 5){
        
        df <- df %>% 
          rename(donation_date = i)
        
      }
      
      
  }
  
  
  for (col in 1:length(good_names)){
    
    if (good_names[col] %in% colnames(df) == FALSE){
      
      tmp_col <- good_names[col]
      
      df[paste0(tmp_col)] <- ''
      
    }
    
    
  }
  
  
  df <- df %>%
    mutate(donation_amount = gsub("\\$", '', donation_amount)) %>% 
    select(good_names)
  
  return(df)

}

test <- donors(df_path)
write.csv(test, "test_data/new_cleaned_adams.csv")




str_detect(colnames(eric_adams), 'amount|Amount|AMNT')







