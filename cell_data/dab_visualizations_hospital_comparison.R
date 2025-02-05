# Load Plotly library
library(plotly)

region_colors <- c(
  "germinal_center" = "blue",
  "light_zone" = "red",
  "dark_zone" = "green",
  "mantle" = "purple"
)

# Set the directory where the files are located
# Replace 'your_directory_path' with the actual directory path
files <- list.files(path = "D:/Qupath-files/cell_data/AllSlides_CustomStainVec/measurements", full.names = TRUE, pattern = "\\.csv$")

# Initialize an empty data frame to store the combined data
combined_data <- data.frame()

# Read each file and append its data to the combined_data data frame
for (file in files) {
  # Read the current CSV file
  df <- read.csv(file, check.names = F)
  
  # Append to the combined data
  combined_data <- rbind(combined_data, df)
}

summary_data <- aggregate(`DAB: Mean` ~ Image + Parent, 
                           data = combined_data, 
                           FUN = mean)

summary_data$Hospital <- ifelse(grepl("J", summary_data$Image), "JGH", "GLEN")
summary_data$Parent <- gsub("Annotation \\((.+)\\)", "\\1", summary_data$Parent)
summary_data$RegionHospital <- paste(summary_data$Parent, summary_data$Hospital, sep = " - ")

summary_data

# Create the plot using Plotly
plot <- plot_ly(data = summary_data, 
                x = ~RegionHospital, 
                y = ~`DAB: Mean`, 
                type = 'scatter', 
                mode = 'markers', 
                marker = list(
                  size = 10,
                  color = ~region_colors[Parent]  # Map colors based on the Region
                ),
                text = ~paste("Slide: ", Image, "<br>Hospital: ", Hospital, "<br>Avg DAB Mean: ", round(`DAB: Mean`, 3)),
                hoverinfo = 'text') %>%
  
  layout(title = "Average DAB Mean by Region and Hospital",
         xaxis = list(title = "Region-Hospital"),
         yaxis = list(title = "Average DAB Mean"))

# Show the plot
plot

