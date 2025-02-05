import groovy.io.FileType

// Define variables
// String batchFolder = "dilution_run4"
// String imagePaths = "../jpg/${batchFolder}"
String batchFolder = "jpg"
String imagePaths = "D:/Qupath/ProjectTestbench/${batchFolder}"
int downsample = 8

// Model folders with tile size
Map<String, Integer> modelFolders = [
    "light_zone_dark_zone": 3120,
    "germinal_center_mantle": 3120,
    "tonsil_appendix": 0
]

// Iterate through detection classes and process images
modelFolders.each { detectionClass, size ->
    File imageDir = new File(imagePaths)
    imageDir.eachFileMatch(FileType.FILES, ~/.*\.jpg/) { file ->
        String fileName = file.name.replaceAll(/\.jpg$/, "")
        
        // Run Python script
        def command = ["python", "pbi_yolo.py", "${fileName}.jpg", detectionClass, "${downsample}", "${size}", "--batch_folder", imagePaths]
        println "Executing: ${command.join(' ')}"
        def process = command.execute()
        process.waitFor()
        println process.text
    }
}
