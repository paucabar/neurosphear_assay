# Neurosphere Assay

## Description


Learn more about neurosphere formation assays:

* Belenguer G, Domingo-Muelas A, Ferrón SR, Morante-Redolat JM & Fariñas I. (2016). [Isolation, culture and analysis of adult subependymal neural stem cells](https://www.sciencedirect.com/science/article/pii/S0301468116300044?via%3Dihub). Differentiation. 91(4-5):28-41. [doi:10.1016/j.diff.2016.01.005](https://www.sciencedirect.com/science/article/pii/S0301468116300044?via%3Dihub)

## Requirements

* [Fiji](https://fiji.sc/)
* [ilastik](https://www.ilastik.org/) 1.3.3
* _BaSiC_ update site (Fiji)
* _ilastik_ update site (Fiji). Once added, it is important to configure the ilastik executable location within the Fiji's plugin.
* _Morphology_ update site (Fiji)
* Image dataset following an IN Cell Analyzer file naming convention (note that the NeuroMol update site includes a [macroinstruction](https://github.com/paucabar/other_macros) to turn data acquired with diferent high content microscopes into an IN Cell Analyzer file naming convention dataset)

How to [follow an update site](https://imagej.net/Following_an_update_site) in Fiji

## Installation

1. Start Fiji
2. Start the **ImageJ Updater** (<code>Help > Update...</code>)
3. Click on <code>Manage update sites</code>
4. Click on <code>Add update site</code>
5. A new blank row is to be created at the bottom of the update sites list
6. Type **NeuroMol Lab** in the **Name** column
7. Type **http://sites.imagej.net/Paucabar/** in the **URL** column
8. <code>Close</code> the update sites window
9. <code>Apply changes</code>
10. Restart Fiji
11. Check if <code>NeuroMol Lab</code> appears now in the <code>Plugins</code> dropdown menu (note that it will be placed at the bottom of the dropdown menu)

## Test Dataset

Download an example [image dataset](https://drive.google.com/drive/folders/1W_UDxg4mbQ1qNeZo1tPUezNgmZxtMwkv?usp=sharing) and some [ilastik classifiers](https://drive.google.com/drive/folders/1mgT7NOzUn5zvgJp47WbMRDCNR9f6efXg?usp=sharing) which have been trained using the same subset of images and user annotations but different sets of features.

## Usage

### Illumination Correction (NFA)

1. Run the **Illumination Correction** macro (<code>Plugins > NeuroMol Lab > Neurosphere Assay > Illumination Correction</code>)
2. Select the directory containing the images (TIF files)
3. Select the illumination correction mode. Note that the **prospective** method will ask for an additional folder containing the reference images to apply the correction function. Conversely, the **retrospective multi-image** method dos not require reference images, but it needs a medium-size dataset in order to perform properly (>25-30 wells) 
4. Run
5. Corrected images  images will be saved in a new subfolder within the original directory

### Pixel Classification: training a new classifier within ilastik (optional)

1. Start a pixel classification project in ilastik
2. Load some corrected images (HDF5 files). Try to use images with different appearence, from several field-of-view positions and wells
3. Select some features (you can start by selecting all of them)
4. Annotate the images. Note that label 1 must correspond to _background_, label 2 to _neurospheres_ and label 3 to _well edges_
5. If it takes too much time to perform the classification, ilastik includes implemented algorithms to keep the major features (look at the features applet)
5. Once the classifier performs fine, set up the prediction export applet: i) set _Probabilities_ at the souce drop-down menu; ii) check _Renormalize_ (from 0 to 1)
6. Save the project

Learn more about the ilastik [pixel classification workflow](https://www.ilastik.org/documentation/pixelclassification/pixelclassification)

### Pixel Classification & Stitching

1. Run the **Pixel Classification & Stitching** macro (<code>Plugins > NeuroMol Lab > Neurosphere Assay > Pixel Classification & Stitching</code>)
2. Select the directory containing the images (TIF files)
3. Load the pixel classification project
4. Select the stitching mode. Note that it depends on the image acquisition parameters. Also note that the macro assumes an overlapping of 15 %
5. Adjust some workflow parameters (mean, threshold, open iterations). Know more about the parameters of the workflow on the **wiki page (not yet)**
6. Run. Note that the stitching workflow may take several hours, depending on the dataset size
7. A series of new files will be saved within different directories: stitched brightfield and probability maps files (TIF), a results table file (CSV) and the ROI files (ZIP) of each well

### Segmentation

Since the **Pixel Classification & Stitching** macro requiures a significative amount of computational time (which is mainly due to the pixel classification and, to a lesser extent, the stitching step), the **Segmentation** macro enables to reset the segmentation parameters and quickly test them on the already stitched probability maps.

1. Run the **Segmentation** macro (<code>Plugins > NeuroMol Lab > Neurosphere Assay > Segmentation</code>)
2. Select the directory containing the stitching output (a folder tagged with the postfix _corrected_stitched_). The folder must contain two subfolders: _Pixel_Prediction_Map_ and _Raw_Data_. Please note that the TIF files stored on both subfolders should never be reallocated or modified in any way in order to be reused with the **Segmentation** macro.
3. Adjust some workflow parameters (mean, threshold, open iterations). Know more about the parameters of the workflow on the **wiki page (not yet)**
4. Run
5. Note that the macro will generate a new results table (CSV), but the ROI files (ZIP) will be aur¡tomatically replaced. The stitched images, both brightfield and probability maps, will not be modified.

## Contributors

[Pau Carrillo-Barberà](https://github.com/paucabar)

## License

Neurosphere Assay in licensed under [MIT](https://imagej.net/MIT)
