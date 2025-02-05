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

// 2 compute performance of tonsil and appendix and only keep the one with the higher value to simplify instanseg computations
// Current functioning: apply an exponential function to the accuracy to reward accuracies closer to 1. multiply this by the area of ONLY detectionsOfInterest classes (we dont actually care about gc)
if( tonsil_roi != null && appendix_roi != null) {
    annotations = getAnnotationObjects()
    tonsil_total = 0
    appendix_total = 0
    for(annotation in annotations.findAll {it -> detectionsOfInterest.contains(it.getPathClass().toString())}) {
        area_value = annotation.getROI().getArea() / 1000
        value = area_value * rewardFunc(annotation)
        if(tonsil_roi.contains(annotation.getROI().getCentroidX(), annotation.getROI().getCentroidY())) {
            tonsil_total += value
        }
        if(appendix_roi.contains(annotation.getROI().getCentroidX(), annotation.getROI().getCentroidY())) {
            appendix_total += value        
        }
    }
    if(tonsil_total >= appendix_total) {
        roi = PathObjects.createAnnotationObject(tonsil_roi, PathClass.fromString(roiClass)) 
        addObject(roi)
        println slide + " tonsil selected for ROI"
    } else {
        roi = PathObjects.createAnnotationObject(appendix_roi, PathClass.fromString(roiClass)) 
        addObject(roi)
        println slide + " appendix selected for ROI"
    }
}else {
    if (tonsil_appendix_roi != null) {
        roi = PathObjects.createAnnotationObject(tonsil_appendix_roi, PathClass.fromString(roiClass)) 
        addObject(roi)
        println slide + " Tonsil or appendix was missing - ROI was forced" 
    }else {
       println slide + " Tonsil and appendix missing - no ROI" 
    }
}