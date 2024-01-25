#------------------------------------------------------------------------------
# Type: helper script
# Name: 100_calc_2D_envimet_syntrees.R
# Author: Chris Reudenbach, creuden@gmail.com

#
#
# Data:  dataframe as provided by the 80_prepare_enviMet_simple_plants.R script
# Output: cluster number and algorithm as well as the clustered data table
# Copyright: Chris Reudenbach, 2021, GPL (>= 3)
# git clone https://github.com/gisma/envimetR.git
#------------------------------------------------------------------------------

# 0 - load packages
#-----------------------------
library(envimaR)
library(rprojroot)
root_folder = find_rstudio_root_file()

source(file.path(root_folder, "src/functions/000_setup.R"))
seed=123
set.seed(seed)


###--------- Estimation of the optimal methods and cluster numbers


treeclust=readRDS(file.path(envrmt$path_sapflow,"sapflow_tree_cluster.rds"))




# library(XML)
#
# # Create function to generate an XML file
# createXML <- function(x){
#   # Get data from current column being processed
#   holding_date <- x[1]
#   holding_lineamount_value <- x[2]
#
#   # Create main node
#   xmlfile <- newXMLNode("MainXML")
#
#   # Add nodes to main node
#   xmlfile <- addChildren(xmlfile, newXMLNode("Date", holding_date))
#   xmlfile <- addChildren(xmlfile, newXMLNode("LineAmountTypes", "Inclusive"))
#   xmlfile <- addChildren(xmlfile, newXMLNode("Description", "total daily income"))
#   xmlfile <- addChildren(xmlfile, newXMLNode("LineAmount", holding_lineamount_value))
#   xmlfile <- addChildren(xmlfile, newXMLNode("LineItem"))
#   xmlfile <- addChildren(xmlfile, newXMLNode("LineItems"))
#
#   # Create BankAccount node
#   ba <- newXMLNode("BankAccount")
#
#   # Add Code node to BankAccount node
#   ba <- addChildren(ba, newXMLNode("Code","value"))
#
#   # Add BankAccount node to main node
#   xmlfile <- addChildren(xmlfile, ba)
#
#   # Return the xml file
#   return(xmlfile)
# }
#
# # Create dataframe
# df <- data.frame(Date = c("20/06/2017", "22/06/2017","23/06/2017"),
#                  Income = c(2000,3023,4021),
#                  stringsAsFactors = FALSE)
#
# # Transpose dataframe to be processed with lapply
# tdf <- as.data.frame(t(df))
#
# # Create a list of XML files for each column of transposed dataframe
# xml.list <- lapply(tdf, createXML)

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
