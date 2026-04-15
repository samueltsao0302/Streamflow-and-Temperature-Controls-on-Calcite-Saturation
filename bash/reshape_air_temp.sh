#!/bin/bash
#SBATCH -J merge_airtemp
#SBATCH -t 4:00:00
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH --output=merge_airtemp_%j.out
#SBATCH --error=merge_airtemp_%j.err

SITES=/home/st929/project/OMEGA_Drought_paper/sites_lonlat.csv
RAW=/home/st929/project/OMEGA_Drought_paper/airtemp_raw
OUT=/home/st929/project/OMEGA_Drought_paper/airtemp_all.csv
n_sites=$(wc -l < $SITES)
echo "Detected $n_sites sites"

echo "site_no,lon,lat,stream_date,tmin,tmax" > $OUT

for YEAR in $(seq 1915 2011); do
    echo "Processing $YEAR..."
    tmax=$RAW/tmax_${YEAR}_raw.txt
    tmin=$RAW/tmin_${YEAR}_raw.txt
    if [[ ! -s $tmax || ! -s $tmin ]]; then
        echo "Skipping $YEAR (missing raw files)"
        continue
    fi

    n_rows=$(wc -l < "$tmin")
    n_days=$(( n_rows / n_sites ))
    echo "  → $n_days days ($n_rows rows per site × $n_sites sites)"
    n_rows_tmax=$(wc -l < "$tmax")
    if [[ $n_rows_tmax -ne $n_rows ]]; then
        echo "⚠️ ERROR: mismatch between tmin ($n_rows) and tmax ($n_rows_tmax)"
        exit 1
    fi

    for ((d=0; d<n_days; d++)); do
        date -d "${YEAR}-01-01 +$d days" +%F
    done > tmp_days

    yes "$(cat tmp_days)" | tr ' ' '\n' | head -n $n_rows > tmp_all_days



    # Replicate the site info for each day
    awk -v n_days=$n_days '{ for (d=1; d<=n_days; d++) print $0 }' "$SITES" > tmp_sites



    # Combine everything: sites + dates + tmin + tmax

    paste -d',' tmp_sites tmp_all_days "$tmin" "$tmax" >> "$OUT"
    rm tmp_days tmp_all_days tmp_sites
    echo "  ✓ Finished $YEAR"

done


echo "✅ Done. Output written to $OUT"
