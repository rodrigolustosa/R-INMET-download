# ---------------------------------------------------------------------------- #
# Name         : INMET Download (2)
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

# directory and file names

# start docker
# sudo docker run -d -p 4445:4444 -v /WORKING/DIRECTORY:/home/seluser/Downloads:rw -d selenium/standalone-firefox:2.53.1
cmd <- str_c("sudo -kS docker run -d -p 4445:4444 -v ", getwd(),
             ":/home/seluser/Downloads:rw -d selenium/standalone-firefox:2.53.1")
docker_id <- system(cmd, intern = TRUE,
                    input=rstudioapi::askForPassword("Enter your password: "))

# set docker download information
fprof <- makeFirefoxProfile(
  list(browser.download.dir = "/home/seluser/Downloads",
       browser.download.folderList = 2L,
       browser.download.manager.showWhenStarting = FALSE,
       browser.helperApps.neverAsk.saveToDisk = "multipart/x-zip,application/zip,application/x-zip-compressed,application/x-compressed,application/msword,application/csv,text/csv,image/png ,image/jpeg, application/pdf, text/html,text/plain,  application/excel, application/vnd.ms-excel, application/x-excel, application/x-msexcel, application/octet-stream"))

# start remote Driver
remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4445L,
  browserName = "firefox",
  extraCapabilities = fprof
)
remDr$open()
remDr$getStatus()

# open URL
remDr$navigate("https://tempo.inmet.gov.br/tabela/mapa/V0500/2023-01-01")
# remDr$refresh()

remDr$screenshot(display = TRUE)

# find date boxes (start and end)
el_datas <- remDr$findElements(using = "css", "[type = 'date']")
# list of backspace keys equal to number of characters in a date string
erase_date_keys        <- as.list(rep("backspace",10))
names(erase_date_keys) <- rep("key",10)
# erase past date values and fill new dates 
el_datas[[1]]$sendKeysToElement(append(erase_date_keys, list("2022-01-01")))
el_datas[[2]]$sendKeysToElement(append(erase_date_keys, list("2022-12-31")))

remDr$screenshot(display = TRUE)

# find button to generate new table and click on it
el_gtabela <- remDr$findElement(using = "tag name", "button")
el_gtabela$clickElement()
# el_gtabela$getElementText()  # "Gerar Tabela"

remDr$screenshot(display = TRUE)

# find button to download new generated table and click on it
el_bCSV <- remDr$findElement(using = "tag name", "a")
el_bCSV$clickElement()
# el_bCSV$getElementText()  # "Baixar CSV"

remDr$refresh()

# close remote driver
remDr$close()

# close docker
# sudo docker stop $(sudo docker ps -q)
system(paste("sudo -kS docker stop", substr(docker_id,0,12)), intern = TRUE,
       input=rstudioapi::askForPassword("Enter your password: "))

