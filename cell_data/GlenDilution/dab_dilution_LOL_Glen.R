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
  
  return(data.frame(
    Name = name,
    Parent = parent,
    Fraction = fraction,
    Mean = weighted_mean,
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

# Plot the combined_data
plot(
  combined_data$Fraction, combined_data$Mean,
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


# Create the linear_data dataframe
linear_data <- combined_data[combined_data$Fraction <= 0.1, ]
# Remove specific fractions where some negative values are produced (below the limit of detection)
linear_data <- linear_data[linear_data$Fraction > 0.002, ]

# Add points at (0, 0) for each region
zero_point <- data.frame(
  Name = rep(NA, 4),
  Fraction = rep(0, 4),
  Mean = rep(0, 4),
  Parent = unique(linear_data$Parent),
  Count = rep(NA, 4),
  Stdev = rep(NA, 4)
)

# Combine original linear data and zero points
linear_data <- rbind(linear_data, zero_point)
linear_data


# Initialize an empty list to store results
results <- list()
models <- list()

# Unique Parent categories
unique_parents <- unique(linear_data$Parent)


# Loop through each Parent category
for (parent in unique_parents) {
  # Subset data for the current Parent
  parent_data <- linear_data[linear_data$Parent == parent, ]
  
  # Perform linear regression with intercept fixed at 0
  fit <- lm(Mean ~ Fraction - 1, data = parent_data) # setting intercept = 0
  models[[parent]] <- fit

  # Access the coefficients
  slope <- coef(fit)[1]
  
  # Create the equation text
  equation <- paste("y =", round(slope, 2), "x")
  
  # Compute Pearson correlation coefficient
  pearson_r <- cor(parent_data$Fraction, parent_data$Mean)
  
  # Add results to the list
  results[[parent]] <- list(
    regression = fit,
    pearson_r = pearson_r,
    equation = equation
  )
  
  # Add the regression line to the plot
  abline(0, slope, col = region_colors[parent], lwd = 2)
}

# Print the Pearson correlation coefficients and regression equations
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





















###some other attempts, including a ggplot2 regression log curve but it wasnt actually log it was just a connected scatter plot?




# Load necessary libraries
library(stats) # For lm function

# Parameters
deviation_percentage <- 5 / 100 # Change this value for different deviation percentage

# Fit linear regression
linear_fit <- lm(Mean ~ Fraction, data = combined_data)

# Fit logarithmic regression
log_fit <- lm(log(Mean) ~ log(Fraction), data = combined_data)

# Predict values
combined_data$linear_pred <- predict(linear_fit, combined_data)
combined_data$log_pred <- exp(predict(log_fit, combined_data))

# Calculate deviation
combined_data$deviation <- abs(combined_data$log_pred - combined_data$linear_pred) / combined_data$linear_pred * 100

# Find the `Fraction` value where the deviation exceeds the specified percentage
deviation_point <- combined_data[which(combined_data$deviation > deviation_percentage), c("Fraction", "deviation")]

# Output the deviation point
print(deviation_point)



# Load necessary libraries
library(ggplot2)

# Parameters
deviation_percentage <- 5 / 100 # Change this value for different deviation percentage

# Fit linear regression
linear_fit <- lm(Mean ~ Fraction, data = combined_data)

# Fit logarithmic regression
log_fit <- lm(log(Mean) ~ log(Fraction), data = combined_data)

# Predict values
combined_data$linear_pred <- predict(linear_fit, combined_data)
combined_data$log_pred <- exp(predict(log_fit, combined_data))

# Calculate deviation
combined_data$deviation <- abs(combined_data$log_pred - combined_data$linear_pred) / combined_data$linear_pred * 100

# Plot
ggplot(combined_data, aes(x = Fraction)) +
  geom_point(aes(y = Mean), color = "blue", size = 1.5, alpha = 0.5, label = "Actual") +
  geom_line(aes(y = linear_pred), color = "red", size = 1, linetype = "dashed", label = "Linear Fit") +
  geom_line(aes(y = log_pred), color = "green", size = 1, linetype = "solid", label = "Logarithmic Fit") +
  labs(
    title = "Linear vs Logarithmic Fit of Data",
    x = "Fraction",
    y = "Mean",
    color = "Fit Type"
  ) +
  scale_color_manual(values = c("red", "green", "blue")) +
  theme_minimal()




