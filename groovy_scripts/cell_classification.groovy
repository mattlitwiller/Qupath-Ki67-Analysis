/**
 * Script to classify cells into Positive and Negative
 * 
 * Reference André Lametti
 * 
 * @Edit Matthew Litwiller
 */

DAB_threshold = 0.15

try{
    if(args.size() > 0) {
        println(args[0])
        println(args[0].trim())
        println(args[0].toDouble())
        println(args[0].trim().toDouble())
        DAB_threshold = args[0].trim().toDouble()
    }

    Cell_class = getDetectionObjects()
    getCurrentHierarchy().getSelectionModel().setSelectedObjects(Cell_class, null)
    classifySelected('Negative')
    DABintensity='DAB: Mean'
    DAB_class = getDetectionObjects()
    DAB_positivenuclei = DAB_class.findAll {it.measurements[DABintensity] >= DAB_threshold}
    getCurrentHierarchy().getSelectionModel().setSelectedObjects(DAB_positivenuclei, null)
    classifySelected('Positive')

}catch (Exception e){
    //propagate error since it otherwise would not be propagated
    e.printStackTrace()
    System.exit(1)
}


