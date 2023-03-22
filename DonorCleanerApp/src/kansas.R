kansas <- function(input_path) {
  
  html <- read_html(input_path)
  
  names <- html_nodes(html, "[id^='lblContributor_']") %>%
    html_text()
  
  address1 <- html_nodes(html, "[id^='lblAddress_']") %>%
    html_text()
  
  address2 <- html_nodes(html, "[id^='lblAddress2_']") %>%
    html_text()
  
  cities <- html_nodes(html, "[id^='lblCity_']") %>%
    html_text()
  
  states <- html_nodes(html, "[id^='lblState_']") %>%
    html_text()
  
  zips <- html_nodes(html, "[id^='lblZip_']") %>%
    html_text()
  
  dates <- html_nodes(html, "[id^='lblDate_']") %>%
    html_text()
  
    html_text() %>%
    str_replace_all("\\$", "") # removes the '$' sign from the amounts
  
  donors_df <- tibble(
    full_name = names,
    addr1 = address1,
    addr2 = address2,
    city = cities,
    state = states,
    zip = zips,
    donation_date = dates,
    donation_amount = amounts
  ) 
  
  return(donors_df)
}
