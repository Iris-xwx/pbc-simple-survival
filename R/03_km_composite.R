# ---------------------------------------------------------------------------
# 03_km_composite.R -- Kaplan-Meier analysis of the composite endpoint
#
# Endpoint: transplant-free survival (transplant or death = event).
# Question: does D-penicillamine delay the first unfavourable event relative
#           to placebo?
# ---------------------------------------------------------------------------

.local_root <- local({
  p <- normalizePath(".")
  while (!file.exists(file.path(p, "_quarto.yml")) && dirname(p) != p) p <- dirname(p)
  p
})
source(file.path(.local_root, "R", "setup.R"))
source(file.path(.local_root, "R", "01_prepare_data.R"))

# ---- Kaplan-Meier curves ---------------------------------------------------
make_km_plot <- function(dat = prepare_s1()) {
  ggsurvfit::survfit2(survival::Surv(time, status) ~ trt, data = dat) |>
    ggsurvfit::ggsurvfit(linewidth = 1.2) +
    ggsurvfit::add_confidence_interval() +
    ggsurvfit::add_risktable() +
    ggsurvfit::add_pvalue(
      caption  = "Log-rank {p.value}",
      size     = 4.5,
      location = "annotation",
      x        = 1000,
      y        = 0.1
    ) +
    ggplot2::scale_color_manual(values = PBC_COLORS) +
    ggplot2::scale_fill_manual(values = PBC_COLORS) +
    ggplot2::labs(
      x     = "Follow-up Time (Days)",
      y     = "Transplant-free Survival Probability"
    ) +
    theme_pbc(base_size = 14)
}

# ---- log-rank test ---------------------------------------------------------
# Returns the survdiff object; the report prints it and reads off the p-value.
run_logrank <- function(dat = prepare_s1()) {
  survival::survdiff(survival::Surv(time, status) ~ trt, data = dat)
}

