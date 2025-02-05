/**
 * Script to export cell positivity based on classification performed previously
 * 
 * @Author Matthew Litwiller
 */

classes = ["germinal_center", "light_zone", "dark_zone", "mantle"]
out_path = "D:/Qupath-files/cell_data/positivity/positivity.csv"

save = true


def outputFile = new File(out_path)
if (save && !outputFile.exists()) {
    outputFile.createNewFile()   
    outputFile.withWriter { writer ->
        writer.writeLine("Slide, Region, Positive, Count, Positivity")
    }
}


dets = getDetectionObjects()
slide = GeneralTools.stripExtension(getCurrentImageData().getServer().getMetadata().getName())

for (c in classes) {
    region_dets = dets.findAll {it.getParent().getPathClass().toString().equals(c)}
    region_dets_count = region_dets.size()
    pos_region_dets = region_dets.findAll {it.getPathClass().toString().equals("Positive")}
    pos_region_dets_count = pos_region_dets.size()
    frac = pos_region_dets_count / Math.max(region_dets_count, 1)
    println(c + " " + frac )
    if(save) {
        outputFile.withWriterAppend { writer ->
            writer.writeLine("${slide},${c},${pos_region_dets_count},${region_dets_count},${frac}")
        }
    }
}