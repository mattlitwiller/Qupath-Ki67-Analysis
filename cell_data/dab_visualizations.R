# Load Plotly library
library(plotly)

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

head(combined_data)

# Calculate the average DAB: Mean for each combination of Slide (Image) and Region (Parent)
summary_data <- aggregate(`DAB: Mean` ~ Image + Parent, data = combined_data, FUN = mean)

# Now, create the plot using Plotly
plot <- plot_ly(data = summary_data, 
                x = ~Parent, 
                y = ~`DAB: Mean`, 
                type = 'scatter', 
                mode = 'markers', 
                marker = list(size = 10),
                text = ~paste("Slide: ", Image, "<br>Region: ", Parent, "<br>Avg DAB: Mean: ", round(`DAB: Mean`, 3)),
                hoverinfo = 'text') %>%

  layout(title = "Average DAB: Mean by Region and Slide",
         xaxis = list(title = "Region"),
         yaxis = list(title = "Average DAB: Mean"))

# Show the plot
plot
