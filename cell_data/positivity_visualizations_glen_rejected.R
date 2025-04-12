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

stdev_by_region_hospital_df
pos_measurements

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
    title = "Slide Region",
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





## Additional analysis for rejected stuff
## Finding values below 2 stdev for each hospital
filtered_df <- pos_measurements[pos_measurements$Positivity + 2*pos_measurements$Stdev < pos_measurements$RegionMean, ]

# Small cheat to keep only unique slide names (will remove duplicate entries if our only concern is counting the number of slides)
unique_filtered_df <- filtered_df[!duplicated(filtered_df$Slide), ]
unique_filtered_df_zeroes <- pos_measurements_zeros[!duplicated(pos_measurements_zeros$Slide), ]

num_unique_slides <- length(unique(pos_measurements$Slide))

# Count the number of unique Slide entries for Hospital "GLEN"
glen_data <- pos_measurements[pos_measurements$Hospital == "GLEN", ]
num_unique_slides_glen <- length(unique(glen_data$Slide))





# Filter pos_measurements for GLEN only
glen_df <- pos_measurements[grepl("GLEN", pos_measurements$Region_Hospital) & 
                              !grepl("JGH", pos_measurements$Region_Hospital), ]

# Filter stdev_by_region_hospital_df for GLEN only
glen_stdev_df <- stdev_by_region_hospital_df[grepl("GLEN", stdev_by_region_hospital_df$Region_Hospital) & 
                                               !grepl("JGH", stdev_by_region_hospital_df$Region_Hospital), ]



# Start from unique_filtered_df_zeroes
glen_zero_df <- unique_filtered_df_zeroes[!grepl("J", unique_filtered_df_zeroes$Slide), ]

# Assign RegionHospitalNumeric
glen_zero_df$RegionHospitalNumeric <- ifelse(
  glen_zero_df$Region == "dark_zone", 1,
  ifelse(glen_zero_df$Region == "light_zone", 5,
         ifelse(glen_zero_df$Region == "germinal_center", 3, NA))
)

# Assign matching colors
glen_zero_df$Color <- region_colors[glen_zero_df$Region]


# Add Hospital, Region_Hospital
glen_zero_df$Hospital <- "GLEN"
# glen_zero_df$Region_Hospital <- paste(glen_zero_df$Region, glen_zero_df$Hospital, sep = "_")
glen_zero_df$Region_Hospital <- paste(tools::toTitleCase(gsub("_", " ", glen_zero_df$Region)), glen_zero_df$Hospital, sep = " - ")

# Assign RegionMean = 0
glen_zero_df$RegionMean <- 0

# Assign offset = 0
glen_zero_df$offset <- 0

# Match Stdev from glen_df by RegionHospitalNumeric
region_stdevs <- tapply(glen_data$Stdev, glen_data$RegionHospitalNumeric, function(x) unique(x)[1])
glen_zero_df$Stdev <- region_stdevs[as.character(glen_zero_df$RegionHospitalNumeric)]

# Ensure column order matches glen_df
glen_zero_df <- glen_zero_df[, names(glen_data)]


# Assign RegionMean based on Region_Hospital
glen_zero_df$RegionMean <- glen_stdev_df$RegionMean[match(glen_zero_df$Region_Hospital, glen_stdev_df$Region_Hospital)]


# Append to glen_df
glen_df_with_zeros <- rbind(glen_data, glen_zero_df)

# Determine threshold for each row
glen_df_with_zeros$LowerThreshold <- glen_df_with_zeros$RegionMean - 2 * glen_df_with_zeros$Stdev

# Mark rows as below threshold
glen_df_with_zeros$BelowThreshold <- glen_df_with_zeros$Positivity < glen_df_with_zeros$LowerThreshold

# Assign marker symbol: 'x' for below threshold, 'circle' otherwise
glen_df_with_zeros$MarkerSymbol <- ifelse(glen_df_with_zeros$BelowThreshold, 'x', 'circle')



# Create the GLEN-only scatter plot
p <- plot_ly(
  data = glen_df_with_zeros, 
  x = ~RegionHospitalNumeric, 
  y = ~Positivity, 
  type = 'scatter', 
  mode = 'markers',
  name = ~Region,
  text = ~paste("Slide: ", Slide,
                "<br>Hospital: ", Hospital, 
                "<br>Positivity: ", round(Positivity, 2), "%",
                "<br>Count: ", Count),
  hoverinfo = 'text',
  marker = list(
    color = ~Color, 
    size = 8,
    symbol = ~MarkerSymbol  # ← key part here
  )
)
# Add mean and error bars (GLEN only)
p <- p %>% add_trace(
  data = glen_stdev_df,
  x = ~RegionHospitalNumeric + offset,
  y = ~RegionMean,
  type = 'scatter', 
  mode = 'markers',
  marker = list(color = 'black', size = 10, symbol = 'o'),
  name = "Region Mean",
  text = ~paste("Region: ", Region_Hospital,
                "<br>Mean: ", round(RegionMean, 2), "%", 
                "<br>Stdev: ", round(Stdev, 2)),
  hoverinfo = 'text',
  error_y = list(
    type = 'data',
    array = ~Stdev,
    visible = TRUE,
    color = 'black',
    line = list(color = 'black')
  )
)
# Create annotations for GLEN-only region means
annotations <- lapply(1:nrow(glen_stdev_df), function(i) {
  list(
    x = glen_stdev_df$RegionHospitalNumeric[i] + offset * 2,
    y = glen_stdev_df$RegionMean[i],
    text = paste(round(glen_stdev_df$RegionMean[i], 2), "%", 
                 "<br>+/- ", round(glen_stdev_df$Stdev[i], 2)),
    showarrow = FALSE,
    font = list(size = 10, weight = 'bold'),
    align = "left"
  )
})
p <- p %>% layout(
  title = "Cell Positivity Above and Below 2 Stdev by Region (GLEN Only, DAB threshold = 0.15)",
  xaxis = list(
    title = "Slide Region",
    tickvals = unique(glen_df_with_zeros$RegionHospitalNumeric),
    ticktext = unique(glen_df_with_zeros$Region_Hospital)),
  yaxis = list(title = "Slide Region Positivity (%)"),
  hovermode = "closest",
  annotations = annotations,
  showlegend = FALSE
)

# Show the plot
p



# Compute threshold per region
glen_df_with_zeros$LowerThreshold <- glen_df_with_zeros$RegionMean - 2 * glen_df_with_zeros$Stdev

# Determine if each row is below threshold
glen_df_with_zeros$BelowThreshold <- glen_df_with_zeros$Positivity < glen_df_with_zeros$LowerThreshold

# Determine which slides have ANY region below the threshold
slide_flags <- aggregate(BelowThreshold ~ Slide, data = glen_df_with_zeros, FUN = any)

# Count how many slides are below vs not below
pie_data <- data.frame(
  Category = c("1+ Region Below 2 Stdev", "All Regions Above or Equal to 2 Stdev"),
  Count = c(sum(slide_flags$BelowThreshold), sum(!slide_flags$BelowThreshold))
)

# Plot pie chart
pie_chart <- plot_ly(
  data = pie_data,
  labels = ~Category,
  values = ~Count,
  type = 'pie',
  textinfo = 'label+percent',
  marker = list(colors = c("#e74c3c", "#2ecc71"))  # red and green
) %>%
  layout(title = "GLEN Slides With Any Region Below 2 Stdev of Region Mean (DAB threshold = 0.15)")

pie_chart






### Different categories
# 1. Blurry images: mantle region tends to be high
# 2. Lack of staining: DZ/LZ tend to have low positivity
# 3. Small sample size: can skew results any direction
# 4. 
