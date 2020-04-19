# Neurosphere Assay

## Description



## Requirements

* [Fiji](https://fiji.sc/)
* [ilastik](https://www.ilastik.org/)
* _BaSiC_ update site (Fiji)
* _ilastik_ update site (Fiji)
* _Morphology_ update site (Fiji)

How to [follow an update site](https://imagej.net/Following_an_update_site) in Fiji (_see Figure 1_)

## Installation

1. Start Fiji
2. Start the **ImageJ Updater** (<code>Help > Update...</code>)
3. Click on <code>Manage update sites</code>
4. Click on <code>Add update site</code> (_see Figure 1_)
5. A new blank row is to be created at the bottom of the update sites list
6. Type **NeuroMol Lab** in the **Name** column
7. Type **http://sites.imagej.net/Paucabar/** in the **URL** column
8. <code>Close</code> the update sites window
9. <code>Apply changes</code>
10. Restart Fiji
11. Check if <code>NeuroMol Lab</code> appears now in the <code>Plugins</code> dropdown menu (note that it will be placed at the bottom of the dropdown menu)

![Snag_29e5797f](https://user-images.githubusercontent.com/39589980/58595799-27f8a500-8272-11e9-8c32-1c72b591c702.png)

**Figure 1.** _Manage update sites_ window. An update site is a web space used by the _ImageJ Updater_ which enables users to share their macros, scripts and plugins. By adding an update site the macros, scripts and plugins maintained there will be installed and updated just like core ImageJ plugins.

## Test Dataset

Download an example [image dataset](https://drive.google.com/drive/folders/1W_UDxg4mbQ1qNeZo1tPUezNgmZxtMwkv?usp=sharing) and a [provided training](https://drive.google.com/drive/folders/1B0eZLaN3c9mcKkUnkeS5lguu4byKxT2b?usp=sharing) for ilastik pixel classification.

## Usage

### Shading Correction

1. Run the **Shading Correction** macro (<code>Plugins > NeuroMol Lab > Neurosphere Assay > Shading Correction</code>)
2. Select the directory containing the images (.tif files)
3. Select the illumination correction mode. Note that the **prospective** method will ask for an additional folder containing the reference images to apply the correction function. Conversely, the **retrospective multi-image** method dos not require reference images, but it needs a medium-size dataset in order to perform properly (>25-30 wells) 
4. Run
5. Corrected images  images will be saved in a new subfolder within the original directory

### Pixel Classification (ilastik)

1. Start a pixel classification project in ilastik
2. Load some corrected images (.HDF5 files). Try to use images with different features and from several wells
3. Select some features (you can start by selecting all of them)
4. Annotate the images. Note that label 1 must correspond to _background_, label 2 to _neurospheres_ and label 3 to _well edges_
5. Once the classifier performs fine, save the project

Learn more about the ilastik [pixel classification workflow](https://www.ilastik.org/documentation/pixelclassification/pixelclassification)

### Stitching

1. Run the **Stitching** macro (<code>Plugins > NeuroMol Lab > Neurosphere Assay > Stitching</code>)
2. Select the directory containing the images (.tif files)
3. Load the pixel classification project
4. Select the stitching mode. Note that it depends on the image acquisition parameters. Also note that the macro assumes an overlapping of 15 %
5. Adjust some workflow parameters (mean, open, threshold). Know more about the parameters of the workflow on the **wiki page (not yet)**
6. Adjust the parameters. Know more about the parameters of the workflow on the **wiki page (not yet)**
7. Run. Note that the stitching workflow may take several hours, depending on the dataset size
8. A series of new files will be saved within different directories: stitched well (.tif) files, a results table (.csv) file and the ROI (.zip) files of each well

## Contributors

[Pau Carrillo-Barberà](https://github.com/paucabar)

## License
