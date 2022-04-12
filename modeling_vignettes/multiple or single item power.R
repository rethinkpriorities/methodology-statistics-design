library(MASS)
library(tidyverse)
library(furrr)

# Parameters
n <- 1000000
r <- .7
r_inter <- .4
sd <- 2
mean <- 5
variance <- sd * sd
covar_target <- r * sd * sd
covar_items <- r_inter * sd * sd

# Prepare parameters
mus <- c(mean, mean, mean, mean) 
sigma <- rbind(c(variance, covar_target, covar_target, covar_target),
               c(covar_target, variance, covar_items, covar_items),
               c(covar_target, covar_items, variance, covar_items),
               c(covar_target, covar_items, covar_items, variance))


# Simulate
samples <- as_tibble(mvrnorm(n = n, mu = mus, Sigma = sigma))

# Add appropirate column names
colnames(samples) <- c("true", "item1", "item2", "item3")

# make a new variable that it correlated with target, adding noise so it is not perfect
# notably we do not specify that the variable is correlated with the other items, only the target
samples <- samples %>% mutate(correlated = (true + rnorm(n = 1000000, mean = 0, sd = 6)) / 3)

# check we made a correlated variable:
cor.test(samples$true, samples$correlated)

ggplot(samples[1:1000, ]) +
  geom_point(aes(x = true, y = correlated), alpha = .33) +
  theme_minimal()

# there is a correlation of about .32 with this noise added

data <- samples %>%
  mutate(
    single = item1,
    two = (item1 + item2) / 2,
    three = (item1 + item2 + item3) / 3
  ) %>%
  dplyr::select(true, single, two, three, correlated) 

# Calculate errors
errors <- data %>%
  pivot_longer(cols = c(-true, -correlated), names_to = "items", values_to = "response") %>%
  mutate(error = response - true)

# Graph the errors by number of items
ggplot(errors, aes(x = error, color = items)) +
  geom_density() +
  theme_minimal()

#### Check power to detect the correlation ####
# We'll go up to a maximum n of 400, in batches of 20
data$split <- rep(1:2500, each = 400)
data$n <- rep(1:400, 2500)

sample_sizes <- seq(from = 20, to = 400, by = 20)
data_split <- data %>% group_by(split) %>% group_split()

correlation_maker <- function(data, breaks) {
  
  # this function cuts the data set it is given into different sample sizes
  # specified by the breaks argument
  cut_samples <- function(break_point, data) {
    cut_data <- filter(data, n <= break_point)
    cut_data <- mutate(cut_data,
                       sample_size = break_point)
    return(cut_data)
  }
  
  data_cuts <- map_dfr(.x = breaks, .f = cut_samples, data = data)
  
  # the data is split according to the sample size
  # to feed to the regression model
  data.cuts <- data_cuts %>% group_by(sample_size) %>% group_split()
  
  # this function runs the correlation test
  run_cor <- function(data) {
    
    cor_1 <- cor.test(x = data$correlated, y = data$single)
    cor_2 <- cor.test(x = data$correlated, y = data$two)
    cor_3 <- cor.test(x = data$correlated, y = data$three)
    
    p1 <- cor_1$p.value
    p2 <- cor_2$p.value
    p3 <- cor_3$p.value
    
    output <- tibble(p_value = c(p1, p2, p3),
                     item_number = c(1, 2, 3),
                     sample_size = nrow(data),
                     sim = data[[1, "split"]],
                     sig_05 = case_when(p_value < .05 ~ 1,
                                        TRUE ~ 0),
                     sig_01 = case_when(p_value < .01 ~ 1,
                                        TRUE ~ 0),
                     sig_001 = case_when(p_value < .001 ~ 1,
                                        TRUE ~ 0))
    
    return(output)
  }
  # run the regression function over the different sample sizes
  output <- map_df(.x = data_cuts, .f = run_cor)
  return(output)
}

plan(multisession)

t1 <- Sys.time()
correlation_output <- future_map_dfr(.x = data_split,
                                .f = correlation_maker,
                                breaks = sample_sizes)
t2 <- Sys.time()
t2 - t1

correlation_summary <- correlation_output %>% pivot_longer(cols = sig_05:sig_001, names_to = "sig_level", values_to = "effect_detected") %>%
  group_by(sample_size, item_number, sig_level) %>%
  summarise(.groups = "keep",
            probability = sum(effect_detected)/2500)

# I suspect my ggplot style is probably overly verbose for you Willem :-p
# but especially when working things up in layers I like to really see exactly what I'm putting in on each line
png(file = "power to detect correlation.png", width = 6, height = 3, units = "in", res = 1000, type = "cairo")
ggplot(data = correlation_summary) +
  scale_x_continuous(limits = c(0, 400),
                     breaks = seq(from = 0, to = 400, by = 40),
                     expand = c(0, 0),
                     labels = c("", seq(from = 40, to = 400, by = 40))) +
  scale_y_continuous(limits = c(0, 1),
                     breaks = seq(from = 0, to = 1, by = .2),
                     expand = c(0, 0)) +
  geom_hline(aes(yintercept = .8), alpha = .3, linetype = "dashed", size = .1) +
  geom_hline(aes(yintercept = .9), alpha = .3, linetype = "dashed", size = .1) +
  geom_point(aes(x = sample_size, y = probability, color = as.factor(item_number)), size = .5, alpha = .66, shape = 16) +
  facet_wrap(~sig_level) +
  labs(x = "Sample size per group", y = "Probability of detecting significant effect", color = "Number of items") +
  theme_minimal() +
  theme(text = element_text(family = "Jost", color = "black", size = 6),
        panel.border = element_rect(fill = NA, color = "grey80"),
        aspect.ratio = 1.2,
        legend.position = "bottom",
        panel.grid = element_line(size = .1))
dev.off()