# 'main.R': this single file should (ideally) source and build all data, build codebooks, run all analysis, and build bookdown and other output

#### Setup -- this does nothing here because it's not preserved

## PUT THESE at the beginning of each qmd (second one only if needs EAS data)!####

# 1.  Load packages, some setup definitions -- need to run it in every qmd
source(here("code", "methods_setup.R"))

# 2. Get EAS data
source(here("code", "get_eas_data.R"))

#source(here("code", "modeling_functions.R")) #TODO - incorporate rest of these into RP r package

# Bring in 'static' content, not to edit here but used ####
# ... from EAMT public ####


try_download("https://raw.githubusercontent.com/daaronr/effective_giving_market_testing/make_publicable/methodological-discussion/adaptive-design-sampling-reinforcement-learning.md?token=GHSAT0AAAAAABRYX5UTORNLOBY242VHQSBAYRWNPPA", here::here("from_ea_market_testing/","adaptive-design-sampling-reinforcement-learning.md"))

# ... this might should go the other way -- we work on it here and we embed it there instead

try_download('https://dl.dropbox.com/s/24ndb3p9aa0tfv2/reinstein_references.bib', here::here("reinstein_bibtex.bib"))

#from_ea_market_testing/experimental-design-methods-issues.md
#from_ea_market_testing/qualitative-design-issues.md
#time_series.md

## Previously used -- converting to bs4 format
#source_url("https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/parse_dr_to_ws.R")
#source(here("code", "dr_to_ws_work.R"))


#!mv *.Rmd old_bookdown_style_rmds


# Moving to Quarto (should only need to be done once)####

# list of files taken from _bookdown.yml

rmd_files <-  c(
  "introduction_overview.Rmd",
  "data_and_code.Rmd", "coding_data.Rmd",
  "presentation_method_discussion.Rmd",
  "survey_designs_methods.Rmd",
  "experiments_trials_design.Rmd",
  "basic_stats.Rmd",
  "ml_modeling.Rmd",
  "time_series_predict.Rmd",
  "time_series_application.Rmd",
  "classification_model_notes.Rmd",
  "causal_inf.Rmd",
  "fermi.Rmd",
  "other_sections.Rmd",
  "power_analysis_framework_2.Rmd"
  )


# Parsing command

library(pacman)
p_load(rex, readr, purrr, devtools, install=FALSE)
source_url("https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/parse_rp_bookdown_to_quarto.R")

# apply all parsing commands and put it into 'chapters' folder
system("mkdir chapters")
map2(rmd_files, rmd_files,
  ~ rp_rmd_to_quarto(.y, here::here("chapters", .y)))

newName <- sub(".Rmd", ".qmd", here::here("chapters", rmd_files))
file.rename(here::here("chapters", rmd_files), newName)

rp_rmd_to_quarto("index.Rmd", "index.qmd")

rp_rmd_to_quarto("from_ea_market_testing/binary_trial_computations_redacted_ed.Rmd", "from_ea_market_testing/binary_trial_computations_redacted_ed.qmd")


#print to screen ... output to put into chapters list in _quarto.yml
cat(
  "- index.qmd",
paste("\n- chapters/", stringr::str_replace_all(
  rmd_files, ".Rmd", ".qmd"),
  sep=""),
  "\n - from_ea_market_testing/binary_trial_computations_redacted_ed.qmd"
)

#Also get rid of 'format_with_col' everywhere (alternative?)


### Build Quarto book ####

system("quarto render") #takes a long time!

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



