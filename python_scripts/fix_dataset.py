import argparse 
import tempfile
import shutil

parser = argparse.ArgumentParser(description=".")
parser.add_argument('proj_dir', type=str, help="The project directory")
parser.add_argument('combined_labels', type=str, help="The combined labels")
args = parser.parse_args()
proj_dir = args.proj_dir
combined_labels = args.combined_labels

# Define the input file path
input_file = f"{proj_dir}/yolo/{combined_labels}/dataset.yaml"

# Create a temporary file to write the modified content
with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
    temp_file_name = temp_file.name  # Store the temporary file name for later

    # Read the input file and replace specific lines
    with open(input_file, 'r') as infile:
        for line in infile:
            if line.startswith("test:"):
                temp_file.write("test: /test\n")
            elif line.startswith("train:"):
                temp_file.write("train: ../train\n")
            elif line.startswith("val:"):
                temp_file.write("val: ../val\n")
            else:
                temp_file.write(line)

# Overwrite the original file with the modified content
shutil.move(temp_file_name, input_file)
