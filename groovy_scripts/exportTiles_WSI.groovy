/**
 * Script to export annotations as labeled tiles for QuPath > 0.2*.
 *
 * All patches will be exported to the same directory called 'tiles' inside the Project directory
 * The patches will be filtered based on tissue content, and finally moved to respective the
 * subdirectories: Images and Labels within the 'tiles' folder
 *
 * Each patch's filename contains the original WSI ID, and images are saved as PNG (by default)
 * and ground truth as TIF
 *
 * The downsampling level can be set by the user, default value is 4.
 *
 * Code is inspired by the script from the QuPath documentations, written by Pete Bankhead:
 * https://qupath.readthedocs.io/en/stable/docs/advanced/exporting_images.html#tile-exporter
 *
 * Reference André Pedersen
 * 
 * @Edit Matthew Litwiller
 */


import qupath.lib.images.servers.LabeledImageServer
import java.awt.image.Raster
import javax.imageio.ImageIO;


// ----- SET THESE PARAMETERS -----
def classNames = ["tonsil", "appendix"]   // names of classes of interest (simply add more values to list to add more classes) - only non-overlapping classes should be added or the model will not be trained properly
def imageExtension = ".jpg"
int nb_channels = 3;
def multiChannel = false;
def roiClass = "region_of_interest" // if an annotation is made with this name, the exported tiles will be contained within this region 
                                    // and create background (unlabeled) tiles with all tiles that are not labeled.
                                    // WARN: do not exclude classNames of interest in doing so, as these tiles will be omitted from Image/Label directories
// --------------------------------


def imageData = getCurrentImageData()
def annotations = getAnnotationObjects()
def targetAnnotation = null
def imgRegion = null


metadata = imageData.getServer().getMetadata()
long x = metadata.getWidth()
long y = metadata.getHeight()
int patchSize = Math.max(metadata.getWidth(), metadata.getHeight())
def maxValue = 178956970        // anything larger can be viewed as a DOS attack with Ultralytics

long maxDownsampleSquared = x * y / maxValue
int maxDownsample = Math.sqrt(maxDownsampleSquared)

int downsample = 1
while (downsample <= maxDownsample) {
    downsample *= 2
}

println imageData.getServer().getMetadata().getName() + " downsample " + downsample

for (annotation in annotations) {
    def pathClass = annotation.getPathClass()
    if (pathClass != null && pathClass.getName() == roiClass) {
        targetAnnotation = annotation
        annotations.remove(targetAnnotation)
    break
    }
}

// Check if the target annotation was found
if (targetAnnotation != null) {
    // Get the ROI of the annotation
    def roi = targetAnnotation.getROI()
    print "ROI found: " + roi.toString() + " Only considering this region for background & labels"
    imgRegion = ImageRegion.createInstance(roi)
} else {
    print "Annotation with label 'region_of_interest' not found! No background will be included outside of labeled tiles"
}

int counter = 0

// Export desired classNames into separate folders
for (className in classNames) {
    print "Exporting " + className + " annotations"
    counter ++
   
    // Define output path (relative to project)
    def name = GeneralTools.getNameWithoutExtension(imageData.getServer().getMetadata().getName())
    def pathOutput = buildFilePath(PROJECT_BASE_DIR, 'tiles', className)
    mkdirs(pathOutput)

    // Create an ImageServer where the pixels are derived from annotations
    def tempServer = new LabeledImageServer.Builder(imageData)
        .backgroundLabel(0, ColorTools.BLACK) // Specify background label (usually 0 or 255)
        .downsample(downsample)    // Choose server resolution; this should match the resolution at which tiles are exported
        .multichannelOutput(multiChannel)  // If true, each label is a different channel (required for multiclass probability)

    tempServer.addLabel(className, counter)

    // finally, build server
    def labelServer = tempServer.build()

    // Create an exporter that requests corresponding tiles from the original & labeled image servers
    def tileExporter = new TileExporter(imageData)
        .downsample(downsample)          // Define export resolution
        .imageExtension(imageExtension)  // Define file extension for original pixels (often .tif, .jpg, '.png' or '.ome.tif')
        .tileSize(patchSize)             // Define size of each tile, in pixels
        .labeledServer(labelServer)      // Define the labeled image server to use (i.e. the one we just built)
        .annotatedTilesOnly(false)        // If true, only export tiles if there is a (labeled) annotation present
        .includePartialTiles(true)      // Define inclusion of partially annotated tiles

    
    // if roi defined, only use this region (and create background only from tiles in the region)
    if (imgRegion != null) {
        tileExporter.region(imgRegion)
        tileExporter.annotatedTilesOnly(false)
    }

    tileExporter.writeTiles(pathOutput)          // Write tiles to the specified directory
    
    // create new folder (IMAGES AND LABELS), but only if they do not exist!
    def dir1 = new File(pathOutput + "/Images");
    if (!dir1.isDirectory())
        dir1.mkdir()
    
    def dir2 = new File(pathOutput + "/Labels");
    if (!dir2.isDirectory())
        dir2.mkdir()

    // attempt to delete unwanted patches, both some formats as well as patches containing mostly glass
    // Iterate through all your tiles
    File folder = new File(pathOutput)
    File[] listOfFiles = folder.listFiles()

    // for each patch
    listOfFiles.each { tile ->
        // skip directories within masks folder, and skip all ground truth patches
        if (tile.isDirectory())
            return;
        def currPath = tile.getPath()
        if (!currPath.endsWith(imageExtension))
            return;
    
    
        def currLabelPatch = new File(pathOutput + "/" + tile.getName().split(imageExtension)[0] + ".png")
        tile.renameTo(pathOutput + "/Images/" + tile.getName())
        currLabelPatch.renameTo(new File(pathOutput + "/Labels/" + tile.getName().split(imageExtension)[0] + ".png"))
    }
}


print "Done!"

// reclaim memory - relevant for running this within a RunForProject
Thread.sleep(100);
javafx.application.Platform.runLater {
    getCurrentViewer().getImageRegionStore().cache.clear();
    System.gc();
}
Thread.sleep(100);