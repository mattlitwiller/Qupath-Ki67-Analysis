import json
import argparse
import os

# Arbitrarily defined color scheme in RGB vals
colors = {
    "germinal_center": [60, 192, 254],
    "light_zone": [192, 64, 45],
    "dark_zone": [101, 190, 75],
    "mantle": [26, 0, 104]
}

parser = argparse.ArgumentParser(description=".")
parser.add_argument('sahi_json', type=str, help="The sahi json file to process")
parser.add_argument('out_file', type=str, help="The name of the output file")
parser.add_argument('downsample', type=int, default=8, help="The downsample used to export the jpg in QuPath")
args = parser.parse_args()
sahi_file = args.sahi_json
out_file = args.out_file
downsample = args.downsample

with open(f'../YOLO_model/output/{sahi_file}') as f:
    sahi_data = json.load(f)

# Prepare the GeoJSON structure
geojson_data = {
    "type": "FeatureCollection",
    "features": []
}

for item in sahi_data:
    bbox = item["bbox"]
    segmentation = item["segmentation"][0]
    confidence = '{0:.2f}'.format(item["score"])

    # Convert the bbox to a GeoJSON Polygon
    x, y, width, height = bbox
    bbox_coordinates = [
        [x, y],
        [x + width, y],
        [x + width, y + height],
        [x, y + height],
        [x, y]
    ]
    
    # Convert segmentation to GeoJSON Polygon
    segmentation_coordinates = []
    for i in range(0, len(segmentation), 2):
        segmentation_coordinates.append([segmentation[i] * downsample, segmentation[i + 1] * downsample])
    # Close the polygon
    if segmentation_coordinates[0] != segmentation_coordinates[-1]:
        segmentation_coordinates.append(segmentation_coordinates[0])

    # Old feature JSON layout (works for annotations but omits class names & colors in QP 0.5.1)

    # feature = {
    #     "type": "Feature",
    #     "geometry": {
    #         "type": "Polygon",
    #         "coordinates": [segmentation_coordinates]
    #     },
    #     "properties": {
    #         "label": item["category_name"],
    #         "bbox": bbox_coordinates
    #     }
    # }

    # QP0.5.1 compliant

    feature = {
        "type": "Feature",
        "geometry": {
            "type": "Polygon",
            "coordinates": [segmentation_coordinates]
        },
        "properties": {
            "objectType": "annotation",
            "classification": {
                "name": item["category_name"],
                "color": colors[item["category_name"]]
            },
            "isLocked": True,
            "name": confidence      # Optional name field in QP
        }
    }

    geojson_data["features"].append(feature)

save_dest = f'../YOLO_model/output/{out_file}.geojson'
with open(save_dest, 'w') as f:
    json.dump(geojson_data, f, indent=4)

print(f"Conversion complete! The new GeoJSON file is saved to {save_dest}")
