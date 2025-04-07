/**
 * InstaSeg script for batch processing
 * 
 * Reference Sebastian K.
 * 
 * @Edit Matthew Litwiller
 */
 
import qupath.lib.images.servers.ColorTransforms
import qupath.lib.gui.scripting.QPEx   

// ==================

// default order: ["light_zone", "dark_zone", "germinal_center", "mantle"]
segmentedClasses = ["light_zone", "dark_zone", "germinal_center", "mantle"]        // Classes that will be selected for instaSeg. Order matters if we are taking in args
model = "brightfield_nuclei"
model_path = "D:/Qupath-files/instanseg/" + model

if(args.size() > 0) {
    def boolValues = args[0].split(";").collect { it.toBoolean() }
    segmentedClasses = segmentedClasses.indices.findAll { boolValues[it] }.collect { segmentedClasses[it] }
    println "========================="
    println segmentedClasses
}

device = "gpu"
threads = 4
tileSize = 256
padding = 32
makeMeasurements = true
randomColors = false

// ==================

clearDetections()

def annotations = getAnnotationObjects()
def pathObjects = []

for (anno in annotations) {
    if (segmentedClasses.contains(anno.getPathClass().toString())) {
        pathObjects.add(anno)
    }
}

// Select all desired objects before running instaseg
selectObjects(pathObjects)
println("model path '" + model_path + "'")
System.properties["ai.djl.offline"] = "false"

try {
    qupath.ext.instanseg.core.InstanSeg.builder()
    .modelPath(model_path)
    .device(device)
    .nThreads(threads)
    .tileDims(tileSize)
    .interTilePadding(padding)
    .inputChannels([
        ColorTransforms.createChannelExtractor("Red"), 
        ColorTransforms.createChannelExtractor("Green"), 
        ColorTransforms.createChannelExtractor("Blue")])
    .outputChannels()
    .makeMeasurements(makeMeasurements)
    .randomColors(randomColors)
    .build()
    .detectObjects()
}catch(Exception e) {
    e.printStackTrace()
    // System.exit(1)
}
