# Load Plotly library
library(plotly)

# Set the directory where the files are located
# Replace 'your_directory_path' with the actual directory path

path <- "D:/Qupath-files/cell_data/AllSlides_CustomStainVec/positivity/positivity.csv"
summary_data <- read.csv(path, check.names = F)
summary_data$Hospital <- ifelse(grepl("J", summary_data$Slide), "JGH", "GLEN")
summary_data$RegionHospital <- paste(summary_data$Region, summary_data$Hospital, sep = " - ")

summary_data

# Now, create the plot using Plotly
plot <- plot_ly(data = summary_data, 
                x = ~RegionHospital, 
                y = ~`Positivity`, 
                type = 'scatter', 
                mode = 'markers', 
                marker = list(size = 10),
                text = ~paste("Slide: ", Slide, "<br>Hospital: ", Hospital, "<br>Avg DAB: Mean: ", round(`Positivity`, 3)),
                hoverinfo = 'text') %>%
  
  layout(title = "Average DAB: Mean by Region and Hospital",
         xaxis = list(title = "Region-Hospital"),
         yaxis = list(title = "Average DAB: Mean"))

# Show the plot
plot


zero_positivity_rows <- summary_data[summary_data$Positivity == 0, ]
print("Zero-positivity Slides & Regions")
print(zero_positivity_rows, row.names = F)



