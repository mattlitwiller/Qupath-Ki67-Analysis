import cv2
import numpy as np

purple_img = "D:/Qupath/ProjectAllTestSlides2/Jpg/CaseKI67_0090.jpg"

def white_balance(img):
    result = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    avg_a = np.average(result[:, :, 1])
    avg_b = np.average(result[:, :, 2])
    result[:, :, 1] = result[:, :, 1] - ((avg_a - 128) * (result[:, :, 0] / 255.0) * 1.1)
    result[:, :, 2] = result[:, :, 2] - ((avg_b - 128) * (result[:, :, 0] / 255.0) * 1.1)
    result = cv2.cvtColor(result, cv2.COLOR_LAB2BGR)
    return result

# Load the purple image
purple_image = cv2.imread(purple_img)

# Apply white balance
balanced_image = white_balance(purple_image)

# Save or display the result
cv2.imwrite('balanced_image.jpg', balanced_image)