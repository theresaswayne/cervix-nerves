// @File(label = "Select VSI file") vsipath
// @File(label = "Output directory", style = "directory") output

// cervix_preprocess_tiff.ijm

// Use for cervical whole-slide VSI images where colors are not rendered properly
// Swaps the red and blue channels, subtracts background, corrects color balance, and corrects scale
// Saves the RGB tiff of the whole area
// Splits colors using "H DAB" scheme and saves constituent colors
// Divides the DAB and RGB images into tiles of < 1000 x 1000 pixels

// Usage: Open a VSI image with VSI Reader, set an ROI to the tissue area, Extract current ROI, close VSI panel and all other windows, then run the script

function makeTiles(file, divisions, outputPath){

// based on IJ forum thread http://forum.imagej.net/t/macro-for-automatic-saving-and-filename-designation/1966 
	File.makeDirectory(outputPath);
	selectWindow(file);
	largeID = getImageID();
	title = getTitle();
	dotIndex = indexOf(title, ".");
	tilebasename = substring(title, 0, dotIndex);
	getLocationAndSize(locX, locY, sizeW, sizeH);
	width = getWidth();
	height = getHeight();
	n = divisions;
	tileWidth = width / n;
	tileHeight = height / n;
	for (y = 0; y < n; y++) {
	  offsetY = y * height / n;
	  for (x = 0; x < n; x++) {
	    offsetX = x * width / n;
	    selectImage(largeID);
	    call("ij.gui.ImageWindow.setNextLocation", locX + offsetX, locY + offsetY);
	    tileTitle = tilebasename + "[" + x + "," + y + "].tif";
	    // using the ampersand allows spaces in the tileTitle to be handled correctly 
	    run("Duplicate...", "title=&tileTitle");
	    makeRectangle(offsetX, offsetY, tileWidth, tileHeight);
	    run("Crop");
	    selectWindow(tileTitle);
	    saveAs("tiff",outputPath+File.separator+tileTitle);
	    close();
	    }
	  }
	//selectImage(largeID);
	//close();
}

// get image name
id = getImageID();
origTitle = getTitle();

//separatorIndex = lastIndexOf(vsipath, File.separator);
vsiname = File.getName(vsipath);
//vsiname = substring(vsiname, separatorIndex); // separator to end of string
dotIndex = indexOf(vsiname, ".");
basename = substring(vsiname, 0, dotIndex);
print("basename is",basename);

// swap red and blue channels because ImageJ doesn't read them properly
Stack.setDisplayMode("color");
Stack.setChannel(1);
run("Blue");
Stack.setChannel(3);
run("Red");
Stack.setDisplayMode("composite");
run("Stack to RGB");

// subtract background
run("Subtract Background...", "rolling=300 light");

// correct color
run("BIOP SimpleColorBalance");

// fix scale
run("Set Scale...", "distance=1 known=2.5595 pixel=1 unit=um");

// save RGB corrected image
saveAs ("tiff", output+File.separator+basename+".tif");

//close original
selectWindow(origTitle+" (RGB)");
close();

// split colors
selectWindow(basename+".tif");
run("Colour Deconvolution", "vectors=[H DAB] hide");

// close Colour 3 image -- not needed
selectWindow(basename+".tif-(Colour_3)");
close();

// save hematoxylin image -- will be used to measure total area
selectWindow(basename+".tif-(Colour_1)");
saveAs ("tiff", output+File.separator+basename+"_H.tif");
close();

// save DAB image -- will be used to detect antibody staining
selectWindow(basename+".tif-(Colour_2)");
saveAs ("tiff", output+File.separator+basename+"_DAB.tif");

// create tile images for faster segmentation
selectWindow(basename+".tif");
width = getWidth();
height = getHeight();
divs = floor((maxOf(width, height))/1000)+1;

rgbTilePath = output+File.separator+"RGB tiles";
dabTilePath = output+File.separator+"DAB tiles";

makeTiles(basename+".tif",divs, rgbTilePath);

makeTiles(basename+".tif",divs, dabTilePath);





