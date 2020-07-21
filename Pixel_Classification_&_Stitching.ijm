//script parameters
#@ File(label="Directory", style="directory") dir
#@ File(label="Pixel Classification", description="Enter an ilastik project (ilp) file", style="extensions:ilp") project
#@ String(label="Type", choices={"Grid: row-by-row", "Grid: column-by-column", "Grid: snake by rows", "Grid: snake by columns"}, style="radioButtonVertical") type
#@ Integer (label="Tile overlap (%)", value=15) overlap
#@ Integer (label="Mean filter (radius)", value=2) mean
#@ Float (label="Threshold (%)", value=0.35, max=1, min=0, stepSize=0.01, style="slider", persist=false) threshold
#@ Integer (label="Open (iterations)", value=15) iterOpen
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Laboratory</b><br>ERI BIOTECMED - Universitat de València (Spain)</font></html>", visibility=MESSAGE, persist=false) message

// set options
roiManager("reset");
setOption("BlackBackground", false);
setOption("ScaleConversions", true);
print("\\Clear");
run("Clear Results");
close("*");
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

//'Well Selection' dialog box
selectionOptions=newArray("Select All", "Include", "Exclude");
fileCheckbox=newArray(nWells);
selection=newArray(nWells);
title = "Select Wells";
Dialog.create(title);
Dialog.addRadioButtonGroup("", selectionOptions, 3, 1, selectionOptions[0]);
Dialog.addCheckboxGroup(sqrt(nWells) + 1, sqrt(nWells) + 1, wellName, selection);
Dialog.show();
selectionMode=Dialog.getRadioButton();

for (i=0; i<wellName.length; i++) {
	fileCheckbox[i]=Dialog.getCheckbox();
	if (selectionMode=="Select All") {
		fileCheckbox[i]=true;
	} else if (selectionMode=="Exclude") {
		if (fileCheckbox[i]==true) {
			fileCheckbox[i]=false;
		} else {
			fileCheckbox[i]=true;
		}
	}
}

//check that at least one well have been selected
checkSelection = 0;
for (i=0; i<nWells; i++) {
	checkSelection += fileCheckbox[i];
}

if (checkSelection == 0) {
	exit("There is no well selected");
}

// time variables
total_fields=checkSelection*fieldsxwell;
count_print=0;
start_PixClas=getTime();

//pixel classification
print("Pixel Classification");
for (i=0; i<nWells; i++) {
	if (fileCheckbox[i]) {
		for (j=0; j<fieldsxwell;j++) {
			fieldOfWiewImage=wellName[i]+"(fld "+fields[j]+")";
			// log timing
			print("\\Update1:"+ fieldOfWiewImage + "     " + count_print+1+"/"+total_fields);
			if (count_print == 0) {
				print("\\Update2:Estimating time...");
			} else {
				elapsed=round((getTime()-start_PixClas)/1000);
				expected=elapsed/(count_print)*total_fields;
				print("\\Update2:Elapsed time "+hours_minutes_seconds(elapsed));
				print("\\Update3:Estimated time "+hours_minutes_seconds(expected));
			}
			count_print++;
			// ilastik's pixel classification
			run("Import HDF5", "select=["+dir+File.separator+fieldOfWiewImage+".h5] datasetname=[/data] axisorder=tzyxc");
			rename(fieldOfWiewImage);
			run("Run Pixel Classification Prediction", "projectfilename=["+project+"] inputimage=["+fieldOfWiewImage+"] pixelclassificationtype=Probabilities");
			rename("probabilities");
			run("Duplicate...", "title=probabilities_neurospheres duplicate channels=2");
			selectImage("probabilities");
			run("Duplicate...", "title=probabilities_background duplicate channels=1");
			// brightfield to 32-bit (normalize frm 0 to 1)
			selectImage(fieldOfWiewImage);
			run("32-bit");
			run("Enhance Contrast...", "saturated=0.3 normalize");
			// merge channels and save
			run("Merge Channels...", "c1=[probabilities_background] c2=[probabilities_neurospheres] c4=["+fieldOfWiewImage+"] create");
			saveAs("tif", outputMerged+File.separator+"merge_"+fieldOfWiewImage);
			run("Close All");
		}
	}
}
elapsed_PixClas=round((getTime()-start_PixClas)/1000);
print("\\Update0:Pixel Classification performed successfully");
print("\\Update1:Elapsed time "+hours_minutes_seconds(elapsed_PixClas));
print("\\Update2:");
print("\\Update3:");

// create results table
title1 = "Project_Results_Table";
title2 = "["+title1+"]";
f = title2;
run("Table...", "name="+title2+" width=500 height=500");
print(f, "\\Headings:Well\tObject\tArea\tCirc.\tAR\tRound\tSolidity\tX\tY");

// time variables
count_print=0;
start_Stitching=getTime();

// stitching
print("\\Clear");
print("Stitching");
setBatchMode(true);
for (i=0; i<nWells; i++) {
	if (fileCheckbox[i]) {
		// log timing
		print("\\Update0:Stitching");
		print("\\Update1:"+ wellName[i] + "     " + count_print+1+"/"+checkSelection);
		if (count_print == 0) {
			print("\\Update2:Estimating time...");
		} else {
			elapsed=round((getTime()-start_Stitching)/1000);
			expected=elapsed/(count_print)*total_fields;
			print("\\Update2:Elapsed time "+hours_minutes_seconds(elapsed));
			print("\\Update3:Estimated time "+hours_minutes_seconds(expected));
		}
		count_print++;
		run("Grid/Collection stitching", "type=["+type+"] order=[Right & Down                ] grid_size_x=5 grid_size_y=5 tile_overlap="+overlap+" first_file_index_i=1 directory=["+outputMerged+"] file_names=[merge_"+wellName[i]+"(fld {ii}).tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
		print("\\Clear");
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
		print("Segmentation");
		selectImage(wellName[i]+"_probabilities.tif");
		run("Mean...", "radius="+mean);
		setThreshold(threshold, 1);
		run("Convert to Mask");
		run("Fill Holes");
		run("Options...", "iterations="+iterOpen+" count=1 do=Open");
		//run("Watershed");
		run("Analyze Particles...", "size=1000-Infinity show=Masks");
		rename("mask1");
	
		//well processing
		selectImage(wellName[i]+"_probabilities_bg.tif");
		run("Median...", "radius=15");
		setThreshold(0.5, 1);
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
		//run("Set Measurements...", "shape stack redirect=None decimal=2");
		//run("Analyze Particles...", "display clear record");
		//run("Classify Particles", "class[1]=AR operator[1]=<= value[1]=1.5 class[2]=Solidity operator[2]=>= value[2]=0.9 class[3]=Circ. operator[3]=>= value[3]=0.8 class[4]=-empty- operator[4]=-empty- value[4]=0.0000 combine=[AND (match all)] output=[Keep members] white");
		
		// measure
		print("Quantification");
		run("Set Measurements...", "area centroid shape redirect=None decimal=2");
		run("Set Scale...", "distance="+1/distance+" known=1 pixel=1 unit="+unit);
		run("Analyze Particles...", "size=0-Infinity show=Masks display add clear");
		// save rois
		roiCount=roiManager("count");
		for (j=0; j<roiCount; j++) {
			roiManager("select", j);
			roiManager("rename", j+1);
		}
		roiManager("Save", rawStitchingOutput+File.separator+wellName[i]+"_roi.zip");
		roiManager("deselect");
		roiManager("delete");
		run("Select None");
	
		//store results
		areaArray=newArray(nResults);
		circArray=newArray(nResults);
		arArray=newArray(nResults);
		roundArray=newArray(nResults);
		solidityArray=newArray(nResults);
		xArray=newArray(nResults);
		yArray=newArray(nResults);
		for (j=0; j<areaArray.length; j++) {
			areaArray[j]=getResult("Area", j);
			circArray[j]=getResult("Circ.", j);
			arArray[j]=getResult("AR", j);
			roundArray[j]=getResult("Round", j);
			solidityArray[j]=getResult("Solidity", j);
			xArray[j]=getResult("X", j);
			yArray[j]=getResult("Y", j);
			print(f, wellName[i] + "\t" + j+1 + "\t" + areaArray[j] + "\t" + circArray[j] + "\t" + arArray[j] + "\t" + roundArray[j] + "\t" + solidityArray[j] + "\t" + xArray[j] + "\t" +yArray[j]);
		}
		
		// clean up
		run("Close All");
		run("Clear Results");
	}
}

elapsed_Stitching=round((getTime()-start_Stitching)/1000);
print("\\Update0:Stitching performed successfully");
print("\\Update1:Elapsed time "+hours_minutes_seconds(elapsed_Stitching));
print("\\Update2:");
print("\\Update3:");

// delete merged directory
print("\\Update3:Deleting temporary files");
listMerged=getFileList(outputMerged);
for (i=0; i<listMerged.length; i++) {
	File.delete(outputMerged+File.separator+listMerged[i]);
}
File.delete(outputMerged);

// date & time
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
dayOfMonth=d2s(dayOfMonth, 0);
while (lengthOf(dayOfMonth) < 2) {
	dayOfMonth="0"+dayOfMonth;
}
month+=1;
month=d2s(month, 0);
while (lengthOf(month) < 2) {
	month="0"+month;
}
hour=d2s(hour, 0);
while (lengthOf(hour) < 2) {
	hour="0"+hour;
}
minute=d2s(minute, 0);
while (lengthOf(minute) < 2) {
	minute="0"+minute;
}

//save results table
print("\\Update3:Saving results");
selectWindow("Project_Results_Table");
saveAs("Text", rawStitchingOutput+File.separator+"ResultsTable_"+dayOfMonth+month+year+hour+minute+".csv");
run("Close");

// clean up
print("\\Clear");
print("Stitching performed successfully");
selectWindow("Results");
run("Close");
roiManager("reset");
setBatchMode(false);

elapsed_total=elapsed_PixClas+elapsed_Stitching;
print("\\Clear");
print("End of process");
print("Pixel Classification elapsed time "+hours_minutes_seconds(elapsed_PixClas));
print("Stitching elapsed time "+hours_minutes_seconds(elapsed_Stitching));
print("Total elapsed time "+hours_minutes_seconds(elapsed_total));
print(" ");
print("Date (DD/MM/YY)     "+ dayOfMonth+"/"+month+"/"+year);
print("Time (24h clock)       " + hour+":"+minute);

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function hours_minutes_seconds(seconds) {
	hours=seconds/3600;
	hours_floor=floor(hours);
	remaining_seconds=seconds-(hours_floor*3600);
	remaining_minutes=remaining_seconds/60;
	minutes_floor=floor(remaining_minutes);
	remaining_seconds=remaining_seconds-(minutes_floor*60);
	hours_floor=d2s(hours_floor, 0);
	minutes_floor=d2s(minutes_floor, 0);
	remaining_seconds=d2s(remaining_seconds, 0);
	if (lengthOf(hours_floor) < 2) hours_floor="0"+hours_floor;
	if (lengthOf(minutes_floor) < 2) minutes_floor="0"+minutes_floor;
	if (lengthOf(remaining_seconds) < 2) remaining_seconds="0"+remaining_seconds;
	return hours_floor+":"+minutes_floor+":"+remaining_seconds;
}