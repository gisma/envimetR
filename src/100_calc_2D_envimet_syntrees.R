#------------------------------------------------------------------------------
# Type: helper script
# Name: 100_calc_2D_envimet_syntrees.R
# Author: Chris Reudenbach, creuden@gmail.com

# Data: sf file as provided by the 90_tree_cluster_analysis.R script
# Output: PLANT List for envimet
# Copyright: Chris Reudenbach, 2024 GPL (>= 3)
# git clone https://github.com/gisma/envimetR.git
#------------------------------------------------------------------------------

# 0 - load packages
#-----------------------------
library(envimaR)
library(rprojroot)
library(XML)
root_folder = find_rstudio_root_file()

source(file.path(root_folder, "src/functions/000_setup.R"))
seed=123
set.seed(seed)


###--------- load data


treeclust=readRDS(file.path(envrmt$path_sapflow,"sapflow_tree_all_cluster_sf.rds"))




#
#
# # Create function to generate an XML file
# move this function later to the function folder

createXML <- function(x){
  # Get data from current column being processed
  LAD <- x[1]
  RAD <- x[2]
  SEASON <- x[3]
  DEPTH <- x[4]
  HEIGHT <- x[5]
  ALBEDO  <- x[6]
  ID  <- x[7]
#   # Create main node
xmlfile <- newXMLNode("PLANT")
#   # Add nodes to main node
xmlfile <- addChildren(xmlfile, newXMLNode("ID",ID))
xmlfile <- addChildren(xmlfile, newXMLNode("Description", "Synthetic LiDARTree"))
xmlfile <- addChildren(xmlfile, newXMLNode("AlternativeName", "(None)"))
xmlfile <- addChildren(xmlfile, newXMLNode("Planttype", "0"))
xmlfile <- addChildren(xmlfile, newXMLNode("Leaftype", "1"))
xmlfile <- addChildren(xmlfile, newXMLNode("Albedo",ALBEDO))
xmlfile <- addChildren(xmlfile, newXMLNode("Transmittance","0.30000"))
xmlfile <- addChildren(xmlfile, newXMLNode("rs_min","400.00000"))
xmlfile <- addChildren(xmlfile, newXMLNode("Height",HEIGHT))
xmlfile <- addChildren(xmlfile, newXMLNode("Depth", DEPTH))
xmlfile <- addChildren(xmlfile, newXMLNode("LAD-Profile",LAD ))
xmlfile <- addChildren(xmlfile, newXMLNode("RAD-Profile", RAD))
xmlfile <- addChildren(xmlfile, newXMLNode("Season-Profile", SEASON))
xmlfile <- addChildren(xmlfile, newXMLNode("Group", "- Legacy | SynTrees"))
xmlfile <- addChildren(xmlfile, newXMLNode("color", "55000"))

#
#   # Return the xml file
  return(xmlfile)
 }
#
# # Create dataframe
# Content should be derived from the statistics of the clustered tree segmentation file

 df <- data.frame(  LAD <- c(" 0.15000,0.15000,0.15000,0.15000,0.65000,2.15000,2.18000,2.05000,1.72000,0.00000 " ),
                    RAD <- c(" 0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.00000 "),
                    SEASON <- c(" 1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000 "),
                    DEPTH <- c(" 2.00000 ") ,
                    HEIGHT <- c(" 20.00000 "),
                    ALBEDO  <-c(" 0.200000 "),
                    ID  <- c(" 0000A1 "),
                  stringsAsFactors = FALSE)

# # Transpose dataframe to be processed with lapply
 tdf <- as.data.frame(t(df))
#
# # Create a list of XML entris for each column of transposed dataframe
 xml.list <- lapply(tdf, createXML)


 # $V1
 # <PLANT>
 #   <ID> 0000A1 </ID>
 #   <Description>Synthetic LiDARTree</Description>
 #   <AlternativeName>(None)</AlternativeName>
 #   <Planttype>0</Planttype>
 #   <Leaftype>1</Leaftype>
 #   <Albedo> 0.200000 </Albedo>
 #   <Transmittance>0.30000</Transmittance>
 #   <rs_min>400.00000</rs_min>
 #   <Height> 20.00000 </Height>
 #   <Depth> 2.00000 </Depth>
 #   <LAD-Profile> 0.15000,0.15000,0.15000,0.15000,0.65000,2.15000,2.18000,2.05000,1.72000,0.00000 </LAD-Profile>
 #   <RAD-Profile> 0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.00000 </RAD-Profile>
 #   <Season-Profile> 1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000 </Season-Profile>
 #   <Group>- Legacy | SynTrees</Group>
 #   <color>55000</color>
 #   </PLANT>

 ## ORIGINAL
# <Header>
#   <filetype>DATA</filetype>
#   <version>1</version>
#   <revisiondat>5/19/2021 6:10:47 PM</revisiondate>
#   <remark>Envi-Data</remark>
#   <checksum>3340896</checksum>
#   <encryptionlevel>1</encryptionlevel>
#   </Header>
#   <SOIL>
# <PLANT>
#   <ID> 0001cl </ID>
#   <Description> cluster tree type 01 </Description>
#   <AlternativeName> (None) </AlternativeName>
#   <Planttype> 0 </Planttype>
#   <Leaftype> 1 </Leaftype>
#   <Albedo> 0.20000 </Albedo>
#   <Transmittance> 0.30000 </Transmittance>
#   <rs_min> 400.00000 </rs_min>
#   <Height> 20.00000 </Height>
#   <Depth> 2.00000 </Depth>
#   <LAD-Profile> 0.15000,0.15000,0.15000,0.15000,0.65000,2.15000,2.18000,2.05000,1.72000,0.00000 </LAD-Profile>
#   <RAD-Profile> 0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.10000,0.00000 </RAD-Profile>
#   <Season-Profile> 1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000,1.00000 </Season-Profile>
#   <Group> - Legacy | Hedges and others </Group>
#   <Color> 56576 </Color>
#   </PLANT>
