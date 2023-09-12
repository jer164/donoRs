col_renamer <- function(df) {
  
  for (bad_col in colnames(df)) {
    new_col <- col_finder(bad_col)
    if (new_col %in% colnames(df) == F) {
      df <- df %>%
        rename(!!new_col := !!bad_col)
    }
  }
  address_checks <- c("state", "city", "zip")
  if ("addr1" %in% colnames(df)){
    reg_pattern <- "\\d{5}$"
    addr_matches <- replace_na(str_detect(df$addr1, reg_pattern), FALSE)
    if ((any(address_checks %in% colnames(df)) == F) & (sum(addr_matches)/nrow(df) > .75)){
    print("Incorrect addr1 detected. Renaming to full_address.")
    df <- df %>%
      rename("full_address" = "addr1")
    }
  }

  return(df)
}
