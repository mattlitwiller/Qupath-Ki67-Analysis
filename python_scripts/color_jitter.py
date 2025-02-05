import os
from PIL import Image
from torchvision import transforms
import argparse
import random
import math

parser = argparse.ArgumentParser(description=".")
parser.add_argument('train_dir', type=str, help="The train directory for dataset images")
args = parser.parse_args()
train_dir = args.train_dir

color_jitter = transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.3, hue=0.1)

# Color jitter 25% of the training set
# frac = 0.25
image_files = [f for f in os.listdir(train_dir) if f.lower().endswith(('.jpg'))]
# image_files = random.sample(image_files, math.ceil(frac * len(image_files)))

# Loop through the selected files
for filename in image_files:
    # Create the full file path
    file_path = os.path.join(train_dir, filename)

    try:
        image = Image.open(file_path)
        jittered_image = color_jitter(image)

        # Replace the original image
        jittered_image.save(file_path)
        
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

print("Color jittering applied to selected images in the directory.")
