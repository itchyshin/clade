library(shiny)
library(ggplot2)
library(dplyr)
library(clade)

# 1. UI: The Frontend Layout
ui <- fluidPage(
  titlePanel("Clade Evolutionary Dynamics"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Simulation Metrics"),
      selectInput("metric", "Select Metric to Track:",
                  choices = c("Population Size" = "n_agents",
                              "Mean Energy" = "mean_energy",
                              "Genetic Diversity" = "genetic_diversity",
                              "Grass Coverage" = "grass_coverage",
                              "Births" = "n_births",
                              "Deaths" = "n_deaths")),
      hr(),
      helpText("Dashboard rendering live data from the Julia backend.")
    ),
    
    mainPanel(
      plotOutput("timeSeriesPlot", height = "500px")
    )
  )
)

# 2. Server: The Backend Logic
server <- function(input, output, session) {
  
  # For Version 1, we run a quick simulation once when the app starts.
  # (Later, we will add a "Run" button to let users trigger this dynamically).
  showNotification("Running Julia Simulation...", duration = 3, type = "message")
  
  specs <- quick_specs()
  env <- run_alife(specs, verbose = FALSE)
  sim_data <- get_run_data(env)$ticks
  
  # Render the ggplot based on the user's dropdown selection
  output$timeSeriesPlot <- renderPlot({
    ggplot(sim_data, aes(x = t, y = .data[[input$metric]])) +
      geom_line(color = "#2c3e50", size = 1.2) +
      geom_area(fill = "#3498db", alpha = 0.2) +
      theme_minimal() +
      labs(x = "Tick (Time)", 
           y = gsub("_", " ", stringr::str_to_title(input$metric)),
           title = paste("Simulation Trajectory:", input$metric)) +
      theme(
        text = element_text(size = 14),
        plot.title = element_text(face = "bold")
      )
  })
}

# 3. Launch the App
shinyApp(ui = ui, server = server)