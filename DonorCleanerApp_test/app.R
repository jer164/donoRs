# Load libraries

library(shiny)
library(shinythemes)
library(readxl)
library(rvest)
library(tidyverse)
library(lubridate)
library(janitor)
library(stringr)
library(glue)
library(DT)
library(reticulate)
library(XML)
library(shinycssloaders)
library(tools)

### options

options(shiny.maxRequestSize = 100 * 1024^2)

### State Donor Pages

links_data <- read_csv("src/donor_links.csv")

# Define UI for data upload app ----
ui <- navbarPage(
  tags$head(
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "https://fonts.googleapis.com/css?family=Open+Sans:400|Roboto:700|Open+Sans:b&effect=3d-float"
    ),
    tags$link(rel = "shortcut icon", href = "https://img.icons8.com/office/40/us-dollar-circled--v1.png", alt="us-dollar-circled--v1", type = "image/x-icon"),
    tags$style(
      ".shiny-output-error { visibility: hidden; }",
      ".shiny-output-error:before { visibility: hidden; }",
      HTML("
        /* Change background color */
        body {
          background-color: #F5F8FA;
          font-family: 'Open Sans', sans-serif;
          font-weight: 400;
        }
        .title {
        font-family: 'Helvetica Neue', sans-serif;
        font-size: 36px;
        font-weight: bold;
        text-align: center;
        margin-top: 20px;
        margin-bottom: 20px;
        color: #0A4571;
        }
        .well {
          background-color: #D1E6F6;
        }
        .btn-default[download] {
          background-color: #F5D8F4;
          border-color: #0F1823;
        }
        table.dataTable tbody tr:hover {
          background-color: #3C6C89;
          color: white;
        }
        table.dataTable {
          header-color: #FF9925;
          background-color: #ffffff;
        }
        /* Change table size */
        .dataTables_wrapper {
          width: 100%;
          height: 100%;
          overflow-x: auto;
          overflow-y: scroll;
        }
        /* Change button color */
        .btn-primary {
          background-color: #197EF0;
          border-color: #0F1823;
        }
        /* Change selectInput color */
        select {
          background-color: #E5EEF3;
        }
      ")
    ),
  ),

  # App title ----
  title = 'Donors App',
  tabPanel("Donor Formatter",

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

      # Input: Select a file ----
      fileInput("donorfile", "Select a .csv, .txt, .xml, or .html list of contributions",
        multiple = TRUE,
        accept = c(
          "text/csv",
          "text/comma-separated-values,text/plain",
          ".csv",
          ".xml",
          ".html",
          ".xlsx"
        )
      ),
      htmlOutput("donorsize"),
      htmlOutput("usabledonors"),
      htmlOutput("avg_donors"),
      htmlOutput("locations"),
      htmlOutput("missing_zips"),
      # Horizontal line ----
      tags$hr(),

      # Button
      downloadButton("downloadData", "Download"),
      tags$hr(),
      tags$a(href = "https://jer164.github.io/donoRs/", "Need Assistance? Check the User Guide", target = "_blank")
    ),

    # Main panel for displaying outputs ----
    mainPanel(withSpinner(type = getOption("spinner.type", default = 4),
                          image = "https://media.tenor.com/k-PfH9O4EpcAAAAj/money-cash.gif",
                          image.width = 100,
                          image.height = 100,

      # Output: Data file ----
      dataTableOutput("contents")
    )
  ))
),

tabPanel("State Website Links",
         dataTableOutput("statelinks")
    ),

tabPanel("File Checker",
      
  sidebarLayout(
           
           # Sidebar panel for inputs ----
    sidebarPanel(
      
         fileInput("formatted_donorfile", "Select a formatted donor .csv.",
                   multiple = TRUE,
                   accept = c(
                     "text/csv",
                     "text/comma-separated-values,text/plain",
                     ".csv")
         ),
         htmlOutput("test_1"),
         htmlOutput("test_2"),
         htmlOutput("test_3"),
         tags$hr(),
         selectInput("plot_type", "Select Plot Type:",
                     choices = c("Donation Amounts", "State Distribution"),
                     selected = "Donation Amounts")
         
    ),
    mainPanel(
      plotOutput("donorplot")
    ),
  )
  )
)

server <- function(input, output) {
  
  output$statelinks <- renderDataTable({
    # Format the "State" column as hyperlinks using their corresponding "link" value
    formattedlinks <- links_data %>%
      mutate(State = paste0("<a href='", Link, "' target='_blank'>", State, "</a>")) %>%
      select(State, Comments)
    datatable(formattedlinks, escape = FALSE, options = list(dom = 't', pageLength = '50'), rownames = FALSE)
  })
  
  # load source code and dict
  
  source("src/auto_transforms.R")
  source("src/get_result.R")
  source("src/detect_delim.R")
  source("src/donor_reads.R")
  
  output_file_name <- reactive({
    file_name <- input$donorfile$name
    word(file_name, 1, sep = "\\.")
  })
  
  ##### Create reactive dataset for download
  
  datasetInput <- reactive({
    #if (input$state == "PHIL") {
      #donors_df <- donor_cleaner(input$philly_can, state_fin())
    #} else {
      donors_df <- donor_cleaner(input$donorfile$datapath)
    #}
    #if(input$filter_state){
      #donors_df %>% filter(state == state_fin())
    #} else {
     # donors_df
   # }
  })

  #### Create DataTable on Output

  output$contents <- renderDataTable({
    df <- datasetInput() %>%
      select_if(function(x) !(all(is.na(x)) | all(x == ""))) %>% 
      select_if(~!all(. == "NULL"))
    
    datatable(df, options = list(
      pageLength = 5
    ))
  })


  ###### Create download
  output$downloadData <- downloadHandler(
    filename = function() {
      glue("{output_file_name()}_formatted.csv")
    },
    content = function(file) {
      write.csv(datasetInput(), file, row.names = FALSE, na = "")
    }
  )

  output$donorsize <- renderText({
    paste("<b>Number of Donors: </b>", nrow(datasetInput()))
  })

  output$usabledonors <- renderText({
    abba_rows <- sum(datasetInput()$full_name != "" | datasetInput()$first_name != "" & datasetInput()$last_name != "")
    paste("<b>ABBA-Friendly Donors: </b>", abba_rows)
  })
  output$avg_donors <- renderText({
    paste("<b>Average Donation Amount: </b>", round(mean(datasetInput()$donation_amount), 3))
  })

  output$locations <- renderText({
    paste("<b>Most Frequent State: </b>", datasetInput() %>% 
            count(state) %>% slice_max(n = 1, order_by = n) %>% pull(state))
  })

  output$missing_zips <- renderText({
    paste("<b>Missing Zips: </b>", datasetInput() %>% pull(zip) %>% anyNA())
  })

  ### Testing file integrity of formatted contributions
  
  fileCheckInput <- reactive({
    testingfile <- read_csv(input$formatted_donorfile$datapath) %>% as_tibble()
  })
  
  output$test_1 <- renderText({
    paste("<b>List of Candidate's Contributions: </b>", all(duplicated(fileCheckInput()$first_name)))
  }) 
  
  output$test_2 <- renderText({
    paste("<b>Number of Columns: </b>", ncol(fileCheckInput()))
  })
  
  output$test_3 <- renderText({
    bad_addresses <- fileCheckInput() %>% 
      filter((full_address == "" & addr1 == "") | (addr1 != "" & zip == "")) %>% 
      nrow()
    if(bad_addresses > nrow(fileCheckInput())/2){
      paste("<b>Possible Address Issues:ues: </b>")
    }
    else{
      paste("<b>Possible Address Issues: </b> No") 
    }
  })
  
  output$donorplot <- renderPlot({
    if(input$plot_type == "Donation Amounts"){
      hist(fileCheckInput()$donation_amount, main = "Histogram of Donations", xlab = "Amounts", 
         ylab = "Frequency", col = "#0b0666")}
    else if(input$plot_type == "State Distribution"){
      state_freqs <- table(fileCheckInput()$state)
      barplot(state_freqs, main = "State Frequencies", xlab = "State", 
           ylab = "Count", col = "#d9a807")}
  })

}



# Run the application
shinyApp(ui = ui, server = server)
