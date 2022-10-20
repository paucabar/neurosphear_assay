//script parameters
#@ File(label="Directory", style="directory") dir
#@ String(label="Method", choices={"Retrospective multi-modal", "Prospective"}, style="radioButtonVertical") method
#@ String(label="Export", choices={"HDF5", "TIF"}, style="radioButtonHorizontal") export
#@ String(label="Type", choices={"Grid: row-by-row", "Grid: snake by rows"}, style="radioButtonVertical") type
#@ Integer (label="Tile overlap (%)", value=15) overlap
#@ boolean (label="Normalise", value=true, persist=true) normalise
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Laboratory</b><br>ERI BIOTECMED - Universitat de València (Spain)</font></html>", visibility=MESSAGE, persist=false) message

original=File.getName(dir);
list=getFileList(dir);
Array.sort(list);
outputFlatField=File.getParent(dir)+File.separator+original+"_flat-field";
outputCorrected=File.getParent(dir)+File.separator+original+"_corrected";
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

//Prospective method needs reference images
if (method=="Prospective") {
	dirFlatField=getDirectory("Select the flat-field Directory");
}

//create the output folders
File.makeDirectory(outputFlatField);
File.makeDirectory(outputCorrected);
File.makeDirectory(outputStitched);

print("\\Clear");
setBatchMode(true);

//generate flat-field refernce images
if (method=="Retrospective multi-modal") {
	for (i=0; i<fieldsxwell; i++) {
		name="stack_"+fields[i];
		print("Generating", name, "flat-field reference images");
		run("Image Sequence...", "open=["+dir+"] file=[(fld "+fields[i]+")] sort");
		rename(name);
		run("BaSiC ", "processing_stack="+name+" flat-field=None dark-field=None shading_estimation=[Estimate shading profiles] shading_model=[Estimate flat-field only (ignore dark-field)] setting_regularisationparametes=Automatic temporal_drift=Ignore correction_options=[Compute shading only] lambda_flat=0.50 lambda_dark=0.50");
		selectWindow("Flat-field:"+name);
		saveAs("tif", outputFlatField+File.separator+"flat-field_"+fields[i]);
		run("Close All");
	}
}

//shading correction
for (i=0; i<nWells; i++) {
	for (j=0; j<fieldsxwell;j++) {
		fieldOfWiewImage=wellName[i]+"(fld "+fields[j]+")";
		flatFieldImage="flat-field_"+fields[j];
		print(fieldOfWiewImage, "shading correction");
		
		//open raw image
		open(dir+File.separator+fieldOfWiewImage+".tif");
		
		//get image scale
		if (i==0 && j==0) {
			getVoxelSize(widthGbl, heightGbl, depthGbl, unitGbl);
			title1 = "Scale";
			title2 = "["+title1+"]";
			f = title2;
			run("Table...", "name="+title2+" width=650 height=500");
			print(f, "distance" + "\t" + widthGbl);
			print(f, "unit" + "\t" + unitGbl);
			saveAs("Text", outputCorrected+File.separator+"Scale.csv");
			selectWindow(title1);
			run("Close");
		}

		//open flat-field image
		if (method=="Retrospective multi-modal") {
			open(outputFlatField+File.separator+"flat-field_"+fields[j]+".tif");
		} else {
			open(dirFlatField+File.separator+flatFieldImage+".tif");
		}
		imageCalculator("Divide create", fieldOfWiewImage+".tif", flatFieldImage+".tif");
		rename("corrected");
		if (export == "HDF5") {
			run("Export HDF5", "select=["+outputCorrected+File.separator+fieldOfWiewImage+".h5] exportpath=["+outputCorrected+File.separator+fieldOfWiewImage+".h5] datasetname=data compressionlevel=0 input=[corrected]");
		} else {
			saveAs("tif", outputCorrected+File.separator+fieldOfWiewImage);
		}		
		run("Close All");
	}
}
print("SHADING CORRECTION PERFORMED SUCCESSFULLY");

//stitching
for (i=0; i<nWells; i++) {
	run("Grid/Collection stitching", "type=["+type+"] order=[Right & Down                ] grid_size_x=5 grid_size_y=5 tile_overlap="+overlap+" first_file_index_i=1 directory=["+outputCorrected+"] file_names=["+wellName[i]+"(fld {ii}).tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
	if (normalise) {
		run("32-bit");
		run("Enhance Contrast...", "saturated=0.3 normalize");
	}
	saveAs("tif", outputStitched+File.separator+wellName[i]);
	close();
}
print("\\Clear");
print("STITCHING PERFORMED SUCCESSFULLY");

setBatchMode(false);