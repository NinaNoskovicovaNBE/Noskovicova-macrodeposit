// Detect Vinculin staining and measure betaintegrin intensity where vinculin is located
// By Joao Firmino
// for Nina Noskovicova


#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".czi") suffix

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	
	run("Set Measurements...", "area mean min integrated limit display redirect=None decimal=3");
	
	//First step consist in opening an image

	open(file);
	
	// we start by duplicating the vinculin channel; naming it vinculin and selecting the window
	run("Duplicate...", "duplicate channels=4-4 title=Vinculin");
	selectWindow("Vinculin");
	
	//run("Brightness/Contrast...");
	run("Enhance Contrast", "saturated=0.18");
	run("Apply LUT");

	// here we start the image processing
	// removing background in the vinculin channel removes that blur present in the center of the cells
	run("Subtract Background...", "rolling=50");

	// next step consists in applying a Moments autothreshold to binarise the signal and obtain a mask representing the vinculin signal
	//run("Threshold...");
	setAutoThreshold("Intermodes dark");
	run("Convert to Mask", "method=Intermodes background=Dark calculate black");

	// before proceeding we need to save this mask in the directory where the initial image was
	run("Save", "save=["+output+File.separator+file+"-VinculinMask.tif]");

	// we now proceed to identify all signals with an area between 1 and 20 micron2 - this is the only step where the user induces some bias!!
	run("Analyze Particles...", "size=0.5-20 clear add");

	// we have the ROIs with the appropriate size so all we have to do now is apply them to the betaintegrin channel and measure signal intensities
	selectWindow(file);
	run("Duplicate...", "duplicate channels=3-3 title=betaIntegrin");
	selectWindow("betaIntegrin");
	
	// removing background in the vinculin channel removes that blur present in the center of the cells
	run("Subtract Background...", "rolling=50");
	roiManager("Measure");

	// we save the obtained results in a csv file which the user can then open in an Excel spreadsheet
	saveAs("betaIntegrinResults", output+File.separator+file+"-betaIntegrinResults.csv");

	// before we move on to the next image we should clear the ROI manager of all the previously identified ROIs
	roiManager("Delete");

	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
}
