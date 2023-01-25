# ---------------------------------------------------------------------------- #
# Name         : R INMET Download (2)
# Description  : Download meteorological data from the Instituto Nacional de 
# Meteorologia (IMNET) using the url https://mapas.inmet.gov.br/#
# Written by   : Rodrigo Lustosa
# Writing date : 19 Jan 2023 17:23 (GMT -03)
# ---------------------------------------------------------------------------- #

# initialization ----------------------------------------------------------

# packages
library(tidyverse)
library(RSelenium)
library(stringr)
library(lubridate)

# directory and file names
dir_data_input  <- "database/aux/csv_files_by_station_and_period"
dir_data_output <- "database/output"
dir_data_temp   <- "database/temp"
file_output <- "02_inmet.csv"

# date and hour information
date_hour_start <- ymd_hm("2018-01-01 00:00")
date_hour_end   <- ymd_hm("2022-01-01 00:00")


# functions ---------------------------------------------------------------

# Name         : Is Path Absolute
# Description  : Check if a path is absolute or relative (checked for Linux)
# Written by   : Rodrigo Lustosa
# Writing date : 25 Jan 2023 12:43 (GMT -03)
is.path.abs <- function(path){
  if (Sys.info()['sysname'] == "Linux"){
    # for Linux
    first_string <- substr(path,1,1)
    if (first_string == "/" | first_string == "~")
      return(TRUE)
  } else {
    # for Windows
    return(stringr::str_detect(path,":/"))
  }
  return(FALSE)
}

# Name         : Wait INMET page to load
# Description  : Search for date boxes to know if page is loaded or not
# Written by   : Rodrigo Lustosa
# Writing date : 25 Jan 2023 12:57 (GMT -03)
wait_inmet_page_to_load <- function(remote_driver){
  el_test <- list()
  el_test <- remote_driver$findElements(using = "css", "[type = 'date']")
  while(is_empty(el_test)){
    Sys.sleep(1)
    el_test <- remote_driver$findElements(using = "css", "[type = 'date']")
  }
}

# Name         : Open Docker
# Description  : Open a docker with Selenium 2.53.1, firefox as browser, a 
# connection with dir_path, and with name rselenium_inmet
# Written by   : Rodrigo Lustosa
# Writing date : 25 Jan 2023 14:31 (GMT -03)
open_docker <- function(dir_path) {
  # alternative in the terminal (replace DIR_DATA_INPUT, must be absolute path):
  # sudo docker run -d -p 4445:4444 -v DIR_DATA_INPUT:/home/seluser/Downloads:rw -d selenium/standalone-firefox:2.53.1
  
  # create folder if it does not exist
  if (!file.exists(dir_path))
    dir.create(dir_path)
  
  # force path to be absolute
  dir_path <- ifelse(is.path.abs(dir_path),dir_path,file.path(getwd(),dir_path))
  
  # terminal command
  cmd <- str_c("sudo -kS docker run --name rselenium_inmet -d -p 4445:4444 -v ",
               dir_path, # path of connection in the host with docker
               ":/home/seluser/Downloads:rw -d selenium/standalone-firefox:2.53.1")
  
  # start docker
  docker_id <- system(cmd, intern = TRUE,
                      input=rstudioapi::askForPassword("Enter your password: "))
  
  # time for the docker to settle down
  Sys.sleep(1)
  
  # return(docker_id)
}

# Name         : Close docker
# Description  : Close docker named as rselenium_inmet
# Written by   : Rodrigo Lustosa
# Writing date : 25 Jan 2023 14:37 (GMT -03)
close_docker <- function(docker_id) {
  # close docker
  # sudo docker stop $(sudo docker ps -q)
  system("sudo -kS docker stop rselenium_inmet",
         input=rstudioapi::askForPassword("Enter your password: "))
}

# Name         : Divide date period
# Description  : Divide date period in smaller ones of one year or less
# Written by   : Rodrigo Lustosa
# Writing date : 25 Jan 2023 16:38 (GMT -03)
divide_date_period <- function(date_start, date_end, largest_period = 366){
  if(date_end - date_start <= largest_period){
    return(list(dates_end = date_end, dates_start = date_start))
  } else {
    # dates information
    year_start <- year(date_start)
    year_end   <- year(date_end)
    years <- year_start:year_end
    n <- length(years)
    # divide in periods of one year
    dates_start <- ymd(str_c(years,"-01-01"))
    dates_end   <- ymd(str_c(years,"-12-31"))
    # first and last date are the given
    dates_start[1] <- date_start
    dates_end[n]   <- date_end
    return(list(dates_start=dates_start,dates_end=dates_end,n_periods=n))
  }
}

# Name         : Download INMET files (2)
# Description  : download raw INMET files by station and save them at dir_path
# Written by   : Rodrigo Lustosa
# Writing date : 25 Jan 2023
download_inmet_files_2 <- function(date_start,date_end,dir_download){
  
  # dates information
  periods <- divide_date_period(date_start,date_end)
  dates_start <- periods$dates_start
  dates_end   <- periods$dates_end
  n_periods   <- periods$n_periods
           
  # set docker download information
  fprof <- makeFirefoxProfile(
    list(browser.download.dir = "/home/seluser/Downloads",
         browser.download.folderList = 2L,
         browser.download.manager.showWhenStarting = FALSE,
         browser.helperApps.neverAsk.saveToDisk = "text/csv"))

  # start remote Driver
  remDr <- remoteDriver(
    remoteServerAddr = "localhost",
    port = 4445L,
    browserName = "firefox",
    extraCapabilities = fprof
  )
  remDr$open(silent = T)
  # remDr$getStatus()
  
  # open URL
  remDr$navigate("https://tempo.inmet.gov.br/tabela/mapa/V0500/2023-01-01")
  wait_inmet_page_to_load(remDr)
  
  # remDr$screenshot(display = TRUE)
  
  for(i in 1:n_periods){
    # file name for station and period
    file_name <- str_c("V0500_",                                # station code
                       "s",format(dates_start[i],"%Y%m%d"),"_", # date start
                       "e",format(dates_end[i],"%Y%m%d"),       # date end
                       ".csv")                                  # file extension
    file_path     <- file.path(dir_data_input,file_name)
    raw_file_path <- file.path(dir_data_input,"tabela.csv") # path of download
    # download file
    if(!file.exists(file_path)){
      # delete possible trash file
      if(file.exists(raw_file_path))
        file.remove(raw_file_path)
      
      # find date boxes (start and end)
      el_datas <- remDr$findElements(using = "css", "[type = 'date']")
      
      # list of backspace keys equal to number of characters in a date string
      erase_date_keys        <- as.list(rep("backspace",10))
      names(erase_date_keys) <- rep("key",10)
      # erase filled date values and fill with new dates 
      el_datas[[1]]$sendKeysToElement(append(erase_date_keys,list(dates_start[i])))
      el_datas[[2]]$sendKeysToElement(append(erase_date_keys,list(dates_end[i])))
      
      # remDr$screenshot(display = TRUE)
      
      # find button to generate new table and click on it
      el_gtabela <- remDr$findElement(using = "tag name", "button")
      el_gtabela$clickElement()
      # el_gtabela$getElementText()  # "Gerar Tabela"
      
      wait_inmet_page_to_load(remDr)
      
      # remDr$screenshot(display = TRUE)
      
      # find button to download new generated table and click on it
      el_bCSV <- remDr$findElement(using = "tag name", "a")
      el_bCSV$clickElement()
      # el_bCSV$getElementText()  # "Baixar CSV"
      
      # files are downloaded with 'tabela.csv' as a name
      file.rename(raw_file_path,file_path)
    }
  }
  
  # close remote driver
  remDr$close()
}


# data information --------------------------------------------------------

# dates to download
date_start <- date(date_hour_start)
date_end   <- date(date_hour_end)


# download files ----------------------------------------------------------

# start docker
open_docker(dir_data_input)

download_inmet_files_2(date_start,date_end,dir_data_input)

close_docker()

