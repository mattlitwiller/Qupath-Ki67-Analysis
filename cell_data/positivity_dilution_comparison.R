region_colors <- c("light_zone" = "red", "dark_zone" = "green", "mantle" = "purple")
hospital_shapes <- c("GLEN" = 16, "JGH" = 1)  # Add as needed for more hospitals


### GLEN DATA
pos_glen_path <- "D:/Qupath-files/cell_data/GlenDilution/positivity/positivity.csv"
glen_measurements <- read.csv(pos_glen_path, check.names = F) 
glen_measurements$Slide <- as.factor(glen_measurements$Slide)
glen_measurements$Positivity <- glen_measurements$Positivity * 100
glen_measurements <- glen_measurements[glen_measurements$Positivity != 0, ] 

glen_measurements$Fraction <- ifelse(
  grepl("in", glen_measurements$Slide),
  with(glen_measurements, as.numeric(sub(".* (\\d+) in (\\d+).*", "\\1", Slide)) /
         as.numeric(sub(".* (\\d+) in (\\d+).*", "\\2", Slide))),
  0
)
glen_measurements$Run <- ifelse(grepl("run", glen_measurements$Slide),
                               as.numeric(sub(".*run(\\d+).*", "\\1", glen_measurements$Slide)),
                               1)
glen_measurements$Hospital <- "GLEN"


### JGH DATA
pos_jgh_path <- "D:/Qupath-files/cell_data/JGHDilution/positivity/positivity.csv"
jgh_measurements <- read.csv(pos_jgh_path, check.names = F) 
jgh_measurements$Slide <- as.factor(jgh_measurements$Slide)
jgh_measurements$Positivity <- jgh_measurements$Positivity * 100
jgh_measurements <- jgh_measurements[jgh_measurements$Positivity != 0, ] 
jgh_measurements$Fraction <- ifelse(
  grepl("full", jgh_measurements$Slide), 1.0, # Handle "full" case
  ifelse(
    grepl("negative", jgh_measurements$Slide), 0.0, # Handle "negative" case
    ifelse(
      grepl("out", jgh_measurements$Slide), # Handle "___out___" notation
      as.numeric(sub(".*?([0-9]+)out([0-9]+).*", "\\1", jgh_measurements$Slide)) / 
        as.numeric(sub(".*?([0-9]+)out([0-9]+).*", "\\2", jgh_measurements$Slide)),
      NA # Fallback for unexpected cases
    )
  )
)
jgh_measurements$Run <- as.numeric(gsub(".*run([0-9]+).*", "\\1", jgh_measurements$Slide))
jgh_measurements$Hospital <- "JGH"

print(jgh_measurements)

pos_measurements <- rbind(jgh_measurements, glen_measurements)
print(pos_measurements)

plot(
  pos_measurements$Fraction, 
  pos_measurements$Positivity, 
  type = "n", # Initialize without points
  xlab = "Fraction", 
  ylab = "Positivity", 
  main = "Positivity Dilution Comparison",
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
    pch = hospital_shapes[subset_data$Hospital]
  )
}

# Add legend for regions
legend(
  "topright",
  inset = c(0.05, 0), # Moves the legend left
  legend = names(region_colors),
  col = region_colors,
  pch = 16, # Solid points for region legend
  title = "Region",
  box.lty = 0,
  bg = rgb(1, 1, 1, alpha = 0) # Transparent background
)

# Add legend for hospitals (shape)
legend(
  "topleft",
  legend = names(hospital_shapes),
  pch = hospital_shapes, # Shape varies for hospital
  title = "Hospital",
  box.lty = 0,
  bg = rgb(1, 1, 1, alpha = 0) # Transparent background
)

# Horizontal lines
for (y in seq(0, 100, by = 10)) {
  abline(h = y, col = "grey", lty = 2) # Horizontal dashed line at each increment
}