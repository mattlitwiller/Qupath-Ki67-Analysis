region_colors <- c("germinal_center" = "blue", "light_zone" = "red", "dark_zone" = "green", "mantle" = "purple")
run_shapes <- c(1, 2, 3) # Example shapes: 1 for "circle", 2 for "triangle", 3 for "plus"


### Display positivity scatter plot for all slides 
pos_path <- "D:/Qupath-files/cell_data/positivity/positivity.csv"
pos_measurements <- read.csv(pos_path, check.names = F) 
pos_measurements$Slide <- as.factor(pos_measurements$Slide)
pos_measurements$Positivity <- pos_measurements$Positivity * 100
pos_measurements <- pos_measurements[pos_measurements$Positivity != 0, ] 

pos_measurements$Fraction <- ifelse(
  grepl("in", pos_measurements$Slide),
  with(pos_measurements, as.numeric(sub(".* (\\d+) in (\\d+).*", "\\1", Slide)) /
         as.numeric(sub(".* (\\d+) in (\\d+).*", "\\2", Slide))),
  0
)
pos_measurements$Run <- ifelse(grepl("run", pos_measurements$Slide),
                               as.numeric(sub(".*run(\\d+).*", "\\1", pos_measurements$Slide)),
                               1)
# View the dataframe
print(pos_measurements)


plot(
  pos_measurements$Fraction, 
  pos_measurements$Positivity, 
  type = "n", # Initialize without points
  xlab = "Fraction", 
  ylab = "Positivity", 
  main = "Positivity Dilution GLEN",
  xlim = c(0,1),
  ylim = c(0,100)
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
  box.lty = 0
)