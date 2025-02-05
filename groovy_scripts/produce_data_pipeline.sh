# Usage:
qupath_cli="D:/Qupath/v0.6.0-rc1/QuPath-0.6.0-rc1 (console).exe"
groovy_directory="D:/Qupath-files/groovy_scripts"
project_name="ProjectGlenDilution2_run4_5_ManualAnno"
project_dir="D:/Qupath/$project_name"

###################
# PIPELINE
# 1. Create project with desired project name: Idempotent 
# 2. Set Stain Vectors for all slides: Idempotent.
# 3. Import predictions: Idempotent
# 4. Create roi from tonsils (and appendix if needed): Idempotent
# 5. Remove all annotations outside of roi: Idempotent
# 6. Clean annotations: Idempotent
# 7. Instanseg: Idempotent
# 8. Cell classification: Idempotent
# 9. Report positivity: Not idempotent (will keep creating the positivity.csv file - need to ensure it does not exist before running)
# 10. Export measurements: Idempotent
###################

# "$qupath_cli" script "$groovy_directory/create_project.groovy" --args "$project_dir" -s
# "$qupath_cli" script "$groovy_directory/set_manual_stain_vectors.groovy" -p "$project_dir/project.qpproj" -s
# "$qupath_cli" script "$groovy_directory/import_geojson_annotations.groovy" -p "$project_dir/project.qpproj" -s
# "$qupath_cli" script "$groovy_directory/create_roi_from_yolo.groovy" -p "$project_dir/project.qpproj" -s
# "$qupath_cli" script "$groovy_directory/filter_annotations_ROI_only.groovy" -p "$project_dir/project.qpproj" -s
# # "$qupath_cli" script "$groovy_directory/clean_detections_old.groovy" -p "$project_dir/project.qpproj" -s
# "$qupath_cli" script "$groovy_directory/clean_detections.groovy" -p "$project_dir/project.qpproj" -s
# "$qupath_cli" script "$groovy_directory/instanseg.groovy" -p "$project_dir/project.qpproj" -s
"$qupath_cli" script "$groovy_directory/cell_classification.groovy" -p "$project_dir/project.qpproj" -s
"$qupath_cli" script "$groovy_directory/cell_classification_data_export.groovy" -p "$project_dir/project.qpproj" -s
"$qupath_cli" script "$groovy_directory/export_measurements.groovy" -p "$project_dir/project.qpproj" -s