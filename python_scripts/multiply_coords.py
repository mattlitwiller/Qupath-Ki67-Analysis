import json
import argparse
import os

parser = argparse.ArgumentParser(description=".")
parser.add_argument('sahi_geojson', type=str, help="The sahi geojson file to process")
parser.add_argument('output_file_name', type=str, help="The output file name (without file extension)")
args = parser.parse_args()
sahi_file = args.sahi_geojson
out_file_name = args.output_file_name

input_file = f"../YOLO_model/output/{sahi_file}"
output_file = f"../YOLO_model/output/{out_file_name}.geojson"

# Function to multiply all coordinates by 4
def multiply_coordinates(data, factor):
    for feature in data['features']:
        # Update the coordinates in the geometry field
        feature['geometry']['coordinates'] = [
            [[x * factor, y * factor] for x, y in polygon]
            for polygon in feature['geometry']['coordinates']
        ]
        
        # Update the bbox in the properties field
        if 'bbox' in feature['properties']:
            feature['properties']['bbox'] = [
                [x * factor, y * factor] for x, y in feature['properties']['bbox']
            ]

# Read data from file
with open(input_file, 'r') as f:
    data = json.load(f)

# Multiply coordinates and bbox values by scaling factor
scale_factor = 4
multiply_coordinates(data, scale_factor)

# Write the updated data to a new file
with open(output_file, 'w') as f:
    json.dump(data, f, indent=4)

print(f"Updated data saved to {output_file}")