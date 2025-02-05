library(plotly)

region_colors <- c("light_zone" = "red", "dark_zone" = "green", "mantle" = "purple", "germinal_center" = "blue")
run_shapes <- c(1, 2, 3) # Shapes: 1 = circle, 2 = triangle, 3 = plus
linear_bounds = c(0.04, 0.25)
positivity_thresh <- 0.15
y_metric <- 'Mean' # Options: 'Mean' or 'Positivity' 

files <- list.files(path = "D:/Qupath-files/cell_data/GlenDilution_run4/measurements", full.names = TRUE, pattern = "\\.csv$")

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

column <- 'DAB: Mean'
if (y_metric == 'Mean') {
  
}

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
      Mean = mean_value, Count = count_value, Positivity = positivity_value,
      Stdev = stdev_value, stringsAsFactors = FALSE
    ))
  }
}

data <- data[complete.cases(data), ] # Remove rows with NA (regions where no detections were made will have NA values for mean, count, and stdev)

data
point_colors <- region_colors[data$Parent]
point_shapes <- run_shapes[as.numeric(factor(data$Run))]

# Plot the data
plot(
  data$Fraction, data[[y_metric]],
  col = point_colors,  # Color based on region
  pch = 16,            # All points will have pch = 16 (solid circle)
  xlab = "Dilution Concentration", 
  ylab = "Mean Slide DAB", 
  main = "DAB Mean Dilution GLEN"
)

# Add a legend for regions (colors)
legend("topleft", 
       legend = names(region_colors), 
       col = region_colors, 
       pch = 16, 
       title = "Region", 
       bty = "n"
)


# Function to calculate weighted mean and pooled standard deviation
aggregate_data <- function(name, parent, fraction) {
  subset_data <- data[data$Parent == parent & data$Fraction == fraction, ]
  head(subset_data)
  total_count <- sum(subset_data$Count)
  
  # Weighted mean
  weighted_mean <- sum(subset_data$Mean * subset_data$Count) / total_count
  
  # Pooled standard deviation
  pooled_stdev <- sqrt(
    sum(((subset_data$Count - 1) * subset_data$Stdev^2) + 
          (subset_data$Count * (subset_data$Mean - weighted_mean)^2)) / 
      (total_count - 1)
  )
  
  name <- subset_data$Name[1]
  positivity <- subset_data$Positivity

  return(data.frame(
    Name = name,
    Parent = parent,
    Fraction = fraction,
    Mean = weighted_mean,
    Positivity = positivity,
    Count = total_count,
    Stdev = pooled_stdev
  ))
}

# Unique combinations of Parent and Fraction
unique_combinations <- unique(data[c("Parent", "Fraction")])

# Aggregate data for each combination
combined_data <- do.call(rbind, lapply(1:nrow(unique_combinations), function(i) {
  aggregate_data(
    name = unique_combinations$Name[i],
    parent = unique_combinations$Parent[i],
    fraction = unique_combinations$Fraction[i]
  )
}))

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
  ylab = "Mean Slide DAB", 
  main = "DAB Mean Dilution GLEN"
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
  ylab = "Mean Slide DAB", 
  main = "DAB Mean Dilution GLEN"
)

# Add a legend for regions (colors)
legend("topleft", 
       legend = names(region_colors), 
       col = region_colors, 
       pch = 16, 
       title = "Region", 
       bty = "n"
)

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
  lines(fraction_seq, fitted_means, col = "blue", lwd = 2)
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

lol_values