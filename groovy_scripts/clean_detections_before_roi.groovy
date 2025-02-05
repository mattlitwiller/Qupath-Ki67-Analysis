import qupath.lib.roi.RoiTools

def detectionsOfInterest = ["light_zone", "dark_zone", "mantle"]
def classesOfInterest = ["tonsil", "appendix"]
def roiClass = "region_of_interest"
def annotations = getAnnotationObjects()

def annotationROI = null

def slide = getCurrentImageData().getServer().getMetadata().getName()

def rewardFunc(annotation) {
    return (annotation.getName() as BigDecimal)**5
}

// 1 remove all annotations outside of tonsil & appendix region
tonsil_roi = null
appendix_roi = null
tonsil_appendix_roi = null
for (annotation in annotations) {
    tissue_class = annotation.getPathClass().getName().toString()
    if (tissue_class.equals("tonsil")) {
        if (tonsil_roi == null) {
            tonsil_roi = annotation.getROI()
        }else {
            tonsil_roi = RoiTools.union(tonsil_roi, annotation.getROI()) 
        }     
    }
    if (tissue_class.equals("appendix")) {
        if (appendix_roi == null) {
            appendix_roi = annotation.getROI()
        }else {
            appendix_roi = RoiTools.union(appendix_roi, annotation.getROI()) 
        }     
    }
}
if(tonsil_roi != null && appendix_roi == null) {
   tonsil_appendix_roi =  tonsil_roi
}else if (tonsil_roi == null && appendix_roi != null) {
    tonsil_appendix_roi = appendix_roi
}else if (tonsil_roi == null && appendix_roi == null) {
    tonsil_appendix_roi = null
}else {
    tonsil_appendix_roi = RoiTools.union(appendix_roi, tonsil_roi)   
}


for(annotation in annotations) {
    if(tonsil_appendix_roi != null && !classesOfInterest.contains(annotation.getPathClass().getName().toString()) && !tonsil_appendix_roi.contains(annotation.getROI().getCentroidX(), annotation.getROI().getCentroidY())) {
        removeObject(annotation, false)
    }
}


// Clean up GCs based off accuracy
// Bottom 20% of GC detections are removed by default.
// Then remove additional GCs that are below 0.3 accuracy and keep all GCs above 0.75 accuracy, regardless of how this affects the filtered percentage
if(annotationList.contains("germinal_center_mantle")) {
    omitted_fraction = 0.2 // Fraction of GCs that will be omitted 
    lowest_gc_accuracy = 0.3 // Min value accepted, all values below will be filtered regardless of omitted_fraction
    safe_accuracy = 0.75 // Values of safe_accuracy and above will never be filtered
    gc = getAnnotationObjects().findAll { it.getPathClass().toString().equals("germinal_center") }
    gc_accuracies = gc.collect { it.getName().toDouble() }.sort()
    gc_accuracies = gc_accuracies.drop((gc_accuracies.size() * omitted_fraction).toInteger())
    gc_accuracies = gc_accuracies.drop((gc_accuracies.size() * omitted_fraction).toInteger())
    gc_accuracies = gc_accuracies.findAll { it >= lowest_gc_accuracy }
    gc_to_remove = gc.findAll { it.getName().toDouble() !in gc_accuracies && it.getName().toDouble() < safe_accuracy}
    println name + " " + gc_to_remove
//    removeObjects(gc_to_remove, false)
}


// 2 flag GCs to remove by ROI, make remaining GCs into one ROI
gc_roi_to_remove = null
gc_roi = null
gc_annos = getAnnotationObjects.findAll {it.getPathClass().getName().toString().equals("germinal_center")}
if(gc_annos.size() > 0) {
   for(gc_anno in gc_annos) {
      if()
      gc_roi = RoiTools.union(gc_roi, gc_anno.getROI())
   }
}


//// 2 compute performance of tonsil and appendix and only keep the one with the higher value to simplify instanseg computations
//// Current functioning: apply an exponential function to the accuracy to reward accuracies closer to 1. multiply this by the area of ONLY detectionsOfInterest classes (we dont actually care about gc)
//if( tonsil_roi != null && appendix_roi != null) {
//    annotations = getAnnotationObjects()
//    tonsil_total = 0
//    appendix_total = 0
//    for(annotation in annotations.findAll {it -> detectionsOfInterest.contains(it.getPathClass().toString())}) {
//        area_value = annotation.getROI().getArea() / 1000
//        value = area_value * rewardFunc(annotation)
//        if(tonsil_roi.contains(annotation.getROI().getCentroidX(), annotation.getROI().getCentroidY())) {
//            tonsil_total += value
//        }
//        if(appendix_roi.contains(annotation.getROI().getCentroidX(), annotation.getROI().getCentroidY())) {
//            appendix_total += value        
//        }
//    }
//    if(tonsil_total >= appendix_total) {
//        roi = PathObjects.createAnnotationObject(tonsil_roi, PathClass.fromString(roiClass)) 
//        addObject(roi)
//        println slide + " tonsil selected for ROI"
//    } else {
//        roi = PathObjects.createAnnotationObject(appendix_roi, PathClass.fromString(roiClass)) 
//        addObject(roi)
//        println slide + " appendix selected for ROI"
//    }
//}else {
//    if (tonsil_appendix_roi != null) {
//        roi = PathObjects.createAnnotationObject(tonsil_appendix_roi, PathClass.fromString(roiClass)) 
//        addObject(roi)
//        println slide + " Tonsil or appendix was missing - ROI was forced" 
//    }else {
//       println slide + " Tonsil and appendix missing - no ROI" 
//    }
//}