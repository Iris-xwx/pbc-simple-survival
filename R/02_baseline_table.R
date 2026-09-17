# ---------------------------------------------------------------------------
# 02_baseline_table.R -- Table 1: baseline characteristics by treatment arm
#
# Produces the standard "Table 1" for the randomised cohort, with an overall
# column, a between-arm p-value, and a Benjamini-Hochberg q-value to account
# for the number of tests performed.
# ---------------------------------------------------------------------------

.local_root <- local({
  p <- normalizePath(".")
  while (!file.exists(file.path(p, "_quarto.yml")) && dirname(p) != p) p <- dirname(p)
  p
})
source(file.path(.local_root, "R", "setup.R"))
source(file.path(.local_root, "R", "01_prepare_data.R"))

# Continuous variables measured on a roughly symmetric scale are summarised as
# mean (SD) and tested with t-tests; right-skewed laboratory values are
# summarised as median [IQR] and tested with Wilcoxon rank-sum tests.
NORMAL_SCALE_VARS   <- c("age", "albumin", "chol")
SKEWED_SCALE_VARS   <- c("bili", "copper", "alk.phos", "ast", "trig",
                         "platelet", "protime")
BINARY_VARS         <- c("sex", "ascites", "hepato", "spiders")

make_baseline_table <- function(dat = prepare_cohort()) {
  dat |>
    dplyr::select(-c(id, time, status)) |>
    gtsummary::tbl_summary(
      by           = trt,
      missing_text = "Missing (N/A)",
      type         = list(c(sex, ascites, hepato, spiders) ~ "categorical"),
      statistic    = list(
        all_continuous()  ~ "{mean} ({sd})",
        all_categorical() ~ "{n} ({p}%)",
        dplyr::all_of(NORMAL_SCALE_VARS) ~ "{mean} ({sd})",
        dplyr::all_of(SKEWED_SCALE_VARS) ~ "{median} [{p25}, {p75}]"
      ),
      label = list(
        age      ~ "Age (years)",
        bili     ~ "Serum Bilirubin (mg/dl)",
        alk.phos ~ "Alkaline Phosphatase (U/L)",
        protime  ~ "Prothrombin Time (s)"
      ),
      digits = all_continuous() ~ 2
    ) |>
    gtsummary::add_overall() |>
    # Test choice follows the summary statistic: parametric summary -> t-test,
    # rank summary -> Wilcoxon. Categorical tests omitted by default because
    # several cells are sparse; add chisq/fisher tests if reviewers ask.
    gtsummary::add_p(
      test = list(
        dplyr::all_of(NORMAL_SCALE_VARS) ~ "t.test",
        dplyr::all_of(SKEWED_SCALE_VARS) ~ "wilcox.test"
      ),
      pvalue_fun = ~ gtsummary::style_pvalue(.x, digits = 3)
    ) |>
    gtsummary::add_q() |>
    gtsummary::bold_p(t = 0.05) |>
    gtsummary::bold_labels()
}











