# R-INMET-download
[![en](https://img.shields.io/badge/lang-en-red)](https://github.com/rodrigolustosa/R-INMET-download/blob/main/README-en.md)
[![pt-br](https://img.shields.io/badge/lang-pt--br-blue)](https://github.com/rodrigolustosa/R-INMET-download/blob/main/README.md)

Download meteorological data from the Instituto Nacional de Meteorologia (INMET) in R language.

## General description

This repository can download INMET data by two different ways (with script [`inmet_download_1.R`](https://github.com/rodrigolustosa/R-INMET-download/blob/main/inmet_download_1.R) and [`inmet_download_2.R`](https://github.com/rodrigolustosa/R-INMET-download/blob/main/inmet_download_2.R)) using the [INMET portal](https://portal.inmet.gov.br/). Overall `inmet_download_1.R` is **easier to use** but can't access some data and might download a lot of data that you don't want and `inmet_download_2.R` can **access more data** but won't work in Windows without some tweaks and the download velocity is lower. Bellow is summary of the main conditions.

|    |  script 1 |  script 2 |
|----------|:------:|:------:|
| **Operational System**                  | Linux and Windows :heavy_check_mark:            | Linux |
| **Stations available**                  | Only INMET automatic stations | INMET automatic and conventional and other Organizations (all available at https://mapas.inmet.gov.br/) :heavy_check_mark: |
| **Setup**                  | Just R packages :heavy_check_mark:            | R packages and Docker |
| **time for data to be available**       | Can take several days         | Usually on the same day :heavy_check_mark:|
| **Smaller chunks possible to download** (Note: In both you'll have a single file at the end)  | All INMET automatic stations by year inside a ZIP file (~100 MB by file) | CSV file for each station and each day (~3.7 KB) :heavy_check_mark: |
| **Download velocity**                   | Fast :heavy_check_mark:                         | Medium |

Overall `inmet_download_1.R` is recommended just for Windows users or if you will download a lot of stations and years or if you don't want to bother with Docker. 

## How to setup and use

Install R and RStudio. You can install the packages used here by running the following into your R console:
```
install.packages("tidyverse")
install.packages("stringr")
install.packages("stringi")
install.packages("lubridate")
install.packages("RCurl")     # only for script 1
install.packages("RSelenium") # only for script 2
```
If you are using Linux, it is necessary to install some dependencies before trying to install packages (as shown [here](https://blog.zenggyu.com/en/post/2018-01-29/installing-r-r-packages-e-g-tidyverse-and-rstudio-on-ubuntu-linux/)).

Download the repository last version [here](https://github.com/rodrigolustosa/R-INMET-download/releases) (`Assets` -> `Source Code (zip)`) and unzip it.


### Script 1

Open `inmet_download_1.R`, fill the date and hour of start and end you want and the station IDs (you can search more stations using the INMET portal) then run the script. Your files will be downloaded inside your working directory. 

### Script 2

Before running `inmet_download_2.R`, it is necessary to install docker. Follow the instructions given at [docker's website](https://docs.docker.com/engine/install/ubuntu/). Then you can run `inmet_download_2.R`. There are two functions that interact with the Linux Terminal, `open_docker` and `close_docker`. They're running in the terminal, respectively:
```
sudo docker run --name rselenium_inmet -d -p 4445:4444 -v dir_path:/home/seluser/Downloads:rw -d selenium/standalone-firefox:2.53.1
```
to start a docker (where `dir_path` should be replaced by the absolute path your data will be downloaded) and
```
sudo docker stop rselenium_inmet; sudo docker rm rselenium_inmet
```
to stop and remove the docker. If any problem occurs to those functions in R, you can run those commands in your terminal in place of the R functions. As with Script 1, fill the date and hour of start and end you want and the station IDs (you can search more stations using the INMET portal) then run the script. Your files will be downloaded inside your working directory. 

[![version](https://img.shields.io/badge/version-0.3.0-green)](https://github.com/rodrigolustosa/R-INMET-download/releases/tag/v0.3.0)

