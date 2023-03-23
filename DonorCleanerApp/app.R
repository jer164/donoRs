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

### options

options(shiny.maxRequestSize = 30 * 1024^2)

# Define UI for data upload app ----
ui <- fluidPage(
  tags$style(
    type = "text/css",
    ".shiny-output-error { visibility: hidden; }",
    ".shiny-output-error:before { visibility: hidden; }",
    HTML("
      /* Change background color */
      body {
        background-color: #FAFAFA;
        font-family: 'Helvetica', sans-serif;
      }
      .well {
        background-color: #B2C7DF;
      }
      .btn-default[download] {
        background-color: #3498db;
        border-color: #3498db;
      }
      table.dataTable tbody tr:hover {
        background-color: #3498db;
        color: white;
      }
      table.dataTable {
        background-color: #f7f7f7;
      }
      /* Change table size */
      .dataTables_wrapper {
        width: 100%;
        height: 100%;
        overflow-x: auto;
        overflow-y: scroll;
      }
      /* Change font size */
      h1, h2, h3, h4, h5, h6 {
        font-size: 1.5em;
      }
      .title.panel-title {
        font-size: 48px;
      }
      /* Change button color */
      .btn-primary {
        background-color: ##197EF0;
        border-color: #0B1E33;
      }
    ")
  ),

  # App title ----
  titlePanel("Donor Formatter"),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(



      # Input: Select a file ----
      fileInput("donorfile", "Select a .csv, .txt, .xml, or .html Donor File",
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
      selectInput(
        "state",
        "Source:",
        list(
          `National` = list("FEC" = "FEC"),
          `City` = list(
            "Atlanta" = "ATL",
            "Detroit" = "DET",
            "Los Angeles" = "LA_C",
            "New York City" = "NYC",
            "Philadelphia" = "PHIL"
          ),
          `State` = list(
            "Alabama" = "AL",
            "Alaska" = "AK",
            "Arizona" = "AZ",
            "California" = "CA",
            "Colorado" = "CO",
            "Connecticut" = "CT",
            "Delaware" = "DE",
            "Florida" = "FL",
            "Georgia (Transactions)" = "GA",
            "Georgia (Finance Report)" = "GA_old",
            "Hawaii" = "HI",
            "Idaho" = "ID",
            "Illinois" = "IL",
            "Indiana" = "IN",
            "Iowa" = "IA",
            "Kansas" = "KS",
            "Kentucky" = "KY",
            "Louisiana" = "LA",
            "Maine" = "ME",
            "Massachusetts" = "MA",
            "Maryland" = "MD",
            "Michigan" = "MI",
            "Missouri" = "MO",
            "Montana" = "MT",
            "Nebraska" = "NE",
            "New Jersey" = "NJ",
            "New Mexico" = "NM",
            "New York" = "NY",
            "North Carolina" = "NC",
            "North Dakota" = "ND",
            "Ohio" = "OH",
            "Oklahoma" = "OK",
            "Oregon" = "OR",
            "Rhode Island" = "RI",
            "South Carolina" = "SC",
            "Tennessee" = "TN",
            "Texas" = "TX",
            "Utah" = "UT",
            "Virginia" = "VA",
            "Vermont" = "VT",
            "Washington" = "WA",
            "West Virginia" = "WV",
            "Wisconsin" = "WI",
            "Wyoming" = "WY"
          )
        ),
        selected = "Alabama",
      ),
      conditionalPanel(
        condition = "input.state == 'PHIL'",
        textInput("philly_can", "Philadelphia Candidate")
      ),

      # Button
      downloadButton("downloadData", "Download"),
      tags$hr(),
      tags$a(href = "https://jer164.github.io/donoRs/", "Need Assistance? Check the User Guide", target = "_blank")
    ),

    # Main panel for displaying outputs ----
    mainPanel(

      # Output: Data file ----
      dataTableOutput("contents")
    )
  )
)


server <- function(input, output) {
  source("src/transforms.R")
  
  output_file_name <- reactive({
    file_name <- input$donorfile$name
    substr(file_name, 1, nchar(file_name) - 4)
  })

  candidate <- reactive({
    input$philly_can
  })

  state_fin <- reactive({
    input$state
  })

  #### Create DataTable on Output

  output$contents <- renderDataTable({
    df <- datasetInput() %>%
      select_if(function(x) !(all(is.na(x)) | all(x == ""))) %>% 
      select_if(~!all(. == "NULL"))
    datatable(df, options = list(
      pageLength = 5 # Set the height to 300px
    ))
  })

  ##### Create reactive dataset for download


  datasetInput <- reactive({
    if (input$state == "PHIL") {
      donors_df <- donor_cleaner(input$philly_can, state_fin())
    } else {
      donors_df <- donor_cleaner(input$donorfile$datapath, state_fin())
    }
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
}

# Run the application
shinyApp(ui = ui, server = server)
