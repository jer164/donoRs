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