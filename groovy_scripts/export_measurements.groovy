/**
 * Script to automate exporting cell data (DAB: Mean, etc.). Produces one file per slide.
 * 
 * @Author Matthew Litwiller
 */

import qupath.lib.gui.tools.MeasurementExporter
import qupath.lib.objects.PathDetectionObject

def slide = getCurrentImageData().getServer().getMetadata().getName().toString()
def slide_save_name = GeneralTools.stripExtension(getCurrentImageData().getServer().getMetadata().getName()).replaceAll(' ', '_')
def imagesToExport = project.getImageList().findAll{it.toString().equals(slide)}

// Separate each measurement value in the output file with a tab ("\t")
def separator = ","

// Choose the columns that will be included in the export
// Note: if 'columnsToInclude' is empty, all columns will be included
def columnsToInclude = new String[]{"Image", "Parent", "DAB: Mean"}

// Choose the type of objects that the export will process
// Other possibilities include:
//    1. PathAnnotationObject
//    2. PathDetectionObject
//    3. PathRootObject
// Note: import statements should then be modified accordingly
def exportType = PathDetectionObject

// Choose your *full* output path
def outputPath = "D:/Qupath-files/cell_data/measurements/" + slide_save_name + ".csv"
def outputFile = new File(outputPath)

// Create the measurementExporter and start the export
def exporter  = new MeasurementExporter()
                  .imageList(imagesToExport)            // Images from which measurements will be exported
                  .separator(separator)                 // Character that separates values
                  .includeOnlyColumns(columnsToInclude) // Columns are case-sensitive
                  .exportType(exportType)               // Type of objects to export
                  .exportMeasurements(outputFile)        // Start the export process
                  
println "Done!"