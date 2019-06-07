//script parameters
#@ File(label="Directory", style="directory") dir
#@ String(label="Type", choices={"Grid: row-by-row", "Grid: column-by-column", "Grid: snake by rows", "Grid: snake by columns"}, style="radioButtonVertical") type

original=File.getName(dir);
list=getFileList(dir);
Array.sort(list);
outputMerged=File.getParent(dir)+File.separator+original+"_merged";
outputStitched=File.getParent(dir)+File.separator+original+"_stitched";

//check if the folder contains tif files
tifFiles=0;
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "tif")==true) {
		tifFiles++;
	}
}

//error message
if (tifFiles==0) {
	exit("No tif files found in "+original);
}

//create a an array containing only the names of the tif files in the folder
tifArray=newArray(tifFiles);
count=0;
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "tif")) {
		tifArray[count]=list[i];
		count++;
	}
}

//count the number of wells
nWells=1;
well=newArray(tifFiles);
well0=substring(tifArray[0],0,6);
for (i=0; i<tifFiles; i++) {
	well[i]=substring(tifArray[i],0,6);
	well1=substring(tifArray[i],0,6);
	if (well1!=well0) {
		nWells++;
		well0=substring(tifArray[i],0,6);
	}
}

wellName=newArray(nWells);
fieldsxwell = (tifFiles/nWells);

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
probStitchingOutput=outputStitched+File.separator+"Pixel_Prediction_Map"
rawStitchingOutput=outputStitched+File.separator+"Raw_Data";
File.makeDirectory(probStitchingOutput);
File.makeDirectory(rawStitchingOutput);

print("\\Clear");
setBatchMode(true);

//merge channels
for (i=0; i<nWells; i++) {
	for (j=0; j<fieldsxwell;j++) {
		fieldOfWiewImage=wellName[i]+"(fld "+fields[j]+")";
		print(fieldOfWiewImage, "merging channels");
		open(dir+File.separator+fieldOfWiewImage+".tif");
		open(dir+File.separator+fieldOfWiewImage+"_Probabilities_1.tiff");
		run("16-bit");
		run("Merge Channels...", "c2=["+fieldOfWiewImage+"_Probabilities_1.tiff] c4=["+fieldOfWiewImage+".tif] create");
		saveAs("tif", outputMerged+File.separator+"merge_"+fieldOfWiewImage);
		run("Close All");
	}
}
print("MERGE CHANNELS PERFORMED SUCCESSFULLY");

for (i=0; i<nWells; i++) {
	print(wellName[i], "stitching");
	run("Grid/Collection stitching", "type=["+type+"] order=[Right & Down                ] grid_size_x=5 grid_size_y=5 tile_overlap=15 first_file_index_i=1 directory=["+outputMerged+"] file_names=[merge_"+wellName[i]+"(fld {ii}).tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
	run("Split Channels");
	selectWindow("C1-Fused");
	run("Grays");
	saveAs("tif", rawStitchingOutput+File.separator+wellName[i]+"_probabilities");
	selectWindow("C2-Fused");
	run("Grays");
	saveAs("tif", probStitchingOutput+File.separator+wellName[i]);
	run("Close All");
}
print("STITCHING PERFORMED SUCCESSFULLY");

setBatchMode(false);