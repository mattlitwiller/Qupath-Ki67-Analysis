#!/usr/bin/env bash
batch_folder="dilution_run6"
downsample=8

image_paths="../jpg/$batch_folder"

# Model folders with tile size for pbi step - folders should be contained within the yolo folder
declare -A model_folders
model_folders=(
  ["light_zone_dark_zone"]=3120
  ["germinal_center_mantle"]=3120
  ["tonsil_appendix"]=0
)

# Path to the folder containing the training directories
folder_path="./runs/segment"

# Extract the highest training number - the one that will be created by the yolo_model.py script
last_train=$(ls "$folder_path" | grep -Eo 'train[0-9]+' | grep -Eo '[0-9]+' | sort -n | tail -1)

if [ -n "$last_train" ]; then
  echo "The last training number is: $last_train"
else
  echo "No training directories found."
fi

for detection_class in "${!model_folders[@]}"; do
  size="${model_folders[$detection_class]}"

  # Predict all files within a folder
  for file in "$image_paths"/*.jpg; do
    # echo $file
    [[ -f "$file" ]] || continue  # Skip if no .jpg files are found
    file_name=$(basename "$file" .jpg)
    downsample=8  # Set downsample to 8 for all files in the folder
    python3 pbi_yolo.py "$file_name".jpg "$detection_class" "$downsample" "$size" "--batch_folder" "$batch_folder"
  done

  # mkdir -p runs/segment/train"$last_train"/input
  # cp -r ../yolo/"$detection_class" runs/segment/train"$last_train"/input
  # cp -r ../YOLO_model/"$detection_class" runs/segment/train"$last_train"/input
done

