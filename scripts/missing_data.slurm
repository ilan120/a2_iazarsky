#!/bin/bash
#SBATCH --partition=Centaurus
#SBATCH --exclusive
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --nodes=1
#SBATCH --time=02:00:00

# Part A missing data
./out_a 1024 1024 1024 1 1 64
./out_a 1024 1024 1024 2 1 64
./out_a 1024 1024 1024 4 1 64
./out_a 1024 1024 1024 8 1 64
./out_a 1024 1024 1024 12 1 64
./out_a 1024 1024 1024 18 1 64
./out_a 1024 1024 1024 36 1 64

./out_a 2048 2048 2048 1 1 64
./out_a 2048 2048 2048 2 1 64
./out_a 2048 2048 2048 4 1 64
./out_a 2048 2048 2048 8 1 64
./out_a 2048 2048 2048 12 1 64
./out_a 2048 2048 2048 18 1 64
./out_a 2048 2048 2048 36 1 64

# Part B missing items
export OMP_PROC_BIND=true
export OMP_PLACES=cores

./out_b 1024 1024 1024 1 1 64
./out_b 1024 1024 1024 2 1 64
./out_b 1024 1024 1024 4 1 64
./out_b 1024 1024 1024 8 1 64
./out_b 1024 1024 1024 12 1 64
./out_b 1024 1024 1024 18 1 64
./out_b 1024 1024 1024 36 1 64

./out_b 2048 2048 2048 1 1 64
./out_b 2048 2048 2048 2 1 64
./out_b 2048 2048 2048 4 1 64
./out_b 2048 2048 2048 8 1 64
./out_b 2048 2048 2048 12 1 64
./out_b 2048 2048 2048 18 1 64
./out_b 2048 2048 2048 36 1 64
