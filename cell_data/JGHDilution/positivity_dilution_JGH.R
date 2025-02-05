region_colors <- c("light_zone" = "red", "dark_zone" = "green", "mantle" = "purple")
run_shapes <- c(1, 2, 3) # Example shapes: 1 for "circle", 2 for "triangle", 3 for "plus"


### Display positivity scatter plot for all slides 
pos_path <- "D:/Qupath-files/cell_data/JGHDilution/positivity/positivity.csv"
pos_measurements <- read.csv(pos_path, check.names = F) 
pos_measurements$Slide <- as.factor(pos_measurements$Slide)
pos_measurements$Positivity <- pos_measurements$Positivity * 100
pos_measurements <- pos_measurements[pos_measurements$Positivity != 0, ] 
pos_measurements$Fraction <- ifelse(
  grepl("full", pos_measurements$Slide), 1.0, # Handle "full" case
  ifelse(
    grepl("negative", pos_measurements$Slide), 0.0, # Handle "negative" case
    ifelse(
      grepl("out", pos_measurements$Slide), # Handle "___out___" notation
      as.numeric(sub(".*?([0-9]+)out([0-9]+).*", "\\1", pos_measurements$Slide)) / 
        as.numeric(sub(".*?([0-9]+)out([0-9]+).*", "\\2", pos_measurements$Slide)),
      NA # Fallback for unexpected cases
    )
  )
)
pos_measurements$Run <- as.numeric(gsub(".*run([0-9]+).*", "\\1", pos_measurements$Slide))

# View the dataframe
print(pos_measurements)


plot(
  pos_measurements$Fraction, 
  pos_measurements$Positivity, 
  type = "n", # Initialize without points
  xlab = "Fraction", 
  ylab = "Positivity", 
  main = "Positivity Dilution JGH",
  xlim = c(0, 1),
  ylim = c(0, 100)
)

# Add points to the plot
for (i in unique(pos_measurements$Run)) {
  subset_data <- pos_measurements[pos_measurements$Run == i, ]
  points(
    subset_data$Fraction,
    subset_data$Positivity,
    col = region_colors[subset_data$Region],
    pch = 16
  )
}

# Add legend for regions
legend(
  "topleft",
  legend = names(region_colors),
  col = region_colors,
  pch = 16, # Solid points for region legend
  title = "Region",
  box.lty = 0,
  bg = rgb(1, 1, 1, alpha = 0) # Transparent background
)