import subprocess
import os
import argparse

parser = argparse.ArgumentParser(description="Script to setup conda environment and perform predictions within QuPath project")
parser.add_argument('model_dir', type=str, help="The model directory")
parser.add_argument("project_dir", type=str, help="The QuPath project script directory")
parser.add_argument("python_dir", type=str, help="The python script directory containing pbi_yolo.py")
parser.add_argument("downsample", type=float, help="The downsample value used in the WSItoJpg step")
parser.add_argument("req_path", type=str, help="The location of the requirements.txt file")

args = parser.parse_args()
model_dir = args.model_dir
project_dir = args.project_dir
python_dir = args.python_dir
downsample = args.downsample
req_path = args.req_path

env_name = "ki67"
result = subprocess.run("conda env list", shell=True, text=True, capture_output=True)

print(f"PWD================={os.getcwd()}")

if env_name not in result.stdout:
    print("Creating new conda environment for ki67 assessment...")
    subprocess.run(f"conda create --name {env_name} python=3.12.4 -y", shell=True, text=True)
    subprocess.run(f"conda run -n {env_name} conda info --envs", shell=True, text=True)

    # Install requirements
    failed_packages = []

    with open(req_path, "r") as file:
        for package in file:
            package = package.strip()
            if package:
                print(f"Installing: {package}")
                result = subprocess.run(f"conda run -n ki67 pip install {package}", capture_output=True, text=True)
                if result.returncode != 0:
                    print(f"Failed to install: {package}")
                    failed_packages.append(package)

    if failed_packages:
        print("\nThe following packages failed to install:")
        for pkg in failed_packages:
            print(pkg)
    else:
        print("\nAll packages installed successfully!")

else:
    print("\nConda environment already exists!")
# Run pbi
print("\nRunning pbi")

batch_folder = "jpg"

image_paths = os.path.join(project_dir, batch_folder)

# Model folders with tile size for pbi step - folders should be contained within the yolo folder
model_folders = {
    "light_zone_dark_zone": 3120,
    "germinal_center_mantle": 3120,
    "tonsil_appendix": 0,
}

downsamples_found = False
for detection_class, size in model_folders.items():
    
    # Predict all files within a folder
    if not os.path.exists(image_paths):
        print(f"Folder does not exist: {image_paths}")
        continue
    
    for file in os.listdir(image_paths):
        if file.endswith('.jpg') and file.startswith(f"{downsample}_"):
            downsamples_found = True
            file_path = os.path.join(image_paths, file)
            file_name, _ = os.path.splitext(file)
            
            # Execute the Python script with parameters in the ki67 conda environment
            subprocess.run([
                "conda", "run", "--name", "ki67", "python", 
                f"{python_dir}/pbi_yolo.py", f"{file_name}.jpg", detection_class, 
                str(downsample), str(size), 
                str(model_dir), str(project_dir), str(python_dir),
                "--batch_folder", batch_folder
            ])

if not downsamples_found:
    raise Exception(f"No images with downsample {downsample} found for yolo predictions.")
