#' Setup project environment
#'
#' @description This script configures the project environment.
#'
#' @author [name], [email@com]
#'

# Use this file for general project settings.

# This script is sourced when you run the main control script. Use variable envrmt to access project directories.


require(envimaR)

# Define libraries
libs <- c()

# Load libraries and create environment object to be used in other scripts for path navigation
project_folders <- list.dirs(path = root_folder, full.names = FALSE, recursive = TRUE)
project_folders <- project_folders[!grepl("\\..", project_folders)]
envrmt <- createEnvi(
  root_folder = root_folder, fcts_folder = file.path(root_folder, "src/functions/"),  folders = project_folders,
  libs = libs, create_folders = FALSE)
meta <- createMeta(root_folder)

# Define more variables

# Load more data
