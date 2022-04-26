##
# Then running this should produce results that are exported  "see "Save final_models"
# and displayed/presented in `donations_20.Rmd`


#DR NOTE: I'm making a  'vignette' of this in `eas_ml_modeling_vignette.qmd`; this may be owrth swapping in here, in some form

library(logr) #this is just to log the messages, it doesn't affect the running
library(tidymodels)
library(tidyverse)
library(here)
library(workflowsets)
library(dyneval)


library(vip) #'variable importance plots'
library(ranger) #random forest
library(glmnet) #elastic net models

options(scipen = 999)
lf <- log_open(here("log_donation_pred.log"))
options("logr.on" = TRUE, "logr.notes" = TRUE)
options("logr.autolog" = TRUE)

#Note these are also present in main.R so maybe you can skip thems
source(here("code", "modeling_functions.R"))
#source(here("build", "labelling_eas.R"))

library(pacman)
p_load(rsample)
p_load(parsnip, tune, dials)

conflicted::conflict_prefer("set_label", "sjlabelled")
conflicted::conflict_prefer("add_footnote", "kableExtra")
conflicted::conflict_prefer("sample_n", "tidylog")

set_label <- sjlabelled::set_label

filter <- dplyr::filter
ungroup <- dplyr::ungroup
mutate <- dplyr::mutate

seed <- 1
set.seed(seed)

# Setup for running in parallel
cores <- parallel::detectCores()
if (!grepl("mingw32", R.Version()$platform)) {
  library(doMC)
  registerDoMC(cores = cores)
} else {
  library(doParallel)
  cl <- makePSOCKcluster(cores)
  registerDoParallel(cl)
}

if(Sys.info()[[4]]=="Yosemites-iMac.local") {
  cores <-1 #DR: Older machine could not handle multiple cores 
}

# Read data ---------------------------------------------------------------

df <- rethinkpriorities::read_file_from_repo(
  repo = "ea-data",
  path = "data/edited_data/eas_all_s_rl_imp.Rdata",
  user = "rethinkpriorities",
  token_key = "github-API",
  private = TRUE
  ) %>%  
labelled::remove_attributes("label") %>%  # Labels don't work with tidymodels :/, sadly
  ungroup()


#Note: the above RDS was built in donations_sparse.R; try to move it to a _build_ operation before doing analysis 

#Random draw of 2k obs for trial run on David's mac
if(Sys.info()[[4]]=="MacBook-Pro-4.local") {
  df <- df %>%
    sample_n(2000)
  }

#'Big global filtering step' ... removing any people who did not answer the donation question... on which (all our) outcome variables are based'
df <- df %>% dplyr::filter(!is.na(d_don_1k))


# Some ad-hoc data cleaning and filtering ####

income_filter <- quo(income_c_imp_bc5k < 500000)

#DR, @OF: I swapped in income_c_imp_bc5k even though it doesn't matter for this filter, just for consistency

# Remove values of d_don_1k that are missing (only about 40, consider computing)
#DR: CHECK -- why missing -- TODO -  I think this removes all entries where people did not report a donation; but that would be way too small a number?



# Set base categories to most common (#TODO -- for future, this saves 800 lines of code)
df <- df %>% mutate(
  across(where(is.factor),
    ~ forcats::fct_infreq(.x)))

# Create training and test data ####
init_split <- rsample::initial_split(df, prop = 3/4) #3/4 of data goes for training, rest for testing

train <- rsample::training(init_split)
test <- rsample::testing(init_split)

#... same for (lt 500k income) filtered data
# Consider: in some cases we might want to filter *before* making training/test, but there are pros and cons

train_filter <- train %>% filter(!!income_filter)
test_filter <- test %>% filter(!!income_filter)

# Cross validation splits ####

cv <- rsample::vfold_cv(train) # 10 fold
cv_filter <- vfold_cv(train_filter)

# Misc ####

# ... Create formulas ####
rhs_vars <- c("ln_years_involved", "year_f", "ln_age", "not_male_cat", "student_cat", "race_cat", "where_live_cat",
                  "city_cat", "d_pt_employment", "d_not_employed", "d_career_etg", "ln_years_involved_post_med", "ln_income_c_imp_bc5k",
                  "first_hear_ea_lump")


##Consider: -- Medium importance: Consider constructing this starting with lists defined in donations_20 and adding/subtracting things (but could this cause problems?)


l_don_av_2yr_f <- make_formula("l_don_av_2yr", rhs_vars) #shortcut for stats::reformulate to make a formal out of rhs and lhs
don_share_inc_imp_f <- make_formula("don_share_inc_imp_bc5k", rhs_vars)
d_don_1k_f <- make_formula("d_don_1k", rhs_vars)

# Model recipes -----------------------------------------------------------

# .... Standard preprocessing (imputation and variable formatting) ####

preprocess_func <- function(formula, data = train){
  require(recipes)

  # Function to save time in creating recipes for different outcomes
  #? Todo -- add to rethinkpriorities package
  
  recipes::recipe(formula, data=data) %>% #formula is a 'y~x1+x2` thing, defining rhs and lhs variables
    recipes::step_impute_median(all_numeric_predictors()) %>% #rem: replaces missing values with medians

    # Create NA feature
    recipes::step_unknown(all_nominal_predictors()) %>%
    recipes::step_scale(all_numeric_predictors(), factor=2) %>% #the 2sd Gelman adjustment
    #Removing because redundant: step_impute_mode(all_nominal_predictors(), -all_outcomes()) %>%
    recipes::step_zv(all_predictors()) %>% #cut any predictors with zero variance
    recipes::step_dummy(all_nominal_predictors())
}

# Create recipes (defined above in preprocess_func) (with 'formulas') attached to data objects (default is 'train')

l_don_av_2yr_rec <- preprocess_func(l_don_av_2yr_f, data=train) #used preprocess_func to define a recipe
#`data=train` as a reminder that this is a data thing

don_share_inc_imp_rec <- preprocess_func(don_share_inc_imp_f)
d_don_1k_rec <- preprocess_func(d_don_1k_f)

l_don_av_2yr_rec_filter <- preprocess_func(l_don_av_2yr_f, data = train_filter)

#NOT running income filters for these models bc its not outlier-sensitive:
#don_share_inc_imp_rec_filter <- preprocess_func(don_share_inc_imp_f, data = train_filter) 
#d_don_1k_rec_filter <- preprocess_func(d_don_1k_f, data = train_filter)

# unimportant comment

# Define machine learning models (procedures)...  (regression) ----------------------------------------------

# Regression tree
dt_model_reg <- parsnip::decision_tree(cost_complexity = tune(), #rem -- what 'charge' is this relative to tree_depth; possibly to do with 'post-pruning'
                              tree_depth = tune(),
                              min_n = tune()) %>%
  parsnip::set_engine("rpart") %>%
  parsnip::set_mode("regression")

# Random forest model
rf_model_reg <- parsnip::rand_forest(mtry = tune(), #number of predictors to randomly sample at each 'split'
                            trees = tune(), #how many trees in the 'ensemble'
                            min_n = tune()) %>%
  parsnip::set_engine("ranger", importance = "impurity") %>% 
  parsnip::set_mode("regression")


# Glmnet penalized regression (combines ridge and lasso, tuning the mix of L1 and L2 norms for penalization)

linear_model_reg <- linear_reg(penalty = tune(), 
                               mixture = tune()) %>%
            set_engine("glmnet")

# Create list of 'regression models' (i.e., continuous outcomes)
regression_models <- list(decision_tree = dt_model_reg,
                          random_forest = rf_model_reg,
                          linear_reg = linear_model_reg)

# Define classification models --------------------------------------------

#DR @OF: Note there is a lot of defined elements repeated here. Maybe tidyable? E.g., you could make an object with all of the arguments that seem to be repeated everywhere. It makes code more readable

# Decision tree
dt_model_class <- decision_tree(cost_complexity = tune(),
                                tree_depth = tune(),
                                min_n = tune()) %>%
  set_engine("rpart") %>%
  set_mode("classification")

# Random forest model
rf_model_class <- rand_forest(mtry = tune(), #number of predictors to randomly sample at each 'split'
                              trees = tune(), #how many trees in the 'ensemble'
                              min_n = tune()) %>%
  set_engine("ranger", importance = "impurity") %>%
  set_mode("classification")

# Logistic regression
logistic_model_reg <- logistic_reg(penalty = tune(),
                                   mixture = tune()) %>% #DR, @OS -- what is the 'mixture' here? -- is it a mixture of L1 and L2 norms (ridge and lasso?)
  set_engine("glmnet")

# Create list
classification_models <- list(decision_tree = dt_model_class,
                              random_forest = rf_model_class,
                              logistic_reg = logistic_model_reg)


# Create workflows --------------------------------------------------------
# "A workflow is an object that can bundle together your pre-processing, modeling, and post-processing requests."

# Fit random forest parameter ranges to data (find cleaner way to do this)
rf_params <- tune::parameters(rf_model_reg) %>%
  # finalize(train)
  recipes::update(mtry = mtry(c(0, nrow(d_don_1k_rec$var_info)-1))) #rem: mtry is 'number of sampled predictors'


l_don_av_2yr_wf <-
  workflow_set(preproc = list(preprocess = l_don_av_2yr_rec),
               #'preprocessing objects' ... here 'recipes'
               models = regression_models) %>% #'parsnip model specifications'
  workflowsets::option_add_parameters() %>%
  #'adds a parameter object to the 'option' column'
  option_add(param_info = rf_params, #this is the restriction defined above
             id = "preprocess_random_forest")
#'add options saved in a workflow set' esp in the 'option column'

don_share_inc_imp_wf <-
  workflow_set(preproc = list(preprocess = don_share_inc_imp_rec),
               models = regression_models) %>%
  option_add(param_info = rf_params, id = "preprocess_random_forest")

d_don_1k_wf <-
  workflow_set(preproc = list(preprocess = d_don_1k_rec),
               models = classification_models) %>%
  option_add(param_info = rf_params, id = "preprocess_random_forest")


# Workflows for filtered data
l_don_av_2yr_wf_filter <- workflow_set(preproc = list(preprocess = l_don_av_2yr_rec_filter),
               models = regression_models) %>%
  workflowsets::option_add_parameters() %>%
  option_add(param_info = rf_params,
             id = "preprocess_random_forest")


# Fitting models ----------------------------------------------------------

# Bayesian optimization of parameters (quicker than grid search and more effective than random search)
# setting options for this now
# We think this is for the *tuning* parameters

bayes_ctrl <- control_bayes(parallel_over = "everything",
                      verbose = TRUE,
                      # no_improve = 1,
                      save_pred = TRUE,
                      save_workflow = TRUE,
                      seed = seed)

max_iter <- 30

if(Sys.info()[[4]]=="MacBook-Pro-4.local") {
  max_iter <- 5
}

# Evaluate models ('RUNNING it' here, takes 20 minutes or so on DR old macbook using 2 cores with 30 max iter and ... runs much faster with the abridgement made above?)

# Todo: can we store these 'base options' for the workflow_map as an object, for coding clarity (avoid repetition)?

#remember that these are each across three distinct modeling approaches

l_don_av_2yr_results <- l_don_av_2yr_wf %>%
  workflow_map("tune_bayes",
               seed = seed,
               resamples = cv,
               iter = max_iter,
               # metrics = metric_set(mae),
               control = bayes_ctrl) #'control' how the function works

#produces a tibble of fit workflows, has not yet been applied to the testing data 

don_share_inc_imp_results <- don_share_inc_imp_wf %>%
  workflow_map("tune_bayes",
               seed = seed,
               resamples = cv,
               iter = max_iter,
               control = bayes_ctrl)

d_don_1k_results <- d_don_1k_wf %>%
  workflow_map("tune_bayes",
               seed = seed,
               resamples = cv,
               iter = max_iter,
               control = bayes_ctrl)

# Same again for filtered data
l_don_av_2yr_results_filter <- l_don_av_2yr_wf_filter %>%
  workflow_map("tune_bayes",
               seed = seed,
               iter = max_iter,
               resamples = cv,
               control = bayes_ctrl)


# Working with results ----------------------------------------------------


# ... renaming vectors ####

# Char vector for renaming of models from workflowset defaults (for display)

pred_model_names <- c("preprocess_decision_tree" = "Decision Tree",
  "preprocess_random_forest" = "Random Forest",
  "preprocess_linear_reg" = "Linear Regression (glmnet)",
  "preprocess_logistic_reg" = "Logistic Regression (glmnet)")


rename_metrics <- c("Workflow" = "wflow_id",
                    "Iteration" = ".config",
                    "Iteration Number" = ".iter",
                    "Preprocessing" = "preproc",
                    "Model" = "model",
                    "Metric" = ".metric",
                    "Estimator" = ".estimator",
                    "Mean" = "mean",
                    "N" = "n",
                    "Standard error" = "std_err")

rename_models <- function(df, new_names = pred_model_names){
  df <- df %>% mutate(model = stringr::str_replace_all(model, pred_model_names))

  return(df)
}


#actually grab stuff from each of the fit workflows, best parameters, metrics. etc, as described above 
l_don_av_2yr_best_params <- best_wflow_preds_vi(l_don_av_2yr_results, outcome_var = "l_don_av_2yr")

don_share_inc_imp_best_params <- best_wflow_preds_vi(don_share_inc_imp_results, "don_share_inc_imp_bc5k")

d_don_1k_best_params <- best_wflow_preds_vi(d_don_1k_results, outcome_var = "d_don_1k", classification = TRUE,
                                            metric = "roc_auc")

l_don_av_2yr_best_params_filter <- best_wflow_preds_vi(l_don_av_2yr_results_filter, outcome_var = "l_don_av_2yr",
                                                       train_sample = train_filter,
                                                       test_sample = test_filter)

# Regression metrics -- evaluate the model with these metrics
regress_metrics <- list(rmse = yardstick::rmse_vec,
                        mae = yardstick::mae_vec)

# Classification metrics
class_metrics <- list(accuracy = yardstick::accuracy_vec,
                      recall = yardstick::recall_vec,
                      precision = yardstick::precision_vec,
                      f1_score = f_meas_vec)


# Calculate performance metrics -------------------------------------------

# Convert to levels before calculating RMSE/MAE
l_don_av_2yr_best_params <- l_don_av_2yr_best_params %>% mutate(across(c(preds, true_y), ~map(.x, exp))) %>%
  calculate_metrics(regress_metrics)
l_don_av_2yr_best_params_filter <- l_don_av_2yr_best_params_filter %>% mutate(across(c(preds, true_y), ~map(.x, exp))) %>%
  calculate_metrics(regress_metrics)

don_share_inc_imp_best_params <- calculate_metrics(don_share_inc_imp_best_params, regress_metrics)
d_don_1k_best_params <- calculate_metrics(d_don_1k_best_params, class_metrics)

# don_share_inc_imp_best_params_filter <- calculate_metrics(don_share_inc_imp_best_params_filter, regress_metrics)
# d_don_1k_best_params_filter <- calculate_metrics(d_don_1k_best_params_filter, class_metrics)

# Add info on filter ... adds column 'this has been filterted'
l_don_av_2yr_best_params_filter <- l_don_av_2yr_best_params_filter %>%
  mutate(filter_name = str_replace_all(quo_name(income_filter), key_eas_all_labels))

# don_share_inc_imp_best_params_filter <- don_share_inc_imp_best_params_filter %>%
#   mutate(filter_name = quo_name(income_filter))
#
# d_don_1k_best_params_filter <- d_don_1k_best_params_filter %>%
#   mutate(filter_name = quo_name(income_filter))

# Change model names
l_don_av_2yr_best_params <- rename_models(l_don_av_2yr_best_params)
don_share_inc_imp_best_params <- rename_models(don_share_inc_imp_best_params)
d_don_1k_best_params <- rename_models(d_don_1k_best_params)
l_don_av_2yr_best_params_filter <- rename_models(l_don_av_2yr_best_params_filter)

final_models <- here("analysis", "intermed_results", "donation_prediction", "final_models")

# Save final_models
write_rds(l_don_av_2yr_best_params, here(final_models, "l_don_av_2yr.Rdata"))
write_rds(don_share_inc_imp_best_params, here(final_models, "don_share_inc_imp.Rdata"))
write_rds(d_don_1k_best_params, here(final_models, "d_don_1k.Rdata"))

write_rds(l_don_av_2yr_best_params_filter, here(final_models, "l_don_av_2yr_filter.Rdata"))

# write_rds(don_share_inc_imp_best_params_filter, here(final_models, "don_share_inc_imp_filter.Rdata"))
# write_rds(d_don_1k_best_params_filter, here(final_models, "d_don_1k_filter.Rdata"))

log_close()
