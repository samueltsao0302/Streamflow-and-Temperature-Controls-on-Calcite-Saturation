#!/bin/bash
#SBATCH -J wrtds_batch              # Job name
#SBATCH --mem=40G                   # Memory
#SBATCH -t 4:00:00                 # Runtime (8 hours)
#SBATCH -o logs/wrtds_batch_%j.out       # Standard output
#SBATCH -e logs/wrtds_batch_%j.err       # Standard error
#SBATCH --array=1-1381%50

# Load R
module reset

module load R/4.4.1-foss-2022b


SITE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /home/st929/project/OMEGA_Drought_paper/site_list_forWRTDS.txt)


Rscript /home/st929/project/OMEGA_Drought_paper/wrtds.R $SITE
