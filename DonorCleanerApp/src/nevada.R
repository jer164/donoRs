library(rvest)
library(tidyverse)

nevada <- function(input_path) {
  # Read and parse the content using rvest
  
  content <- read_html(input_path)

  table_id <- "ctl04_mobjContributions_dgContributions"
  cont_table <- content %>% html_node(paste0("table[id='", table_id, "']"))
  nv_df <- cont_table %>% html_table(header = 1)

  # Split name and address column
  nv_df <- nv_df %>%
    mutate(
      full_name = sapply(`NAME AND ADDRESS OF PERSON, GROUP OR ORGANIZATION WHO MADE CONTRIBUTION`, function(x) paste0(unlist(strsplit(x, " "))[1:2], collapse = " ")),
      full_address = sapply(`NAME AND ADDRESS OF PERSON, GROUP OR ORGANIZATION WHO MADE CONTRIBUTION`, function(x) paste0(unlist(strsplit(x, " "))[3:length(unlist(strsplit(x, " ")))], collapse = " "))
    )

  # Rename columns and drop unnecessary ones
  nv_df <- nv_df %>%
    rename(
      donation_amount = `AMOUNT OF CONTRIBUTION`,
      donation_date = `DATE OF CONTRIBUTION`
    ) %>%
    select(-`NAME AND ADDRESS OF PERSON, GROUP OR ORGANIZATION WHO MADE CONTRIBUTION`, -`CHECK HERE IF LOAN`, -`NAME AND ADDRESS OF 3rd PARTY IF LOAN GUARANTEED BY 3rd PARTY`, -`NAME AND ADDRESS OF PERSON, GROUP OR ORGANIZATION WHO FORGAVE THE LOAN, IF DIFFERENT THAN CONTRIBUTOR`)

  # Process donation_date and donation_amount columns
  nv_df$donation_date <- substr(nv_df$donation_date, 1, 10)
  nv_df$donation_amount <- gsub("\\$", "", nv_df$donation_amount)
  nv_df$donation_amount <- gsub("\\.", "", nv_df$donation_amount)
  nv_df$donation_amount <- gsub(",", "", nv_df$donation_amount)

  # Filter rows based on regex
  nv_df <- nv_df[!grepl(",", nv_df$full_name) & !grepl("\\.", nv_df$full_name) & !grepl("\\$", nv_df$full_name) & !grepl("\\&", nv_df$full_name) & !grepl("'", nv_df$full_name) & !grepl("\\d+", nv_df$full_name), ]
  nv_df$full_address <- gsub("^[^\\d]*", "", nv_df$full_address)

  # Remove duplicate rows based on full_name column
  nv_df <- nv_df[!duplicated(nv_df$full_name), ]

  return(nv_df)
}
