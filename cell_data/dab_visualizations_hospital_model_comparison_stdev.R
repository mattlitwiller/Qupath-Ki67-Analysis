# Load Plotly library
library(plotly)

region_colors <- c("light_zone" = "#c0402d", 
                   "dark_zone" = "#65be4b", 
               #    "mantle" = "#1a0068", 
                   "germinal_center" = "#3cc0fe")

# Set the directory where the files are located
# Replace 'your_directory_path' with the actual directory path
files1 <- list.files(path = "D:/Qupath-files/cell_data/ModelComparison/JGH/measurements", full.names = TRUE, pattern = "\\.csv$")

# Initialize an empty data frame to store the combined data
combined_data1 <- data.frame()

# Read each file and append its data to the combined_data data frame
for (file in files1) {
  # Read the current CSV file
  df <- read.csv(file, check.names = F)
  
  # Append to the combined data
  combined_data1 <- rbind(combined_data1, df)
}

summary_data1 <- aggregate(`DAB: Mean` ~ Image + Parent, 
                           data = combined_data1, 
                           FUN = mean)

summary_data1$Hospital <- "JGH"



files2 <- list.files(path = "D:/Qupath-files/cell_data/ModelComparison/GLEN/measurements", full.names = TRUE, pattern = "\\.csv$")

# Initialize an empty data frame to store the combined data
combined_data2 <- data.frame()

# Read each file and append its data to the combined_data data frame
for (file in files2) {
  # Read the current CSV file
  df <- read.csv(file, check.names = F)
  
  # Append to the combined data
  combined_data2 <- rbind(combined_data2, df)
}

summary_data2 <- aggregate(`DAB: Mean` ~ Image + Parent, 
                           data = combined_data2, 
                           FUN = mean)

summary_data2$Hospital <- "GLEN"



files3 <- list.files(path = "D:/Qupath-files/cell_data/ModelComparison/BOTH/measurements", full.names = TRUE, pattern = "\\.csv$")

# Initialize an empty data frame to store the combined data
combined_data3 <- data.frame()

# Read each file and append its data to the combined_data data frame
for (file in files3) {
  # Read the current CSV file
  df <- read.csv(file, check.names = F)
  
  # Append to the combined data
  combined_data3 <- rbind(combined_data3, df)
}

summary_data3 <- aggregate(`DAB: Mean` ~ Image + Parent, 
                           data = combined_data3, 
                           FUN = mean)

summary_data3$Hospital <- "BOTH"



summary_data <- rbind(summary_data1, summary_data2)
summary_data <- rbind(summary_data, summary_data3)

summary_data$Parent <- gsub("Annotation \\((.+)\\)", "\\1", summary_data$Parent)
summary_data$RegionHospital <- paste(summary_data$Parent, summary_data$Hospital, sep = " - ")

#Only include regions from region_colors
summary_data <- summary_data[summary_data$Parent %in% names(region_colors), ]


### Mean + Stdev work
# Get the unique RegionHospital values
regions <- unique(summary_data$RegionHospital)

region_stats <- data.frame(
  RegionHospital = regions,
  RegionMean = sapply(regions, function(region) mean(summary_data$`DAB: Mean`[summary_data$RegionHospital == region], na.rm = TRUE)),
  Stdev = sapply(regions, function(region) sd(summary_data$`DAB: Mean`[summary_data$RegionHospital == region], na.rm = TRUE)),
  stringsAsFactors = FALSE
)
summary_data <- merge(summary_data, region_stats, by = "RegionHospital", all.x = TRUE)

# Create an offset column for the mean and error bar points
summary_data$RegionHospitalNumeric <- as.numeric(as.factor(summary_data$RegionHospital))

offset <- 0.3


# Create the plot using Plotly
plot <- plot_ly(data = summary_data, 
                x = ~RegionHospitalNumeric, 
                y = ~`DAB: Mean`, 
                type = 'scatter', 
                mode = 'markers', 
                marker = list(
                  size = 10,
                  color = ~region_colors[Parent]  # Map colors based on the Region
                ),
                text = ~paste("Slide: ", Image, "<br>Hospital: ", Hospital, "<br>DAB Mean: ", round(`DAB: Mean`, 3)),
                hoverinfo = 'text')

# Add region mean points slightly offset to the side with detailed text
plot <- plot %>%
  add_trace(data = summary_data,
            x = ~RegionHospitalNumeric + offset,
            y = ~RegionMean,
            type = 'scatter',
            mode = 'markers',
            marker = list(size = 12, color = 'black', symbol = 'o'),
            name = 'Region Mean',
            hoverinfo = 'text',
            text = ~paste("Region: ", RegionHospital, "<br>Mean: ", round(RegionMean, 3), "<br>Stdev: ", round(Stdev, 3)))

# Add standard deviation error bars with the same offset
plot <- plot %>%
  add_trace(data = summary_data,
            x = ~RegionHospitalNumeric + offset,
            y = ~RegionMean,
            type = 'scatter',
            mode = 'markers',
            error_y = list(
              type = 'data',
              array = ~Stdev,
              visible = TRUE,
              color = 'black'
            ),
            name = 'Stdev',
            line = list(color = 'transparent'), # Hide connecting lines
            marker = list(color = 'transparent'), # Hide marker
            hoverinfo = 'text')

# Create annotations for each point
annotations <- lapply(1:nrow(summary_data), function(i) {
  list(
    x = summary_data$RegionHospitalNumeric[i] + offset * 2,
    y = summary_data$RegionMean[i],
    text = paste("OD = ", round(summary_data$RegionMean[i], 2), "<br>",
                 "+/- ", round(summary_data$Stdev[i], 2)),
    showarrow = FALSE,
    font = list(size = 10),
    align = "left"
  )
})

# Customize the layout without a legend
plot <- plot %>%
  layout(title = "Slide DAB Mean by Region for models trained on JGH, GLEN and BOTH datasets",
         xaxis = list(
           title = "Slide Region - Training Dataset",
           tickvals = unique(summary_data$RegionHospitalNumeric),
           ticktext = tools::toTitleCase(gsub("_", " ", unique(summary_data$RegionHospital)))  # Capitalize each word
         ),
         yaxis = list(title = "Slide DAB Mean"),
         annotations = annotations,
         showlegend = F)

# Show the plot
plot


