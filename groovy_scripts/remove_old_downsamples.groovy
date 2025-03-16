import qupath.imagej.tools.IJTools
import qupath.lib.gui.images.servers.RenderedImageServer
import qupath.lib.gui.viewer.overlays.HierarchyOverlay
import qupath.lib.regions.RegionRequest

import static qupath.lib.gui.scripting.QPEx.*

double downsample = 8
try {
    if(args.size() > 0) {
        downsample = args[0].toDouble()
    }
}catch (Exception e){
    //propagate error since it otherwise would not be propagated
    e.printStackTrace()
    System.exit(1)
}

def keepPrefix = downsample + "_"

def dir = new File(path).getParentFile()

// Delete all files with other downsamples
dir.listFiles()?.each { file ->
    if (!file.name.startsWith(keepPrefix)) {  // Delete if it doesn't start with "10.0_Case"
        file.delete()
    }
}