library(tidyverse)
library(brms)

# effect size of .2 in standard deviation units
data <- tibble(group = c(rep("a", 100), rep("b", 100)),
               outcome = c(rnorm(100), rnorm(100, .2, 1)),
               n = c(1:100, 1:100))

formula <- outcome ~ 1 + group

get_prior(formula,
          data,
          gaussian)

# if you are going to look at updating, then you will have to be more careful/considerate regarding priors
# because the amount of updating of course depends greatly on the priors you set -
# these are not super carefully thought out priors, just an example
prior <- c(set_prior("normal(0, 1)", class = "Intercept"),
           set_prior("normal(0, 1)", class = "b"),
           set_prior("normal(0, 1)", class = "sigma"))

# to run this you might need to remove the threads and backend args which rely on command stan R

# run for just prior
model_prior <- brm(formula = formula,
                   family = gaussian,
                   data = data,
                   control = list(adapt_delta = 0.95, max_treedepth = 15),
                   prior = prior,
                   chains = 4,
                   cores = 4,
                   iter = 10500,
                   warmup = 500,
                   sample_prior = "only",
                   backend = "cmdstanr",
                   threads = threading(4),
                   seed = 1010)

# run for n = 10
model_n10 <- brm(formula = formula,
                 family = gaussian,
                 data = filter(data, n <= 10),
                 control = list(adapt_delta = 0.95, max_treedepth = 15),
                 prior = prior,
                 chains = 4,
                 cores = 4,
                 iter = 10500,
                 warmup = 500,
                 #sample_prior = "only",
                 backend = "cmdstanr",
                 threads = threading(4),
                 seed = 1010)

# run for n = 50
model_n50 <- brm(formula = formula,
                 family = gaussian,
                 data = filter(data, n <= 50),
                 control = list(adapt_delta = 0.95, max_treedepth = 15),
                 prior = prior,
                 chains = 4,
                 cores = 4,
                 iter = 10500,
                 warmup = 500,
                 #sample_prior = "only",
                 backend = "cmdstanr",
                 threads = threading(4),
                 seed = 1010)

# run for n = 100
model_n100 <- brm(formula = formula,
                 family = gaussian,
                 data = data,
                 control = list(adapt_delta = 0.95, max_treedepth = 15),
                 prior = prior,
                 chains = 4,
                 cores = 4,
                 iter = 10500,
                 warmup = 500,
                 #sample_prior = "only",
                 backend = "cmdstanr",
                 threads = threading(4),
                 seed = 1010)

# get posterior samples for each model (for the prior only model, the posterior is the prior)
model_prior_draws <- as_tibble(posterior_samples(model_prior)) %>% 
  mutate(effect_size = b_groupb / sigma)

model_n10_draws <- as_tibble(posterior_samples(model_n10)) %>% 
  mutate(effect_size = b_groupb / sigma)

model_n50_draws <- as_tibble(posterior_samples(model_n50)) %>% 
  mutate(effect_size = b_groupb / sigma)

model_n100_draws <- as_tibble(posterior_samples(model_n100)) %>% 
  mutate(effect_size = b_groupb / sigma)

# function ends up like a rolling function that goes from -2.5 to 2.5,
# counting the number of posterior samples in bins of .05 along the parameter space
# then makes a ratio of the prior to posterior in that bin
ratio_maker <- function(lowerbin, prior, posterior, n) {
  
  upperbin <- lowerbin + .05
  
  prior_es_count <- sum(prior$effect_size >= lowerbin & prior$effect_size < upperbin)
  posterior_es_count <- sum(posterior$effect_size >= lowerbin & posterior$effect_size < upperbin)
  
  output <- tibble(prior = prior_es_count / 20000,
                   posterior = posterior_es_count / 20000,
                   ratio = posterior / prior,
                   logratio = log(ratio),
                   log10ratio = log10(ratio),
                   x = (upperbin + lowerbin) / 2,
                   sample_size = n)
  
  return(output)
  
}

ratio_n10 <- 
map_df(.x = seq(-2.5, 2.45, .005),
       .f = ratio_maker,
       prior = model_prior_draws,
       posterior = model_n10_draws,
       n = 10)

ratio_n50 <- 
  map_df(.x = seq(-2.5, 2.45, .005),
         .f = ratio_maker,
         prior = model_prior_draws,
         posterior = model_n50_draws,
         n = 50)

ratio_n100 <- 
  map_df(.x = seq(-2.5, 2.45, .005),
         .f = ratio_maker,
         prior = model_prior_draws,
         posterior = model_n100_draws,
         n = 100)

# make single tibble from the objects above
ratio_tib <- bind_rows(ratio_n10,
                       ratio_n50,
                       ratio_n100)

ggplot(ratio_tib) +
  geom_col(aes(x = x, y = ratio, fill = as.factor(sample_size))) +
  geom_hline(aes(yintercept = 1), alpha = .5, linetype = "dashed") +
  facet_wrap(~sample_size) +
  scale_fill_manual(values = c("#49bca9", "#39789f", "#efa800")) +
  labs(x = "Effect size parameter space",
       y = "Posterior/Prior ratio or 'Updating factor'") +
  scale_fill_manual(values = c("#49bca9", "#39789f", "#efa800")) +
  labs(x = "Effect size parameter space",
       y = "Posterior/Prior ratio or 'Updating factor'",
       fill = "Sample size") +
  theme(
    panel.background = element_rect(fill = "#f5f5f5"),
    text = element_text(family = "Jost", color = "#000000"),
    strip.background = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank()
  )

ggplot(ratio_tib) +
  geom_col(aes(x = x, y = log10ratio, fill = as.factor(sample_size))) +
  facet_wrap(~sample_size) +
  scale_fill_manual(values = c("#49bca9", "#39789f", "#efa800")) +
  labs(x = "Effect size parameter space",
       y = "Log10-transformed Posterior/Prior ratio or 'Updating factor'\nEnables seeing where updating reduces likelihood of value",
       fill = "Sample size") +
  theme(
    panel.background = element_rect(fill = "#f5f5f5"),
    text = element_text(family = "Jost", color = "#000000"),
    strip.background = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank()
  )

# get the posterior densities of the different models
show_density <- bind_rows(mutate(model_prior_draws, n = "1. Prior"),
                          mutate(model_n10_draws, n = "2. n = 10"),
                          mutate(model_n50_draws, n = "3. n = 50"),
                          mutate(model_n100_draws, n = "4. n = 10"))

ggplot(show_density) +
  scale_x_continuous(limits = c(-2.5, 2.5)) +
  geom_density(aes(x = effect_size, fill = n), alpha = .5) +
  scale_fill_manual(values = c("#ffcdcd", "#49bca9", "#39789f", "#efa800")) +
  theme(
    panel.background = element_rect(fill = "#f5f5f5"),
    text = element_text(family = "Jost", color = "#000000"),
    strip.background = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank()
  )