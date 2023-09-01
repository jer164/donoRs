get_result <- function(ext, enc, cols, key_list) {
  key <- paste(ext, enc, cols)
  if (key %in% names(key_list)) {
    return(key_list[[key]])
  } else {
    return(NULL)  # Return NULL or any other default value if not found
  }
}