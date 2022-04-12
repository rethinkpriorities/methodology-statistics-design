#Install and load relevant packages

library(here)
library(pacman)
here <- here::here()
rename_all <- dplyr::rename_all

filter <- dplyr::filter



pacman::p_load(arm, bookdown,  binom, bslib, corrr, data.table, DescTools, digest, downlit, dplyr, forcats, gdata, gganimate, ggthemes, ggpointdensity, ggpubr, ggrepel, ggridges, gtsummary, here, huxtable, infer, purrr, janitor, lmtest, magrittr, labelled, lubridate, plotly, pryr, readr, readstata13, rlang, sandwich, santoku, scales, sjlabelled,  snakecase, tidyverse, treemapify, vtable, install = FALSE) #note -- install = FALSE should be OK if the `renv` environment is present -- unless it was gitignored
#ggstatsplot

#p_load("systemfonts")
#p_load("ggstatsplot")
#p_load("likert")
#p_load_gh("https://github.com/bbolker/broom.mixed")
#p_load("SuppDists")

if (!require("devtools")) { install.packages("devtools", dependencies=TRUE) }

install.packages("remotes")
#remotes::install_github("peterhurford/checkr")
#library(checkr)

#pacman::p_load_gh("peterhurford/checkr", "remotes", install = TRUE)

#remotes::install_github("tidymodels/corrr")
#require(corrr)

devtools::install_github("robertzk/bettertrace")

#install_github("peterhurford/surveytools2")
#install_github("peterhurford/funtools")
#install_github("peterhurford/currencyr")
#library(funtools)
#library(currencyr)

#library(surveytools2)
library(bettertrace)

devtools::install_github("rethinkpriorities/rp-r-package")
library(rethinkpriorities)

devtools::install_github("rethinkpriorities/r-noodling-package")
library(rnoodling)



#Just a bunch of handy shortcuts and precedence of packages
source_url("https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/baseoptions.R")


