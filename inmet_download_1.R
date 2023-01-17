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
library(lubridate)
library(RCurl)

# directory and file names
dir_data <- "banco_de_dados"
dir_data_input <- "raw"
dir_data_output <- "output"

# data information
date_start <- ymd("2019-01-01")
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
# Description  : download raw zip INMET files (by year) and save them at dir_path
# Written by   : Rodrigo Lustosa
# Writing date : 17 Jan 2023 17:18 (GMT -03)
download_inmet_files <- function(years,dir_path) {
  # basic info
  n_files     <- length(years)
  files_names <- str_c(years,".zip")
  urls        <- return_urls_inmet_download(years)
  path <- file.path(dir_path, files_names)
  # download each file
  for (i in 1:n_files) {
    message(str_c("Downloading year ",years[i]))
    # download if url exists and file was not downloaded yet
    if (!file.exists(path[i]))
      if(url.exists(urls[i]))
        download.file(urls[i], destfile = path[i], method="curl")
  }
}


# data information --------------------------------------------------------

# years to download
year_start <- year(date_start)
year_end   <- year(date_end)


# download data -----------------------------------------------------------

dir_input <- file.path(dir_data,dir_data_input)
download_inmet_files(year_start:year_end,dir_input)



