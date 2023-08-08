# ---------------------------------------------------------------------------- #
# Name         : R INMET Download (2)
# Description  : Download meteorological data from the Instituto Nacional de 
# Meteorologia (IMNET) using the url https://mapas.inmet.gov.br/#
# Example URL  : https://tempo.inmet.gov.br/tabela/mapa/A701/2022-01-01
# Written by   : Rodrigo Lustosa
# Writing date : 19 Jan 2023 17:23 (GMT -03)
# ---------------------------------------------------------------------------- #

# initialization ----------------------------------------------------------

# packages
library(tidyverse)
library(stringr)
library(stringi)
library(lubridate)
library(RSelenium)

# directory and file names
dir_data_input  <- "database/aux/csv_files_by_station_and_period"
dir_data_output <- "database/output"
dir_data_temp   <- "database/temp"
file_output <- "02_inmet.csv"

# date and hour information
date_hour_start <- ymd_hm("2018-01-01 00:00")
date_hour_end   <- ymd_hm("2022-01-01 00:00")

# code stations to be used
# for more IDs, check: https://mapas.inmet.gov.br/
station_ids <- c("A701","A755","A771","V0500")


# functions ---------------------------------------------------------------

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
wait_inmet_page_to_load <- function(remote_driver, maxtime = 120){
  el_test <- list()
  el_test <- remote_driver$findElements(using = "css", "[type = 'date']")
  start <- Sys.time()
  now <- Sys.time()
  while(is_empty(el_test) & now - start < maxtime){
    Sys.sleep(1)
    el_test <- remote_driver$findElements(using = "css", "[type = 'date']")
    now <- Sys.time()
  }
  return(now - start < maxtime)
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
# Description  : Stop and remove docker named as rselenium_inmet
# Written by   : Rodrigo Lustosa
# Writing date : 25 Jan 2023 14:37 (GMT -03)
close_docker <- function(docker_id) {
  # close docker
  # sudo docker stop $(sudo docker ps -q)
  system("sudo -S docker stop rselenium_inmet; sudo -S docker rm rselenium_inmet",
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

# Name         : Make file name
# Description  : Use station id, data date start and date end to make a file
# name
# Written by   : Rodrigo Lustosa
# Writing date : 26 Jan 2023 10:37 (GMT -03)
make_file_name <- function(id,date_start,date_end){
  # file name for station and period
  file_name <- str_c(id,"_",                              # station code
                     "s",format(date_start,"%Y%m%d"),"_", # date start
                     "e",format(date_end,"%Y%m%d"),       # date end
                     ".csv")                              # file extension
}

# Name         : Wait file to download
# Description  : Follow size file changes until it stop changing
# Written by   : Rodrigo Lustosa
# Writing date : 26 Jan 2023 11:53 (GMT -03)
wait_file_to_download <- function(path, time = 0.1){
  past_size <- file.size(path)
  Sys.sleep(time)
  size <- file.size(path)
  while(size != past_size | size == 0){
    past_size <- size
    Sys.sleep(time)
    size <- file.size(path)
  }
}

# Name         : Download INMET files (2)
# Description  : download raw INMET files by station, save them at dir_path and
# return file paths. 
# Written by   : Rodrigo Lustosa
# Writing date : 25 Jan 2023
download_inmet_files_2 <- function(station_ids,date_start,date_end,dir_download,
                                   silent = FALSE){
  
  # dates information
  periods <- divide_date_period(date_start,date_end)
  dates_start <- periods$dates_start
  dates_end   <- periods$dates_end
  n_periods   <- periods$n_periods
  n_ids       <- length(station_ids)
  
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
  # remDr$getStatus()
  
  for(id in 1:n_ids){
    navigate_done <- FALSE
    
    # start progress bar
    if(!silent){
      cat(str_c("\nDownloading ",station_ids[id],":\n"))
      pb = txtProgressBar(min = 0, max = n_periods, initial = 0, style = 3) 
    }
    
    # remDr$screenshot(display = TRUE)
    for(i in 1:n_periods){
      # file name for station and period
      file_name     <- make_file_name(station_ids[id],dates_start[i],dates_end[i])
      file_path     <- file.path(dir_data_input,file_name)
      raw_file_path <- file.path(dir_data_input,"tabela.csv") # path of download
      
      # download file
      if(!file.exists(file_path)){
        # open URL
        while(!navigate_done){
          remDr$open(silent = T)
          link <- str_c("https://tempo.inmet.gov.br/tabela/mapa/", 
                        station_ids[id], "/", date_end)
          remDr$navigate(link)
          navigate_done <- wait_inmet_page_to_load(remDr)
        }
        
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
        
        wait_inmet_page_to_load(remDr, maxtime = Inf)
        
        # remDr$screenshot(display = TRUE)
        
        # find button to download new generated table and click on it
        el_bCSV <- remDr$findElement(using = "tag name", "a")
        el_bCSV$clickElement()
        # el_bCSV$getElementText()  # "Baixar CSV"
        
        wait_file_to_download(raw_file_path)
        
        # files are downloaded with 'tabela.csv' as a name
        file.rename(raw_file_path,file_path)
      }
      
      # update progress bar
      if(!silent)
        setTxtProgressBar(pb,i)
      
    }
    # close progress bar
    if(!silent)
      close(pb)
    
    # close remote driver if it was opened
    if(navigate_done)
      remDr$close()
  }
  
}

# Name         : Read and tidy up INMET files (2)
# Description  : Read raw INMET files by station, merge and tidy up
# Written by   : Rodrigo Lustosa
# Writing date : 26 Jan 2023 13:31 (GMT -03)
read_n_tidy_inmet_files_2 <- function(station_ids,date_hour_start,date_hour_end,
                                      dir_read){
  # dates information
  date_start <- date(date_hour_start)
  date_end   <- date(date_hour_end)
  periods <- divide_date_period(date_start,date_end)
  dates_start <- periods$dates_start
  dates_end   <- periods$dates_end
  n_periods   <- periods$n_periods
  n_ids       <- length(station_ids)
  
  dados <- vector("list",n_ids)
  for(j in 1:n_ids){
    id <- station_ids[j]
    dados[[j]] <- vector("list",n_periods)
    for(i in 1:n_periods){
      # file name for station and period
      file_name     <- make_file_name(id,dates_start[i],dates_end[i])
      file_path     <- file.path(dir_read,file_name)
      # read file
      if(file.exists(file_path)){
        suppressMessages({
          dados[[j]][[i]] <- read_csv2(file_path)
        })
        # tidy header
        names(dados[[j]][[i]]) <- rm.complex.format(names(dados[[j]][[i]]))
        # tidy and filter data
        dados[[j]][[i]] <- dados[[j]][[i]] %>% 
          mutate(data = dmy_hm(paste(data, hora)),.keep="unused") %>% # merge date and hours
          mutate(codigo = id, .before = 1) %>% 
          filter(data >= date_hour_start & data <= date_hour_end)
      }
    }
    # merge dataframes from year y
    dados[[j]] <- bind_rows(dados[[j]])
  }
  # merge all dataframes
  dados <- bind_rows(dados)
  
  return(dados)
}


# data information --------------------------------------------------------

# dates to download
date_start <- date(date_hour_start)
date_end   <- date(date_hour_end)


# download files ----------------------------------------------------------

# start docker
open_docker(dir_data_input)

# download
download_inmet_files_2(station_ids,date_start,date_end,dir_data_input)

# stop and remove docker
close_docker()


# read files --------------------------------------------------------------

dados <- read_n_tidy_inmet_files_2(station_ids,date_hour_start,date_hour_end,
                                   dir_data_input)


# write final file --------------------------------------------------------

# create folder if it does not exist
if (!file.exists(dir_data_output))
  dir.create(dir_data_output)
# free up unused memory
gc()
# write data
path <- file.path(dir_data_output, file_output)
write_csv(dados,path,na = "")

