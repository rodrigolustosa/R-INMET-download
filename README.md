# R-INMET-download

Download meteorological data from the Instituto Nacional de Meteorologia (INMET) in R language.

## General description

This repository can download INMET data by two different ways (with script [`inmet_download_1.R`](https://github.com/rodrigolustosa/R-INMET-download/blob/main/inmet_download_1.R) and [`inmet_download_2.R`](https://github.com/rodrigolustosa/R-INMET-download/blob/main/inmet_download_2.R)). Overall `inmet_download_1.R` is **easier to use** but can't access some data and might download a lot of data that you don't want and `inmet_download_2.R` can **access more data** but won't work in Windows without some tweaks and the download velocity is lower. Bellow is summary of the main conditions.

|    |  script 1 |  script 2 |
|----------|:------:|:------:|
| **Operational System**                  | Linux and Windows             | Linux |
| **Stations available**                  | Only INMET automatic stations | INMET automatic and conventional and other Organizations (all available at https://mapas.inmet.gov.br/) |
| **Setup**                  | Just R packages             | R packages and Docker |
| **time for data to be available**       | Can take several days         | Usually on the same day |
| **Smaller possible downloaded chunks** (Note: In both you'll have a single file at the end)  | All INMET automatic stations by year inside a ZIP file (~100 MB by file) | CSV file for each station and each day (~3.7 KB)  |
| **Download velocity**                   | Fast                          | Medium |

Overall `inmet_download_1.R` is recommended just for Windows users or if you will download a lot of stations and years or if you don't want to bother with dockers.
