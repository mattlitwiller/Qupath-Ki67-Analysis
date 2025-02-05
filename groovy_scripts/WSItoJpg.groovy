
/**
 * Script to export WSI as a jpg by downsampling
 * 
 * Reference Pete Bankhead
 * 
 * @Edit Steven Wen
 */
import qupath.imagej.tools.IJTools
import qupath.lib.gui.images.servers.RenderedImageServer
import qupath.lib.gui.viewer.overlays.HierarchyOverlay
import qupath.lib.regions.RegionRequest

import static qupath.lib.gui.scripting.QPEx.*

// It is important to define the downsample!
// This is required to determine annotation line thicknesses
double downsample = 8

// Add the output file path here
// Custom name of output
//String custom_name = 'KI67_1_500'
name = GeneralTools.stripExtension(getCurrentImageData().getServer().getMetadata().getName())
String path = buildFilePath(PROJECT_BASE_DIR, 'jpg', name + '.jpg')

// Request the current viewer for settings, and current image (which may be used in batch processing)
def viewer = getCurrentViewer()
def imageData = getCurrentImageData()
def server = null


try {
    // Create a rendered server that includes a hierarchy overlay using the current display settings
    server = new RenderedImageServer.Builder(imageData)
        .downsamples(downsample)
        // .layers(new HierarchyOverlay(viewer.getImageRegionStore(), viewer.getOverlayOptions(), imageData))
        .build()
}catch (Exception e){
    print(e)
}

// Write or display the rendered image
if (path != null) {
    mkdirs(new File(path).getParent())
    writeImage(server, path)
    print("Image saved to: " + path)  // Output the path where the image is saved
} else {
    IJTools.convertToImagePlus(server, RegionRequest.createInstance(server)).getImage().show()
}