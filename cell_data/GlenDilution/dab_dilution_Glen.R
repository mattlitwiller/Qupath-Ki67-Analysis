region_colors <- c("light_zone" = "red", "dark_zone" = "green", "mantle" = "purple", "germinal_center" = "blue")
run_shapes <- c(1, 2, 3) # Shapes: 1 = circle, 2 = triangle, 3 = plus

files <- list.files(path = "D:/Qupath-files/cell_data/GlenDilution/measurements", full.names = TRUE, pattern = "\\.csv$")

# Initialize an empty data frame to store the combined data
measurements <- data.frame()

# Read each file and append its data to the combined_data data frame
for (file in files) {
  # Read the current CSV file
  df <- read.csv(file, check.names = F)
  
  # Append to the combined data
  measurements <- rbind(measurements, df)
}

measurements <- measurements[complete.cases(measurements), ] # Remove rows with NA (assumed to be in DAB: Mean but doesn't matter)
measurements$Parent <- sub(".*\\((.*)\\).*", "\\1", measurements$Parent)

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
  
  sprintf("Count: %d", count)
  sprintf("Mean: %f", mean)
  sprintf("Std. Dev: %f", sd)
  sprintf("Min: %f", min)
  sprintf("Max: %f", max)
  
  ret_list <- list(mean = mean, count = count, stdev = sd)
  return(ret_list)
}

parent_values <- c("germinal_center", "light_zone", "dark_zone", "mantle")
unique_images <- unique(measurements$Image)

data <- data.frame(
  Name = character(), Parent = character(), Fraction = numeric(), Run = numeric(),
  Mean = numeric(), Count = numeric(), Stdev = numeric(), stringsAsFactors = FALSE
)

for (image in unique_images) {
  for (parent in parent_values) {
    # Filter measurements for the current image and parent
    subset <- measurements[measurements[["Image"]] == image & measurements[["Parent"]] == parent, c("Image", "Parent", "DAB: Mean")]
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
    data <- rbind(data, data.frame(
      Name = image, Parent = parent, Fraction = fraction, Run = run,
      Mean = mean_value, Count = count_value, Stdev = stdev_value, stringsAsFactors = FALSE
    ))
  }
}

data <- data[complete.cases(data), ] # Remove rows with NA (regions where no detections were made will have NA values for mean, count, and stdev)

point_colors <- region_colors[data$Parent]
point_shapes <- run_shapes[as.numeric(factor(data$Run))]

# Plot the data
plot(
  data$Fraction, data$Mean,
  col = point_colors,  # Color based on region
  pch = 16,            # All points will have pch = 16 (solid circle)
  xlab = "Fraction", 
  ylab = "Mean", 
  main = "DAB Dilution GLEN"
)

# Add a legend for regions (colors)
legend("topleft", 
       legend = names(region_colors), 
       col = region_colors, 
       pch = 16, 
       title = "Region", 
       bty = "n"
)