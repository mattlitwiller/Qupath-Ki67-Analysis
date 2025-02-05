import json
import cv2
from patched_yolo_infer import (
    MakeCropsDetectThem,
    CombineDetections,
    visualize_results
)
import numpy as np
import sys
from PIL import Image
import time
import argparse
import os
import re
from datetime import datetime

parser = argparse.ArgumentParser(description="Use model predictions on a slide image file.")
parser.add_argument('image', type=str, help="The image file to process")
parser.add_argument("detection_classes", type=str, default="germinal_center", help="The detection classes/folder (underscore joined)")
parser.add_argument('downsample', type=int, default=4, help="The downsample used to export the jpg in QuPath")
parser.add_argument('size', type=int, default=0, help="Tile size (which will be divided by downsample)")
parser.add_argument('--batch_folder', type=str, required = False, default=None, help="Folder for batch processing")
# parser.add_argument("--name", help="Disk name", required = False)

args = parser.parse_args()
classes = args.detection_classes
image_file = args.image
downsample = args.downsample
sz = args.size
batch_folder = args.batch_folder

# Arbitrarily defined color scheme in RGB vals
colors = {
    "germinal_center": [60, 192, 254],
    "light_zone": [192, 64, 45],
    "dark_zone": [101, 190, 75],
    "mantle": [26, 0, 104],
    "tonsil": [76, 89, 241],
    "appendix": [96, 189, 208]
}

date = datetime.today().strftime('%Y-%m-%d')

# Load the image 
image_path = f"../jpg/downsample{downsample}/{image_file}"
if batch_folder is not None: 
    image_path = f"../jpg/{batch_folder}/{image_file}"
img = cv2.imread(image_path)

# tile downsample * tile size = 4 * 780 = 3120    
# tile_size = 3120       # gc/lz/dz/mantle sizes
# size = int(2*tile_size / downsample)    #downsample = 4 --> size = 1560
size_x = 0
size_y = 0
if(sz <= 0):
    size_y, size_x, _ = img.shape
else:
    size_x = int(2*sz / downsample)
    size_y = size_x
# print(f"patch size: {size}")

# export_dir = f"../YOLO_model/output/allslides"
export_dir = f"../YOLO_model/output/{date}"
if (not os.path.exists(export_dir)):
    os.mkdir(export_dir)
yolo_model_path = f"../YOLO_model/{classes}/trained_yolo11n_{classes}.pt"

# start = time.time()

x_off = 0
y_off = 0

# Determine if we are looking at a subset of the WSI or the entire WSI. Subset ==> coordinates to tell us where roi begins and ends. Otherwise, WSI
matches = re.findall(r'(\w+)=(\d+\.?\d*)', image_file)
result_dict = {key: float(value) if '.' in value else int(value) for key, value in matches}

if(len(matches) > 0):
    x_off = result_dict.get("x")
    y_off = result_dict.get("y")

element_crops = MakeCropsDetectThem(
    image=img,
    model_path=yolo_model_path,
    segment=True,
    shape_x=size_x,
    shape_y=size_y,
    overlap_x=30,
    overlap_y=30,
    conf=0.2,
    iou=0.7,
    show_crops=False     # Shows number of images (but slows down computation significantly, only use for development)
)

# nms_threshold of 1 means it will not suppress any annotations due to overlap between tiles. 
# Increases number of annotations but reduces instances where we lose precision due to overlap
result = CombineDetections(element_crops, nms_threshold=0.8)  

confidences=result.filtered_confidences
polygons=result.filtered_polygons
classes_ids=result.filtered_classes_id
classes_names=result.filtered_classes_names

geojson_data = {
    "type": "FeatureCollection",
    "features": []
}

for i in range(len(classes_ids)):
    confidence = '{0:.2f}'.format(confidences[i])

    segmentation = polygons[i]
    segmentation_coordinates = []

    for j in range(0, len(segmentation)):
        segmentation_coordinates.append([int(segmentation[j][0] * downsample + x_off), int(segmentation[j][1] * downsample + y_off)])
    
    # Close the polygon
    if(len(segmentation_coordinates) > 0 and (segmentation_coordinates[0][0] != segmentation_coordinates[-1][0] or segmentation_coordinates[0][1] != segmentation_coordinates[-1][1])):
        segmentation_coordinates.append([int(segmentation[0][0] * downsample + x_off), int(segmentation[0][1] * downsample + y_off)])        

    feature = {
        "type": "Feature",
        "geometry": {
            "type": "Polygon",
            "coordinates": [segmentation_coordinates]
        },
        "properties": {
            "objectType": "annotation",
            "classification": {
                "name": classes_names[i],
                "color": colors[classes_names[i]]
            },
            "isLocked": True,
            "name": confidence      # Optional name field in QP
        }
    }

    geojson_data["features"].append(feature)

out_file = image_file.replace(" ", "_")
save_dest = f'{export_dir}/{os.path.splitext(out_file)[0]}_{classes}.geojson'

with open(save_dest, 'w') as f:
    json.dump(geojson_data, f, indent=4)

print(f"Inference and conversion to GeoJSON complete! The new GeoJSON file is saved to {save_dest}")

# end = time.time()
# print(f"Time: {'{0:.1f}'.format(end-start)} secs")

