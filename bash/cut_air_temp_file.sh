#!/bin/bash

#SBATCH -J split_airtemp        # Job name

#SBATCH --mem=8G                # Memory

#SBATCH -t 05:00:00             # Runtime (2 hours)

#SBATCH -o logs/split_airtemp_%j.out   # Standard output

#SBATCH -e logs/split_airtemp_%j.err   # Standard error

#SBATCH -p day              # Partition (adjust to your cluster)

#SBATCH -n 1                    # Number of tasks




bigfile="airtemp_all.csv"

sitelist="site_list_forWRTDS.txt"

outdir="daily_airtemp_output"



mkdir -p "$outdir"



# Extract header once

header=$(head -n 1 "$bigfile")



# Loop over each site

while read -r site; do

    echo "Processing $site ..."

    out="$outdir/${site}_airtemp.csv"



    # Write header

    echo "$header" > "$out"



    # Append matching rows (site_no is first column, so use ^site, for exact match)

    grep "^$site," "$bigfile" >> "$out"

done < "$sitelist"


