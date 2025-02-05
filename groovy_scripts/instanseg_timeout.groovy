import qupath.lib.images.servers.ColorTransforms
import qupath.lib.gui.scripting.QPEx   
import java.util.concurrent.*

segmentedClasses = ["germinal_center", "light_zone", "dark_zone", "mantle"]        // Classes that will be selected for instaSeg
model = "brightfield_nuclei"
model_path = "D:/Qupath-files/instanseg/" + model

if(args.size() > 0) {
   model_path = args[0]   
}

device = "gpu"
threads = 4
tileSize = 256
padding = 32
makeMeasurements = true
randomColors = false
timeoutInSeconds = 3    // Timeout of 360 seconds (6 minutes)

// ==================

// Create a ScheduledExecutorService to handle the timeout
def executor = Executors.newSingleThreadScheduledExecutor()

// Schedule the timeout action
def timeoutTask = executor.schedule({
    println "Timeout exceeded!"
    // Trigger the timeout logic here
    throw new TimeoutException("Operation timed out.")
}, timeoutInSeconds, TimeUnit.SECONDS)

try {
    // Your task logic starts here
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

    println "Task completed."
} catch (TimeoutException e) {
    // If timeout occurs, handle it here
    println "Task was interrupted due to timeout."
    executor.shutdown()
} catch (Exception e) {
    // Catch any other exceptions that might occur
    println "An error occurred: ${e.message}"
} finally {
    // Make sure to cancel the timeout task if the task completes before timeout
    timeoutTask.cancel(true)
    executor.shutdown()
}

println "Execution completed."
