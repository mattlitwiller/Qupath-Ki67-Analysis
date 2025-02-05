import java.awt.image.BufferedImage
import qupath.lib.images.servers.ImageServerProvider
import java.nio.file.*
import java.nio.file.attribute.BasicFileAttributes
import qupath.lib.gui.commands.ProjectCommands
import groovy.io.FileType





// Paths
def dir_string = "D:/Qupath/CommandLineUnnamedProj" //override with imported args
def dir_images = "D:/Qupath/slides/all_slides/ki67" //override with imported args
if(args.size() > 0) {
    args_list = args[0].split(" ")
    dir_string = args_list[0]
    dir_images = args_list[1]
}
// Define the directory paths
def directory = new File(dir_string)

// List of images with their paths (to override with images from imageDirectory if the argument is passed)
def images = [
    "D:/Qupath/slides/all_slides/ki67/CaseKI67_0021.ndpi", 
    "D:/Qupath/slides/all_slides/ki67/JGH/CaseKI67J_0007.ndpi"
]


def imageDirectory = new File(dir_images)
if (imageDirectory.exists() && imageDirectory.isDirectory()) {
    // Get all files in the immediate directory (non-recursive)
    def ndpiFiles = imageDirectory.listFiles().findAll { file ->
        file.isFile() && file.name.endsWith(".ndpi")  // Filter files with ".ndpi" extension
    }.collect { file -> 
        file.absolutePath  // Convert the File object to its absolute path as a string
    }
    images = ndpiFiles
} else {
    println "No files found! Check that directory exists and is not empty"
}

def predictions = [""]


//returns the path of all NDPI files within the baseDir
List<Path> getAllNDPIFiles(Path baseDir) {
    List<Path> ndpiFiles = []
    Files.walkFileTree(baseDir, new SimpleFileVisitor<Path>() {
        @Override
        FileVisitResult visitFile(Path file, BasicFileAttributes attrs) {
            if (file.toString().endsWith(".ndpi")) {
                ndpiFiles.add(file)
            }
            return FileVisitResult.CONTINUE
        }
    })
    return ndpiFiles
}

Path baseDir = Paths.get(dir_images)  // Replace with the path to 'folder1'
List<Path> ndpiFiles = getAllNDPIFiles(baseDir)
print "Found .ndpi files:"
print ndpiFiles.size()


//Create project and initialize images
if (!directory.exists()) directory.mkdir()

// Create project
def project = Projects.createProject(directory , BufferedImage.class)

for (imagePath in images) {
    def file = (imagePath =~ /[^\/]+\.ndpi$/)[0]

    // Get serverBuilder
    def support = ImageServerProvider.getPreferredUriImageSupport(BufferedImage.class, imagePath)
    print support
    def builder = support.builders.get(0)

    // Make sure we don't have null 
    if (builder == null) {
        print "Image not supported"
        return
    }
   
    // Add the image as entry to the project
    print "Adding: " + imagePath
    entry = project.addImage(builder)
    
    // Set a particular image type
    def imageData = entry.readImageData()
    imageData.setImageType(ImageData.ImageType.BRIGHTFIELD_H_DAB)
    entry.saveImageData(imageData)
    
    // Write a thumbnail if we can
    var img = ProjectCommands.getThumbnailRGB(imageData.getServer());
    entry.setThumbnail(img)
    
    // Add an entry name (the filename)
    entry.setImageName(file)
}

// Changes should now be reflected in the project directory
project.syncChanges()

print "Done"