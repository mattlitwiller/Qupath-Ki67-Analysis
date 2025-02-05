import os
import shutil
from ultralytics import YOLO
import torch
import argparse
import re

parser = argparse.ArgumentParser(description=".")
parser.add_argument('yolo_labels', type=str, help="The label folder to process")
args = parser.parse_args()
yolo_labels = args.yolo_labels

cwd = os.getcwd()

yolo_path = "../yolo"
yolo_model_dir = "..YOLO_model"
train_path = "./runs/segment"
model_name = "yolo11n-seg.pt"
data_path = f"{cwd}/../yolo/{yolo_labels}/dataset.yaml"
save_dir = f"{cwd}/../YOLO_model/{yolo_labels}"

# Model training parameters
epochs = 200
imgsz = 640
batch = 16
patience = 40

# Function to train the model
def train_yolo_model(model_name, data_path, save_dir, epochs=20, imgsz=640, batch = 8, patience=8):
    # Load the pretrained model
    model = YOLO(model_name)
    
    # Check if GPU is available
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    #device = 'mps' if torch.backends.mps.is_available() else 'cpu'

    print(f"Training on: {device}")
    
    # Train the model
    results = model.train(data=data_path, epochs=epochs, imgsz=imgsz, batch=batch, device=device, verbose=True, patience=patience)
    
    # Get the directory where the model was saved
    run_dir = results.save_dir
    
    # Find the best model path
    best_model_path = os.path.join(run_dir, "weights", "best.pt")
    
    # Ensure save directory exists
    os.makedirs(save_dir, exist_ok=True)
    
    # Define save path
    final_model_path = os.path.join(save_dir, f"trained_yolo11n_{yolo_labels}.pt")
    
    # Copy the best model
    shutil.copy(best_model_path, final_model_path)
    
    print(f"Model saved to: {final_model_path}")
    return final_model_path

def get_last_train():
    # List all directories in the folder
    directories = os.listdir(train_path)

    # Extract training numbers from directories that match the 'train<number>' pattern
    train_numbers = []
    for dir_name in directories:
        match = re.match(r'train(\d+)', dir_name)
        if match:
            train_numbers.append(int(match.group(1)))

    # Find the highest training number if available
    if train_numbers:
        last_train = max(train_numbers)
    else:
        print("No training directories found.")
    
    return last_train

def save_inputs(detection_class, last_train, base_path, detection_class_src_yolo, detection_class_src_yolo_model):
    # Create the target directory if it doesn't exist
    os.makedirs(base_path, exist_ok=True)
    os.makedirs(detection_class_src_yolo_model, exist_ok=True)

    # Copy the detection class from yolo folder
    shutil.copytree(detection_class_src_yolo, os.path.join(base_path, detection_class), dirs_exist_ok=True)

    # Copy the detection class from YOLO_model folder
    shutil.copytree(detection_class_src_yolo_model, os.path.join(base_path, detection_class), dirs_exist_ok=True)

    print("Model inputs saved in " + base_path)

def save_model(model_path, last_train):
    model_save_path = f'{train_path}/train{last_train}/model'
    os.makedirs(model_save_path, exist_ok=True)
    shutil.copy(model_path, model_save_path)
    print("Model saved in " + model_save_path)

if __name__ == "__main__":
    # Matthew paths
    yolo_data_path = f"{yolo_path}/{yolo_labels}"
    yolo_input_path = f"{yolo_data_path}/input"
    
    # Train and save the model
    model_path = None
    try:
        model_path = train_yolo_model(model_name, data_path, save_dir, epochs, imgsz, batch, patience)
    except Exception as e:
        print(f"An error occurred during training: {e}")
    
    # last_train = get_last_train()
    # model_input_save_path = f'{train_path}/train{last_train}/input'


    # Save inputs that created the model
    # save_inputs(yolo_labels, last_train, model_input_save_path, yolo_data_path, save_dir)

    # Save model in same location as training results & input 
    # save_model(model_path, last_train)
 