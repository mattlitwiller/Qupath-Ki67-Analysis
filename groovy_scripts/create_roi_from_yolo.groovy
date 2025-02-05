/**
 * Script to set ROI as the best tonsil and the best appendix detection if either/both exist.
 * 
 * @Author Matthew Litwiller
 */

import qupath.lib.roi.RoiTools

def classesOfInterest = ["tonsil", "appendix"]
def roiClass = "region_of_interest"
def annotations = getAnnotationObjects()

def annotationROI = null

tonsils = annotations.findAll {it.getPathClass().toString().equals("tonsil")}
appendices = annotations.findAll {it.getPathClass().toString().equals("appendix")}

def extractDecimalWithoutNulls(annotation) {
    def matcher = annotation =~ /(\d+\.\d+)/
    return matcher ? matcher[0][1].toDouble() : null
}

def best_tonsil = tonsils.findAll { extractDecimalWithoutNulls(it) != null }.max { extractDecimalWithoutNulls(it) }
def best_appendix = appendices.findAll { extractDecimalWithoutNulls(it) != null }.max { extractDecimalWithoutNulls(it) }


//Four cases for presense or absence of tonsils and appendices
if(best_tonsil != null && best_appendix != null) {
    annotationROI = RoiTools.union(best_tonsil.getROI(), best_appendix.getROI())   
    roi = PathObjects.createAnnotationObject(annotationROI, PathClass.fromString(roiClass))
    addObject(roi)  
}else if (best_tonsil != null) {
    roi = PathObjects.createAnnotationObject(best_tonsil.getROI(), PathClass.fromString(roiClass))
    addObject(roi)     
}else if (best_appendix != null) {
    roi = PathObjects.createAnnotationObject(best_appendix.getROI(), PathClass.fromString(roiClass))
    addObject(roi)      
}else {
    slide = GeneralTools.stripExtension(getCurrentImageData().getServer().getMetadata().getName())
    println slide + " ERROR: No tonsil or appendix found"
}


/**
 * Old method of taking ALL tonsils and appendices
 */
//for (annotation in annotations) { 
//    if (annotation.getPathClass().toString().equals("tonsil") || annotation.getPathClass().toString().equals("appendix")) {
//        if (annotationROI == null) {
//            annotationROI = annotation.getROI()
//        }else {
//            annotationROI = RoiTools.union(annotationROI, annotation.getROI())   
//        }
//    }
//    
//    //remove all previous region_of_interests in case they were used incorrectly
//    if(annotation.getPathClass().toString().equals(roiClass)) {
//        removeObject(annotation, false)
//    }
//}
//
//roi = PathObjects.createAnnotationObject(annotationROI, PathClass.fromString(roiClass))
//addObject(roi)





/**
 * Code to produce only the ROI around the tonsil or appendix, not both
 */
// Only consider tonsil if there is one, otherwise consider appendix (is can be more wonky)
//for (annotation in annotations) { 
//    if (annotation.getPathClass().toString().equals("tonsil")) {
//        if (annotationROI == null) {
//            annotationROI = annotation.getROI()
//        }else {
//            annotationROI = RoiTools.union(annotationROI, annotation.getROI())   
//        }
//    }
//    
//    //remove all previous region_of_interests in case they were used incorrectly
//    if(annotation.getPathClass().toString().equals(roiClass)) {
//        removeObject(annotation, false)
//    }
//}
//
//// If no tonsil was found, create roi around appendix 
//if(annotationROI == null) {
//for (annotation in annotations) { 
//    if (annotation.getPathClass().toString().equals("appendix")) {
//        if (annotationROI == null) {
//            annotationROI = annotation.getROI()
//        }else {
//            annotationROI = RoiTools.union(annotationROI, annotation.getROI())   
//        }
//    }
//}
// 
//}
//
//roi = PathObjects.createAnnotationObject(annotationROI, PathClass.fromString(roiClass))
//addObject(roi)
//