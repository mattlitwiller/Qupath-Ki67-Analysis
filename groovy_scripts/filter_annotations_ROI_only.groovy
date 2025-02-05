/**
 * Script to remove all annotations with ROI centroids outside of a desired region of interest, and label all un-classified annotations 
 * There can be 0 or 1 regions annotated with the "region_of_interest" class (0 -> no annotations will be removed)
 * It is recommended to use a rectangular ROI
 * 
 * @Author Matthew Litwiller
 * 
 */


//---------------------------------------

def roiClass = "region_of_interest"

//---------------------------------------

def annotations = getAnnotationObjects()
def roi = null
for (annotation in annotations) {
    if (annotation.getPathClass().toString().equals(roiClass)) {
       roi = annotation.getROI();
       annotations.remove(annotation)
       break    // only select the first roi
    }
}

// remove roi since we don't need it anymore if using the pipelined version
//def rois = getAnnotationObjects().findAll {it.getPathClass().toString().equals(roiClass)}
//removeObjects(rois, false)

if (roi == null) {
    println "Slide " + GeneralTools.stripExtension(getCurrentImageData().getServer().getMetadata().getName()) + " No ROI detected - all annotations will be removed"
    removeObjects(annotations, false)
}

// remove all annos outside of ROI
def annotations_to_remove = []
if (roi != null) {
    for (annotation in annotations) {
        if (!roi.contains(annotation.getROI().getCentroidX(), annotation.getROI().getCentroidY())) {
            annotations_to_remove.add(annotation)
        }
    }
    
    println "Removing " + annotations_to_remove.size() + " unwanted annotations"
    removeObjects(annotations_to_remove, false)
}