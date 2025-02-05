#file_path <- "D:/Qupath/Cell_Data/measurements.csv" # Modify this as needed
#file_path <- "D:/Qupath/DilutionSeries_Clean/dark_zone_manual_detections.csv"
#file_path <- "D:/Qupath/Cell_Data/measurements_2024-10-22.csv"
#file_path <- "D:/Qupath/Cell_Data/auto_stain_measurements.csv"
file_path1 <- "D:/Qupath/Cell_Data/uniform_vectors1.csv"
file_path2 <- "D:/Qupath/Cell_Data/uniform_vectors2.csv"
file_path3 <- "D:/Qupath/Cell_Data/uniform_vectors3.csv"

measurements1 <- read.csv(file_path1, check.names = F) 
measurements2 <- read.csv(file_path2, check.names = F)
measurements3 <- read.csv(file_path3, check.names = F)


measurements = rbind(measurements1, measurements2)
measurements = rbind(measurements, measurements3)

germinal_center_df <- subset(measurements, Parent == "Annotation (germinal_center)")
light_zone_df <- subset(measurements, Parent == "Annotation (light_zone)")
dark_zone_df <- subset(measurements, Parent == "Annotation (dark_zone)")
mantle_df <- subset(measurements, Parent == "Annotation (mantle)")

# Assuming the column you're interested in is 'DAB..Mean'
germinal_center_mean <- round(mean(germinal_center_df[["DAB: Mean"]], na.rm = TRUE), 3)
light_zone_mean <- round(mean(light_zone_df[["DAB: Mean"]], na.rm = TRUE), 3)
dark_zone_mean <- round(mean(dark_zone_df[["DAB: Mean"]], na.rm = TRUE), 3)
mantle_mean <- round(mean(mantle_df[["DAB: Mean"]], na.rm = TRUE), 3)

# Create a list of means rounded to 3 decimal places
means_list <- list(
  germinal_center = germinal_center_mean,
  light_zone = light_zone_mean,
  dark_zone = dark_zone_mean,
  mantle = mantle_mean
)

# Print the list of means
print(means_list)



df_list <- list(germinal_center_df, light_zone_df, dark_zone_df, mantle_df)

object_type <- "Detection"
intensity_metric <- "DAB: Mean"

color_list <- c("darkturquoise", "red", "green", "blueviolet")
region_names <- c("Germinal Center", "Light Zone", "Dark Zone", "Mantle")

# x_label_order <- c("KI67 negative.ndpi", "KI67 1 in 1000.ndpi", "KI67 1 in 500.ndpi", "KI67 1 in 100.ndpi", "KI67 1 in 20.ndpi", "KI67 1 in 10.ndpi", "KI67 1 in 4.ndpi", "KI67 1 in 2.ndpi", "KI67 3 in 4.ndpi")
# x_label_order <- c("KI67 1 in 200.ndpi", "KI67 1 in 200 run2.ndpi", "KI67 1 in 200 run3.ndpi", "KI67 1 in 100 run2.ndpi", "KI67 1 in 100 run3.ndpi", "KI67 1 in 50.ndpi", "KI67 1 in 50 run2.ndpi", "KI67 1 in 50 run3.ndpi", "KI67 1 in 20 run2.ndpi", "KI67 1 in 20 run3.ndpi", "KI67 1 in 10 run2.ndpi", "KI67 1 in 10 run3.ndpi", "KI67 1 in 4 run2.ndpi", "KI67 1 in 4 run3.ndpi", "KI67 1 in 2 run2.ndpi", "KI67 1 in 2 run3.ndpi", "KI67 3 in 4 run2.ndpi", "KI67 3 in 4 run3.ndpi")
x_label_order <- sort(unique(measurements$Image))

slide_hist <- function(df, image, colName, bins, plot) {
  d <- df[df[["Image"]] == image & df[["Object type"]] == object_type, c("Image", colName)]
  # Set parameters for histogram
  metric <- d[[colName]]    # Metric to track
  
  # Summary Statistics
  count <- sum(!is.na(metric))
  mean <- mean(metric, na.rm = TRUE)
  min <- min(metric, na.rm = TRUE)
  max <- max(metric, na.rm = TRUE)
  std <- sd(metric, na.rm = TRUE)
  median <- median(metric, na.rm = TRUE)
  
  if (plot && count > 0) {
    hist(metric, breaks=seq(min, max, length.out = bins), main=paste("Histogram of", colName, "(", image,")"), xlab=paste(colName))
  }
  
  ret_list <- list(mean = mean, count = count, min = min, max = max, std = std, median = median)
  return(ret_list)
}


# Scatter plot comparison of dilution series (across all slides)
slide_dab_comparison_scatter <- function (unique_images, mean, count, df) {
  print(df)
  img_names <- gsub("^KI67|KI67_|KI67J|\\.ndpi$", "", unique_images)
  
  data <- data.frame(Name = img_names, Mean = mean, Count = count)
  data <- data[is.finite(data$Mean), ]
  data <- data[order(data$Mean), ]
  rownames(data) <- NULL
  
  # Assuming all annotations in the df are on the same region
  region <- gsub("[\\(\\)]", "", regmatches(df[1, "Parent"], gregexpr("\\(.*?\\)", df[1, "Parent"]))[[1]])
  
  par(mar = c(8, 8, 4, 0), mgp = c(6, 1, 0))  # Adjust margins and label positioning
  
  # Set up x-axis labels with count information
  x_labels <- paste(data$Name, "\n(n=", prettyNum(data$Count, big.mark = ",", scientific = FALSE), ")", sep = "")
  
  # Create a scatterplot
  plot(data$Mean, type = "b", pch = 19, col = "black", xaxt = "n", ylim = c(0, max(data$Mean) + 0.1),
       main = paste(intensity_metric, "of detections per slide (", region, ")"),
       xlab = "KI67 Slide (count)", ylab = intensity_metric, cex.axis = 0.7)
  
  # Add custom x-axis labels
  axis(1, at = 1:length(data$Name), labels = x_labels, las = 2, cex.axis = 0.7)
  
  # Connect the scatter points with lines
  lines(data$Mean, type = "b", pch = 19, col = "blue", lwd = 2)
  
  text(1:length(data$Mean) - 0.1, data$Mean + 0.01, labels = round(data$Mean, 2), pos = 3, cex = 0.8)
}

# Generate histograms for all slides, one for each annotation region
unique_images <- unique(measurements$Image)
for (df in df_list) {
  mean <- numeric()
  count <- numeric()
  for (image in unique_images) {
    hist_graph = slide_hist(df, image, intensity_metric, 32, FALSE)
    mean <- c(mean, hist_graph$mean)
    count <- c(count, hist_graph$count)
  }
  slide_dab_comparison_scatter(unique_images, mean, count, df)
}


# Scatter plot comparison of dilution series (combined for all regions)
produce_superimposed_df <- function(df_list, region_names) {
  superimposed_df <- data.frame()
  
  pch_values <- c(19, 17, 15, 18)  # Different point symbols for different regions
  
  par(mar = c(8, 8, 4, 2), mgp = c(6, 1, 0))  # Adjust margins and label positioning
  
  # Initialize the plot with the first dataframe
  first = TRUE
  for (i in seq_along(df_list)) {
    df <- df_list[[i]]
    unique_images <- unique(df$Image)
    img_names <- gsub("^KI67|KI67_|KI67J|\\.ndpi$", "", unique_images)
    mean <- numeric()
    count <- numeric()
    region <- gsub("[\\(\\)]", "", regmatches(df[1, "Parent"], gregexpr("\\(.*?\\)", df[1, "Parent"]))[[1]])
    new_image <- data.frame()
    for (image in unique_images) {
      mean <- numeric()
      count <- numeric()
      min <- numeric()
      max <- numeric()
      std <- numeric()
      median <- numeric()
      hist_graph = slide_hist(df, image, intensity_metric, 32, FALSE)
      mean <- c(mean, hist_graph$mean)
      count <- c(count, hist_graph$count)
      std <- c(std, hist_graph$std)
      min <- c(min, hist_graph$min)
      max <- c(max, hist_graph$max)
      median <- c(median, hist_graph$median)
      new_row <- data.frame(Image = image, Region = region, Mean = mean, Median = median, Count = count, Min = min, Max = max, Stdev = std)
      new_image <- rbind(new_image, new_row)
    }
    superimposed_df <- rbind(superimposed_df, new_image)
  }
  return(superimposed_df)
}

# Call the combined scatter plot function
superimposed_df <- produce_superimposed_df(df_list, region_names)

print(superimposed_df)
write.csv(superimposed_df, "D:/Qupath/Cell_Data/superimposed_df.csv", row.names = T)


# Dataframe for dilution series graph (with multiple curves) is now prepped
# Reorder by custom x label order
produce_dilution_series <- function(superimposed_df, lines) {
  superimposed_df$Image <- factor(superimposed_df$Image, levels = x_label_order)
  superimposed_df <- superimposed_df[order(superimposed_df$Image), ]
  junk <- rep(-1L, length(x_label_order))
  x <- 1:length(x_label_order)
  
  gc <- data.frame(Mean = numeric(), Count = numeric())
  lz <- data.frame(Mean = numeric(), Count = numeric())
  dz <- data.frame(Mean = numeric(), Count = numeric())
  m  <- data.frame(Mean = numeric(), Count = numeric())
  
  for(i in 1: nrow(superimposed_df)) {
    row <- superimposed_df[i,]
    if(row["Region"]=="germinal_center") {
      gc <- rbind(gc, data.frame(Mean = row["Mean"], Count = row["Count"]))
    }
    if(row["Region"]=="light_zone") {
      lz <- rbind(lz, data.frame(Mean = row["Mean"], Count = row["Count"]))
    }
    if(row["Region"]=="dark_zone") {
      dz <- rbind(dz, data.frame(Mean = row["Mean"], Count = row["Count"]))
    }
    if(row["Region"]=="mantle") {
      m <- rbind(m, data.frame(Mean = row["Mean"], Count = row["Count"]))
    }
    
    # Pad with NA values if we have completed an iteration through a slide name
    gc_len = nrow(gc)
    lz_len = nrow(lz)
    dz_len = nrow(dz)
    m_len = nrow(m)
    
    max_len <- max(nrow(gc), nrow(lz), nrow(dz), nrow(m))

    if (max_len - gc_len >= 2) {
      gc <- rbind(gc, data.frame(Mean = NA, Count = NA))
    }
    if (max_len - lz_len >= 2) {
      lz <- rbind(lz, data.frame(Mean = NA, Count = NA))
    }  
    if (max_len - dz_len >= 2) {
      dz <- rbind(dz, data.frame(Mean = NA, Count = NA))
    }  
    if (max_len - m_len >= 2) {
      m <- rbind(m, data.frame(Mean = NA, Count = NA))
    }
  }

  par(mar = c(8, 8, 6, 1), mgp = c(6, 1, 0))  # Adjust margins and label positioning
  
  img_names <- gsub(".ndpi$", "", x_label_order)
  

  plot(junk, type = "b", pch = 19, col = "black", xaxt = "n", ylim = c(-0.05, max(superimposed_df$Mean) + 0.1),
       xlab = "KI67 Slide", ylab = intensity_metric, cex.axis = 0.7)
  
  # Adjust the title position with mtext, specifying 'adj = 0' to align left
  mtext(paste(intensity_metric, "of detections (custom stain vectors)"), side = 3, line = 1, adj = 0.4, font = 2)
  
  
  axis(1, at = 1:length(img_names), labels = img_names, las = 2, cex.axis = 0.7)
  
  type <- "p"
  # Plot each line one by one
  if(lines) {
    type <- "b"
  }
  
  points(x, gc[["Mean"]], type = type, pch = 19, col = color_list[1])
  points(x, lz[["Mean"]], type = type, pch = 19, col = color_list[2])
  points(x, dz[["Mean"]], type = type, pch = 19, col = color_list[3])
  points(x , m[["Mean"]], type = type, pch = 19, col = color_list[4])
  
  
  text(x , gc[["Mean"]], labels = round(gc[["Mean"]], 3), pos = 3, cex = 0.8, col = color_list[1])
  text(x, lz[["Mean"]], labels = round(lz[["Mean"]], 3), pos = 3, cex = 0.8, col = color_list[2])
  text(x, dz[["Mean"]], labels = round(dz[["Mean"]], 3), pos = 3, cex = 0.8, col = color_list[3])
  text(x, m[["Mean"]], labels = round(m[["Mean"]], 3), pos = 3, cex = 0.8, col = color_list[4])
  
  # Add a legend
  legend("topright", legend = paste(region_names, means_list), 
         col = color_list, lty = 1,
         xpd = TRUE, inset = c(0.0, -0.3))
}

# produce_dilution_series(superimposed_df, T)










# Extract fraction and calculate decimal value
superimposed_df$Fraction <- as.numeric(sub(" .*", "", sub("KI67 ", "", superimposed_df$Image))) /
  as.numeric(sub(" .*", "", sub("\\.ndpi", "", sub(".* in ", "", superimposed_df$Image))))

print(superimposed_df)

run1 <- c("KI67 1 in 10.ndpi",
          "KI67 1 in 20.ndpi",
          "KI67 1 in 200.ndpi",
          "KI67 3 in 4.ndpi",
          "KI67 1 in 100.ndpi",
          "KI67 1 in 4.ndpi",
          "KI67 1 in 50.ndpi",
          "KI67 1 in 2.ndpi")

run2 <- c("KI67 1 in 10 run2.ndpi",
          "KI67 1 in 20 run2.ndpi",
          "KI67 1 in 200 run2.ndpi",
          "KI67 3 in 4 run2.ndpi",
          "KI67 1 in 100 run2.ndpi",
          "KI67 1 in 4 run2.ndpi",
          "KI67 1 in 50 run2.ndpi",
          "KI67 1 in 2 run2.ndpi")

run3 <- c("KI67 1 in 50 run3.ndpi",
          "KI67 1 in 200 run3.ndpi",
          "KI67 1 in 100 run3.ndpi",
          "KI67 1 in 20 run3.ndpi",
          "KI67 1 in 10 run3.ndpi",
          "KI67 3 in 4 run3.ndpi",
          "KI67 1 in 4 run3.ndpi",
          "KI67 1 in 2 run3.ndpi")

run1_df <- subset(superimposed_df, Image %in% run1)
run2_df <- subset(superimposed_df, Image %in% run2)
run3_df <- subset(superimposed_df, Image %in% run3)



dilution_curve <- function(df, max_fraction, run) {
  df <- df[as.numeric(as.character(df$Fraction)) < max_fraction, ]
  
  # Set up the plot window
  plot(df$Fraction, df$Mean, type = "n", 
       xlab = "Concentration", ylab = "DAB Mean", 
       main = paste("Calibration Curve for KI67 Regions", run))
  
  regions <- c("germinal_center", "light_zone", "dark_zone", "mantle")

  # Plot points and lines by region, sorted by Fraction
  for (i in seq_along(regions)) {
    subset_data <- subset(df, Region == regions[i])
    subset_data <- subset_data[order(subset_data$Fraction), ]  # Sort by Fraction
    points(subset_data$Fraction, subset_data$Mean, col = color_list[i], pch = 16)
    lines(subset_data$Fraction, subset_data$Mean, col = color_list[i])
  }
  
  # Add a legend
  legend("topright", legend = region_names, col = color_list, pch = 16, title = "Region")
}

# Calculate average Mean for each Region and Fraction combination
averaged_df <- aggregate(superimposed_df$Mean, 
                         by = list(Region = superimposed_df$Region, Fraction = superimposed_df$Fraction), 
                         FUN = mean, na.rm = TRUE)

# Rename the aggregated column
colnames(averaged_df)[3] <- "Mean"

print(run1_df)
print(run2_df)
print(run3_df)
print(averaged_df)
dilution_curve(run1_df, 1, "run 1")
dilution_curve(run2_df, 1, "run 2")
dilution_curve(run3_df, 1, "run 3")

print(averaged_df)
dilution_curve(averaged_df, 0.1, "combined runs")
dilution_curve(averaged_df, 1, "combined runs")
