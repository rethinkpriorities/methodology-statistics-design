## ----r------------------------------------------------------------------------
library(here)

# 1.  Load packages, some setup definitions -- need to run it in every qmd
source(here("code", "methods_setup.R"))
options(knitr.duplicate.label = "allow")




## ----r change-memory-limit0, message = FALSE, warning = FALSE, echo=FALSE-----

memory.limit(100000)



## ----r load-tidyverse, message = FALSE, warning = FALSE-----------------------

# tidyverse simply used for data wrangling and plotting
library(tidyverse)



## ----r datamaker-function, message = FALSE, warning = FALSE-------------------
four.group.datamaker <- function(sim = 1, a = 0, b = .1, c = .2, d = .4, ppg=1500) {

#DR I renamed it `ppg` for 'population per group' because `pop` confused me

  # first a tibble (data frame) with 1500 ppts, with the different groups showing
  # effect sizes in Cohen's d of .1, .2, and .4
  four.groups <- tibble(a.control = rnorm(ppg, a, 1),
                        b.small = rnorm(ppg, b, 1),
                        c.medsmall = rnorm(ppg, c, 1),
                        d.medium = rnorm(ppg, d, 1),
                        counter = 1:ppg) %>% #we previously called the counter 'sample.size' because of its later use

    # turn the data into long form
    pivot_longer(cols = 'a.control':'d.medium', names_to = 'group', values_to = 'response') %>%

    # put cutpoints in the data to make it more similar to the ordinal responses we would get
    mutate(ordinal = case_when(response < -1.5 ~ 1,
                               response < -.5 ~ 2,
                               response < .5 ~ 3,
                               response < 1.5 ~ 4,
                               response >= 1.5 ~ 5),

           # for the purposes of this demo we will not analyse it as ordinal as it takes longer
           # to run the regressions, but if you did so you would also want to make the response
           # a factor
           ordinal = as.factor(ordinal),
           sim = sim)

  return(four.groups)

 }


## ----r datamaker-test, message = FALSE, warning = FALSE-----------------------

# test that the function works to make one data set before making many!
test.data <- four.group.datamaker()

ggplot(data = test.data) +
  geom_density(aes(x = response, fill = group), alpha = .3) +
  theme(
    aspect.ratio = .5
  ) +
  ggtitle('Test four groups, continuous outcome')

ggplot(data = test.data) +
  geom_histogram(aes(x = as.numeric(ordinal)), alpha = .6,
                 position = position_dodge(), bins = 10) +
  facet_wrap(~group, nrow=1) +
  theme(
    aspect.ratio = 1
  ) +
  ggtitle('Test four groups, categorical outcome')



## ----r load-furr, message = FALSE, warning = FALSE----------------------------

p_load(furrr)
library(furrr)

plan(multisession)
options <- furrr_options(seed = 48238)


## ----r run-datamaker-function, message = FALSE, warning = FALSE---------------

# we will pass N = 500 simulations to the map function
nsims <- 1:500

# the map function will run our data-making function over nsims=500 simulations
sim.data <- furrr::future_map_dfr(
  .x = nsims,
  .f = four.group.datamaker,
  a = 0,
  b = .1,
  c = .2,
  d = .4,
  .options = options
)

# split the simulated data into the separate simulations

sim.data <- sim.data %>% group_by(sim) %>% group_split()



## ----r check-data, message = FALSE, warning = FALSE---------------------------
head(sim.data[[3]])


## ----r regression-function, message = FALSE, warning = FALSE------------------

linear.reg.maker <- function(data, breaks) { #runs a particular regression over a set of cuts of larger and larger subsets of  multiple data sets

  # this function cuts the data set it is given into different sample sizes
  cut.samples <- function(break.point, data) {
    cut.data <- filter(data, counter <= break.point) %>%
      mutate(sample.size = break.point)
    return(cut.data)
  }

  data.cuts <- map_dfr(.x = breaks, .f = cut.samples, data = data)

  # the data is split according to the sample size
  # to feed to the regression model
  data.cuts <- data.cuts %>% group_by(sample.size) %>% group_split()

  # this function runs the regression
  run.reg <- function(data) {

    four.group.form <- as.numeric(ordinal) ~ 1 + group

    four.group.reg <-
      lm(formula = four.group.form,
           data = data)

    # we extract confidence intervals for the parameters of interest
    ci99 <- confint(four.group.reg, level = .99)
    ci95 <- confint(four.group.reg, level = .95)

    # we create an 'output' to show the confidence intervals around the effects
    # and some additional inference info, e.g., 'nonzero' indicates whether
    # the lower bound of the CI excludes 0 or not.
    # 'width' indicates the width of the confidence interval,
    # for assessment of precision
    output <- tibble(group = c('small', 'medsmall', 'medium',
                               'small', 'medsmall', 'medium'),
                     interval = c(.99, .99, .99, .95, .95, .95),
                     lower = c(ci99[[2,1]], ci99[[3,1]], ci99[[4,1]],
                               ci95[[2,1]], ci95[[3,1]], ci95[[4,1]]),
                     upper = c(ci99[[2,2]], ci99[[3,2]], ci99[[4,2]],
                               ci95[[2,2]], ci95[[3,2]], ci95[[4,2]])) %>%
  #DR: maybe this code should be made a little more flexible?; because if you wanted to consider additional-sized effects you would need to expand the entries above

      mutate('nonzero' = case_when(lower > 0 ~ 1,
                                   TRUE ~ 0),
             'width' = abs(upper - lower),
               'sim' = data[[1, 'sim']],
             'cell.size' = nrow(data)/4)

    return(output)
  }

  # run the regression function over the different sample sizes
  output <- map_df(.x = data.cuts, .f = run.reg)

  return(output)
}



## ----r run-regression, message = FALSE, warning = FALSE-----------------------

t1 <- Sys.time()
linreg.output <- future_map_dfr(.x = sim.data,
                                .f = linear.reg.maker,
                                breaks = seq(from = 150, to = 1500, by = 150))
t2 <- Sys.time()
t2 - t1



## ----r summarise-output, message = FALSE, warning = FALSE---------------------

# group the data according to group, confidence interval, and size per group
four.group.lin.summary <- linreg.output %>% group_by(group, interval, cell.size) %>%
  # summarise the amount of times we get a CI greater than 0
  summarise(.groups = 'keep',
            'ci above 0 vs. control' = sum(nonzero)/5)  %>%
  # change some factors for plotting
  mutate(interval = factor(interval, levels = c('0.95', '0.99'),
                           labels = c('95% CI', '99% CI')),
         'Effect size' = factor(group, levels = c('small', 'medsmall', 'medium'),
                                labels = c('Very small (.1)', 'Small (.2)', 'Medium (.4)')))



## ----r plot-power-curve, message=FALSE, warning=FALSE-------------------------
(
power_curve_4_group_lin <- ggplot(data = four.group.lin.summary) +
  scale_x_continuous(limits = c(100, 1550), breaks = seq(from = 150, to = 1500, by = 150)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(from = 0, to = 100, by = 20)) +
  geom_hline(aes(yintercept = 80), linetype = 'dashed', size = .33, alpha = .25) +
  geom_hline(aes(yintercept = 90), linetype = 'dashed', size = .33, alpha = .25) +
  geom_path(aes(x = cell.size, y = `ci above 0 vs. control`, color = `Effect size`,
                group = `Effect size`), size = .66) +
  geom_point(aes(x = cell.size, y = `ci above 0 vs. control`, color = `Effect size`),
             size = 1.5) +
  labs(y = 'Power to detect a non-zero effect',
       x = 'Number of participants per condition (control group not included)') +
  scale_color_manual(values = c('#c10d0d', '#7dc3c2', '#dcc55b')) +
  facet_wrap(~interval) +
  theme(
    aspect.ratio = 1,
    panel.grid.major = element_line(colour = "white", size = 0.33),
    panel.grid.minor = element_line(colour = "white", size = 0.2),
    panel.background = element_rect(fill = "grey96"),
    axis.line = element_line(color = 'black', size = 0.375),
    axis.ticks = element_line(color = 'black', size = 0.5),
    text = element_text(color = 'black', family = 'Gill Sans MT', size = 9),
    axis.text = element_text(color = 'black', family = 'Gill Sans MT', size = 7),
    strip.background = element_blank()
  )
)



## ----r------------------------------------------------------------------------
knitr::purl(here("chapters", "power_analysis_framework_2.qmd"), here("chapters", "power_analysis_framework_2.R"))


