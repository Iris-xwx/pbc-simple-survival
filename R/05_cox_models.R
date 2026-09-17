# ---------------------------------------------------------------------------
# 05_cox_models.R -- Cox PH models, assumption diagnostics, and the
#                    Fine-Gray subdistribution model
#
# Analysis path, mirroring the decisions a reviewer would expect:
#   1. Unadjusted Cox for the composite endpoint.
#   2. Multivariable Cox with the classical PBC prognostic factors.
#   3. Check proportional hazards; if violated, transform or stratify.
#   4. Fine-Gray subdistribution model for the competing-risks endpoint.
#
# The PBC prognostic factors (age, bilirubin, prothrombin time) follow the
# Mayo risk score literature for primary biliary cholangitis; log transforms
# are used where the linearity of the log-hazard is not supported.
# ---------------------------------------------------------------------------

.local_root <- local({
  p <- normalizePath(".")
  while (!file.exists(file.path(p, "_quarto.yml")) && dirname(p) != p) p <- dirname(p)
  p
})
source(file.path(.local_root, "R", "setup.R"))
source(file.path(.local_root, "R", "01_prepare_data.R"))

# Continuous covariates on a multiplicative scale enter the model logged,
# because survival is expected to vary multiplicatively with them.
COVARS_MULTIPLICATIVE <- c("age", "bili", "protime")

# ---------------------------------------------------------------------------
# Situation 1: composite endpoint (transplant or death)
# ---------------------------------------------------------------------------

## Unadjusted: treatment effect alone.
fit_cox_unadjusted <- function(dat = prepare_s1()) {
  survival::coxph(survival::Surv(time, status) ~ trt, data = dat)
}

## Multivariable, linear covariates -- the starting point before any
## transformation. Kept so the PH diagnostics below have something to compare.
fit_cox_multi_linear <- function(dat = prepare_s1()) {
  survival::coxph(
    survival::Surv(time, status) ~ trt + age + bili + protime,
    data = dat
  )
}

## Multivariable with log-transformed lab values. `protime` is dichotomised
## and used as a stratification factor instead, because log-protime still
## violates PH (see the report's diagnostics section).
fit_cox_multi_stratified <- function(dat = prepare_s1()) {
  survival::coxph(
    survival::Surv(time, status) ~ trt + age + log(bili) + strata(protime_cat),
    data = dat
  )
}

# `prepare_s1()` does not carry protime_cat (only s2 does), so add it here in
# one place rather than duplicating the ifelse in each fit function.
add_protime_cat <- function(dat) {
  if (!"protime_cat" %in% names(dat)) {
    dat <- dat |>
      dplyr::mutate(
        protime_cat = factor(
          ifelse(protime >= 11, "Prolonged (>=11s)", "Normal (<11s)"),
          levels = c("Normal (<11s)", "Prolonged (>=11s)")
        )
      )
  }
  dat
}

# ---------------------------------------------------------------------------
# PH assumption diagnostics
# ---------------------------------------------------------------------------

#' Schoenfeld residual test for proportional hazards.
#' A significant p-value means the hazard ratio is not constant over time and
#' the model's HR should not be reported as a single number.
ph_test <- function(fit) survival::cox.zph(fit)

#' Schoenfeld residual plot, one panel per covariate.
#'
#' Uses the base plot method for `cox.zph` objects, which adds a smoothing
#' curve and a horizontal reference line; a systematic trend away from the
#' horizontal line is what indicates a time-varying hazard ratio.
ph_plot <- function(ph, base_size = 12) {
  old <- par(family = "serif", cex = base_size / 14)
  on.exit(par(old), add = TRUE)
  plot(ph)
}

# ---------------------------------------------------------------------------
# Situation 2: competing-risks endpoint (death, transplant = competing)
# ---------------------------------------------------------------------------

## Fine-Gray subdistribution hazard model. `crr` gives the subdistribution
## hazard ratios directly; `fg_cox_fit` is the equivalent weighted-Cox
## representation, kept only because it supports cox.zph() diagnostics (crr
## objects have no built-in PH test).
fit_fine_gray <- function(dat = prepare_s2()) {
  tidycmprsk::crr(
    survival::Surv(time, status) ~ trt + age + log(bili) + strata(protime_cat),
    data = dat
  )
}

fit_fine_gray_cox <- function(dat = prepare_s2()) {
  fg <- survival::finegray(survival::Surv(time, status) ~ ., data = dat)
  survival::coxph(
    survival::Surv(fgstart, fgstop, fgstatus) ~ trt + age + log(bili) +
      strata(protime_cat),
    weight = fgwt,
    data   = fg,
    id     = id
  )
}

# ---- regression table formatting -------------------------------------------
# One shared formatter so every Cox/Fine-Gray table renders identically:
# exponentiated estimates (HR / sHR), 2 decimals, 3-decimal p-values.
format_cox_table <- function(fit, caption = NULL, header = "**HR**") {
  terms <- names(stats::coef(fit))
  labels <- if ("log(bili)" %in% terms) {
    list(`log(bili)` ~ "Log(Serum Bilirubin)")
  } else {
    NULL
  }
  tbl <- fit |>
    gtsummary::tbl_regression(
      exp          = TRUE,
      estimate_fun = \(x) gtsummary::style_ratio(x, digits = 2),
      pvalue_fun   = \(x) gtsummary::style_pvalue(x, digits = 3),
      label        = labels
    ) |>
    gtsummary::modify_header(estimate ~ header) |>
    gtsummary::bold_labels()
  
  tbl <- tryCatch(
    gtsummary::add_global_p(tbl),
    error = function(e) {
      message("add_global_p() not available for this model: ",
              conditionMessage(e))
      tbl
    }
  )
  tbl <- gtsummary::bold_p(tbl, t = 0.05)
  if (!is.null(caption)) tbl <- gtsummary::modify_caption(tbl, caption)
  tbl
}
