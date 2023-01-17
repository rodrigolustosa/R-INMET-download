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

# directory and file names
dir_data <- "banco_de_dados"
dir_data_input <- "raw"
dir_data_output <- "raw"

# data information


# functions ---------------------------------------------------------------

# Name         : Return Urls from INMET to download
# Description  : Receive years as input and return zip files urls to download
# Written by   : Rodrigo Lustosa
# Writing date : 17 Jan 2023 16:50 (GMT -03)
return_urls_inmet_download <- function(years) {
  url_prefix <- "https://portal.inmet.gov.br/uploads/dadoshistoricos/"
  url_posfix <- ".zip"
  str_c(url_prefix,years,url_posfix)
}


# download data -----------------------------------------------------------

return_urls_inmet_download(2020:2025)


