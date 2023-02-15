#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(lubridate)
library(janitor)
library(stringr)
library(DT)
library(reticulate)
library(XML)

### options

options(shiny.maxRequestSize=30*1024^2)

# Define UI for data upload app ----
ui <- fluidPage(
  
  tags$style(type="text/css",
             ".shiny-output-error { visibility: hidden; }",
             ".shiny-output-error:before { visibility: hidden; }"
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
                accept = c("text/csv",
                           "text/comma-separated-values,text/plain",
                           ".csv",
                           ".xml",
                           ".html")),
      
      htmlOutput("donorsize"),
      # Horizontal line ----
      tags$hr(),
      
      selectInput(
        'state',
        'Source:',
        list(`National` = list("FEC" = "FEC"),
             `City` = list("Atlanta" = "ATL",
                           "Los Angeles" = "LA_C",
                           "New York City" = "NYC"),
          `State` = list("Alabama" = "AL",
          "Alaska" = "AK",
          "Arizona" = "AZ",
          "California" = "CA",
          "Colorado" = "CO",
          "Connecticut" = "CT",
          "Delaware" = "DE",
          "Florida" = "FL",
          "Georgia" = "GA",
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
          "Utah" = "UT",
          "Virginia" = "VA",
          "Vermont" = "VT",
          "Washington" = "WA",
          "West Virginia" = "WV",
          "Wisconsin" = "WI",
          "Wyoming" = "WY")),
        selected = "Alabama",
      ),
      
      # Button
      downloadButton("downloadData", "Download"),
      
      tags$a(href="https://jer164.github.io/donoRs/", "User Guide", target = "_blank")
      
    ),
      
      # Main panel for displaying outputs ----
      mainPanel(
        
        # Output: Data file ----
        dataTableOutput("contents")
        
    )
    
  )    
  
)


server <- function(input, output) {
  
  source("transforms.R")
  
#### Create DataTable on Output
    
  output$contents <- renderDataTable({
    
    req(input$donorfile)
    
    if (input$state == "VA"){
      
    df <- virginia(input$donorfile$datapath) %>% as_tibble() 
      
    }
    
    else if (input$state == "KS"){
      
      df <- kansas(input$donorfile$datapath) %>% as_tibble() 
      
    }
    
    else if (input$state == "MO"){
      
      df <- missouri(input$donorfile$datapath) %>% as_tibble() 
      
    }
    
    else if (input$state == "NC" | input$state == "NM" | input$state == "WV"){  
    
    df <- read_csv(input$donorfile$datapath, skip = 1)
    
    }
    
    else if (input$state == "MA" | input$state == "MI"){
      
      df <- read_delim(input$donorfile$datapath, 
                       delim = "\t", escape_double = FALSE, 
                       trim_ws = TRUE)
      
    }
    
    else if (input$state == "MT") {
      
      df <- read_delim(input$donorfile$datapath, 
                              delim = "|", escape_double = FALSE, trim_ws = TRUE)
      
    }
    
    else if (input$state == 'AZ'){
      
      temp_data <- read.csv(input$donorfile$datapath, fileEncoding="UTF-16LE") %>% as_tibble()
      
    }
    
    else {
      
      df <- read_csv(input$donorfile$datapath)
      
    }
    
    df <- donor_cleaner(input$donorfile$datapath, input$state) %>% 
      select_if(function(x) !(all(is.na(x)) | all(x=="")))
    
  })

##### Create reactive dataset for download  
  
  datasetInput <- reactive({donor_cleaner(input$donorfile$datapath, input$state)})
  
###### Create download
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("candidatename_formatted.csv", sep = "") 
    },
    content = function(file) {
      write.csv(datasetInput(), file, row.names = FALSE, na = "")
    }
  )
  
  output$donorsize <- renderText({
    paste("<b>Number of Donors: </b>", nrow(datasetInput()))
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
