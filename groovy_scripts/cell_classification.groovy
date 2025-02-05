/**
 * Script to classify cells into Positive and Negative
 * 
 * Reference André Lametti
 * 
 * @Edit Matthew Litwiller
 */

DAB_threshold = 0.15

Cell_class = getDetectionObjects()
getCurrentHierarchy().getSelectionModel().setSelectedObjects(Cell_class, null)
classifySelected('Negative')
DABintensity='DAB: Mean'
DAB_class = getDetectionObjects()
DAB_positivenuclei = DAB_class.findAll {it.measurements[DABintensity] >= DAB_threshold}
getCurrentHierarchy().getSelectionModel().setSelectedObjects(DAB_positivenuclei, null)
classifySelected('Positive')