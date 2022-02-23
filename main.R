# 'main.R': this single file should (ideally) source and build all data, build codebooks, run all analysis, and build bookdown and other output

#### Setup ####

library(here)
library(pacman)
here <- here::here()
rename_all <- dplyr::rename_all

filter <- dplyr::filter

#... Import setup for this project using template from dr-rstuff  ####

#source(here("code", "packages.R")) # Install and load packages used in build and analysis (note: these could be cleaned)

#WITH RENV this is not needed! 
#... add packages as and when needed; note, the file below has been vastly trimmed down, mainly only loading RP's pacakages
source(here("code", "packages.R"))

#renv::dependencies()

#p_load(devtools)

#Just a bunch of handy shortcuts and precedence of packages 

source_url("https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/baseoptions.R")

#Put these in if and when we need them, 
#source(here("code", "modeling_functions.R")) #TODO - incorporate rest of these into RP r package


### Source model-building tools/functions
#source(here::here("code","modeling_functions.R"))

#Pulling in key files from other repos; don't edit them here
#Just 'pull these in' from the ea-data repo for now; we may re-home them here later

#dir.create(here("remote"))

#THIS fails, probably because its a private repo: try_download("https://raw.githubusercontent.com/rethinkpriorities/ea-data/master/Rmd/methods_interaction_sharing.Rmd?token=AB6ZCMD4HRHLJCFNLBKYO5LBRWHLY", here::here("remote", "methods_interaction_sharing_remote.Rmd"))
#TODO -- find a good way to move the relevant content over from other repos

options(pkgType = "binary")
p_load("bettertrace") #better tracking after bugs


## Parsing tool/parse to 'new formats' (use only once, and carefully!) ####

p_load(rex, readr, magrittr)

source_url("https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/parse_dr_to_ws.R")

rmd_files <- c("index.Rmd", "introduction_overview.Rmd", "data_and_code.Rmd", "coding_data.Rmd", "presentation_method_discussion.Rmd", "survey_designs_methods.Rmd", "experiments_trials_design.Rmd",  "basic_stats.Rmd", "ml_modeling.Rmd", "time_series_predict.Rmd", "time_series_application.Rmd", "classification_model_notes.Rmd", "causal_inf.Rmd", "fermi.Rmd", "other_sections.Rmd", "power_analysis_framework_2.Rmd")


#!mv *.Rmd old_bookdown_style_rmds

map2(rmd_files, rmd_files,
     ~ dr_to_bs4(here::here("old_bookdown_style_rmds", .x), .y))

other_rmd_files <- c("from_ea_market_testing/binary_trial_computations_redacted.Rmd", "from_ea_market_testing/qualitative-design-issues.md")

other_rmd_files_names <- c("from_ea_market_testing/binary_trial_computations_redacted_ed.Rmd", "from_ea_market_testing/qualitative-design-issues_ed.md")

purrr::map2(other_rmd_files, other_rmd_files_names,
            ~ dr_to_bs4(.x, .y))


#### BUILD the bookdown ####
#The line below should 'build the bookdown' in the order specified in `_bookdown.yml`

#p_load(bookdown)


#p_load(bookdown)
{
  options(knitr.duplicate.label = "allow")
  rmarkdown::render_site(output_format = 'rethinkpriorities::book', encoding = 'UTF-8')
}

#{
 # options(knitr.duplicate.label = "allow")
  #rmarkdown::render_site(output_format = 'bookdown::gitbook', encoding = 'UTF-8')
#}


# trackdown command examples ####

#p_load(googledrive)
#remotes::install_github("claudiozandonella/trackdown", build_vignettes = TRUE)
#library(trackdown)

#see https://app.getguru.com/card/cd469abi/collab-writing-sessions-working-this-into-Github-and-Rmarkdown and https://rethinkpriorities.slack.com/archives/C027CUXNQTD/p1637074537043600 and https://claudiozandonella.github.io/trackdown/

trackdown::upload_file(
  file = here("power_analysis_framework_2_COLLAB.Rmd"), 
  shared_drive = "Research", #this works -- name looked up with googledrive::shared_drive_find()
  hide_code = FALSE) #hide_code=TRUE is usually better but I want to see it for now

trackdown::upload_file(
  file = here("time_series_application.Rmd"), 
  shared_drive = "Research", #this works -- name looked up with googledrive::shared_drive_find()
  hide_code = FALSE) #hide_code=TRUE is usually better but I want to see it for now

