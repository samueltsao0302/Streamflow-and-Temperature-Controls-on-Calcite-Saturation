#!/usr/bin/env Rscript
# --- Ensure packages are installed ---
user_lib <- "~/project/R/library"
if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
.libPaths(user_lib)

pkgs <- c("EGRET", "EGRETci", "ggplot2", "mgcv", "dplyr", "lattice")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org/")
  }
}


args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("Need to pass site_no")
site_no <- args[1]

library(EGRET)
library(EGRETci)
library(ggplot2)
library(mgcv)
library(dplyr)


# --- Paths ---

base_dir   <- "/home/st929/project/OMEGA_Drought_paper"
daily_dir  <- file.path(base_dir, "daily_Q_WRTDS")
sample_dir <- file.path(base_dir, "sample_WRTDS")
info_dir   <- file.path(base_dir, "info_WRTDS")
out_dir    <- file.path(base_dir, "output_WRTDS")
# collect log rows here

logs <- list()

# --- Chemistries to process ---

chems <- c("alk", "ca", "mg", "na", "ph","tds")



for (chem in chems) {
  cat("=== Processing chemistry:", chem, "===\n")

  # Input dirs for this chemistry
  chem_sample_dir <- file.path(sample_dir, paste0(chem, "_Sample"))
  chem_info_dir   <- file.path(info_dir, chem)

  # Output dirs for this chemistry
  chem_out_dir <- file.path(out_dir, chem)
  dir.create(chem_out_dir, showWarnings = FALSE)
  dir.create(file.path(chem_out_dir, "daily"),  showWarnings = FALSE)
  dir.create(file.path(chem_out_dir, "annual"), showWarnings = FALSE)
  dir.create(file.path(chem_out_dir, "plots"),  showWarnings = FALSE)



  # Site list from daily Q files

  daily_files <- list.files(daily_dir, pattern = "_Q.csv$", full.names = TRUE)



  sample_file <- file.path(chem_sample_dir, paste0(site_no, "_Sample.csv"))
  info_file   <- file.path(chem_info_dir,   paste0(site_no, "_INFO.csv"))

  log_row <- data.frame(
    site_no       = site_no,
    chem          = chem,
    unique_dates  = NA_integer_,
    na_Q          = NA_integer_,
    expected_rows = NA_integer_,
    actual_rows   = NA_integer_,
    model_status  = "not_run",
    r2            = NA_real_,
    rmse          = NA_real_,
    stringsAsFactors = FALSE
  )

    # --- Case 1: missing files ---
  if (!file.exists(sample_file) || !file.exists(info_file)) {
    cat("Skipping", site_no, "for", chem, "(missing Sample/Info)\n")
    log_row$model_status <- "missing_files"
    logs[[length(logs) + 1]] <- log_row
    next
  }
  
  cat("Processing site:", site_no, "for", chem, "\n")
    # --- Load Daily (qUnit = 2 for m³/s) ---
  Daily <- readUserDaily(daily_dir, paste0(site_no, "_Q.csv"), qUnit = 2)
   # Ensure all days exist but leave missing Q as NA
  fix_daily <- function(Daily) {
    # --- 2. Force correct types ---
    Daily$Date <- as.Date(Daily$Date)
    Daily$Q <- as.numeric(Daily$Q)
    # --- 3. Remove duplicates (keep first occurrence) ---
    Daily <- Daily[!duplicated(Daily$Date), ]
    # --- 4. Ensure full daily sequence (fill gaps with NA) ---
    all_days <- data.frame(Date = seq(min(Daily$Date), max(Daily$Date), by = "day"))
    Daily <- dplyr::right_join(Daily, all_days, by = "Date") %>%
      dplyr::arrange(Date)
    # --- 5. Final sanity checks ---
 #   stopifnot(nrow(Daily) == length(seq(min(Daily$Date), max(Daily$Date), by = "day")))
 #   stopifnot(length(unique(Daily$Date)) == nrow(Daily))
    expected <- as.integer(max(Daily$Date) - min(Daily$Date) + 1)
    message("Daily rows expected: ", expected)
    message("Daily rows actual:   ", nrow(Daily))
    message("Unique dates:        ", length(unique(Daily$Date)))
    message("NA discharge count:  ", sum(is.na(Daily$Q)))
    
    return(Daily)
  }
  Daily <- fix_daily(Daily)

    # --- Load Sample & INFO ---
  Sample <- readUserSample(chem_sample_dir, paste0(site_no, "_Sample.csv"), separator = ",")
  INFO   <- read.csv(info_file, stringsAsFactors = FALSE)
  INFO$shortName[is.na(INFO$shortName) | INFO$shortName == ""] <- site_no
  
  # --- Merge & run WRTDS ---
  eList <- tryCatch({
    mergeReport(INFO, Daily, Sample) |> modelEstimation()
  }, error = function(e) NULL)

  if (is.null(eList)) {
    cat("Model failed for", site_no, "chem", chem, "\n")
    log_row$model_status  <- "failed"
    log_row$unique_dates  <- length(unique(Daily$Date))
    log_row$na_Q          <- sum(is.na(Daily$Q))
    log_row$expected_rows <- as.integer(max(Daily$Date) - min(Daily$Date) + 1)
    log_row$actual_rows   <- nrow(Daily)
    logs[[length(logs) + 1]] <- log_row
    next
  }

    # --- Save Daily (includes ConcDay) ---

  write.csv(eList$Daily,
            file.path(chem_out_dir, "daily", paste0(site_no, "_Daily.csv")),
            row.names = FALSE)

    # --- Save Annual (concentration summaries only) ---
  annualResults <- makeAnnualSeries(eList)
  if (nrow(annualResults) > 0) {
    write.csv(annualResults,
              file.path(chem_out_dir, "annual", paste0(site_no, "_AnnualSeries.csv")),
              row.names = FALSE)
  }



    # --- Save Plots (concentration only) ---
  plot_dir <- file.path(chem_out_dir, "plots")

  png(file.path(plot_dir, paste0(site_no, "_ResidPred.png")), width = 1200, height = 800)
  plotResidPred(eList); dev.off()


  png(file.path(plot_dir, paste0(site_no, "_ResidQ.png")), width = 1200, height = 800)
  plotResidQ(eList); dev.off()

  png(file.path(plot_dir, paste0(site_no, "_ResidTime.png")), width = 1200, height = 800)
  plotResidTime(eList); dev.off()


  png(file.path(plot_dir, paste0(site_no, "_ConcTimeDaily.png")), width = 1200, height = 800)
  plotConcTimeDaily(eList, plotGenConc = FALSE); dev.off()


  png(file.path(plot_dir, paste0(site_no, "_ConcHist.png")), width = 1200, height = 800)
  plotConcHist(eList); dev.off()

  # --- Compute performance metrics (Sample vs Daily ConcDay) ---
  obs  <- eList$Sample$ConcAve
  dates_obs <- eList$Sample$Date
  pred <- eList$Daily$ConcDay[match(dates_obs, eList$Daily$Date)]

  # Print observed and predicted pairs

  cat("\n--- Debug output for site:", site_no, "chem:", chem, "---\n")
  print(head(data.frame(Date = dates_obs, Obs = obs, Pred = pred), 20))  # first 20 rows



  # Print Daily column names

  cat("\nColumns in eList$Daily:\n")
  print(colnames(eList$Daily))
  cat("\n--- End debug output ---\n")

  ok <- complete.cases(obs, pred)
  if (sum(ok) > 2) {
    log_row$r2   <- cor(obs[ok], pred[ok])^2
    log_row$rmse <- sqrt(mean((obs[ok] - pred[ok])^2))
  }

  log_row$model_status  <- "success"
  log_row$unique_dates  <- length(unique(Daily$Date))
  log_row$na_Q          <- sum(is.na(Daily$Q))
  log_row$expected_rows <- as.integer(max(Daily$Date) - min(Daily$Date) + 1)
  log_row$actual_rows   <- nrow(Daily)
  # --- Update log ---

  cat("✅ Finished site:", site_no, "for", chem, "\n")
  logs[[length(logs) + 1]] <- log_row
}
status_log <- do.call(rbind, logs)
log_file <- file.path(out_dir, "site_status.csv")

if (file.exists(log_file)) {
  old_log <- read.csv(log_file, stringsAsFactors = FALSE)
  status_log <- rbind(old_log, status_log)
}
write.csv(status_log, log_file, row.names = FALSE)



