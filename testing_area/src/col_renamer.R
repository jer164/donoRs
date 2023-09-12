col_renamer <- function(df) {
  for (bad_col in colnames(df)){
    new_col <- col_finder(bad_col)
    if(new_col %in% colnames(df) == F)
      df <- df %>% 
        rename(!!new_col := !!bad_col)
  }
  return(df)
}