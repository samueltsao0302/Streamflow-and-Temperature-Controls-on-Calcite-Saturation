#!/bin/bash
#SBATCH -J calculate_omega

#SBATCH --mem=10G

#SBATCH -t 24:00:00

#SBATCH --output=omega_%j.txt

#SBATCH --error=omega_%j.txt

#SBATCH -c 40 # Request 4 CPUs

module load miniconda

conda activate my_env

python -u calculate_daily_omega_opencondition.py 
