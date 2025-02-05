import os
import shutil
import random
from glob import glob
import argparse
import re

parser = argparse.ArgumentParser(description="Process tiles for multiple classes into a unified dataset.")
parser.add_argument('proj_dir', type=str, help="The project directory")
parser.add_argument('classes', type=str, nargs='+', help="The class folders to process (e.g. (space-separated): 'light_zone dark_zone mantle'")
args = parser.parse_args()
classes = args.classes
proj_dir = args.proj_dir

print("Combining images and masks into unified training and validation sets...")

split = 0.7  # Split ratio for training/validation

val_set = []
# val_set = ["CaseKI67_0001",
#            "CaseKI67_0007",
#            "CaseKI67_0017",
#            "CaseKI67_0018",
#            "CaseKI67_0026",
#            "CaseKI67_0027",
#            "CaseKI67_0033",
#            "CaseKI67_0038",
#            "CaseKI67_0039",
#            "CaseKI67_0041",
#            "CaseKI67J_0002",
#            "CaseKI67J_0006",
#            "CaseKI67J_0010",
#            "CaseKI67J_0011",
#            "CaseKI67J_0016",
#            "CaseKI67J_0020",
#            "CaseKI67J_0023",
#            "CaseKI67J_0025",
#            "CaseKI67J_0030"
# ]

classes_str = "_".join(classes)

# Define the output paths for combined data
combined_path = f"{proj_dir}/yolo/{classes_str}"
train_images_path = os.path.join(combined_path, "train_images")
val_images_path = os.path.join(combined_path, "val_images")
train_masks_path = os.path.join(combined_path, "train_masks")
val_masks_path = os.path.join(combined_path, "val_masks")

# Create directories if they don't exist
os.makedirs(train_images_path, exist_ok=True)
os.makedirs(val_images_path, exist_ok=True)
os.makedirs(train_masks_path, exist_ok=True)
os.makedirs(val_masks_path, exist_ok=True)

# For each class folder, we need to store its mask files in a subfolder
for class_name in classes:
    os.makedirs(os.path.join(train_masks_path, class_name), exist_ok=True)
    os.makedirs(os.path.join(val_masks_path, class_name), exist_ok=True)

# Function to move files
def copy_files(tile_names, src_images_path, src_labels_path, dest_images_path, dest_labels_path, dest_class):
    for tile_name in tile_names:
        # Move the image files
        image_file = os.path.join(src_images_path, f"{tile_name}.jpg")
        if os.path.exists(image_file):
            shutil.copy2(image_file, os.path.join(dest_images_path, f"{tile_name}.jpg"))
        
        # Move the label (mask) files
        label_file = os.path.join(src_labels_path, f"{tile_name}.png")
        if os.path.exists(label_file):
            shutil.copy2(label_file, os.path.join(dest_labels_path, f"{dest_class}/{tile_name}.png"))


'''
Get list of all file names: KI67_0054[d=2,x=4,etc.].jpg -> KI67_0054[d=2,x=4,etc.].
shuffle the list and split 30% into val 70% into training
go back into folders and add files with these names to their respective training or val sets
'''

trailblazer = classes[0] # Extract first class since all classes contain the same tiles

class_path = f"{proj_dir}/tiles/{trailblazer}"
images_path = f"{class_path}/Images"

# Get all image files in the current class folder
# tile_names = set(glob(os.path.join(images_path, "*.jpg")))
tile_names = set(os.path.splitext(os.path.basename(f))[0] for f in glob(os.path.join(images_path, "*.jpg")))

# Shuffle and split images for training and validation
new_tile_names = list(tile_names)
random.shuffle(new_tile_names)
split_idx = int(split * len(new_tile_names))

new_train_tiles = new_tile_names[:split_idx]
new_val_tiles = new_tile_names[split_idx:]

if(len(val_set) > 0):
    for tile in new_tile_names:       
        result = re.match(r'^[^\[]+', tile).group(0)     
        if result in val_set:
            new_val_tiles.append(tile)
        else:
            new_train_tiles.append(tile)


# print(f"{len(new_val_tiles)}{new_val_tiles}")
# print("\n\n")
# print(f"{len(new_train_tiles)}{new_train_tiles}")

for class_name in classes:
    class_path = f"{proj_dir}/tiles/{class_name}"
    images_path = os.path.join(class_path, "Images")
    labels_path = os.path.join(class_path, "Labels")

    # Move files for this class to the combined dataset
    copy_files(new_train_tiles, images_path, labels_path, train_images_path, train_masks_path, class_name)
    copy_files(new_val_tiles, images_path, labels_path, val_images_path, val_masks_path, class_name)

print("Dataset successfully combined!")