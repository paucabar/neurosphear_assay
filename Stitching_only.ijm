//script parameters
#@ File(label="Directory", style="directory") dir
#@ String(label="Type", choices={"Grid: row-by-row", "Grid: snake by rows"}, style="radioButtonVertical") type
#@ Integer (label="Tile overlap (%)", value=15) overlap
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Lab</b><br>ERI BIOTECMED - Universitat de València (Spain)</font></html>", visibility=MESSAGE, persist=false) message

//input output
original=File.getName(dir);
list=getFileList(dir);
Array.sort(list);
output=File.getParent(dir)+File.separator+original+"_stitched";
File.makeDirectory(output);

// count the number of TIF files
tifFiles=0;
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "tif")) {
		tifFiles++;
	}
}

// check that the directory contains TIF files
if (tifFiles==0) {
	beep();
	exit("No tif files")
}

// create a an array containing only the names of the TIF files in the directory path
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
well=newArray(tifArray.length);
well0=substring(tifArray[0],0,6);
for (i=0; i<tifArray.length; i++) {
	well[i]=substring(tifArray[i],0,6);
	well1=substring(tifArray[i],0,6);
	if (well1!=well0) {
		nWells++;
		well0=substring(tifArray[i],0,6);
	}
}

//get well names
wellName=newArray(nWells);
fieldsxwell = (tifArray.length/nWells);
for (i=0; i<nWells; i++) {
	wellName[i]=well[i*fieldsxwell];
}

//stitching
setBatchMode(true);
for (i=0; i<nWells; i++) {
	run("Grid/Collection stitching", "type=["+type+"] order=[Right & Down                ] grid_size_x=5 grid_size_y=5 tile_overlap="+overlap+" first_file_index_i=1 directory=["+dir+"] file_names=["+wellName[i]+"(fld {ii}).tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
	saveAs("tif", output+File.separator+wellName[i]);
	close();
}
print("\\Clear");
print("Ya está");