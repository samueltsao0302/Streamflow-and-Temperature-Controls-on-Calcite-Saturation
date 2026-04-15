# Streamflow and Temperature Controls on Calcite Saturation (Ω) in River Systems

This repository contains code to reproduce the analysis and figures from:

**Tsao et al. (2026)** – *Streamflow and Temperature Controls on Calcite Saturation in River Systems*.


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
- Extract and process air temperature data
- Merge temperature and discharge data

### 2. WRTDS modeling (R)
- Estimate daily alkalinity concentration and using WRTDS

### 3. Calcite saturation (Ω) calculation and main analysis (Python)
- Compute Ω using water chemistry outputs
- Aggregate site-level results of percentage of time and alkalinity flux when Ω >10

