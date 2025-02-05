file_path <- "D:/Qupath/Cell_Data/measurements.csv" # Modify this as needed
measurements <- read.csv(file_path, check.names = F) 

plot_hist <- function(d, colName, bins, slide) {
  # Set parameters for histogram
  metric = d[[colName]]    # Metric to track
  
  # Summary Statistics
  count <- length(metric)
  mean <- mean(metric, na.rm = TRUE)
  sd <- sd(metric, na.rm = TRUE)
  min <- min(metric, na.rm = TRUE)
  max <- max(metric, na.rm = TRUE)
  
  hist(metric, breaks=seq(min, max, length.out = bins), main=paste("Histogram of", colName, "(", slide,")"))
  
  sprintf("Count: %d", count)
  sprintf("Mean: %f", mean)
  sprintf("Std. Dev: %f", sd)
  sprintf("Min: %f", min)
  sprintf("Max: %f", max)
  
  ret_list <- list(mean = mean, count = count)
  return(ret_list)
}

unique_images <- unique(measurements$Image)
mean <- numeric()
count <- numeric()

# Generate histograms for all slides
for (image in unique_images) {
  subset <- measurements[measurements[["Image"]] == image & measurements[["Object type"]] == "Cell", c("Image", "Cell: DAB: Mean")]
  hist_graph = plot_hist(subset, "Cell: DAB: Mean", 32, image)
  mean <- c(mean, hist_graph$mean)
  count <- c(count, hist_graph$count)
}

# Create new dataframe where image name is connected to Cell DAB mean and count
img_names <- gsub("^KI67|KI67_|KI67J|\\.ndpi$", "", unique_images)
img_names

data <- data.frame(Name = img_names, Mean = mean, Count = count)
data <- data[order(data$Mean), ]
rownames(data) <- NULL
data

# Plot Mean of Means across all slides

par(mar = c(8, 8, 4, 0), mgp = c(6, 1, 0))  # Move x-axis title farther from labels
x_labels <- paste(data$Name, "\n(n=", prettyNum(data$Count, big.mark = ",", scientific = FALSE), ")", sep = "")
barplot(data$Mean, names.arg = x_labels, las = 1, ylim = c(0, max(data$Mean) + 0.1), col = "skyblue", 
        main = "Cell DAB Mean values per slide", xlab = "KI67 Slide (count)", ylab = "Mean", 
        cex.names = 0.7)


