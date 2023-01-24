# ---------------------------------------------------------------------------- #
# Name         : INMET Download (2)
# Description  : Download meteorological data from the Instituto Nacional de 
# Meteorologia (IMNET) using the url https://mapas.inmet.gov.br/#
# Written by   : Rodrigo Lustosa
# Writing date : 19 Jan 2023 17:23 (GMT -03)
# ---------------------------------------------------------------------------- #

# initialization ----------------------------------------------------------

# packages
# library(tidyverse)
library(RSelenium)

# directory and file names


# start docker
# sudo docker run -d -p 4445:4444 selenium/standalone-firefox:4.0.0
docker_id <- system(
  "sudo -kS docker run -d -p 4445:4444 selenium/standalone-firefox:4.0.0",
  input=rstudioapi::askForPassword("Enter your password: "), intern = TRUE
)

# start remote Driver
remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4445L,
  browserName = "firefox"
)
remDr$open()
remDr$getStatus()

# open URL
remDr$navigate("https://mapas.inmet.gov.br/#")
# remDr$refresh()

remDr$screenshot(display = TRUE)

# set Window Size and refresh page
remDr$setWindowSize(800, 800, winHand = "current")
remDr$refresh()

remDr$screenshot(display = TRUE)

# find search icon and click on it
el_lupa <- remDr$findElement(using = "css", "[class = 'icone_submenu fas fa-search']")
el_lupa$clickElement()
# el_lupa$getElementLocation()
# el_lupa$getElementSize()
# remDr$mouseMoveToLocation(webElement = el_lupa)
# remDr$mouseMoveToLocation(x = 78/2,y = 50/2 + 90)
# remDr$click(0)

remDr$screenshot(display = TRUE)

# find search box and write station name (search is done automatically)
el_busca <- remDr$findElement(using = "css", "[id = 'search']")
el_busca$sendKeysToElement(list("[V0500] SUZANO - SETE CRUZES - SP"))

remDr$screenshot(display = TRUE)

# move over the station point and click it
move <- c(800*0.5, (800-85)*0.5) # station point is centered in window
remDr$mouseMoveToLocation(x = move[1], y = move[2])
# remDr$mouseMoveToLocation(x = move[1] - 1, y = move[2])
# remDr$mouseMoveToLocation(x =           1, y = 0)

remDr$screenshot(display = TRUE)

remDr$click(0)

remDr$screenshot(display = TRUE)







# close remote driver
remDr$close()

# remDr$screenshot(display = TRUE)

# close docker
# sudo docker stop $(sudo docker ps -q)
system(paste("sudo -kS docker stop", substr(docker_id,0,12)), intern = TRUE,
       input=rstudioapi::askForPassword("Enter your password: "))

