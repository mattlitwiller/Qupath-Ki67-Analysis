/**
 * Script that performs the following operations:
 * - simplify shape of all objects (to ensure no holes are produced when tiles are exported with downsample)
 * - combine (merge) detections by their annotation class
 * - fill holes in annotations
 * - insert donut holes in mantles that overlap with GCs (required because yolo format not allowing holes) 
 * - ensure no overlap of light and dark zones occur by removing any intersecting area from both of their regions
 * - ensure no LZ/DZ exist outside of a GC
 * - remove annotations that are deemed too small
 * - lock annotations
 * 
 * Note: mantle will not have its holes filled - it is the responsibility of the annotator to ensure only one hole exists at most per mantle (the one where the GC lies)
 * 
 * @Author Matthew Litwiller
 */
 
import qupath.lib.roi.*
import qupath.lib.objects.*
import java.lang.Object.*
import qupath.lib.images.servers.PixelCalibration
import qupath.lib.roi.RoiTools
import qupath.lib.gui.commands.Commands
import qupath.lib.roi.RoiTools.CombineOp
import groovy.time.TimeCategory 
import groovy.time.TimeDuration

//=================

def downsample = 8                             // Downsample used for tile export - a value smaller than the downsample used to export tiles could result in holes
def excludeClasses = ["region_of_interest"]    // Classes that will not be merged together. All other classes will be combined in their own classes
def minArea = 5000                            // Minimum area of annotations (micrometers^2)
simplify_shapes = true                         // simplify shapes to downsample
fill_holes = true                              // fill holes 
fix_mantle = true                              // if enabled, will ensure no mantle covers a germinal center
fix_zone_overlap = true                        // if enabled, no light zone or dark zone can overlap
fix_gc_zones = true                            // if enabled, no light zone or dark zone can exist outside of a GC
remove_small_annotations = true                // if enabled, will remove small annotations
lock = true                                    // if enabled, will lock annotations at the end
merge = true                                   // if enabled, will merge annotations at the end
remove_names = true                            // if enabled, will remove names (can help prevent issues with typecasting in data analysis)
gc_threshold = 0.8                             // Minimum GC accuracy that will be preserved

//=================

def classNameList = []
annotations = getAnnotationObjects()

if (annotations.findAll {it.getPathClass() == null}.size() != 0) println("WARNING! Annotation with no classification detected. This will cause problems at ROI modification steps.")

// Unlock all objects to simplify shape
if(simplify_shapes) {
    getAnnotationObjects().each {
        it.setLocked(false)
        def roi = ShapeSimplifier.simplifyShape(it.getROI(), downsample)
        it.setROI(roi)
    } 
}



// Create list of class names
for (annotation in annotations) {
    def c = annotation.getPathClass().toString()
    if(!classNameList.contains(c) && !excludeClasses.contains(c)) {
       classNameList.add(c) 
    }
}

gc = annotations.findAll {it.getPathClass().toString().equals("germinal_center")}
gc_to_remove = null
try {
    gc_to_remove = gc.findAll {Double.parseDouble(it.getName()) < gc_threshold}
} catch (Exception e) {
    
}

gc_roi_to_remove = null
if(gc_to_remove != null && gc_to_remove.size() > 0) {
    gc_roi_to_remove = gc_to_remove[0].getROI()
    for(gc in gc_to_remove) {
        gc_roi_to_remove = RoiTools.union(gc_roi_to_remove, gc.getROI())   
    }
}

println "Cleaning the following annotations: " + classNameList

def imageData = getCurrentImageData()
def pixelCalibration = imageData.getServer().getPixelCalibration()
def pixelWidth = pixelCalibration.getPixelWidth()
def pixelHeight = pixelCalibration.getPixelHeight()

// Fill holes for all classes (ensure mantle does not have any holes that we don't want filled (i.e. where the GC is)
if(fill_holes) {
    for (c in classNameList) {   
        selectObjectsByClassification(c)
        runPlugin('qupath.lib.plugins.objects.SplitAnnotationsPlugin', '{}')
        mergeSelectedAnnotations()
        runPlugin('qupath.lib.plugins.objects.FillAnnotationHolesPlugin', '{}') 
    }  
}

if(fix_mantle || fix_zone_overlap) {    
    for (c in classNameList) {   
        selectObjectsByClassification(c)
        runPlugin('qupath.lib.plugins.objects.SplitAnnotationsPlugin', '{}')
    }

    // list of mantles that contain gcs stored as tuples
    containedPairs = []
    zonePairs = []
    all_annos = getAnnotationObjects()

    // Unlock all objects to simplify shape
    getAnnotationObjects().each {
        for(annotation in all_annos) {
            if(fix_mantle && RoiTools.intersection(it.getROI(), annotation.getROI()).getArea() > 0 && it.getPathClass().toString().equals("mantle") && annotation.getPathClass().toString().equals("germinal_center")) {
                containedPairs.add([it, annotation])
            }
            if(fix_zone_overlap && RoiTools.intersection(it.getROI(), annotation.getROI()).getArea() > 0 && it.getPathClass().toString().equals("light_zone") && annotation.getPathClass().toString().equals("dark_zone")) {
                zonePairs.add([it, annotation])
            }
        }
    }

    if(fix_mantle) {
        for (i = 0; i < containedPairs.size(); i++) {
           mantle = containedPairs[i][0]
           id = mantle.getID()
           gc = containedPairs[i][1]
           selectObjects(gc)
           makeInverseAnnotation()
   
           //assumes the only non-classified object will be the one we just created
           not_gc = getAnnotationObjects().find {
              it.getPathClass() == null 
           }
   
           roi_intersect = RoiTools.intersection(mantle.getROI(), not_gc.getROI())
           new_mantle = PathObjects.createAnnotationObject(roi_intersect, mantle.getPathClass())
           addObject(new_mantle)
   
           //modify future pairs to contain the new mantle instead of the old one
           for(j=i; j < containedPairs.size(); j++) {
               if(containedPairs[j][0].getID().equals(id)) {
                  containedPairs[j][0] = new_mantle 
               }
           }
   
           removeObjects([mantle, not_gc], false)           
        } 
    }
    
    if(fix_zone_overlap) {
        for(i = 0; i < zonePairs.size(); i++) {
            lz = zonePairs[i][0]
            dz = zonePairs[i][1]
            intersection = RoiTools.intersection(lz.getROI(), dz.getROI())
            new_lz_roi = RoiTools.subtract(lz.getROI(), intersection)
            new_dz_roi = RoiTools.subtract(dz.getROI(), intersection)
            new_lz = PathObjects.createAnnotationObject(new_lz_roi, lz.getPathClass())
            new_dz = PathObjects.createAnnotationObject(new_dz_roi, dz.getPathClass())
            addObject(new_lz)
            addObject(new_dz)
            
            //modify future pairs to contain the new zones instead of the old one
            for(j=i; j < zonePairs.size(); j++) {
                if(zonePairs[j][0].getID().equals(lz.getID())) {
                    zonePairs[j][0] = new_lz
                }
                if(zonePairs[j][1].getID().equals(dz.getID())) {
                    zonePairs[j][1] = new_dz
                }
            }
            removeObjects([lz, dz], false)
        }
    }
}

// Second pass to remove all small annotations
if(remove_small_annotations || merge) {
    for (c in classNameList) {
        selectObjectsByClassification(c)
        runPlugin('qupath.lib.plugins.objects.SplitAnnotationsPlugin', '{}')
        def smallAnnotations = getAnnotationObjects().findAll {
            it.getROI().getScaledArea(pixelWidth, pixelHeight) < minArea && !excludeClasses.contains(it.getPathClass().toString())
        }
        if(remove_small_annotations) removeObjects(smallAnnotations, true)
        selectObjectsByClassification(c)
        if (merge) mergeSelectedAnnotations()
    }
}

// Remove all GCs below threshold
if(gc_roi_to_remove != null) {
    gc = getAnnotationObjects().find {it.getPathClass().toString().equals("germinal_center")}
    new_gc_roi = gc.getROI()
    new_gc_roi = RoiTools.subtract(gc.getROI(), gc_roi_to_remove)
    new_gc = PathObjects.createAnnotationObject(new_gc_roi, gc.getPathClass())
    addObject(new_gc)
    removeObject(gc, false)
}



// Fix GC zones to ensure LZ and DZ only exist within a GC
if(fix_gc_zones) {
    annos = getAnnotationObjects()
    not_gc = null
    lz = null
    dz = null
    new_lz = null
    new_dz = null
    for (anno in annos) {
        if(anno.getPathClass().toString().equals("germinal_center")) {
            selectObjects(anno)
            makeInverseAnnotation()
            not_gc = getAnnotationObjects().find {
                it.getPathClass() == null 
            }
        }
        if(anno.getPathClass().toString().equals("light_zone")) {
            lz = anno
        }
        if(anno.getPathClass().toString().equals("dark_zone")) {
            dz = anno
        }
    }
    
    if(lz != null && not_gc != null) {
        new_roi = RoiTools.subtract(lz.getROI(), not_gc.getROI())
        new_lz = PathObjects.createAnnotationObject(new_roi, lz.getPathClass())
        addObject(new_lz)
        removeObject(lz, false)
    }
    if(dz != null && not_gc != null) {
        new_roi = RoiTools.subtract(dz.getROI(), not_gc.getROI())  
        new_dz = PathObjects.createAnnotationObject(new_roi, dz.getPathClass())
        addObject(new_dz)
        removeObject(dz, false)
    }
    if(not_gc != null) {
       removeObject(not_gc, false) 
    }
}

if(lock) {
    getAnnotationObjects().each{it.setLocked(true)}
}

if(remove_names) {
    getAnnotationObjects().each{it.setName(null)}
}

// Lastly, clean up annotations with 0 areas
for (anno in getAnnotationObjects()){
    if(anno.getROI().getArea() == 0) removeObject(anno, false)
}
