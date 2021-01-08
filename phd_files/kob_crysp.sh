#! /bin/bash
#SBATCH --job-name=kob_crysp
#SBATCH --time=05:00:00
#SBATCH -N 1
#SBATCH -n 16
#SBATCH -o kob_crysp.out
#SBATCH -e kob_crysp.err
#SBATCH --oversubscribe



module load gnu/7.4.0
module load openmpi/gcc/4.0.1
export LD_LIBRARY_PATH=/export/usr/lib64:$LD_LIBRARY_PATH
mpirun -np 16 /home/gnanasbr/temp_projects/uehara/uehara-opt -i /home/gnanasbr/temp_projects/uehara/kob_crysp.i -malloc_dump  --mca orte_base_help_aggregate 0

