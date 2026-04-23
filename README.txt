# Streamflow and Temperature Controls on Calcite Saturation (Ω) in River Systems

This repository contains code to reproduce the analysis and figures from:

**Tsao et al. (2026)** – *Streamflow and Temperature Controls on Calcite Saturation in River Systems*. (manuscript under review)


## 📊 Data Sources

All data used in this study are publicly available:

- **USGS National Water Information System (NWIS)**  
  https://waterdata.usgs.gov/

- **Air temperature data (Livneh dataset)**
https://psl.noaa.gov/data/gridded/data.livneh.html

Due to file size limitations, raw and intermediate datasets are not included in this repository.

---

## 🔄 Workflow Overview

The analysis pipeline consists of three main stages:

### 1. Data preprocessing (bash)
extract_air_temp_livneh.sh 
- Extract the pixel value from daily air temperature nc files downloaded


merge_reshape_air_temp.sh
- merge the extracted daily air temperature values

cut_air_temp_file.sh
- cut only the sites which will be needed in our analysis

stream_temp_discharge_awk.sh
- merge the daily stream temperature and discharge data for later analysis.


### 2. WRTDS modeling (R)
- Estimate daily alkalinity concentration and flux using WRTDS. 
wrtds.R
run_wrtds.sh (this is the code that execute the R code)


### 3. Calcite saturation (Ω) calculation and main analysis (Python)
- Compute daily Ω using water chemistry outputs 
calculate_daily_omega.py
run_calculate_daily_omega.sh (this is the code that execute the python code)

- Aggregate site-level results of percentage of time and alkalinity flux when Ω >10
omega_file_io.ipynb  (this notebook takes care of the file IO, reads all the raw files)
omega_analysis.ipynb  (this notebook conduct tha main analysis and produce figures in the manuscript)
 
