# README: methodology-statistics-design
Surveys, experiments, data analysis: Methodology, protocols and templates

Proceeding from Slack discussion [here](https://rethinkpriorities.slack.com/archives/G01962YABHB/p1636393408082200)


## 'Methods and RP Guidelines Bookdown'

### To contain...

... *Only* things that we use, have used, want to use, or have been requested to address. To keep this manageable, don't add content just because "it's in a typical syllabus'.

See [airtable topic list](https://airtable.com/shrK7Pc0K8JPjmQkN) ... some examples below

**Data and code**

- Visualizations: suggested/preferred formats and templates
     - Integrate/move content from [ea-data 'presentation and method discussion'](https://github.com/rethinkpriorities/ea-data/blob/master/Rmd/presentation_method_discussion.Rmd and some Gdocs and Slack threads

**Survey designs and methods**

(How to ask good survey questions, avoiding pitfalls, sampling issues and representativeness, constructing reliable indices...)

**Experiments and trials*

- Experiment and trial design: qualitative issues and guidelines
- Power analyses for planning experiments and trials
- Adaptive designs

**Basic statistical testing and inference**

- Bayesian, frequentist, and other approaches
- A 'statistical model'
- Bayesian updating and inference
- Hypothesis testing
- Preferred approaches ('which tests') etc.

**Modeling, prediction, inference, and machine learning**

- "Regression models" and specification choices
- Interpreting model results
- Predictive modeling and machine learning
- Practical Bayesian approaches and interpretations
- Psychometrics, especially factor analysis

**Causal inference**

- Basic ideas and frameworks (simple, potential outcomes, DAGs)
- Pitfalls and mistakes (layman's terms)
- The experimental ideal
- Non-experimental approaches to causal inference
- Dealing with attrition

**Monte-Carlo 'Fermi estimation' approaches**

- the basic ideas
- Causal and Guesstimate
- code-based tools

*Todo*: Integrate some content/organization from [Reinstein's "Metrics bookdown"](https://daaronr.github.io/metrics_discussion/introduction.html)

### Using and building this Bookdown (proposed guidelines)

- Add stuff to the Bookdown in a concise way, once it's at least minimally readable/useable. (See distinct branches discussed below).
- For non-core material: out-link to standalone pages/gists/blogdowns whatever and/or Bookdown ‘appendix’ sections and folding boxes for the non-core material
- Link to these resources in Guru, but don't repeat this content there.
- If an ideal guide to 'exactly what we want' exist elsewhere, just 'curate link it', Pete W-style, don't re-write the wheel

*Key links for tips on using 'these tools'*

- [Reinstein's tips (from the EA barriers project)](https://daaronr.github.io/ea_giving_barriers/bookdown-appendix.html)
- [Reinstein's 'bookdown+ template' repo](https://github.com/daaronr/dr-rstuff/tree/master/bookdown_template)
- [Yihui's bookdown bookdown](https://bookdown.org/yihui/bookdown/)
- [Happy git with R](https://happygitwithr.com/)
- Pete's walkthroughs:
    - [git 101](https://gist.github.com/peterhurford/4d43aa5d6de114c0c741ba664c9c5ff5)
    - [Advanced R, abridged](https://gist.github.com/peterhurford/72dbd44e0a34e29297485a8cf679cf73)

### Repo branches (proposed)

- ‘main’: Decent looking, go-to
- ‘public’: same as ‘main’ but censoring anything we need to keep in-house (build a parsing script for that)
    - This branch can be made public (needs to be mirrored to another repo for that?)
- ‘work-in-progress’: Work in progress including discussion

## Folder structure, other resources in this repo

