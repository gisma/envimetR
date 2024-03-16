# envimetR 


envimetR is a collection of scripts supporting the generation of Envimet model domains and meaningful simple plant types with a focus on typical managed low mountain forests. 

The aim is to derive area-wide input data for a reproducible and sufficiently realistic model domain from RGB aerial LiDAR or UAV point clouds and satellite data. This includes the following

1. land use and vegetation area data
2. derivation of tree types to generate Envimet compliant simple plant types
3. export of the necessary vector and plant database data in an EnviMet compliant format.

The following analyses are performed:
* ML-based classification of RGB aerial imagery to determine tree types.
* Segmentation of trees based on the Lidar/UAV point clouds.
* Derivation of LAD classes from the lidar data.
* Calculate and extract the corresponding LAI data from the sentinel data. 
* Calculation of albedo from sentinel data 
* Typification using an extended cluster analysis of typical tree classes based on all available data to generate hybrid (or synthetic) tree types for EnviMet modelling purposes.
* Envimet-compliant export of synthetic EnviMEt tree classes 
