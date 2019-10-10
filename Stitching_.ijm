//script parameters
#@ File(label="Directory", style="directory") dir
#@ File(label="Pixel Classification", description="Enter an ilastik project (ilp) file", style="extensions:ilp") project
#@ String(label="Type", choices={"Grid: row-by-row", "Grid: column-by-column", "Grid: snake by rows", "Grid: snake by columns"}, style="radioButtonVertical") type

original=File.getName(dir);
list=getFileList(dir);
Array.sort(list);
outputMerged=File.getParent(dir)+File.separator+original+"_merged";
outputStitched=File.getParent(dir)+File.separator+original+"_stitched";

//check if the folder contains h5 files
h5Files=0;
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "h5")==true) {
		h5Files++;
	}
}

//error message
if (h5Files==0) {
	exit("No h5 files found in "+original);
}

//create a an array containing only the names of the tif files in the folder
h5Array=newArray(h5Files);
count=0;
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "h5")) {
		h5Array[count]=list[i];
		count++;
	}
}

//count the number of wells
nWells=1;
well=newArray(h5Files);
well0=substring(h5Array[0],0,6);
for (i=0; i<h5Files; i++) {
	well[i]=substring(h5Array[i],0,6);
	well1=substring(h5Array[i],0,6);
	if (well1!=well0) {
		nWells++;
		well0=substring(h5Array[i],0,6);
	}
}

wellName=newArray(nWells);
fieldsxwell = (h5Files/nWells);

for (i=0; i<nWells; i++) {
	wellName[i]=well[i*fieldsxwell];
}

fields=newArray(fieldsxwell);
for (i=0; i<fieldsxwell; i++) {
	fieldNumber=d2s(i+1, 0);
	while (lengthOf(fieldNumber)<2) {
		fieldNumber="0"+fieldNumber;
	}
	fields[i]=fieldNumber;
}

//create the output folders
File.makeDirectory(outputMerged);
File.makeDirectory(outputStitched);
probStitchingOutput=outputStitched+File.separator+"Pixel_Prediction_Map";
rawStitchingOutput=outputStitched+File.separator+"Raw_Data";
File.makeDirectory(probStitchingOutput);
File.makeDirectory(rawStitchingOutput);

print("\\Clear");

//merge channels
for (i=0; i<nWells; i++) {
	for (j=0; j<fieldsxwell;j++) {
		fieldOfWiewImage=wellName[i]+"(fld "+fields[j]+")";
		print(fieldOfWiewImage, "merging channels");
		run("Import HDF5", "select=["+dir+File.separator+fieldOfWiewImage+".h5] datasetname=[/data: (1, 1, 2048, 2048, 1) uint16] axisorder=tzyxc");
		rename(fieldOfWiewImage);
		run("Run Pixel Classification Prediction", "saveonly=false projectfilename=["+project+"] inputimage=["+fieldOfWiewImage+"] chosenoutputtype=Probabilities");
		rename("probabilities");
		run("Duplicate...", "title=probabilities_neurospheres duplicate channels=2");
		run("16-bit");
		run("Merge Channels...", "c2=[probabilities_neurospheres] c4=["+fieldOfWiewImage+"] create");
		saveAs("tif", outputMerged+File.separator+"merge_"+fieldOfWiewImage);
		run("Close All");
	}
}
print("MERGE CHANNELS PERFORMED SUCCESSFULLY");

setBatchMode(true);
for (i=0; i<nWells; i++) {
	print(wellName[i], "stitching");
	run("Grid/Collection stitching", "type=["+type+"] order=[Right & Down                ] grid_size_x=5 grid_size_y=5 tile_overlap=15 first_file_index_i=1 directory=["+outputMerged+"] file_names=[merge_"+wellName[i]+"(fld {ii}).tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
	run("Split Channels");
	selectWindow("C1-Fused");
	run("Grays");
	saveAs("tif", probStitchingOutput+File.separator+wellName[i]);
	selectWindow("C2-Fused");
	run("Grays");
	saveAs("tif", rawStitchingOutput+File.separator+wellName[i]+"_probabilities");
	run("Close All");
}
print("STITCHING PERFORMED SUCCESSFULLY");

setBatchMode(false);