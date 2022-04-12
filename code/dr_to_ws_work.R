
## Parsing tool/parse to 'new formats' (USE ONLY ONCE, AND CAREFULLY!) ####

rmd_files <- c("index.Rmd", "introduction_overview.Rmd", "data_and_code.Rmd", "coding_data.Rmd", "presentation_method_discussion.Rmd", "survey_designs_methods.Rmd", "experiments_trials_design.Rmd",  "basic_stats.Rmd", "ml_modeling.Rmd", "time_series_predict.Rmd", "time_series_application.Rmd", "classification_model_notes.Rmd", "causal_inf.Rmd", "fermi.Rmd", "other_sections.Rmd", "power_analysis_framework_2.Rmd")

other_rmd_files <- c("from_ea_market_testing/binary_trial_computations_redacted.Rmd", "from_ea_market_testing/qualitative-design-issues.md")
other_rmd_files_names <- c("from_ea_market_testing/binary_trial_computations_redacted_ed.Rmd", "from_ea_market_testing/qualitative-design-issues_ed.md")

p_load(rex, readr, purrr)
source_url("https://raw.githubusercontent.com/daaronr/dr-rstuff/master/functions/parse_dr_to_ws.R")
#!mv *.Rmd old_bookdown_style_rmds
map2(rmd_files, rmd_files,
     ~ dr_to_bs4(here::here("old_bookdown_style_rmds", .x), .y))

purrr::map2(other_rmd_files, other_rmd_files_names,
            ~ dr_to_bs4(.x, .y))

