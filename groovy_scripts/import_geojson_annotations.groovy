
/**
 * Script to import all geojson prediction files from a desired folder. Set dir to desired folder and annotationList to the list of model names that are being used.
 * 
 * @Author Matthew Litwiller
 */


def annotationList = ["germinal_center_mantle", "light_zone_dark_zone", "tonsil_appendix"]
//def dir = "D:/Qupath/predictions/2024-10-28"
removeOldAnnos = true
// def dir = "D:/Qupath-files/predictions/allslides2"
def dir = "D:/Qupath-files/predictions/allslides2"


if(args.size() > 0) {
   dir = args[0]   
}

//def directory = new File(dir)
//directory.eachFile { file ->
//    if (file.name.endsWith(".geojson")) {
//        def newName = file.name.replace(".ndpi", "")
//        def newFile = new File(file.parentFile, newName) // Use full path for the new file
//        if (file.renameTo(newFile)) {
//            println "Renamed: ${file.name} -> ${newFile.name}"
//        } else {
//            println "Failed to rename: ${file.name}"
//        }
//    }
//}

def modified = false

def gson = GsonTools.getInstance(true)
def name = GeneralTools.stripExtension(getCurrentImageData().getServer().getMetadata().getName()).replaceAll(' ', '_')
def previous_annotations = getAnnotationObjects()
for (annotationType in annotationList) {
    try {
        def path = dir + '/' + name + '_' + annotationType + '.geojson'
        path = path.replaceAll(" ", "")
        println(path)
        def json = new File(path).text

        def geoJsonType = new com.google.gson.reflect.TypeToken<Map<String, Object>>() {}.getType()
        def geoJsonData = gson.fromJson(json, geoJsonType)
        def featuresList = geoJsonData.get("features")
        def type = new com.google.gson.reflect.TypeToken<List<qupath.lib.objects.PathObject>>() {}.getType()
        def deserializedAnnotations = gson.fromJson(gson.toJson(featuresList), type)
        addObjects(deserializedAnnotations)
        print(name + " - Adding predictions for " + annotationType)
        modified = true
    }catch(FileNotFoundException e) {
        println(e)
        println(name + " - Missing predictions for " + annotationType) 
    }
}

//if any annotations were added, remove previous annotations (while preserving roi annotations)
def roiList = []
for (annotation in previous_annotations) {
    if (annotation.getPathClass().toString().equals("region_of_interest")) {
       roiList.add(annotation)
    }
}

if(modified && removeOldAnnos) {
    removeObjects(previous_annotations, false)
    addObjects(roiList)
}