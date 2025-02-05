/** 
 * Script to use the density of the cells within YOLO annotations to determine if the image is blurry
 * 
 * @Author Matthew Litwiller
 */
 


segmentedClasses = ["germinal_center", "light_zone", "dark_zone", "mantle"]        // Classes that will be selected for checks

for (c in segmentedClasses) {
    anno = getAnnotationObjects().find{ a -> a.getPathClass().toString().equals(c)}
    if(anno != null) {
        count = anno.getChildObjects().size()
        long area = anno.getROI().getArea()
        if(area > 0) {
            ratio = 10000 * count / area
            if(ratio < 5) {
                println getCurrentImageData().getServer().getMetadata().getName()
                println ratio + " " + anno
            }
        }
    }
}