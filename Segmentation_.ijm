//script parameters
#@ File(label="Directory", style="directory") dir
#@ Integer (label="Mean filter (radius)", value=2) mean
#@ Float (label="Threshold (%)", value=0.35, max=1, min=0, stepSize=0.01, style="slider", persist=false) threshold
#@ Integer (label="Open (iterations)", value=15) iterOpen
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Laboratory</b><br>ERI BIOTECMED - Universitat de València (Spain)</font></html>", visibility=MESSAGE, persist=false) message

// set options
roiManager("reset");
setOption("BlackBackground", false);
setOption("ScaleConversions", true);
setOption("ExpandableArrays", true);
print("\\Clear");
run("Clear Results");
close("*");

// get file list from the Raw Data folder
subfolders=getFileList(dir);
rawDataDir=dir+File.separator+"Raw_Data";
list=getFileList(rawDataDir);
Array.sort(list);

// create a new array containing only the well names without extension
wellList=newArray();
count=0;
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], ".tif")) {
		index2=indexOf(list[i], ".");
		wellList[count]=substring(list[i], 0, index2);
		count++;
	}
}

//'Well Selection' dialog box
nWells=wellList.length;
selectionOptions=newArray("Select All", "Include", "Exclude");
fileCheckbox=newArray(nWells);
selection=newArray(nWells);
title = "Select Wells";
Dialog.create(title);
Dialog.addRadioButtonGroup("", selectionOptions, 3, 1, selectionOptions[0]);
Dialog.addCheckboxGroup(sqrt(nWells) + 1, sqrt(nWells) + 1, wellList, selection);
Dialog.show();
selectionMode=Dialog.getRadioButton();

for (i=0; i<nWells; i++) {
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

// create results table
title1 = "Project_Results_Table";
title2 = "["+title1+"]";
f = title2;
run("Table...", "name="+title2+" width=500 height=500");
print(f, "\\Headings:Well\tObject\tArea\tCirc.\tAR\tRound\tSolidity\tX\tY");

// image processing
setBatchMode(true);
for (i=0; i<wellList.length; i++) {
	if (fileCheckbox[i]) {
		open(dir+File.separator+"Pixel_Prediction_Map"+File.separator+wellList[i]+"_probabilities.tif");
		open(dir+File.separator+"Pixel_Prediction_Map"+File.separator+wellList[i]+"_probabilities_bg.tif");

		//neurospheres processing
		selectImage(wellList[i]+"_probabilities.tif");
		run("Mean...", "radius="+mean);
		setThreshold(threshold, 1);
		run("Convert to Mask");
		run("Fill Holes");
		run("Options...", "iterations="+iterOpen+" count=1 do=Open");
		//run("Watershed");
		run("Analyze Particles...", "size=1000-Infinity show=Masks");
		rename("mask1");
	
		//well processing
		selectImage(wellList[i]+"_probabilities_bg.tif");
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
		run("Set Measurements...", "area centroid shape redirect=None decimal=2");
		run("Analyze Particles...", "size=0-Infinity show=Masks display add clear");
		
		// save rois
		roiCount=roiManager("count");
		for (j=0; j<roiCount; j++) {
			roiManager("select", j);
			roiManager("rename", j+1);
		}
		roiManager("Save", dir+File.separator+"Raw_Data"+File.separator+wellList[i]+"_roi.zip");
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
			print(f, wellList[i] + "\t" + j+1 + "\t" + areaArray[j] + "\t" + circArray[j] + "\t" + arArray[j] + "\t" + roundArray[j] + "\t" + solidityArray[j] + "\t" + xArray[j] + "\t" +yArray[j]);
		}
		
		// clean up
		run("Close All");
		run("Clear Results");

	}
}

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
saveAs("Text", dir+File.separator+"Raw_Data"+File.separator+"ResultsTable_"+dayOfMonth+month+year+hour+minute+".csv");
run("Close");

// clean up
print("\\Clear");
print("Analysis performed successfully");
selectWindow("Results");
run("Close");
roiManager("reset");
setBatchMode(false);
