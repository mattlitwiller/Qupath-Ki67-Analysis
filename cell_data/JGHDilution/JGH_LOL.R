library(plotly)

y_metric <- 'Positivity' # Options: 'Mean' or 'Positivity' 
y_axis <- 'Positivity (%)'
main_title <- 'Positivity Dilution JGH'
#y_axis <- 'Mean Slide DAB'
#main_title <- 'DAB Mean Dilution JGH'

region_colors <- c("light_zone" = "red", "dark_zone" = "green", "mantle" = "purple", "germinal_center" = "blue")
run_shapes <- c(1, 2, 3) # Shapes: 1 = circle, 2 = triangle, 3 = plus
linear_bounds = c(0.04, 0.25)
positivity_thresh <- 0.15




files <- list.files(path = "D:/Qupath-files/cell_data/JGHDilution/measurements", full.names = TRUE, pattern = "\\.csv$")

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
  positivity <- 100 * sum(metric >= positivity_thresh, na.rm = TRUE) / count 
  sd <- sd(metric, na.rm = T)
  min <- min(metric, na.rm = T)
  max <- max(metric, na.rm = T)
  
  if (plot) {
    hist(metric, breaks=seq(min, max, length.out = bins), main=paste("Histogram of", colName, "(", slide,")"))
  }
  
  ret_list <- list(mean = mean, count = count, positivity = positivity, stdev = sd)
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
      positivity_value <- hist_graph$positivity
    } else {
      mean_value <- NA
      count_value <- NA
      stdev_value <- NA
      positivity_value <- NA
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
    data <- rbind(data, data.frame(
      Name = image, Parent = parent, Fraction = fraction, Run = run,
      Mean = mean_value, Positivity = positivity_value, Count = count_value, 
      Stdev = stdev_value, stringsAsFactors = FALSE
    ))
  }
}


data <- data[complete.cases(data), ] # Remove rows with NA (regions where no detections were made will have NA values for mean, count, and stdev

point_colors <- region_colors[data$Parent]
point_shapes <- run_shapes[as.numeric(factor(data$Run))]

# Plot the data
plot(
  data$Fraction, data[[y_metric]],
  col = point_colors,  # Color based on region
  pch = 16,            # All points will have pch = 16 (solid circle)
  xlab = "Dilution Concentration", 
  ylab = y_axis, 
  main = main_title
)

# Add a legend for regions (colors)
legend("topleft", 
       legend = names(region_colors), 
       col = region_colors, 
       pch = 16, 
       title = "Region", 
       bty = "n"
)




# Remove the "runX.ndpi" portion from Name and add a new column
data$BaseName <- sub("run[0-9]+\\.ndpi$", "", data$Name)

# Aggregate data by Parent and Fraction
combined_data <- aggregate(
  cbind(Mean = data$Mean * data$Count,  # Weighted sum for Mean
        Positivity = data$Positivity * data$Count,  # Weighted sum for Positivity
        Count = data$Count,            # Sum of counts
        SSQ = (data$Count - 1) * data$Stdev^2 + 
          data$Count * (data$Mean - data$Mean)^2) ~ Parent + Fraction + BaseName,
  data = data,
  FUN = sum
)

# Calculate weighted mean and pooled standard deviation
combined_data$WeightedMean <- combined_data$Mean / combined_data$Count
combined_data$WeightedPositivity <- combined_data$Positivity / combined_data$Count
combined_data$PooledStdev <- sqrt(combined_data$SSQ / (combined_data$Count - 1))

# Keep only relevant columns
combined_data <- combined_data[, c("BaseName", "Parent", "Fraction", "WeightedMean", "WeightedPositivity", "Count", "PooledStdev")]

# Rename columns for clarity
names(combined_data) <- c("Name", "Parent", "Fraction", "Mean", "Positivity", "Count", "Stdev")

# View the result
print(combined_data)

point_colors <- region_colors[combined_data$Parent]
point_shapes <- run_shapes[as.numeric(factor(combined_data$Run))]
combined_data$Color <- region_colors[combined_data$Parent]


# Plot the combined_data
plot(
  combined_data$Fraction, combined_data[[y_metric]],
  col = combined_data$Color,  # Color based on region
  pch = 16,            # All points will have pch = 16 (solid circle)
  xlab = "Dilution Concentration", 
  ylab = y_axis, 
  main = main_title
)

# Add a legend for regions (colors)
legend("topleft", 
       legend = names(region_colors), 
       col = region_colors, 
       pch = 16, 
       title = "Region", 
       bty = "n"
)


# Create the linear_data dataframe
linear_data <- combined_data[combined_data$Fraction <= linear_bounds[2], ]
# Remove specific fractions where some negative values are produced (below the limit of detection)
linear_data <- linear_data[linear_data$Fraction >= linear_bounds[1], ]


# Initialize an empty list to store results
results <- list()
models <- list()
linear_predictions <- list()

# Unique Parent categories
unique_parents <- unique(linear_data$Parent)

# Loop through each Parent category
for (parent in unique_parents) {
  # Subset data for the current Parent
  parent_data <- linear_data[linear_data$Parent == parent, ]
  
  # Perform linear regression with intercept coeff
  formula <- as.formula(paste(y_metric, "~ Fraction"))
  fit <- lm(formula, data = parent_data)
  models[[parent]] <- fit
  
  # Access the coefficients
  intercept <- coef(fit)[1] # Extract intercept
  slope <- coef(fit)[2]     # Extract slope
  
  # Create the equation text
  equation <- paste("y =", round(intercept, 2), "+", round(slope, 2), "x")
  
  # Compute Pearson correlation coefficient
  pearson_r <- cor(parent_data$Fraction, parent_data$Mean)
  
  # Add results to the list
  results[[parent]] <- list(
    regression = fit,
    pearson_r = pearson_r,
    equation = equation
  )
  
  # Add the regression line to the plot
  abline(a = intercept, b = slope, col = region_colors[parent], lwd = 2)
  
  linear_predictions[[parent]] <- list(intercept = intercept, slope = slope)
}

abline(v = linear_bounds[1], col = "gray", lty = 2) # Red dashed line at 0.02
abline(v = linear_bounds[2], col = "gray", lty = 2) # Blue dashed line at 0.25

# Print the Pearson correlation coefficients and regression equations
results
print("Pearson R Coefficients and Equations:")
for (parent in names(results)) {
  cat(parent, ": R =", round(results[[parent]]$pearson_r, 2), "\nEquation:", results[[parent]]$equation, "\n")
}


# Predict the values at a certain concentrations from the regression models here
conc <- 0.2
predictions <- sapply(models, function(model) coef(model)[1] * conc)
predictions



combined_data
models[1]
y_gc <- predict(models[["germinal_center"]], newdata = combined_data[combined_data$Parent == "germinal_center" & combined_data$Fraction == 0.25, ])
y_gc




full_rows <- combined_data[combined_data$Fraction == 1.00, ]

calculate_x <- function(parent, metric_val) {
  # Extract the coefficients from the regression model
  intercept <- results[[parent]]$regression$coefficients[1]
  slope <- results[[parent]]$regression$coefficients[2]
  
  # Solve for x: x = (y - intercept) / slope
  x_value <- (metric_val - intercept) / slope
  return(x_value)
}

# Apply the function to the combined_data dataframe
full_rows$x <- mapply(calculate_x, full_rows$Parent, full_rows[[y_metric]])

# View the updated dataframe with the new x values
print(full_rows)

points(
  full_rows$x, full_rows[[y_metric]],  # Plot the calculated x values and their corresponding y_metric
  col = region_colors[full_rows$Parent],  # Color by Parent region
  pch = 17  # Different point style (optional)
)


combined_data <- combined_data[combined_data$Fraction >= linear_bounds[1] & !is.na(combined_data$Fraction), ]
combined_data

# Plot the combined_data
plot(
  combined_data$Fraction, combined_data[[y_metric]],
  col = combined_data$Color,  # Color based on region
  pch = 16,            # All points will have pch = 16 (solid circle)
  xlab = "Dilution Concentration", 
  ylab = y_axis, 
  main = main_title
)

# Add a legend for regions (colors)
legend("topleft", 
       legend = names(region_colors), 
       col = region_colors, 
       pch = 16, 
       title = "Region", 
       bty = "n"
)

abline(v = linear_bounds[1], col = "gray", lty = 2) # Red dashed line at 0.02
abline(v = linear_bounds[2], col = "gray", lty = 2) # Blue dashed line at 0.25


combined_data
log_models <- list()
lol_values <- list()


for (parent in parent_values) {
  parent_data <- combined_data[combined_data$Parent == parent,] 
  formula <- as.formula(paste(y_metric, "~ a + b * log(Fraction)"))
  log_model <- nls(formula, 
                   data = parent_data, 
                   start = list(a = 1, b = 0.3))
  summary(log_model)
  log_models[[parent]] <- log_model
  fraction_seq <- seq(min(parent_data$Fraction), max(parent_data$Fraction), length.out = 100)
  # Predict the y_metric using the nls model
  fitted_means <- predict(log_model, newdata = data.frame(Fraction = fraction_seq))
  # Add the fitted curve to the plot
  lines(fraction_seq, fitted_means, col = region_colors[[parent]], lwd = 2)
  # Add linear predictions to the plot
  abline(a = linear_predictions[[parent]]$intercept, b = linear_predictions[[parent]]$slope, col = region_colors[parent], lwd = 2)
  
  
  linear_means <- linear_predictions[[parent]]$intercept + 
    linear_predictions[[parent]]$slope * fraction_seq
  absolute_diff <- abs(fitted_means - linear_means)
  relative_diff <- abs(fitted_means - linear_means) / linear_means
  
  linear_fraction_seq <- fraction_seq[fraction_seq >= linear_bounds[1] & fraction_seq <= linear_bounds[2]]
  
  # Predict the Mean using the log model and the linear model in the linear region
  fitted_means_linear_region <- predict(log_model, newdata = data.frame(Fraction = linear_fraction_seq))
  linear_means_linear_region <- linear_predictions[[parent]]$intercept + 
    linear_predictions[[parent]]$slope * linear_fraction_seq
  
  # Calculate the relative differences between the log model and linear model
  relative_diff_linear_region <- abs(fitted_means_linear_region - linear_means_linear_region) / linear_means_linear_region
  
  # Identify where the log model is predicting larger values than the linear model
  log_greater_than_linear <- fitted_means_linear_region > linear_means_linear_region
  
  # Apply the threshold to only the cases where log model > linear model
  relative_diff_log_greater <- relative_diff_linear_region[log_greater_than_linear]
  
  # Find the maximum relative difference where the log model is greater than the linear model
  max_relative_diff_log_greater <- max(relative_diff_log_greater)
  
  
  # Define threshold
  threshold <- max_relative_diff_log_greater # maximum difference where log model predicts larger than linear model
  limit_index <- which(relative_diff > threshold)
  
  # Find where the clusters (consecutive indices) start
  clusters <- rle(limit_index - seq_along(limit_index))$lengths
  
  # Find the first index of the last cluster
  last_cluster_start <- tail(limit_index, n = 1) - clusters[length(clusters)] + 1
  
  limit_of_linearity <- fraction_seq[last_cluster_start]
  lol_values[[parent]] <- list(x = limit_of_linearity, y = linear_predictions[[parent]]$intercept + 
                                 linear_predictions[[parent]]$slope * limit_of_linearity)
  
}
y_values <- sapply(lol_values, function(x) x$y)


# Plot LOL values
for(parent in parent_values){
  print(lol_values[[parent]])
  # Plot the points
  points(lol_values[[parent]]$x, lol_values[[parent]]$y, 
       col = region_colors[parent],
       pch = 17,  # Point style
       main = "Scatter Plot of Regions")
  text(
    lol_values[[parent]]$x, lol_values[[parent]]$y,
    labels = round(lol_values[[parent]]$y, 2),  # Round to 2 decimals
    pos = 4,          # Position the label to the right of the point
    col = region_colors[parent]  # Match label color with point color
  )
}
