#!/bin/bash
#SBATCH --job-name=a2_mm
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=36
#SBATCH --exclusive
#SBATCH --time=02:00:00
#SBATCH --output=a2_%j.out
##SBATCH --partition=FILL_ME_IN      # copy the partition line from your Assignment 1 script, remove one '#'

# ITCS 4145 Assignment 2: every measurement of Part A and Part B in one job.
# Submit from the project root:   sbatch scripts/run_all.slurm
# Build both programs on the cluster first (g++ -O2 -pthread / g++ -O2 -fopenmp).

# ---- edit these two paths to match your layout ----
A=${A:-./src/partA/mm_a}        # Part A binary (pthreads)
B=${B:-./src/partB/mm_b}        # Part B binary (OpenMP)
# ---------------------------------------------------
OUT=${OUT:-data}
BIG=${BIG:-2048}                # overridable only so the script can be dry-run on small sizes
SMALL=${SMALL:-1024}

for bin in "$A" "$B"; do
    [ -x "$bin" ] || { echo "ERROR: binary not found or not executable: $bin"; exit 1; }
done
mkdir -p "$OUT"

# Required for Part B (ignored by the pthreads program)
export OMP_PROC_BIND=true
export OMP_PLACES=cores

# Node type and compiler version, both required in the report
{ date; hostname; g++ --version | head -1; lscpu; } > "$OUT/node_info.txt" 2>&1

# run <binary> <output file> M K N pr pc b
run() {
    local bin=$1 out=$2; shift 2
    echo "### $bin $*" >> "$out"
    "$bin" "$@" >> "$out" 2>&1 || echo "### FAILED (exit $?): $bin $*" | tee -a "$out"
}

# ---------- Part A, item 1: tile sweep (sequential) ----------
for b in 0 16 32 64 128 256; do
    run "$A" "$OUT/A1_tile_sweep.txt" $BIG $BIG $BIG 0 0 $b
done
run "$A" "$OUT/A1_tile_sweep.txt" $SMALL $SMALL $SMALL 0 0 0

# b* = tile size (b > 0) with the smallest median at the big size
BSTAR=$(awk -F'[= ]' -v big="$BIG" '
    /^M=/      { m = $2 }
    /^grid=/   { b = $NF }
    /^median=/ { if (m == big && b > 0 && (best == "" || $2 + 0 < best + 0)) { best = $2; bs = b } }
    END        { print bs }' "$OUT/A1_tile_sweep.txt")
[ -n "$BSTAR" ] || { echo "ERROR: could not determine b* from $OUT/A1_tile_sweep.txt"; exit 1; }
echo "b* = $BSTAR" | tee "$OUT/bstar.txt"

# ---------- Part B: its own sequential baselines ----------
for s in $SMALL $BIG; do
    for b in 0 $BSTAR; do
        run "$B" "$OUT/B0_baselines.txt" $s $s $s 0 0 $b
    done
done

# ---------- Items 2 to 4, identical for both parts ----------
for part in A B; do
    if [ $part = A ]; then bin=$A; else bin=$B; fi

    # item 2: one-dimensional partition (grid p x 1), b = 0 and b = b*
    for s in $SMALL $BIG; do
        for p in 1 2 4 8 12 18 36; do
            for b in 0 $BSTAR; do
                run "$bin" "$OUT/${part}2_1d.txt" $s $s $s $p 1 $b
            done
        done
    done

    # item 3: two-dimensional partition, square grids, b = b*
    for s in $SMALL $BIG; do
        for g in 1x2 2x2 2x4 3x4 3x6 6x6; do
            run "$bin" "$OUT/${part}3_2d.txt" $s $s $s ${g%x*} ${g#*x} $BSTAR
        done
    done
    run "$bin" "$OUT/${part}3_2d.txt" $BIG $BIG $BIG 1 36 $BSTAR      # column grid at p = 36

    # item 4: non-divisible dimensions
    run "$bin" "$OUT/${part}4_nondivisible.txt" 1000 1024 1536 6 6 $BSTAR
done

echo "runs recorded: $(cat "$OUT"/[AB][0-9]_*.txt | grep -c '^### \./\|^### /')"
echo "runs failed:   $(cat "$OUT"/[AB][0-9]_*.txt | grep -c '^### FAILED')"
date
