library(plotly)

### Display positivity scatter plot for all slides 
pos_path1 <- "D:/Qupath-files/cell_data/ModelComparison/JGH/positivity/positivity.csv"
pos_measurements1 <- read.csv(pos_path1, check.names = F) 
pos_measurements1$Slide <- as.factor(pos_measurements1$Slide)
pos_measurements1$Positivity <- pos_measurements1$Positivity * 100
pos_measurements1 <- pos_measurements1[pos_measurements1$Positivity != 0, ] 

region_colors <- c("light_zone" = "#c0402d", 
                   "dark_zone" = "#65be4b", 
                   #    "mantle" = "#1a0068", 
                   "germinal_center" = "#3cc0fe")

pos_list <- split(pos_measurements1, pos_measurements1$Region)

pos_measurements1$Hospital <- "JGH"

pos_path2 <- "D:/Qupath-files/cell_data/ModelComparison/GLEN/positivity/positivity.csv"
pos_measurements2 <- read.csv(pos_path2, check.names = F) 
pos_measurements2$Slide <- as.factor(pos_measurements2$Slide)
pos_measurements2$Positivity <- pos_measurements2$Positivity * 100
pos_measurements2 <- pos_measurements2[pos_measurements2$Positivity != 0, ] 

pos_list2 <- split(pos_measurements2, pos_measurements2$Region)

pos_measurements2$Hospital <- "GLEN"


pos_path3 <- "D:/Qupath-files/cell_data/ModelComparison/BOTH/positivity/positivity.csv"
pos_measurements3 <- read.csv(pos_path3, check.names = F) 
pos_measurements3$Slide <- as.factor(pos_measurements3$Slide)
pos_measurements3$Positivity <- pos_measurements3$Positivity * 100
pos_measurements3 <- pos_measurements3[pos_measurements3$Positivity != 0, ] 

pos_list3 <- split(pos_measurements3, pos_measurements3$Region)

pos_measurements3$Hospital <- "BOTH"

pos_measurements <- rbind(pos_measurements1, pos_measurements2)
pos_measurements <- rbind(pos_measurements, pos_measurements3)

#Only include regions from region_colors
pos_measurements <- pos_measurements[pos_measurements$Region %in% names(region_colors), ]

# Remove 0 values for calculations
pos_measurements$Color <- region_colors[pos_measurements$Region]

# Add a new column combining Region and Hospital
pos_measurements$Region_Hospital <- paste(pos_measurements$Region, pos_measurements$Hospital, sep = ".")
pos_measurements$Region_Hospital <- gsub("\\.", " - ", pos_measurements$Region_Hospital)
pos_measurements$Region_Hospital <- tools::toTitleCase(gsub("_", " ", pos_measurements$Region_Hospital))

# Split the data by Region and Hospital
split_data <- split(pos_measurements, list(pos_measurements$Region, pos_measurements$Hospital))

# Calculate mean and standard deviation for each Region and Hospital combination
stdev_by_region_hospital <- sapply(split_data, function(x) sd(x$Positivity))
mean_by_region_hospital <- sapply(split_data, function(x) mean(x$Positivity))

# Convert the results to data frames
stdev_by_region_hospital_df <- data.frame(
  Region_Hospital = names(stdev_by_region_hospital),
  Stdev = unname(stdev_by_region_hospital), # Remove names from the vector
  RegionMean = unname(mean_by_region_hospital) # Remove names from the vector
)

stdev_by_region_hospital_df$Region_Hospital <- gsub("\\.", " - ", stdev_by_region_hospital_df$Region_Hospital)
stdev_by_region_hospital_df$Region_Hospital <- tools::toTitleCase(gsub("_", " ", stdev_by_region_hospital_df$Region_Hospital))
pos_measurements <- merge(pos_measurements, stdev_by_region_hospital_df, by = "Region_Hospital", all.x = TRUE)

pos_measurements$RegionHospitalNumeric <- as.numeric(as.factor(pos_measurements$Region_Hospital))
stdev_by_region_hospital_df$RegionHospitalNumeric <- as.numeric(as.factor(stdev_by_region_hospital_df$Region_Hospital))

offset = 0.3

# Create the original scatter plot
p <- plot_ly(
  data = pos_measurements, 
  x = ~RegionHospitalNumeric, 
  y = ~Positivity, 
  type = 'scatter', 
  mode = 'markers',
  name = ~Region,
  text = ~paste("Slide: ", Slide,
                "<br>Hospital: ", Hospital, 
                "<br>Positivity: ", round(Positivity, 2), "%"),  # Hover info
  hoverinfo = 'text',  # Only show custom text on hover
  marker = list(color = ~Color, size = 8)  # Customize marker color and size
)
# Add mean and error bars
p <- p %>% add_trace(
  data = stdev_by_region_hospital_df,
  x = ~RegionHospitalNumeric + offset,  # Custom x value
  y = ~RegionMean,               # Custom y value
  type = 'scatter', 
  mode = 'markers',
  marker = list(color = 'black', size = 10, symbol = 'o'),  # Customize appearance
  name = "Region Mean",  # Legend label for the custom point
  text = ~paste("Region: ", Region_Hospital,
                "<br>Mean: ", round(RegionMean, 2), "%", 
                "<br>Stdev: ", round(Stdev, 2)),  # Hover info
  hoverinfo = 'text',
  error_y = list(
    type = 'data',                # Indicates that error bars use data values
    array = ~Stdev,    # Upper error values
    visible = TRUE, 
    color = 'black',
    line = list(color = 'black')
  )
)

# Create annotations for each point
annotations <- lapply(1:nrow(stdev_by_region_hospital_df), function(i) {
  list(
    x = stdev_by_region_hospital_df$RegionHospitalNumeric[i] + offset * 2,
    y = stdev_by_region_hospital_df$RegionMean[i],
    text = paste(round(stdev_by_region_hospital_df$RegionMean[i], 2), "%", 
                 "<br>+/- ", round(stdev_by_region_hospital_df$Stdev[i], 2)),
    showarrow = FALSE,
    font = list(size = 10, weight = 'bold'),
    align = "left"
  )
})

# Customize layout
p <- p %>% layout(
  title = "Non-Zero Cell Positivity By Slide Regions for models trained on JGH, GLEN and BOTH datasets (OD threshold = 0.2)",
  xaxis = list(
    title = "Slide Region - Training Dataset",
    tickvals = unique(pos_measurements$RegionHospitalNumeric),
    ticktext = unique(pos_measurements$Region_Hospital)),
  yaxis = list(title = "Slide Region Positivity (%)"),
  hovermode = "closest",
  annotations = annotations,
  showlegend = F
)

# Show the plot
p