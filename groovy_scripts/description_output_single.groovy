/**
 * Assess each slide by ensuring a number of factors:
 * 1. Tonsil and/or Appendix tissue detected
 * 2. GC, LZ, DZ all detected
 * 3. Positivity of LZ, DZ, GC within threshold
 * 4. Non-blurry image
 * 
 * @Author Matthew Litwiller
 */

import qupath.lib.gui.scripting.QPEx
import qupath.lib.objects.*

base_thresholds = [75, 69, 89]
jgh_thresholds = [65, 55, 84]
blur_thresh = 5

try {
    
    if(args.size() > 0) {
        def lst = args[0].split(";").collect { it.toDouble() }
        base_thresholds = lst[0..2]
        jgh_thresholds = lst[0..2]
        blur_thresh = lst[3]
    }
    def name = "- Ki-67 Assessment -"

    // Remove all previous ki67 assessments
    for (anno in getAnnotationObjects()) {
        if(anno.getName().equals(name)) {
            removeObject(anno, false)
        }
    }

    def imageData = getCurrentImageData()
    println imageData

    // Example for how to set description
    desc = "Ki-67 Control Tissue Assessment \n"
    // code 0 OK, 1 WARN, 2 ERROR.
    code = 0

    annos = getAnnotationObjects()
    
    // 1. Tonsil and/or appendix tissue detected 
    t_a_presence = annos.find{a -> a.getPathClass().toString().equals("tonsil") || a.getPathClass().toString().equals("appendix")} != null
    if(t_a_presence) {
        desc += "OK - Tonsil/Appendix Tissue Present \n"
    }else {
    desc += "WARN - Tonsil & Appendix Tissues Missing \n" 
    code = Math.max(code, 1)
    }

    GC = annos.find{ a -> a.getPathClass().toString().equals("germinal_center")}
    LZ = annos.find{ a -> a.getPathClass().toString().equals("light_zone")}
    DZ = annos.find{ a -> a.getPathClass().toString().equals("dark_zone")}

    lz_missing = false
    dz_missing = false

    // 2. GZ, LZ, DZ all detected
    if (GC != null) {
        desc += "OK - GC Region Present \n"    
    }else {
        desc += "ERROR - GC Region Missing \n"
        code = Math.max(code, 2)
    }
    if (LZ != null) {
    desc += "OK - LZ Region Present \n"    
    }else {
        lz_missing = true
        desc += "ERROR - LZ Region Missing \n"
        code = Math.max(code, 2)    
    }
    if ( DZ != null) {
        desc += "OK - DZ Region Present \n"     
    }else {
        dz_missing = true
        desc += "ERROR - DZ Region Missing \n"
        code = Math.max(code, 2)     
    }

    // 3. Positivity of LZ/DZ/GC within threshold
    classes = ["germinal_center", "light_zone", "dark_zone"]

    dets = getDetectionObjects()
    slide = GeneralTools.stripExtension(getCurrentImageData().getServer().getMetadata().getName())
    jgh = slide.contains("J")  // find if JGH slide or not

    for (i in 0..<classes.size()) {
        def c = classes[i].split("_")
                .collect { it[0].toUpperCase() }  
                .join("")  
        region_dets = dets.findAll {it.getParent().getPathClass().toString().equals(classes[i])}
        region_dets_count = region_dets.size()
        pos_region_dets = region_dets.findAll {it.getPathClass().toString().equals("Positive")}
        pos_region_dets_count = pos_region_dets.size()
        pos = 100 * pos_region_dets_count / Math.max(region_dets_count, 1)
        if(jgh) {
            if(1.1 * pos < jgh_thresholds[i]) {
                desc += "ERROR - " + c + " Positivity Far Below Threshold \n"
                code = Math.max(code, 2)
            }else if(pos < jgh_thresholds[i]) {
                desc += "WARN - " + c + " Positivity Slightly Below Threshold \n"
                code = Math.max(code, 1)
            }else {
                desc += "OK - " + c + " Positivity Above Accepted \n"
            }
        }else {
            if(1.1 * pos < base_thresholds[i]) {
                desc += "ERROR - " + c + " Positivity Far Below Threshold \n"
                code = Math.max(code, 2)
            }else if(pos < base_thresholds[i]) {
                desc += "WARN - " + c + " Positivity Slightly Below Threshold \n"
                code = Math.max(code, 1)
            }else {
                desc += "OK - " + c + " Positivity Above Accepted \n"
            }
        }
    }

    // 4. Non-blurry image
    if(GC != null) {
        count = GC.getChildObjects().size()
        long area = GC.getROI().getArea()
        if(area > 0) {
            ratio = 10000 * count / area
            if(ratio < blur_thresh && ratio > 0) {
                desc += "WARN - Low GC Cell Density Detected; Blurred Image Likely \n"
                code = Math.max(code, 1)
            }else if (ratio == 0) {
            desc += "ERROR - 0 GC Cell Detections; Likely Critical Image Blurring or InstanSeg Run Failed \n" 
            code = Math.max(code, 2)
            }else {
                desc += "OK - No GC Blurriness Detected \n"       
            }
        }
    }
    if(LZ != null && !lz_missing) {
        count = LZ.getChildObjects().size()
        long area = LZ.getROI().getArea()
        if(area > 0) {
            ratio = 10000 * count / area
            if(ratio < blur_thresh && ratio > 0) {
                desc += "WARN - Low LZ Cell Density Detected; Likely Blurred Image \n"
                code = Math.max(code, 1)
            }else if (ratio == 0) {
            desc += "ERROR - 0 LZ Cell Detections; Likely Critical Image Blurring or InstanSeg Run Failed \n" 
            code = Math.max(code, 2)
            }else {
                desc += "OK - No LZ Blurriness Detected \n"       
            }        
        }
    }
    if(DZ != null && !dz_missing) {
        count = DZ.getChildObjects().size()
        long area = DZ.getROI().getArea()
        if(area > 0) {
            ratio = 10000 * count / area
            if(ratio < blur_thresh && ratio > 0) {
                desc += "WARN - Low DZ Cell Density Detected; Likely Blurred Image \n"
                code = Math.max(code, 1)
            }else if (ratio == 0) {
            desc += "ERROR - 0 DZ Cell Detections; Likely Critical Image Blurring or InstanSeg Run Failed \n" 
            code = Math.max(code, 2)
            }else {
                desc += "OK - No DZ Blurriness Detected \n"       
            }           
        }
    }

    if (code == 1) {
    desc += "RECOMMEND - Inspect Image for Possible Issues in Control \n" 
    }else if(code == 2) {
    desc += "REQUIRED - Inspect Image for Defects in Control \n" 
    }

    def hierarchy = imageData.getHierarchy()

    // Create a small annotation
    def roi = ROIs.createRectangleROI(0, 0, 0, 0, ImagePlane.getDefaultPlane())
    def annotation = PathObjects.createAnnotationObject(roi)

    // Add text as metadata
    annotation.setName(name)
    annotation.setDescription(desc)
    annotation.setLocked(true)

    hierarchy.addObject(annotation)
    fireHierarchyUpdate()

}catch(Exception e){
    //propagate error since it otherwise would not be propagated
    e.printStackTrace()
    System.exit(1)
}
 