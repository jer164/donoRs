
headers <- read_csv("src/column_headers.csv")

headers <- headers %>% clean_names() %>%  
  mutate(bad_name = str_replace_all(bad_name, '"', "")) %>% 
  mutate(bad_name = str_replace_all(bad_name, ',', '')) %>% 
  mutate(bad_name = make_clean_names(bad_name, allow_dupes = TRUE)) %>% 
  group_by(correct_name) %>% 
  summarize(unique_bad_names = list(unique(bad_name)))

save(headers, file = "src/headers_list.Rdata")

save(headers, file = "~/donoRs/DonorCleanerApp_test/src/headers_list.Rdata")
