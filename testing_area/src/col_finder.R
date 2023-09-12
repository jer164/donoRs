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