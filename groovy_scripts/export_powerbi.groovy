import java.time.LocalDateTime
import static java.lang.Math.*

String date = String.format('%tF', java.time.LocalDateTime.now())
//Positivity means and stdevs obtained experimentally for dab threshold 0.15 for 90 GLEN slides
means = ["germinal_center": 85.13677, "light_zone": 78.30358, "dark_zone": 93.43648]
stdevs = ["germinal_center": 6.990378, "light_zone": 6.998688, "dark_zone": 2.903930]
classes = ["germinal_center", "light_zone", "dark_zone"]
String header = "Date, Slide, Region, Count, Positivity"


try {
    if(args.size() > 0) {
        def output_dir = args[0]
        def output_str = output_dir + "/levey-jennings-data.csv"
        def outputFile = new File(output_str)

        // Add header only once
        def writeHeader = !outputFile.exists()

        // Read the existing file into memory, if it exists
        def existingEntries = []
        if (outputFile.exists()) {
            outputFile.eachLine { line ->
                def parts = line.split(",")
                if (parts.size() > 1) {
                    existingEntries << parts[0].trim() + "-" + parts[1].trim()  // Create a unique identifier for slide-region combination
                }
            }
        }

        outputFile.withWriterAppend { writer ->
            if (writeHeader)
                writer.writeLine(header)

            dets = getDetectionObjects()
            slide = GeneralTools.stripExtension(getCurrentImageData().getServer().getMetadata().getName())
            println slide

            for (c in classes) {
                region_dets = dets.findAll { it.getParent().getPathClass().toString().equals(c) }
                region_dets_count = region_dets.size()
                
                // dabMean = 0
                // dabStdev = 0
                // if (region_dets_count > 0) {
                //     dabValues = region_dets.collect { it.getMeasurements().get("DAB: Mean") }
                //     dabValues = dabValues.findAll { it != null && !it.isNaN() }
                //     if (!dabValues.isEmpty()) {
                //         dabMean = dabValues.sum() / dabValues.size()
                //         dabStdev = sqrt(dabValues.collect { pow(it - dabMean, 2) }.sum() / dabValues.size())
                //     }
                // }

                posMean = 0
                posVals = region_dets.collect { it.getPathClass().toString().equals("Positive") ? 1.0 : 0.0 }
                if(posVals.size() > 0){
                    posMean = posVals.sum() * 100 / posVals.size()
                }

                String entryKey = "${date}-${slide}-${c}"
                
                // Only append new entry if it has not been added already
                sd = stdevs[c]
                mean = means[c]
                if (!existingEntries.contains(entryKey)) {
                    writer.writeLine("${date},${slide},${c},${region_dets_count},${posMean}")
                    existingEntries << entryKey  // Add the combination to the list
                }
            }
        }
    }
}catch (Exception e){
    //propagate error since it otherwise would not be propagated
    e.printStackTrace()
    System.exit(1)
}