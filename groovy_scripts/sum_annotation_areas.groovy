accepted = ["germinal_center", "light_zone", "dark_zone", "mantle"]

long area = 0
for( anno in getAnnotationObjects()) {
    if(accepted.contains(anno.getPathClass().toString())) {
        area += anno.getROI().getArea() / 1e6
    }
}

print area +  " " + getCurrentImageData().getServer().getMetadata().getName() 