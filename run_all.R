# ---------------------------------------------------------------------------
# run_all.R -- run every analysis and write all figures and tables to output/
# ---------------------------------------------------------------------------

source("R/setup.R")
source("R/01_prepare_data.R")
source("R/02_baseline_table.R")
source("R/03_km_composite.R")
source("R/04_competing_risks.R")
source("R/05_cox_models.R")

message("Building baseline table ...")
save_table(make_baseline_table(prepare_cohort()), "table1_baseline.csv")

message("Building Kaplan-Meier figure ...")
save_figure(make_km_plot(prepare_s1()), "km_composite.png", width = 9, height = 6)

message("Building cumulative incidence figure ...")
save_figure(make_cuminc_plot(prepare_s2()), "cuminc_death.png", width = 9, height = 6)
save_table(make_cuminc_table(prepare_s2()), "cuminc_5yr.csv")

message("Fitting Cox models ...")
save_table(format_cox_table(fit_cox_unadjusted(prepare_s1())), "cox_unadjusted.csv")
save_table(format_cox_table(fit_cox_multi_linear(prepare_s1())), "cox_multi_linear.csv")

s1_strat <- add_protime_cat(prepare_s1())
cox_strat <- fit_cox_multi_stratified(s1_strat)
save_table(format_cox_table(cox_strat), "cox_stratified.csv")

# Proportional-hazards diagnostics, written as a figure for the record.
png(file.path(PATH_FIGURES, "ph_diagnostics.png"),
    width = 1400, height = 1000, res = 130)
ph_plot(ph_test(cox_strat), base_size = 12)
dev.off()

message("Fitting Fine-Gray model ...")
fg_fit <- fit_fine_gray(prepare_s2())
save_table(format_cox_table(fg_fit, header = "**sHR**"), "fine_gray.csv")

message("Done. Figures in output/figures/, tables in output/tables/.")
