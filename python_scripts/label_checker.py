from ultralytics import YOLO
import matplotlib.pyplot as plt

# Load a sample image and its corresponding label
# image_path = '/home/mlitwiller/gc_detection/yolo/light_zone_dark_zone_mantle/train/images/KI67 1 in 4 [d=4,x=253088,w=2560,h=2560].jpg'
image_path = '/home/mlitwiller/gc_detection/yolo/light_zone_dark_zone_mantle/train/images/t1.jpg'
# label_path = '/home/mlitwiller/gc_detection/yolo/light_zone_dark_zone_mantle/train/labels/KI67 1 in 4 [d=4,x=253088,w=2560,h=2560].txt'
label_path = '/home/mlitwiller/gc_detection/yolo/light_zone_dark_zone_mantle/train/labels/t1.txt'


# Visualize the image and label
image = plt.imread(image_path)
plt.imshow(image)
plt.show()

# Load and visualize the label
with open(label_path, 'r') as file:
    labels = file.readlines()
    for label in labels:
        print(label)