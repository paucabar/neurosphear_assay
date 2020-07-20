run("Trainable Weka Segmentation");
wait(3000);
//selectWindow("Trainable Weka Segmentation v3.2.34");
call("trainableSegmentation.Weka_Segmentation.loadClassifier", "C:\\Users\\Pau\\Desktop\\weka test\\classifier.model");
call("trainableSegmentation.Weka_Segmentation.applyClassifier", "C:\\Users\\Pau\\Desktop\\weka test", "blobs.tif", "showResults=true", "storeResults=false", "probabilityMaps=true", "");
