library(reticulate)


reticulate::source_python("~/Documents/donors/donoRs/DonorCleaner/virginia.py", convert = TRUE)


df <- virginia("/Users/jackson/Documents/xml_testing/virginia.xml") %>% as_tibble()


reticulate::py_config()
