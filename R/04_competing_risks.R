# ---------------------------------------------------------------------------
# 04_competing_risks.R -- cumulative incidence of death treating transplant
#                        as a competing event
#
# Endpoint: death (event of interest), transplant (competing event),
#           censoring.
# Question: does D-penicillamine change the cause-specific risk of death?
#
# The composite analysis in 03_km_composite.R treats transplant and death as
# interchangeable. They are not: transplant is arguably a *good* outcome for
# the patient, so a treatment that increases transplant access would look
# harmful on the composite scale. Competing-risks methods separate the two.
# ---------------------------------------------------------------------------

.local_root <- local({
  p <- normalizePath(".")
  while (!file.exists(file.path(p, "_quarto.yml")) && dirname(p) != p) p <- dirname(p)
  p
})
source(file.path(.local_root, "R", "setup.R"))
source(file.path(.local_root, "R", "01_prepare_data.R"))

# 5 years in days (using 365.25 to respect leap years)
HORIZON_DAYS <- 1826.25

# ---- cumulative incidence curves -------------------------------------------
make_cuminc_plot <- function(dat = prepare_s2()) {
  tidycmprsk::cuminc(survival::Surv(time, status) ~ trt, data = dat) |>
    ggsurvfit::ggcuminc(outcome = "Death", linewidth = 1.2) +
    ggsurvfit::add_confidence_interval() +
    ggsurvfit::add_risktable() +
    ggplot2::scale_color_manual(values = PBC_COLORS) +
    ggplot2::scale_fill_manual(values = PBC_COLORS) +
    ggplot2::labs(
      x     = "Follow-up Time (Days)",
      y     = "Cumulative Incidence of Death",
      color = "Treatment",
      fill  = "Treatment"
    ) +
    theme_pbc(base_size = 14)
}

# ---- Gray's test and 5-year cumulative incidence ---------------------------
# Gray's test is the competing-risks analogue of the log-rank test and is what
# tbl_cuminc reports. It must be used instead of survdiff here.
make_cuminc_table <- function(dat = prepare_s2()) {
  tidycmprsk::cuminc(survival::Surv(time, status) ~ trt, data = dat) |>
    tidycmprsk::tbl_cuminc(
      times         = HORIZON_DAYS,
      label_header  = "**{time/365.25}-year cumulative incidence**",
      outcomes      = "Death"
    ) |>
    gtsummary::add_n() |>
    gtsummary::add_p(pvalue_fun = \(x) gtsummary::style_pvalue(x, digits = 3)) |>
    gtsummary::bold_p(t = 0.05)
}




























