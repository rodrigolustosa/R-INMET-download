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

# directory and file names


