from skimage import exposure, io

normal_img = "D:/Qupath/ProjectTonsilAppendix/tiles/appendix/Images/CaseKI67_0036 [d=16,x=0,y=0,w=149760,h=80640].jpg"
purple_img = "D:/Qupath/ProjectAllTestSlides2/Jpg/CaseKI67_0090.jpg"

# Load the purple image and a reference image
purple_image = io.imread(purple_img)
reference_image = io.imread(normal_img)

# Perform histogram matching
matched_image = exposure.match_histograms(purple_image, reference_image, channel_axis=2)

# Save or display the result
io.imsave('normalized_image.jpg', matched_image)

print("Done")