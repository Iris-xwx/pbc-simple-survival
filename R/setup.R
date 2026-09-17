# ---------------------------------------------------------------------------
# setup.R -- packages, project paths, shared plotting theme
#
# Sourced by every analysis script and by the Quarto report. Keeps package
# loading and path resolution in one place so the analysis files stay readable.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(survival)     # Surv, coxph, survdiff, cox.zph, finegray
  library(gtsummary)    # tbl_summary, tbl_regression
  library(ggsurvfit)    # survfit2, ggsurvfit
  library(tidycmprsk)   # cuminc, ggcuminc, tbl_cuminc, crr
  library(ggplot2)
  library(dplyr)
})

# ---- project paths ---------------------------------------------------------
# Walk up from the working directory until we find the Quarto project file.
# This lets the report render from either the project root or analysis/.
proj_root <- function(start = ".") {
  p <- normalizePath(start)
  while (!file.exists(file.path(p, "_quarto.yml")) && dirname(p) != p) {
    p <- dirname(p)
  }
  p
}

PATH_ROOT <- proj_root()
PATH_DATA <- file.path(PATH_ROOT, "data")
PATH_FIGURES <- file.path(PATH_ROOT, "output", "figures")
PATH_TABLES <- file.path(PATH_ROOT, "output", "tables")

dir.create(PATH_FIGURES, recursive = TRUE, showWarnings = FALSE)
dir.create(PATH_TABLES,  recursive = TRUE, showWarnings = FALSE)


# ---- shared palette and theme ----------------------------------------------
PBC_COLORS <- c("D-penicillamine" = "#00468B",
                "Placebo"         = "#ED0000")

theme_pbc <- function(base_size = 14) {
  ggplot2::theme_classic(base_size = base_size, base_family = "serif")
}

# ---- output helpers --------------------------------------------------------
save_figure <- function(plot, filename, width = 8, height = 6, dpi = 300) {
  path <- file.path(PATH_FIGURES, filename)
  ggplot2::ggsave(path, plot = plot, width = width, height = height, dpi = dpi)
  invisible(path)
}

save_table <- function(tbl, filename) {
  path <- file.path(PATH_TABLES, filename)
  readr_write <- tryCatch(
    gtsummary::as_tibble(tbl),
    error = function(e) NULL
  )
  if (!is.null(readr_write)) utils::write.csv(readr_write, path, row.names = FALSE)
  invisible(path)
}

