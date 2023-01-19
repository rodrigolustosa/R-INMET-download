# ---------------------------------------------------------------------------- #
# Name         : INMET Download (1)
# Description  : Download meteorological data from the Instituto Nacional de 
# Meteorologia (IMNET) using the url <portal.inmet.gov.br/dadoshistoricos>.
# Written by   : Rodrigo Lustosa
# Writing date : 16 Jan 2023 12:04 (GMT -03)
# Note:        : At this url, data is divided by year. Data from every station
# will be in the same zip file, so all stations will be downloaded.
# ---------------------------------------------------------------------------- #

# initialization ----------------------------------------------------------

# packages
library(tidyverse)
library(stringr)
library(stringi)
library(lubridate)
library(RCurl)

# directory and file names
dir_data <- "banco_de_dados"
dir_data_input  <- "raw"
dir_data_output <- "output"
dir_data_temp   <- "temp"

# data information
date_start <- ymd("2018-01-01")
date_end   <- ymd("2022-01-01")


# functions ---------------------------------------------------------------

# Name         : Return Urls from INMET to download
# Description  : Receive years as input and return zip files urls to download
# Written by   : Rodrigo Lustosa
# Writing date : 17 Jan 2023 16:50 (GMT -03)
return_urls_inmet_download <- function(years) {
  url_prefix <- "https://portal.inmet.gov.br/uploads/dadoshistoricos/"
  url_posfix <- ".zip"
  return(str_c(url_prefix,years,url_posfix))
}

# Name         : Download INMET files
# Description  : download raw zip INMET files by year and save them at dir_path
# Written by   : Rodrigo Lustosa
# Writing date : 17 Jan 2023 17:18 (GMT -03)
download_inmet_files <- function(years,dir_path) {
  # basic info
  n_files     <- length(years)
  files_names <- str_c(years,".zip")
  urls        <- return_urls_inmet_download(years)
  path <- file.path(dir_path, files_names)
  # create folder if it does not exist
  if (!file.exists(dir_input))
    dir.create(dir_input)
  # download each file
  for (i in 1:n_files) {
    message(str_c("Downloading year ",years[i]))
    # download if url exists and file was not downloaded yet
    if (!file.exists(path[i]))
      if(url.exists(urls[i]))
        download.file(urls[i], destfile = path[i], method="curl")
  }
}

# Name         : Remove complex format
# Description  : Remove all symbols that are not proper for a header or 
# something related
# Written by   : Rodrigo Lustosa
# Writing date : 19 Jan 2023 15:43 (GMT -03)
rm.complex.format <- function(string){
  # remove accents and other complex symbols
  new_string <- stri_trans_general(string, "Latin-ASCII")
  # remove characters inside parenthesis
  new_string <- str_remove_all(new_string,"\\(.*\\)")
  # remove spaces after and before string
  new_string <- str_trim(new_string)
  # replace spaces by underline
  new_string <- str_replace_all(new_string," ","_")
  # change upper to lower case
  new_string <- str_to_lower(new_string)
  # remove all other characters that aren't letters, digits or underline
  new_string <- str_remove_all(new_string,"[^a-zA-Z0-9_\\s]")
  # replace repeated underlines by a single underline
  new_string <- str_replace_all(new_string,"_+","_")
  return(new_string)
}


# data information --------------------------------------------------------

# directories
dir_input  <- file.path(dir_data,dir_data_input)
dir_output <- file.path(dir_data,dir_data_output)
dir_temp   <- file.path(dir_data,dir_data_temp)

# years to download
year_start <- year(date_start)
year_end   <- year(date_end)


# download data -----------------------------------------------------------

download_inmet_files(year_start:year_end,dir_input)


# read one file -----------------------------------------------------------

path <- file.path(dir_input, str_c(year_start,".zip"))
allzipfiles <- unzip(path, list=TRUE)
# extract data files names and address inside zip file
if(a$Length[1] == 0){
  zipfolder             <- allzipfiles$Name[1]
  filenames_with_zipdir <- allzipfiles$Name[-1]
  filenames             <- str_remove(filenames_with_zipdir,zipfolder)
}else{
  zipfolder <- ""
  filenames_with_zipdir <- a$Name
  filenames             <- a$Name
}


# unzip one file in temporary directory
file_unziped <- unzip(path,filenames_with_zipdir[1],
                      exdir = dir_temp,junkpaths = T)

# read first lines, with basic info
con <- file(file_unziped,encoding = "ISO-8859-15") 
first_lines <- readLines(con,9)
close(con)

# extract raw station basic info and raw dataframe header
basic_info <- first_lines[-9]
csv_header <- first_lines[ 9]

# tidy basic info
basic_info <- str_split(basic_info,":;")
n_basic_info <- length(basic_info)
for (i in 1:n_basic_info) {
  names(basic_info)[i] <- basic_info[[i]][1]
  basic_info[[i]]      <- basic_info[[i]][2]
}
names(basic_info) <- rm.complex.format(names(basic_info))

# tidy header
csv_header <- str_split(csv_header,";")[[1]]
csv_header <- rm.complex.format(csv_header)

# read data
dados <- read.csv2(file_unziped, header = F, skip = 9, na.strings = "-9999",
                   fileEncoding = "ISO-8859-15") 

# insert header
names(dados) <- csv_header
  
# remove unzipped file
file.remove(file_unziped)

