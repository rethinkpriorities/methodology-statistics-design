# Server for RP and DR projects

1. Simulation and computation: Machine Learning, Bayesian, MonteCarlo

Occasional intense work

Jamie Elsley wants 'Bayesian workflow'

- Iterate model over data and effect sizes, run these in a chain
(Nick suggested efficiency gains

- Does this 'once in a while, not all the time'

- Wants 'occasional use of 12 hours of server time'

MCMC is processor intensive, most ML is processor intensive

We probably *don't* need 'GPU intensive massively parallel' stuff, Stan doesn't use it, Python does but ee probably wont
We are probably not neural-network deep leaning

For this work suggests an EC2 'compute instance' ...
Maybe C4 or C3

- you get your *own* Ubuntu (?) or Mac server

'Minute billing' -- you can sign up indefinitely and cancel when you are done

?? Need some ballpark numbers ... Oska is looking into it


2. API pulls, bots, and scraping: Low complexity low intensity ongoing runs

- Relevant for field experiments
- and possibly collecting data for other project

Considering EC2-T2

Can have it 'on all the time' ... costs about $150 per month for 8 cores 32 gb Ram.
with 81 CPU credits per hour -- each core at 100% for 10 minutes







