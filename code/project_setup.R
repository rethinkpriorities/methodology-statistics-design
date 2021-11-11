#### Script for sourcing basic options and functions ####

# No package loading, use renv instead!!

library(here)

here <- here::here

source(here("code", "baseoptions.R")) # Basic options used across files and shortcut functions, e.g., 'pp()' for print

source(here("code", "functions.R")) # functions grabbed from web and created by us for analysis/output
