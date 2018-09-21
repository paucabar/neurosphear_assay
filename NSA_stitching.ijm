macro "NSA_stitching" {
	//Dialog box
	Dialog.create("Well reconstruction");
	Dialog.addNumber("Grid_size_x", 5);
	Dialog.addNumber("Grid_size_y", 5);
	Dialog.addSlider("Tile_overlap_[%]", 0, 100, 15);
	Dialog.addSlider("Scale_factor", 0.1, 0.9, 0.5);
	Dialog.addString("Output directory", "Stitching");
	Dialog.show();
	gridSizeX=Dialog.getNumber();
	gridSizeY=Dialog.getNumber();
	tileOverlap=Dialog.getNumber();
	scaleFactor=Dialog.getNumber();
	newDirectory=Dialog.getString();

	//choose a directory
	dir = getDirectory("Choose a Directory");
	outputDirectoryPath=dir+"\\"+newDirectory;
	File.makeDirectory(outputDirectoryPath);
	list = getFileList(dir);
	Array.sort(list);

	//count the number of TIF files
	tiffFiles=0;
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "tif")) {
			tiffFiles++;
		}
	}

	//check that the directory contains TIF files
	if (tiffFiles==0) {
		beep();
		exit("No TIFF files")
	}

	//create a an array containing only the names of the TIF files in the directory path
	tiffArray=newArray(tiffFiles);
	count=0;
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "tif")) {
			tiffArray[count]=list[i];
			count++;
		}
	}

	//count the number of wells
	count=0;
	nWells=1;
	well=newArray(tiffFiles);
	well0=substring(tiffArray[0],0,6);
	for (i=0; i<tiffArray.length; i++) {
		if (endsWith(list[i], "tif")) {
			well[count]=substring(list[i],0,6);
			well1=substring(list[i],0,6);
			if (well1!=well0) {
				nWells++;
				well0=substring(list[i],0,6);
			}
			count++;
		}
	}

	wellName=newArray(nWells);
	imagesxwell = (tiffFiles / nWells);

	for (i=0; i<nWells; i++) {
		wellName[i]=well[i*imagesxwell];
	}

	//select wells to be analysed
	fileCheckbox=newArray(nWells);
	selection=newArray(nWells);
	title = "Select Wells";
	Dialog.create(title);
	Dialog.addCheckbox("Select All", true);
	Dialog.addCheckboxGroup(8,12,wellName,selection);
	Dialog.show();
	selectAll=Dialog.getCheckbox();
	for (i=0; i<nWells; i++) {
		fileCheckbox[i]=Dialog.getCheckbox();
		if (selectAll==true) {
			fileCheckbox[i]=true;
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

	//STITCHING & RESIZING
	setBatchMode(true);
	for (z=0; z<nWells; z++) {
		if (fileCheckbox[z]==true) {
			run("Grid/Collection stitching", "type=[Grid: snake by rows] order=[Right & Down                ] "+
			"grid_size_x="+gridSizeX+" grid_size_y="+gridSizeY+" tile_overlap=15 first_file_index_i=1 directory=["+dir+"] file_names=["+
			wellName[z]+"(fld {ii}).tif] output_textfile_name=TileConfiguration.txt fusion_method=[Linear Blending] "+
			"regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 "+
			"compute_overlap computation_parameters=[Save memory (but be slower)] image_output=[Fuse and display]");
			width=getWidth();
			height=getHeight();
			widthFinal=width*scaleFactor;
			heightFinal=height*scaleFactor;
			run("Resize ", "sizex="+widthFinal+" sizey="+heightFinal+" method=Least-Squares interpolation=Cubic unitpixelx=true unitpixely=true");
			rename(wellName[z]);
			makeOval(2, 2, widthFinal-4, heightFinal-4);
			run("Create Mask");
			run("Invert");
			imageCalculator("Transparent-zero create", wellName[z],"Mask");
			setColor(4096);
			floodFill(0, 0);
			saveAs("tiff", outputDirectoryPath+"\\"+wellName[z]);
			run("Close All");
			if (isOpen("Log")) {
				selectWindow("Log");
				run("Close");
			}
		}
	}
	setBatchMode(false);
}