import PyCO2SYS as pyco2

import pandas as pd

import numpy as np



# --- Load data ---

merged_with_q = pd.read_csv(
    "/home/st929/Shuang_Project_backup_from_projectfolder/merged_with_flow_quantile_min1.csv",
    index_col=False
)

opt_pH_scale = 4  # NBS scale for freshwater



# --- Prepare result lists ---

omega_calcite_vals   = []

omega_aragonite_vals = []

k_calcite_vals       = []

k_aragonite_vals     = []

pco2_vals            = []

co3_vals             = []

dic_vals             = []

ph25_vals            = []

pco225_vals          = []

omega_calcite25_vals   = []

omega_aragonite25_vals = []

total_rows = len(merged_with_q)



# --- Loop over rows ---

for i, (idx, row) in enumerate(merged_with_q.iterrows(), start=1):
    try:
        alk_uM = row["alk"] * 1e6 if pd.notna(row["alk"]) else np.nan
        ca_uM  = row["ca"]  * 1e6 if pd.notna(row["ca"])  else np.nan
        temp_C = row["temp"]
        salinity = row["tds"] / 1000.0 if pd.notna(row["tds"]) else np.nan  # mg/L → g/L ≈ PSU
        # Convert [H+] to pH
        pH_val = -np.log10(row["pH"]) if (pd.notna(row["pH"]) and row["pH"] > 0) else np.nan
        if any(np.isnan(x) for x in [alk_uM, ca_uM, salinity, temp_C, pH_val]):
            omega_calcite_vals.append(np.nan)
            omega_aragonite_vals.append(np.nan)
            k_calcite_vals.append(np.nan)
            k_aragonite_vals.append(np.nan)
            pco2_vals.append(np.nan)
            co3_vals.append(np.nan)
            dic_vals.append(np.nan)
            ph25_vals.append(np.nan)
            pco225_vals.append(np.nan)
            omega_calcite25_vals.append(np.nan)
            omega_aragonite25_vals.append(np.nan)
            continue
        # --- Step 1: Run PyCO2SYS at in-situ T using TA + pH ---
        results = pyco2.sys(
            par1=alk_uM,
            par2=pH_val,
            par1_type=1,  # total alkalinity
            par2_type=3,  # pH
            salinity=salinity,
            temperature=temp_C,
            pressure=0,
            total_calcium=ca_uM,
            opt_pH_scale=opt_pH_scale,
            opt_k_carbonic=15
        )

        omega_calcite_vals.append(results["saturation_calcite"])
        omega_aragonite_vals.append(results["saturation_aragonite"])
        k_calcite_vals.append(float(results["k_calcite"]))       # convert array → float
        k_aragonite_vals.append(float(results["k_aragonite"]))   # convert array → float
        pco2_vals.append(results["pCO2"])
        co3_vals.append(results["CO3"])
        dic_vals.append(results["dic"])
        dic = results["dic"]



        # --- Step 2: Re-run at 25 °C using TA + DIC ---

        results25 = pyco2.sys(
            par1=alk_uM,
            par2=dic,
            par1_type=1,  # total alkalinity
            par2_type=2,  # DIC
            salinity=salinity,
            temperature=25,
            pressure=0,
            total_calcium=ca_uM,
            opt_pH_scale=opt_pH_scale,
            opt_k_carbonic=15

        )
        ph25_vals.append(results25["pH"])
        pco225_vals.append(results25["pCO2"])
        omega_calcite25_vals.append(results25["saturation_calcite"])
        omega_aragonite25_vals.append(results25["saturation_aragonite"])
    except Exception as e:
        print(f"❌ Error at row {i}, site {row.get('site_no','NA')} date {row.get('stream_date','NA')}: {e}")
        omega_calcite_vals.append(np.nan)
        omega_aragonite_vals.append(np.nan)
        k_calcite_vals.append(np.nan)
        k_aragonite_vals.append(np.nan)
        pco2_vals.append(np.nan)
        co3_vals.append(np.nan)
        dic_vals.append(np.nan)
        ph25_vals.append(np.nan)
        pco225_vals.append(np.nan)
        omega_calcite25_vals.append(np.nan)
        omega_aragonite25_vals.append(np.nan)
    # Progress printing
    if i % 50 == 0 or i == total_rows:
        print(f"Processed {i}/{total_rows} rows ({i/total_rows:.1%})")



# --- Assign new columns ---
merged_with_q["omega_calcite"]   = omega_calcite_vals
merged_with_q["omega_aragonite"] = omega_aragonite_vals
merged_with_q["Ksp_calcite"]     = k_calcite_vals
merged_with_q["Ksp_aragonite"]   = k_aragonite_vals
merged_with_q["pCO2"]            = pco2_vals
merged_with_q["CO3"]             = co3_vals
merged_with_q["DIC"]             = dic_vals
merged_with_q["pH_25C"]          = ph25_vals
merged_with_q["pCO2_25C"]        = pco225_vals
merged_with_q["omega_calcite_25C"]   = omega_calcite25_vals
merged_with_q["omega_aragonite_25C"] = omega_aragonite25_vals


# --- Save ---

out_path = "/home/st929/Shuang_Project_backup_from_projectfolder/merged_with_q_with_carbonate_params.csv"
merged_with_q.to_csv(out_path, index=False)
print(f"✅ Finished — saved with carbonate parameters: {merged_with_q.shape}, file: {out_path}")


