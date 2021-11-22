# Adaptive design/sampling, reinforcement learning

## Overview: conversation with DB

Dillon Bowen: End of 3rd year of decision processes in Wharton Phd.

Here is a stats package for estimating effect sizes in multi-armed experiments. [https://dsbowen.gitlab.io/conditional-inference/](https://dsbowen.gitlab.io/conditional-inference/)

### **Adaptive experimentation**,

...running experiments with many arms and winnowing out the 'best ones' to learn the most/best.

* See: adaptive design, adaptive sampling, dynamic design, reinforcement learning,  exploration sampling, Thompson's sampling, Bayesian adaptive inference, multifactor experiment

### Treatment space

_**Discrete vs continuous**_: switches vs knobs

In our cases of the ‘options are discrete’, many knobs to turn, although some are discrete. - There is a different version of this for discrete vs continuous

**If we can order the different treatments (arms/knobs) as 'dimensions' we can infer more...** Can do better thinking of them as a ‘multifactor experiment’ rather than 2 unrelated … several separate dimensions

Model running in the background trying to figure out ‘things about the effectiveness of the interventions you might use’

### **Explore only or explore & exploit at the same time**

“Ex post regret versus cumulative regret” … latter suggests Thompson sampling ? (Does Thompson's sampling take into account the length of the future period)

### **Learning and inference**

**Ex-post** … Use Machine Learning to consider which matter and how much they matter … although he doesn’t know of papers that have looked at this, but assumes there are adaptive designs that incorporate this.

**Statistical inference** can be challenging with adaptive designs, but this is a ripe area of research

Dillon (?): has a paper on traditional statistical inference after an adaptive design.

Goals what kinds of inference:

1. The arm you using relative to (? the average arm?)
2. Which factors matter/joint distribution ….. Bayesian models 

### Implementing adaptive design

We need a great web developer, a system so that a program Dillon writes is fed data on the factors (?) to assign a user to a treatment. Dillon will set up an ML model that is continuously updated … ‘next person clicking on this page gets this treatment … web dev makes sure it shows the recommended content’

We figure out what factors we want, what levels, have a basic web design … Dillon comes in and turns the ‘1000 dim treatment space and featurise it so his model can use it’.. Works with a Dev to set up a pipeline.
