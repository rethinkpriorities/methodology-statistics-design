# Bayes odds ratio modeling example (Elsey) ####
# ...Code written by Jamie Elsey in response to Slack thread: #### 

# https://rethinkpriorities.slack.com/archives/G01BDCD2QPR/p1647970569265519

library(tidyverse)
library(brms)
library(tidybayes)


#https://mc-stan.org/users/interfaces/brms
#The brms package provides a flexible interface to fit Bayesian generalized (non)linear multivariate multilevel models using Stan.


mock_data <- tibble(condition = c(rep("A", 1000), rep("B", 1000)),
                    outcome = c(rep(1, 11), rep(0, 989), rep(1, 14), rep(0, 986)))

#formX <- outcome ~ condition
#DR: This version would allow you to explicitly specify the prior over the *differences*, I guess

# Setup ... or something (?) ####

form <- outcome ~ 0 + condition

brms::get_prior(formula = formX,
          data = mock_data,
          family = bernoulli)

fit <- brm(formula = form,
                    family = bernoulli("logit"),
                    data = mock_data,
                    control = list(adapt_delta = 0.99, max_treedepth  = 15),
                    prior = c(prior(normal(-4, 1.5), class = b)), # not a very well thought out prior and not really necessary either
                    inits = 0,
                    chains = 3,
                    cores = 3,
                    iter = 2100,
                    warmup = 350,
                    backend = "cmdstanr", # if you don't have cmdstan then hash this out
                    threads = threading(4),  # if you don't have cmdstan then hash this out
                    seed = 1010)

new_data <- tibble(condition = c("A", "B"))

posterior <- posterior_epred(fit,
                             newdata = new_data,
                             ndraws = 5000) 

posterior <- tibble("A" = posterior[ , 1],
                    "B" = posterior[ , 2]) %>% 
  mutate(difference = B - A,
         logA = log(A),
         logB = log(B),
         proportion = B / A,
         oddsA = A / (1 - A),
         oddsB = B / (1 - B),
         odds_ratio = oddsB/oddsA)

posterior_summary <- posterior %>% summarise(mean_or = mean(odds_ratio),
                                             lower = hdi(odds_ratio)[1],
                                             upper = hdi(odds_ratio)[2],
                                             perc5 = quantile(odds_ratio, .05),
                                             perc10 = quantile(odds_ratio, .1),
                                             perc15 = quantile(odds_ratio, .15),
                                             perc20 = quantile(odds_ratio, .2),
                                             perc25 = quantile(odds_ratio, .25),
                                             perc75 = quantile(odds_ratio, .75),
                                             perc8 = quantile(odds_ratio, .8),
                                             perc85 = quantile(odds_ratio, .85),
                                             perc9 = quantile(odds_ratio, .9),
                                             perc95 = quantile(odds_ratio, .95),
                                             perc995 = quantile(odds_ratio, .995),
                                             perc005 = quantile(odds_ratio, .005))

png(filename = "posterior odds ratio.png", width = 6, height = 3, units = "in", res = 1000, type = "cairo")
ggplot(data = posterior) +
  scale_x_continuous(breaks = c(0, 1, 2, 3, 4, 5), limits = c(0, 5)) +
  geom_density(aes(x = odds_ratio)) +
  geom_errorbarh(data = posterior_summary, aes(xmin = lower, xmax = upper, y = 0), height = .02) +
  geom_point(data = posterior_summary, aes(x = mean_or, y = 0)) +
  labs(y = "Density", x = "Odds ratio B/A\n(95% HDI and posterior mean)") +
  theme_minimal() +
  theme(aspect.ratio = .5,
        text = element_text(family = "Jost", color = "black", size = 8))
dev.off()

png(filename = "cumulative posterior.png", width = 6, height = 3, units = "in", res = 1000, type = "cairo")
ggplot(data = posterior) +
  scale_x_continuous(breaks = c(0, 1, 2, 3, 4, 5), limits = c(0, 5)) +
  stat_ecdf(aes(x = odds_ratio)) +
  geom_vline(data = posterior_summary, aes(xintercept = perc5), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc10), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc15), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc20), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc25), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc75), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc8), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc85), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc9), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc95), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc995), linetype = "solid", color = "maroon", size = .4, alpha = .8) +
  geom_vline(data = posterior_summary, aes(xintercept = perc005), linetype = "solid", color = "maroon", size = .4, alpha = .8) +
  geom_errorbarh(data = posterior_summary, aes(xmin = lower, xmax = upper, y = 0), height = .02) +
  geom_point(data = posterior_summary, aes(x = mean_or, y = 0)) +
  labs(y = "Cumulative density of posterior", x = "Odds ratio B/A") +
  theme_minimal() +
  theme(aspect.ratio = .5,
        text = element_text(family = "Jost", color = "black", size = 8))
dev.off()

#### Larger sample size
mock_data <- tibble(condition = c(rep("A", 10000), rep("B", 10000)),
                    outcome = c(rep(1, 110), rep(0, 9890), rep(1, 140), rep(0, 9860)))

form <- outcome ~ condition

form <- outcome ~ 0 + condition

get_prior(formula = form,
          data = mock_data,
          family = bernoulli)

fit <- brm(formula = form,
           family = bernoulli("logit"),
           data = mock_data,
           control = list(adapt_delta = 0.99, max_treedepth  = 15),
           prior = c(prior(normal(-4, 1.5), class = b)), # not a very well thought out prior and not really necessary either
           inits = 0,
           chains = 3,
           cores = 3,
           iter = 2100,
           warmup = 350,
           backend = "cmdstanr", # if you don't have cmdstan then hash this out
           threads = threading(4),  # if you don't have cmdstan then hash this out
           seed = 1010)

new_data <- tibble(condition = c("A", "B"))

posterior <- posterior_epred(fit,
                             newdata = new_data,
                             ndraws = 5000) 

posterior <- tibble("A" = posterior[ , 1],
                    "B" = posterior[ , 2]) %>% 
  mutate(difference = B - A,
         logA = log(A),
         logB = log(B),
         proportion = B / A,
         oddsA = A / (1 - A),
         oddsB = B / (1 - B),
         odds_ratio = oddsB/oddsA)


png(filename = "posterior odds ratio 2.png", width = 6, height = 3, units = "in", res = 1000, type = "cairo")
ggplot(data = posterior) +
  scale_x_continuous(breaks = c(0, 1, 2, 3, 4, 5), limits = c(0, 5)) +
  geom_density(aes(x = odds_ratio)) +
  geom_errorbarh(data = posterior_summary, aes(xmin = lower, xmax = upper, y = 0), height = .02) +
  geom_point(data = posterior_summary, aes(x = mean_or, y = 0)) +
  labs(y = "Density", x = "Odds ratio B/A\n(95% HDI and posterior mean)") +
  theme_minimal() +
  theme(aspect.ratio = .5,
        text = element_text(family = "Jost", color = "black", size = 8))
dev.off()

png(filename = "cumulative posterior 2.png", width = 6, height = 3, units = "in", res = 1000, type = "cairo")
ggplot(data = posterior) +
  scale_x_continuous(breaks = c(0, 1, 2, 3, 4, 5), limits = c(0, 5)) +
  stat_ecdf(aes(x = odds_ratio)) +
  geom_vline(data = posterior_summary, aes(xintercept = perc5), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc10), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc15), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc20), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc25), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc75), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc8), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc85), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc9), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc95), linetype = "dashed", size = .25, alpha = .5) +
  geom_vline(data = posterior_summary, aes(xintercept = perc995), linetype = "solid", color = "maroon", size = .4, alpha = .8) +
  geom_vline(data = posterior_summary, aes(xintercept = perc005), linetype = "solid", color = "maroon", size = .4, alpha = .8) +
  geom_errorbarh(data = posterior_summary, aes(xmin = lower, xmax = upper, y = 0), height = .02) +
  geom_point(data = posterior_summary, aes(x = mean_or, y = 0)) +
  labs(y = "Cumulative density of posterior", x = "Odds ratio B/A") +
  theme_minimal() +
  theme(aspect.ratio = .5,
        text = element_text(family = "Jost", color = "black", size = 8))
dev.off()
