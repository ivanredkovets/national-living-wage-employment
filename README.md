# UK National Living Wage and Employment

## Overview

This project examines the employment effects of the introduction of the UK National Living Wage (NLW), announced in July 2015 and introduced in April 2016 for workers aged 25 and over.

The analysis exploits differences in pre-policy exposure to the NLW across industries. Industries with a larger share of employees aged 25+ earning below the future £7.20 wage floor before its introduction were more strongly exposed to the reform.

Using quarterly industry-level employment data from 2012 to 2019, the project applies a continuous difference-in-differences framework and an event-study specification to examine whether employment evolved differently in industries with greater pre-policy exposure to the NLW.

## Research Question

Did the introduction of the UK National Living Wage affect employment differently across industries depending on their pre-policy exposure to the new wage floor?

## Data

The analysis combines two main datasets:

- Quarterly seasonally adjusted employee jobs by industry from the UK Office for National Statistics (ONS).
- Industry-level NLW exposure from ONS, measured as the share of employees aged 25+ paid below the future NLW before its introduction.

The main sample contains 19 SIC 2007 industry sections observed quarterly from 2012Q1 to 2019Q4, giving 608 industry-quarter observations.

## Empirical Strategy

The baseline specification uses a continuous difference-in-differences design, interacting pre-policy NLW exposure with an indicator for the post-reform period while controlling for industry and quarter fixed effects.

An event-study specification allows the relationship between exposure and employment to vary by quarter around the reform. This is used both to examine the dynamics of employment following the NLW and to assess whether differential employment trends were already present before its introduction.

Standard errors are clustered at the industry level.

## Repository Structure

- `data/raw/` — original ONS employment and NLW exposure data
- `data/processed/` — cleaned industry-quarter panel used in the analysis
- `R/` — data cleaning, descriptive analysis, causal models, event study and robustness scripts
- `figures/` — figures produced by the analysis
- `tables/` — regression and summary tables