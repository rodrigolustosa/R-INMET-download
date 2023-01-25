# ---------------------------------------------------------------------------- #
# Name         : R INMET Download (1)
# Description  : Download meteorological data from the Instituto Nacional de 
# Meteorologia (IMNET) using the url https://portal.inmet.gov.br/dadoshistoricos
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
dir_data_input  <- "database/aux/zip_files_yearly_and_allstations"
dir_data_output <- "database/output"
dir_data_temp   <- "database/temp"
file_output <- "01_inmet.csv"

# data information
date_start <- ymd_hm("2018-01-01 00:00")
date_end   <- ymd_hm("2022-01-01 00:00")

# code stations to be used. If empty, all stations will be selected
# for more IDs, check: https://mapas.inmet.gov.br/
stations_id <- c("A701","A755","A771")


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
  if (!file.exists(dir_data_input))
    dir.create(dir_data_input)
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

# years to download
year_start <- year(date_start)
year_end   <- year(date_end)
all_years  <- year_start:year_end


# download data -----------------------------------------------------------

download_inmet_files(all_years,dir_data_input)


# read files --------------------------------------------------------------

n_years <- length(all_years)
dados   <- vector("list",n_years) 
for(k in 1:n_years){
  # select year
  y <- all_years[k]
  # zip file path
  path <- file.path(dir_data_input, str_c(y,".zip"))
  # extract all file and directory names inside zip
  allzipfiles <- unzip(path, list=TRUE)
  # separate file and directory names
  if(allzipfiles$Length[1] == 0){
    # case where data is inside a directory (length zero and first of the list)
    zipfolder             <- allzipfiles$Name[1]
    filenames_with_zipdir <- allzipfiles$Name[-1]
    filenames             <- str_remove(filenames_with_zipdir,zipfolder)
  }else{
    # case where data is not inside a directory
    zipfolder <- ""
    filenames_with_zipdir <- allzipfiles$Name
    filenames             <- allzipfiles$Name
  }
  
  # extract station ids for each file
  codigos <- str_match(filenames,
                       "[a-zA-Z]+_[A-Z]{1,2}_[A-Z]{1,2}_([a-zA-Z\\d]{4,6})_.*")
  codigos <- codigos[,2]
  
  n_files <- length(filenames)
  dados[[k]] <- vector("list",n_files)
  # only stations that are required
  if(is.null(stations_id))
    fs <- 1:n_files else # all stations were required (implicit by empty ids)
      fs <- which(codigos %in% stations_id) # required stations were given
  
  for (f in fs){
    # unzip file f in temporary directory
    file_unziped <- unzip(path,filenames_with_zipdir[f],
                          exdir = dir_data_temp,junkpaths = T)
    
    # read first lines, with basic info
    con <- file(file_unziped,encoding = "ISO-8859-15") 
    first_lines <- readLines(con,9)
    close(con)
    # read data
    dados[[k]][[f]] <- read.csv2(file_unziped, skip = 9, na.strings = "-9999",
                                 header = F, fileEncoding = "ISO-8859-15") 
    # delete unzipped file
    file.remove(file_unziped)
    
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
    # correct cases where files were already incorrect
    names(basic_info)[which(names(basic_info) == "regio")]  <- "regiao"
    names(basic_info)[which(names(basic_info) == "estaco")] <- "estacao"
    names(basic_info)[which(names(basic_info) == "data_de_fundaco")] <- 
      "data_de_fundacao"
    
    # tidy header
    csv_header <- str_split(csv_header,";")[[1]]
    csv_header <- rm.complex.format(csv_header)
    # change hour column name to be equal for all files
    csv_header[which(csv_header == "hora_utc")]  <- "hora"
    
    # insert header
    names(dados[[k]][[f]]) <- csv_header
    
    # tidy and filter data
    dados[[k]][[f]] <- dados[[k]][[f]] %>% 
      select(- "") %>% # remove empty column
      mutate(data = ymd_hm(paste(data, hora)),.keep="unused") %>% # merge date and hours
      mutate(codigo = basic_info$codigo, .before = 1) %>% 
      filter(data >= date_start & data <= date_end)
    
  }
  # merge dataframes from year y
  dados[[k]] <- bind_rows(dados[[k]])
}

# merge all dataframes
dados <- bind_rows(dados)

# create folder if it does not exist
if (!file.exists(dir_data_output))
  dir.create(dir_data_output)
# free up unused memory
gc()
# write data
path <- file.path(dir_data_output, file_output)
write_csv(dados,path,na = "")
