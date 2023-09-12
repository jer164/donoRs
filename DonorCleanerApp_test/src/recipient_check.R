recipient_check <- function(df){
  
  for (test_col in colnames(df)){
    
    if (n_distinct(df %>% select(test_col)) == 1){
      print(test_col)
      tmp_name <- paste0("false_", test_col)
      df <- df %>% 
        rename(!!tmp_name := !!test_col)
    }
  }
  return(df)
}
