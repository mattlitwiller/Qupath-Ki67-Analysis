library(plotly)

region_colors <- c("light_zone" = "red", "dark_zone" = "green", "mantle" = "purple")
hospital_shapes <- c("GLEN" = 16, "JGH" = 1) 

glen_files <- list.files(path = "D:/Qupath-files/cell_data/GlenDilution/measurements", full.names = TRUE, pattern = "\\.csv$")

# Initialize an empty data frame to store the combined data
glen_measurements <- data.frame()

# Read each file and append its data to the combined_data data frame
for (file in glen_files) {
  # Read the current CSV file
  df <- read.csv(file, check.names = F)
  
  # Append to the combined data
  glen_measurements <- rbind(glen_measurements, df)
}

head(glen_measurements)

glen_measurements <- glen_measurements[complete.cases(glen_measurements), ] # Remove rows with NA (assumed to be in DAB: Mean but doesn't matter)
glen_measurements$Parent <- sub(".*\\((.*)\\).*", "\\1", glen_measurements$Parent)

## histogram metrics for each slide like in QuPath (& optional plotting)
plot_hist <- function(d, colName, bins, slide, plot) {
  # Set parameters for histogram
  metric = d[[colName]]    # Metric to track
  
  # Summary Statistics
  count <- length(metric)
  mean <- mean(metric, na.rm = T)
  sd <- sd(metric, na.rm = T)
  min <- min(metric, na.rm = T)
  max <- max(metric, na.rm = T)
  
  if (plot) {
    hist(metric, breaks=seq(min, max, length.out = bins), main=paste("Histogram of", colName, "(", slide,")"))
  }
  
  ret_list <- list(mean = mean, count = count, stdev = sd)
  return(ret_list)
}

parent_values <- c("germinal_center", "light_zone", "dark_zone", "mantle")
unique_glen_images <- unique(glen_measurements$Image)

glen_data <- data.frame(
  Name = character(), Parent = character(), Fraction = numeric(), Run = numeric(),
  Mean = numeric(), Count = numeric(), Stdev = numeric(), stringsAsFactors = FALSE
)

for (image in unique_glen_images) {
  for (parent in parent_values) {
    # Filter measurements for the current image and parent
    subset <- glen_measurements[glen_measurements[["Image"]] == image & glen_measurements[["Parent"]] == parent, c("Image", "Parent", "DAB: Mean")]
    # Compute histogram statistics if the subset is non-empty
    if (nrow(subset) > 0) {
      hist_graph <- plot_hist(subset, "DAB: Mean", 32, image, F)
      mean_value <- hist_graph$mean
      count_value <- hist_graph$count
      stdev_value <- hist_graph$stdev
    } else {
      mean_value <- NA
      count_value <- NA
      stdev_value <- NA
    }
    
    # Determine fraction using the logic from the original code
    fraction <- ifelse(
      grepl("in", image),
      with(data.frame(Slide = image), as.numeric(sub(".* (\\d+) in (\\d+).*", "\\1", Slide)) /
             as.numeric(sub(".* (\\d+) in (\\d+).*", "\\2", Slide))),
      0
    )
    
    # Extract run number using the logic from the original code
    run <- ifelse(
      grepl("run", image),
      as.numeric(sub(".*run(\\d+).*", "\\1", image)),
      1
    )
    
    # Add a row to the data dataframe
    glen_data <- rbind(glen_data, data.frame(
      Name = image, Parent = parent, Fraction = fraction, Run = run,
      Mean = mean_value, Count = count_value, Stdev = stdev_value, stringsAsFactors = FALSE
    ))
  }
}

glen_data <- glen_data[complete.cases(glen_data), ] # Remove rows with NA (regions where no detections were made will have NA values for mean, count, and stdev)
glen_data$Hospital <- "GLEN"

jgh_files <- list.files(path = "D:/Qupath-files/cell_data/JGHDilution/measurements", full.names = TRUE, pattern = "\\.csv$")

# Initialize an empty data frame to store the combined data
jgh_measurements <- data.frame()

# Read each file and append its data to the combined_data data frame
for (file in jgh_files) {
  # Read the current CSV file
  df <- read.csv(file, check.names = F)
  
  # Append to the combined data
  jgh_measurements <- rbind(jgh_measurements, df)
}

jgh_measurements <- jgh_measurements[complete.cases(jgh_measurements), ] # Remove rows with NA (assumed to be in DAB: Mean but doesn't matter)
jgh_measurements$Parent <- sub(".*\\((.*)\\).*", "\\1", jgh_measurements$Parent)

## histogram metrics for each slide like in QuPath (& optional plotting)
plot_hist <- function(d, colName, bins, slide, plot) {
  # Set parameters for histogram
  metric = d[[colName]]    # Metric to track
  
  # Summary Statistics
  count <- length(metric)
  mean <- mean(metric, na.rm = T)
  sd <- sd(metric, na.rm = T)
  min <- min(metric, na.rm = T)
  max <- max(metric, na.rm = T)
  
  if (plot) {
    hist(metric, breaks=seq(min, max, length.out = bins), main=paste("Histogram of", colName, "(", slide,")"))
  }
  
  ret_list <- list(mean = mean, count = count, stdev = sd)
  return(ret_list)
}

parent_values <- c("germinal_center", "light_zone", "dark_zone", "mantle")
unique_jgh_images <- unique(jgh_measurements$Image)

jgh_data <- data.frame(
  Name = character(), Parent = character(), Fraction = numeric(), Run = numeric(),
  Mean = numeric(), Count = numeric(), Stdev = numeric(), stringsAsFactors = FALSE
)

for (image in unique_jgh_images) {
  for (parent in parent_values) {
    # Filter measurements for the current image and parent
    subset <- jgh_measurements[jgh_measurements[["Image"]] == image & jgh_measurements[["Parent"]] == parent, c("Image", "Parent", "DAB: Mean")]
    # Compute histogram statistics if the subset is non-empty
    if (nrow(subset) > 0) {
      hist_graph <- plot_hist(subset, "DAB: Mean", 32, image, F)
      mean_value <- hist_graph$mean
      count_value <- hist_graph$count
      stdev_value <- hist_graph$stdev
    } else {
      mean_value <- NA
      count_value <- NA
      stdev_value <- NA
    }
    
    # Determine fraction
    fraction <- if (grepl("full", image)) {
      1.0
    } else if (grepl("negative", image)) {
      0.0
    } else if (grepl("out", image)) {
      as.numeric(sub(".*?([0-9]+)out([0-9]+).*", "\\1", image)) / 
        as.numeric(sub(".*?([0-9]+)out([0-9]+).*", "\\2", image))
    } else {
      NA
    }
    
    # Extract run number
    run <- as.numeric(gsub(".*run([0-9]+).*", "\\1", image))
    
    # Add a row to the data dataframe
    jgh_data <- rbind(jgh_data, data.frame(
      Name = image, Parent = parent, Fraction = fraction, Run = run,
      Mean = mean_value, Count = count_value, Stdev = stdev_value, stringsAsFactors = FALSE
    ))
  }
}

jgh_data <- jgh_data[complete.cases(jgh_data), ] # Remove rows with NA (regions where no detections were made will have NA values for mean, count, and stdev)
jgh_data$Hospital <- "JGH"

data <- rbind(glen_data, jgh_data)
data <- subset(data, Parent != "germinal_center") # Remove germinal_center from consideration

# Assign colors and shapes dynamically
data$Color <- region_colors[data$Parent]
data$Shape <- hospital_shapes[data$Hospital]

# Create a blank plot
plot(data$Fraction, data$Mean, type = "n", 
     xlab = "Fraction", ylab = "Mean", 
     main = "DAB Dilution Comparison",
     xlim = c(0, 1), ylim = c(0, max(data$Mean, na.rm = TRUE))) # Set limits for better visibility

# Add points
points(data$Fraction, data$Mean, col = data$Color, 
       pch = data$Shape)

# Add horizontal lines at each increment of positivity
abline(h = seq(0, max(data$Mean, na.rm = TRUE) + 0.1, by = 0.1), col = "grey", lty = 2)

# Add a legend for regions
legend("topright", inset = c(0.05, 0), # Moves the legend left
       legend = unique(data$Parent), 
       col = unique(data$Color), 
       pch = 16, # Solid points for region legend
       title = "Region", 
       box.lty = 0, 
       bg = rgb(1, 1, 1, alpha = 0)) # Transparent background

# Add a legend for hospitals (shape)
legend("topleft", 
       legend = unique(data$Hospital), 
       pch = unique(data$Shape), # Shape varies for hospital
       title = "Hospital", 
       box.lty = 0, 
       bg = rgb(1, 1, 1, alpha = 0)) # Transparent background