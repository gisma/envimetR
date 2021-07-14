# envimetR 


envimetR is a collection of scripts that support the generation of Envimet model domains and meaningful simple plant types with a focus on typical managed low mountain forests. 

The aim is to derive area-wide input data for a reproducible and sufficiently realistic model domain from RGB aerial LiDAR or UAV point clouds and satellite data. This includes the following points:

1. area data on land use and vegetation
2. derivation of tree types to generate envimet-compliant simple planttypes
3. export of the necessary vector and plant data base data in EnviMet compliant format.

The following analyses are carried out:
* ML based classification of the RGB aerial data to determine the tree types.
* Segementation of the trees based on the Lidar/UAV point clouds.
* Derivation of the LAD classes from the Lidar data.
* Calculation and extraction of the corresponding LAI data on the basis of sentinel data. 
* Calculation of albedo based on sentinel data 
* Typification of typical "tree classes based on all available data to generate hybrid or synthetic tree types for EnviMet modelling.
* Envimet-compliant export of all data
