detect_delim <- function(input_file){

  
  sample_lines <- readLines(input_file, n = 10)  # Read 5 lines from each file

  potential_delimiters <- c("\t", "|")  # Add more delimiters if needed

  detected_delimiter <- NULL
  for (delimiter in potential_delimiters) {
    if (all(grepl(delimiter, sample_lines))) {
      detected_delimiter <- delimiter
      break
    }
  }
  
  return(detected_delimiter)

}
