#!/bin/bash
#SBATCH -J airtemp_extract
#SBATCH --mem=16G
#SBATCH -t 2:00:00
#SBATCH --output=logs/airtemp_%A_%a.out
#SBATCH --error=logs/airtemp_%A_%a.err
#SBATCH -c 8
#SBATCH --array=1915-2011%5

source ~/bin/gdal3

# Go to project directory
#cd /home/st929/project/Shuang_Project
#awk -F',' 'NR>1 {print $1","$3","$4}' discharge_temp_filtered.csv \
#  | sort -u > sites_lonlat.csv
##

YEAR=$SLURM_ARRAY_TASK_ID
BASE=/home/st929/project/OMEGA_Drought_paper/livneh
OUTDIR=/home/st929/project/OMEGA_Drought_paper/airtemp_yearly
RAW=/home/st929/project/OMEGA_Drought_paper/airtemp_raw

mkdir -p $OUTDIR
mkdir -p $OUTDIR logs
mkdir -p $RAW

#awk -F',' '{
#  lon=$2
#  if (lon<0) lon=lon+360
#  print lon,$3
#}' /home/st929/project/OMEGA_Drought_paper/sites_lonlat.csv \
#  > /home/st929/project/OMEGA_Drought_paper/sites_lonlat_360.csv

SITES=/home/st929/project/OMEGA_Drought_paper/sites_lonlat_360.csv

echo "Processing year $YEAR ..."
gdallocationinfo -wgs84 -valonly -geoloc \
  NETCDF:"$BASE/tmax/tmax.${YEAR}.nc":tmax \
  < $SITES > $RAW/tmax_${YEAR}_raw.txt

gdallocationinfo -wgs84 -valonly -geoloc \
  NETCDF:"$BASE/tmin/tmin.${YEAR}.nc":tmin \
  < $SITES > $RAW/tmin_${YEAR}_raw.txt



