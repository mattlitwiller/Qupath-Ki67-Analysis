#!/usr/bin/env bash
batch_folder="jpg"
downsample=8

image_paths="D:/Qupath/ProjectTestbench/$batch_folder"

# Model folders with tile size for pbi step - folders should be contained within the yolo folder
declare -A model_folders
model_folders=(
  ["light_zone_dark_zone"]=3120
  ["germinal_center_mantle"]=3120
  ["tonsil_appendix"]=0
)

for detection_class in "${!model_folders[@]}"; do
  size="${model_folders[$detection_class]}"

  # Predict all files within a folder
  for file in "$image_paths"/*.jpg; do
    # echo $file
    [[ -f "$file" ]] || continue  # Skip if no .jpg files are found
    file_name=$(basename "$file" .jpg)
    downsample=8  # Set downsample to 8 for all files in the folder
    python pbi_yolo.py "$file_name".jpg "$detection_class" "$downsample" "$size" "--batch_folder" "$batch_folder"
  done
done

