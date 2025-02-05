#!/usr/bin/env bash
project_dir="D:/Qupath/Project3model"
combined_labels="light_zone_dark_zone";   #all detection classes with underscores in between e.g. light_zone_dark_zone_mantle
separated_labels="light_zone dark_zone";  #whitespace separated for the different detection classes e.g. light_zone dark_zone mantle

rm -r -f "$project_dir"/yolo/$combined_labels;
py train_val_split.py $project_dir $separated_labels ;
rm -r -f "$project_dir"/json/$combined_labels;
mkdir -p "$project_dir"/json/$combined_labels;
py bin2coco.py $project_dir $combined_labels $separated_labels;
py coco2yolo.py $project_dir $combined_labels;
py color_jitter.py "$project_dir"/yolo/"$combined_labels"/train/images; # time-consuming
py fix_dataset.py $project_dir $combined_labels;