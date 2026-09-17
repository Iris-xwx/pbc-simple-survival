# D-penicillamine in Primary Biliary Cholangitis: a survival and competing-risks re-analysis

A reproducible analysis of the Mayo Clinic randomised trial of D-penicillamine
in primary biliary cholangitis (PBC), built around a question the original
single-endpoint analyses cannot answer: once liver transplant and death are
treated as distinct outcomes rather than a single composite event, does the
treatment change the cause-specific risk of death?

The project demonstrates an end-to-end survival analysis workflow in R —
baseline characterisation, Kaplan-Meier estimation, competing-risks cumulative
incidence, Cox proportional hazards modelling with assumption diagnostics, and
a Fine-Gray subdistribution model — and is structured so that the whole report
renders from raw data with one command.

## Report

The rendered report is [`docs/report.html`](docs/report.html). It walks through
every step with the reasoning behind each modelling choice, not just the output.

## Data

`data/pbc.csv` is the public `survival::pbc` dataset (Mayo Clinic, 1974–1984),
418 patients with 20 variables. `trt` is missing for 106 patients who were
followed observationally but not randomised; every analysis here is restricted
to the **312 randomised patients**, which is the population a treatment effect
can be estimated in.

The endpoint field `status` has three levels — 0 censored, 1 transplant, 2
death — and the entire report turns on how those three levels are combined.
Collapsing them gives transplant-free survival; keeping them apart gives a
competing-risks analysis where transplant competes with death.

## Structure

```
pbc-survival-rwe/
├── _quarto.yml                  # render configuration
├── data/
│   └── pbc.csv                  # raw data (survival::pbc)
├── R/
│   ├── setup.R                  # packages, paths, shared theme
│   ├── 01_prepare_data.R        # cohort construction and endpoint definitions
│   ├── 02_baseline_table.R      # Table 1
│   ├── 03_km_composite.R        # Kaplan-Meier, composite endpoint
│   ├── 04_competing_risks.R     # cumulative incidence, Gray's test
│   └── 05_cox_models.R          # Cox models, PH diagnostics, Fine-Gray
├── analysis/
│   └── report.qmd               # the report itself
├── output/
│   ├── figures/                 # rendered plots (png)
│   └── tables/                  # rendered tables (csv)
├── docs/
│   └── report.html              # rendered report (GitHub Pages)
└── legacy_pbc_analysis.R        # original single-file script, kept for reference
```

The analysis logic lives in `R/` as small functions, one file per topic.
`analysis/report.qmd` only calls those functions and explains the results, so
the same code can be re-run interactively or rendered as the report without
duplication.

## Requirements

R (≥ 4.2) with:

```r
install.packages(c(
  "survival",     # Surv, coxph, survdiff, cox.zph, finegray
  "gtsummary",    # tbl_summary, tbl_regression
  "ggsurvfit",    # survfit2, ggsurvfit, ggcuminc
  "tidycmprsk",   # cuminc, tbl_cuminc, crr
  "ggplot2", "dplyr",
  "car", "parameters", "broom.helpers", "aod"   # gtsummary::add_global_p() deps
))
```

and [Quarto](https://quarto.org) (≥ 1.4) to render the report.

`car`, `parameters` and `aod` are not used directly — they back
`gtsummary::add_global_p()`, which needs `car` for the Wald test on the Cox
models and `aod` for the global test on the Fine-Gray model. If any is missing,
`format_cox_table()` degrades gracefully and emits the table without the global
p-value rather than failing.

## Usage

Render the full report:

```bash
quarto render
```

Or run a single analysis section interactively, from the project root:

```r
source("R/01_prepare_data.R")
source("R/02_baseline_table.R")
make_baseline_table()
```

Figures and tables are written to `output/` on each render.

## Methods

Baseline continuous variables are summarised as mean (SD) or median [IQR]
according to their distribution and tested with t-tests or Wilcoxon rank-sum
tests respectively; p-values are accompanied by Benjamini–Hochberg q-values.

For survival, the analysis proceeds on two endpoints. The composite endpoint
(transplant or death) is analysed with Kaplan-Meier curves and a log-rank test,
then a Cox model adjusted for the classical PBC prognostic factors (age,
bilirubin, prothrombin time). The proportional hazards assumption is tested
with Schoenfeld residuals; where it fails, covariates are log-transformed, and
prothrombin time — which fails even after transformation — is used as a
stratification factor. The competing-risks endpoint (death, with transplant as
the competing event) is analysed with cumulative incidence curves, Gray's test,
and a Fine-Gray subdistribution model.

## Limitations

This is a methodological re-analysis of a small historical trial for
illustration, not a new clinical result. The cohort is small (312 patients) and
follow-up long, so adjusted estimates carry wide confidence intervals.
Prothrombin time is dichotomised at 11 s to enable stratification — clinically
motivated, but it discards information a continuous or time-varying
specification would retain.

## License

MIT — see [LICENSE](LICENSE). The PBC dataset is distributed with the R
`survival` package by Terry Therneau and is used here under its own terms.
