# ---------------------------------------------------------------------------
# 01_prepare_data.R -- load raw PBC data and derive the analysis datasets
#
# Input : data/pbc.csv  (418 rows, 20 cols; 106 rows have no randomised arm)
# Output: pbc_cleaned, pbc_s1 (composite endpoint), pbc_s2 (competing risks)
#
# The raw dataset is the `survival::pbc` table in CSV form. It descends from a
# Mayo Clinic trial of D-penicillamine in primary biliary cholangitis (PBC).
# Only randomised patients (trt non-missing) enter the analysis: 312 of 418.
# ---------------------------------------------------------------------------

# Resolve the project root by walking up until we find _quarto.yml, so the
# module works whether it is sourced from the project root, from a
# subdirectory, or knitted by Quarto.
.local_root <- local({
  p <- normalizePath(".")
  while (!file.exists(file.path(p, "_quarto.yml")) && dirname(p) != p) p <- dirname(p)
  p
})
source(file.path(.local_root, "R", "setup.R"))

load_pbc <- function(path = file.path(PATH_DATA, "pbc.csv")) {
  read.csv(path, stringsAsFactors = FALSE)
}


# ---- factor labelling shared across analyses -------------------------------
# Keeping the labels in one function means every table and figure shows the
# same group names, in the same order.

label_trt <- function(x) {
  factor(x, levels = c(1, 2), labels = c("D-penicillamine", "Placebo"))
}

label_baseline <- function(dat) {
  dat |>
    dplyr::mutate(
      trt   = label_trt(trt),
      sex   = factor(sex, levels = c("m", "f"), labels = c("Male", "Female")),
      dplyr::across(
        .cols = c(ascites, hepato, spiders),
        .fns  = ~ factor(.x, levels = c(0, 1), labels = c("No", "Yes"))
      ),
      edema = factor(edema, levels = c(0, 0.5, 1),
                     labels = c("No edema", "Responsive to diuretics",
                                "Refractory edema")),
      stage = factor(stage, levels = c(1, 2, 3, 4),
                     labels = c("Stage 1", "Stage 2", "Stage 3", "Stage 4"))
    )
}

# ---- analysis cohort: randomized patients only -----------------------------
prepare_cohort <- function(dat = load_pbc()) {
  dat |>
    dplyr::filter(!is.na(trt)) |>
    label_baseline()
}


# ---- endpoint definitions --------------------------------------------------
# The raw `status` field has three levels: 0 censored, 1 transplant, 2 death.

## Situation 1: composite endpoint, transplant or death counted as one event.
prepare_s1 <- function(dat = load_pbc()) {
  prepare_cohort(dat) |>
    dplyr::mutate(status = ifelse(status == 0, 0, 1))
}

## Situation 2: competing risks, death and transplant kept distinct.
prepare_s2 <- function(dat = load_pbc()) {
  prepare_cohort(dat) |>
    dplyr::mutate(
      status = factor(status, levels = c(0, 2, 1),
                      labels = c("Censored", "Death", "Transplant")),
      protime_cat = factor(
        ifelse(protime >= 11, "Prolonged (>=11s)", "Normal (<11s)"),
        levels = c("Normal (<11s)", "Prolonged (>=11s)")
      )
    )
}







