//script parameters
#@ File(label="Directory", style="directory") dir
#@ File(label="Pixel Classification", description="Enter an ilastik project (ilp) file", style="extensions:ilp") project
#@ String(label="Type", choices={"Grid: row-by-row", "Grid: column-by-column", "Grid: snake by rows", "Grid: snake by columns"}, style="radioButtonVertical") type
#@ Integer (label="Mean filter (radius)", value=2) mean
#@ Integer (label="Open (iterations)", value=15) iterOpen
#@ Integer (label="Threshold (%)", value=50, max=100, min=0, style="slider") threshold
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Laboratory</b><br>ERI BIOTECMED - Universitat de València (Spain)</font></html>", visibility=MESSAGE, persist=false) message

threshold/=100;
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

//check if the folder contains the scale file
scaleBoolean=false;
for (i=0; i<list.length; i++) {
	if (list[i] == "Scale.csv") {
		scaleBoolean=true;
	}
}

//error message
if (scaleBoolean==false) {
	exit("No Scale.csv files found in "+original);
}

//get scale
scaleString=File.openAsString(dir+File.separator+"Scale.csv");
linesScale=split(scaleString, "\n");
columnsScaleDistance=split(linesScale[0],",,");
columnsScaleUnit=split(linesScale[1],",,");
distance=columnsScaleDistance[1];
unit=columnsScaleUnit[1];

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
		selectImage("probabilities");
		run("Duplicate...", "title=probabilities_background duplicate channels=1");
		run("16-bit");
		run("Merge Channels...", "c1=[probabilities_background] c2=[probabilities_neurospheres] c4=["+fieldOfWiewImage+"] create");
		saveAs("tif", outputMerged+File.separator+"merge_"+fieldOfWiewImage);
		run("Close All");
	}
}
print("MERGE CHANNELS PERFORMED SUCCESSFULLY");

setBatchMode(true);
//stitching
for (i=0; i<nWells; i++) {
	print(wellName[i], "stitching");
	run("Grid/Collection stitching", "type=["+type+"] order=[Right & Down                ] grid_size_x=5 grid_size_y=5 tile_overlap=15 first_file_index_i=1 directory=["+outputMerged+"] file_names=[merge_"+wellName[i]+"(fld {ii}).tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
	run("Split Channels");
	selectWindow("C1-Fused");
	run("Grays");
	run("Set Scale...", "distance="+1/distance+" known=1 pixel=1 unit="+unit);
	saveAs("tif", probStitchingOutput+File.separator+wellName[i]+"_probabilities_bg");
	selectWindow("C2-Fused");
	run("Grays");
	run("Set Scale...", "distance="+1/distance+" known=1 pixel=1 unit="+unit);
	saveAs("tif", probStitchingOutput+File.separator+wellName[i]+"_probabilities");
	selectWindow("C3-Fused");
	run("Grays");
	run("Set Scale...", "distance="+1/distance+" known=1 pixel=1 unit="+unit);
	saveAs("tif", rawStitchingOutput+File.separator+wellName[i]);

	//neurospheres processing
	selectImage(wellName[i]+"_probabilities.tif");
	run("Mean...", "radius="+mean);
	setThreshold(65536*threshold, 65536);
	run("Convert to Mask");
	run("Fill Holes");
	run("Options...", "iterations="+iterOpen+" count=1 do=Open");
	//run("Watershed");
	run("Analyze Particles...", "size=1000-Infinity show=Masks");
	rename("mask1");

	//well processing
	selectImage(wellName[i]+"_probabilities_bg.tif");
	run("Median...", "radius=15");
	setThreshold(65536*0.5, 65536);
	run("Convert to Mask");
	run("Analyze Particles...", "size=10000000-Infinity show=Masks");
	run("Create Selection");
	run("Convex Hull");
	run("Create Mask");
	rename("well");
	run("Options...", "iterations=25 count=1 do=Erode");

	//binary reconstruct
	run("BinaryReconstruct ", "mask=mask1 seed=well create white");
	rename("Reconstructed_mask");
	run("Set Measurements...", "shape stack redirect=None decimal=2");
	run("Analyze Particles...", "display clear record");
	run("Classify Particles", "class[1]=AR operator[1]=<= value[1]=1.5 class[2]=Solidity operator[2]=>= value[2]=0.9 class[3]=Circ. operator[3]=>= value[3]=0.8 class[4]=-empty- operator[4]=-empty- value[4]=0.0000 combine=[AND (match all)] output=[Keep members] white");
	rename("Final_mask");
	
	//measure
	run("Set Measurements...", "area mean modal centroid perimeter shape feret's integrated redirect=None decimal=2");
	selectImage("Final_mask");
	run("Set Scale...", "distance="+1/distance+" known=1 pixel=1 unit="+unit);
	run("Analyze Particles...", "size=0-Infinity show=Masks display add clear");
	roiManager("Save", rawStitchingOutput+File.separator+wellName[i]+"_roi.zip");
	roiManager("deselect");
	roiManager("delete");
	run("Select None");
	
	//save
	roiCount=roiManager("count");
	for (j=0; j<roiCount; j++) {
		roiManager("select", j);
		roiManager("rename", j+1);
	}
	selectWindow("Results");
	saveAs("Results", rawStitchingOutput+File.separator+"Results_"+wellName[i]+".csv");
	
	//clean up
	run("Close All");
	run("Clear Results");
}

//delete merged directory
listMerged=getFileList(outputMerged);
for (i=0; i<listMerged.length; i++) {
	File.delete(outputMerged+File.separator+listMerged[i]);
}
File.delete(outputMerged);

//final clean up
print("STITCHING PERFORMED SUCCESSFULLY");
selectWindow("Results");
run("Close");
selectWindow("ROI Manager");
run("Close");
setBatchMode(false);