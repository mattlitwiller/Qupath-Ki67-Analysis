library(plotly)

### Display positivity scatter plot for all slides 
pos_path <- "D:/Qupath-files/cell_data/AllSlides2_NewModels/positivity/positivity.csv"
pos_measurements <- read.csv(pos_path, check.names = F) 
pos_measurements$Slide <- as.factor(pos_measurements$Slide)
pos_measurements$Positivity <- pos_measurements$Positivity * 100
all_measurements <- pos_measurements
pos_measurements <- pos_measurements[pos_measurements$Positivity != 0, ] 

region_colors <- c("light_zone" = "#c0402d", 
                   "dark_zone" = "#65be4b", 
               #    "mantle" = "#1a0068", 
                   "germinal_center" = "#3cc0fe")


pos_measurements <- pos_measurements[pos_measurements$Region %in% names(region_colors), ]

pos_list <- split(pos_measurements, pos_measurements$Region)

pos_measurements$Hospital <- ifelse(grepl("J", pos_measurements$Slide), "JGH", "GLEN")

# Remove 0 values for calculations
pos_measurements_zeros <- all_measurements[all_measurements$Positivity == 0, ] 
print("Slides & regions with 0 positivity: (likely 0 detections)")
print(pos_measurements_zeros)
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
                "<br>Positivity: ", round(Positivity, 2), "%",
                "<br>Count: ", Count),  # Hover info
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
  title = "Non-Zero Slide Cell Positivity by Region and Hospital (DAB threshold = 0.15)",
  xaxis = list(
    title = "Slide Region - Hospital",
    tickvals = unique(pos_measurements$RegionHospitalNumeric),
    ticktext = unique(pos_measurements$Region_Hospital)),
  yaxis = list(title = "Slide Region Positivity (%)"),
  hovermode = "closest",
  annotations = annotations,
  showlegend = F
)

# Show the plot
p

print("Slides & regions with 0 positivity: (likely 0 detections)")
print(pos_measurements_zeros[pos_measurements_zeros$Region != "germinal_center", ])


pos_measurements[pos_measurements$Slide == "CaseKI67J_0030", ]


### Different categories
# 1. Blurry images: mantle region tends to be high
# 2. Lack of staining: DZ/LZ tend to have low positivity
# 3. Small sample size: can skew results any direction
# 4. 
#
#
#