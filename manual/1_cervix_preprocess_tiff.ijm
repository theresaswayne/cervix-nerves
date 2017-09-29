// @File(label = "Select input file") input
// @File(label = "Output directory", style = "directory") output

// cervix_preprocess_tiff.ijm

// Use for cervical whole-slide TIF images
// Subtracts background, corrects color balance, and corrects scale
// Saves the RGB tiff of the whole area
// Splits colors using "H DAB" scheme and saves constituent colors

// Usage: Open the tiff image, crop it (not necessary to save), and run the macro

// get image name
id = getImageID();
origTitle = getTitle();

name = File.getName(input);
dotIndex = indexOf(name, ".");
basename = substring(name, 0, dotIndex);
print("basename is",basename);

// convert to RGB format
Stack.setDisplayMode("composite");
run("Stack to RGB");

// subtract background
run("Subtract Background...", "rolling=300 light");

// correct color
run("BIOP SimpleColorBalance");

// save RGB corrected image
saveAs ("tiff", output+File.separator+basename+".tif");

//close original
//selectWindow(origTitle+" (RGB)");
selectImage(id);
close();

// split colors
selectWindow(basename+".tif");
run("Colour Deconvolution", "vectors=[H DAB] hide");

// close Colour 3 image -- not needed
selectWindow(basename+".tif-(Colour_3)");
close();

// save hematoxylin image -- will be used to measure total area
selectWindow(basename+".tif-(Colour_1)");
run("Set Scale...", "distance=1 known=2.5595 pixel=1 unit=um");
saveAs ("tiff", output+File.separator+basename+"_H.tif");
close();

// save DAB image -- will be used to detect antibody staining
selectWindow(basename+".tif-(Colour_2)");
run("Set Scale...", "distance=1 known=2.5595 pixel=1 unit=um");
saveAs ("tiff", output+File.separator+basename+"_DAB.tif");





