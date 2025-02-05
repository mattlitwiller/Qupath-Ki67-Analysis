setwd("D:/Qupath/Cell_Data")

data <- list()
files = list("KI67_1_10.txt", "KI67_0090.txt", "KI67_0083.txt", "KI67_0030.txt", "KI67_0027.txt", "KI67_0021.txt")

for (i in 1:length(files)) {
  data[[i]] <- c(data, read.delim(files[[i]], header = T, check.names = F))
}

plot_hist <- function(d, colName, bins, file) {
  # Set parameters for histogram
  metric = d[[colName]]    # Metric to track
  
  # Summary Statistics
  count <- length(metric)
  mean <- mean(metric, na.rm = TRUE)
  sd <- sd(metric, na.rm = TRUE)
  min <- min(metric, na.rm = TRUE)
  max <- max(metric, na.rm = TRUE)
  
  hist(metric, breaks=seq(min, max, length.out = bins), main=paste("Histogram of", colName, "(", file,")"))
  
  sprintf("Count: %d", count)
  sprintf("Mean: %f", mean)
  sprintf("Std. Dev: %f", sd)
  sprintf("Min: %f", min)
  sprintf("Max: %f", max)
  
  ret_list <- list(mean = mean, count = count)
  return(ret_list)
}

file_name <- character()
mean <- numeric()
count <- numeric()
for (i in 1: length(data)) {
  file_name <- c(file_name, files[[i]])
  hist_graph = plot_hist(data[[i]], "Cell: DAB: Mean", 32, files[[i]])
  mean <- c(mean, hist_graph$mean)
  count <- c(count, hist_graph$count)
}

# Create a bar plot
windows(width = 8, height = 6)  # You can adjust the width and height
x_labels <- paste(file_name, " (n=", count, ")", sep = "")
barplot(mean, names.arg = x_labels, las = 2, ylim = c(0, max(mean) + 0.1), col = "skyblue", 
        main = "Mean Values per File", xlab = "File Name (Count)", ylab = "Mean")

