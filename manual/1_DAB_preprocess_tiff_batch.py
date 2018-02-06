# @File(label = "Input directory", style = "directory") inputDir
# @File(label = "Output directory", style = "directory") outputDir
# @String(label = "File suffix", description = "Leave blank for no filtering", value = ".tif") suffix
# @String(label = "Objective Lens", choices={"4x", "20x", "Other"}, style="listBox") mag
# @String(label = "If Other, pixel size in um", value = "0") manPixSize
# @LogService logService

# Note: DO NOT DELETE OR MOVE THE FIRST FEW LINES -- they supply essential parameters.

# 1_DAB_preprocess_tiff_batch.py
# Python port of ImageJ/Fiji macro
# Theresa Swayne, tcs6@cumc.columbia.edu, 2018

# Input: a folder of RGB TIF images of hematoxylin and DAB
# Corrects image illumination, color, and scale.
# Deconvolves colors using "H DAB" scheme.
# Output: 	1) RGB TIF corrected for background, color balance, and scale
#     		2) grayscale TIFs of hematoxylin and DAB components

# Usage: Run the macro.

# TODO: Batch mode? Replace IJ.run commands for speed?
# TODO: see http://forum.imagej.net/t/per-pixels-operation-and-performance/3446/3 Java supposed to be best for "per-pixel" operations, macro is 2nd best,

# SETUP

import os, sys, time
from java.lang import Double, Integer
from ij import IJ, ImagePlus, ImageStack, Prefs
from ij.process import ImageProcessor, ImageConverter, LUT, ColorProcessor
from ij.io import FileSaver

startTime = time.clock()
n = 0 # number of images
outputDir = str(outputDir)+os.path.sep

# get list of image files
inputDir = str(inputDir)
fileList = []
for fName in os.listdir(inputDir):
	if fName.endswith(suffix):
		fileList.append(os.path.join(inputDir,fName))
if len(fileList) < 1:
	raise Exception("No images found in %s" % inputDir)

# determine scale factor
# TODO: fix user messages
if (mag=="4x"):
	pixPerMicron = 2.5595
	#IJ.log("4x objective scale",pixPerMicron,"pixels per micron")
elif (mag == "20x"):
	pixPerMicron = 1.9535
	#IJ.log("20x objective scale",pixPerMicron,"pixels per micron")
elif (mag == "other" & manPixSize != "0"):
	pixPerMicron = 1/float(manPixSize)
	#IJ.log("Manual pixel size entered scale",pixPerMicron,"pixels per micron")
else: # TODO: fix this error
	# IJ.error("No scale selected! Please re-run the macro and provide an objective lens or scale.")
	logService.warn("No scale selected! Please re-run the macro and provide an objective lens or scale.")



# PROCESS IMAGES

for item in fileList:

	imp = IJ.openImage(item)
	n += 1
	IJ.showStatus("Processing file "+ str(n) +"/"+ str(len(fileList)))
	#TODO: find this message or Write to log window
	
	# get image name
	origFile = imp.getTitle()	
	titleWithoutExtension = os.path.splitext(origFile)[0]
	rgbName = titleWithoutExtension+"_corrected.tif"
	
	# subtract background
	IJ.run(imp, "Subtract Background...", "rolling=300 light")

	# TODO: FIX ERROR: IJ.run(imp, "BIOP SimpleColorBalance") TypeError: run(): 1st arg can't be coerced to String

	# correct color
	IJ.run(imp, "BIOP SimpleColorBalance")
	
	# save RGB corrected image
	IJ.saveAsTiff(imp, outputDir+rgbName)
		
	# split colors
	IJ.selectWindow(rgbName)
	IJ.run(rgbName, "Colour Deconvolution", "vectors=[H DAB] hide")
	
	# save hematoxylin image -- will be used to measure total area
	IJ.selectWindow(rgbName+"-(Colour_1)")
	IJ.run("Set Scale...", "distance=1 known="+pixPerMicron+" pixel=1 unit=um")
	IJ.saveAsTiff(outputDir+titleWithoutExtension+"_H.tif")

	# save DAB image -- will be used to detect antibody staining
	IJ.selectWindow(rgbName+"-(Colour_2)")
	IJ.run("Set Scale...", "distance=1 known="+pixPerMicron+" pixel=1 unit=um")
	IJ.saveAsTiff(outputDir+titleWithoutExtension+"_DAB.tif")
	
	# close any images remaining open
	while nImages > 0: # works on any number of channels
		IJ.run(close())

	# end image processing loop

# FINISH UP

endTime = time.clock()
elapsedTime = endTime - startTime
IJ.log("Finished processing "+n+" images in "+elapsedTime+" seconds.")
