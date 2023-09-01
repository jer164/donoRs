### Getting Data in for ML Schema Prediction

library(tidyverse)
library(glue)
library(caret)
library(randomForest)
library(tm)

# Identify columns that might contain donation amounts based on shared traits

### MAYBE ADD TRY-READ LOGIC TO DETECT NON-UTF-8??


path <- getwd()
dirs <- list.dirs(path, full.names = F)
dirs <- dirs[-1]
tmp_filenames <- NULL

df <- tibble(
  columns = character(), freq_state = character(),
  freq_city = character(), extension = character(), state_source = character()
)
shared_traits_st <- c("state", "st", "contributor state")
shared_traits_city <- c("city", "contributor city")
state_column <- NULL

for (folder in dirs) {
  tmp_filenames <- list.files(glue("~/donoRs/testing_area/states/{folder}"), full.names = T)

  for (file in tmp_filenames) {
    
    print(glue("Reading in {file}"))
    
    if (folder == "AZ") {
      tmp <- read.csv(file, fileEncoding = "UTF-16LE")
    } else {
      tmp <- read_csv(file, show_col_types = FALSE)
    }

    for (trait in shared_traits_st) {
      matching_columns <- grep(trait, colnames(tmp), ignore.case = TRUE)

      if (length(matching_columns) > 0) {
        state_column <- colnames(tmp)[matching_columns[1]] # Take the first match
        break
      } else {
        state_column <- NULL
      }
    }
    if (is.null(state_column) != T) {
      st_table <- table(tmp[state_column])
      freq_st <- names(st_table)[which.max(st_table)]
      if (is.null(freq_st)){
        freq_st <- "None"
      }
    }
    if (length(str_split_1(freq_st, pattern = ",")) > 1) {
      freq_st <- word(freq_st, 2, sep = ",")
    }

    for (trait in shared_traits_city) {
      matching_columns <- grep(trait, colnames(tmp), ignore.case = TRUE)

      if (length(matching_columns) > 0) {
        city_column <- colnames(tmp)[matching_columns[1]] # Take the first match
        break
      } else {
        city_column <- NULL
      }
    }
    if (is.null(city_column) != T) {
      city_table <- table(tmp[city_column])
      freq_cit <- names(city_table)[which.max(city_table)]
    }
    if (is.null(freq_cit)){
      freq_cit <- "None"
    }
    if ((length(str_split_1(freq_cit, pattern = ",")) > 1 )) {
      freq_cit <- word(freq_cit, 1, sep = ",")
    }
    
    try_read <- try(read_csv(file, 
                             locale = locale(encoding = "UTF-8"), show_col_types = F))
    
    if (inherits(try_read, "try-error")){
      tmp_ext <- "UTF-16 csv"
    }
    else{
      tmp_ext <- "UTF-8 csv"
    }


    tmp_df <- tibble(
      columns = paste(colnames(tmp), collapse = ", "),
      freq_state = freq_st,
      freq_city = freq_cit,
      extension = tmp_ext,
      state_source = word(file, 7, sep = "/")
    )
    df <- bind_rows(df, tmp_df)
  }
}



df <- df %>%
  mutate(freq_state = ifelse(freq_state == "", "None", freq_state)) %>%
  mutate(freq_state = trimws(freq_state)) %>%
  mutate(freq_city = ifelse(freq_city == "" | freq_city == " ", "None", freq_city)) %>%
  mutate(freq_city = trimws(freq_city)) %>% 
  mutate(across(c(freq_city, extension), str_to_lower)) %>% 
  mutate(across(c(state_source, freq_state, freq_city), as.factor))

simp_df <- df %>% select(columns, state_source)

# Set up Classification Model

set.seed(123) # For reproducibility
splitIndex <- createDataPartition(df$state_source, p = 0.7, list = FALSE)
train_data <- df[splitIndex, ]
test_data <- df[-splitIndex, ]

dt_model <- train(state_source ~ ., data = train_data, method = "rpart")
dt_pred <- predict(dt_model, newdata = test_data)
confusionMatrix(dt_pred, test_data$state_source)
