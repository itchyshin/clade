#!/bin/bash
# Launch one CMA-ES subprocess per scenario, in parallel.
#
# Usage: bash dev/audit/calibration/run_all.sh [--iter N] [--pop K] [--max-parallel M]

set -u
ITER=20
POP=6
MAX_PAR=16   # keep well under the 200-core cap; each subprocess owns ~2 GB

while [ $# -gt 0 ]; do
  case "$1" in
    --iter)         ITER="$2"; shift 2 ;;
    --pop)          POP="$2"; shift 2 ;;
    --max-parallel) MAX_PAR="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

export PATH="$HOME/.juliaup/bin:$PATH"
mkdir -p dev/audit/calibration/_artifacts
: > dev/audit/calibration/_artifacts/progress.log

# Scenarios — same ones registered in fitness_functions.R
SCENARIOS=$(Rscript -e '
.libPaths(c("~/R/lib", .libPaths()))
source("dev/audit/calibration/fitness_functions.R")
cat(names(fitness_registry), sep="\n")
')

N_TOTAL=$(printf '%s\n' "$SCENARIOS" | wc -l)
echo "[launcher] $N_TOTAL scenarios, iter=$ITER pop=$POP max_parallel=$MAX_PAR"

# Use xargs to parallelise; each Rscript spawns its own warm Julia process.
printf '%s\n' "$SCENARIOS" | xargs -I {} -P "$MAX_PAR" -n 1 \
  bash -c "
    Rscript dev/audit/calibration/run_one.R '{}' --iter $ITER --pop $POP \
      > dev/audit/calibration/_artifacts/{}.stdout 2>&1
  "

echo "[launcher] all subprocesses exited"
echo "Results in dev/audit/calibration/_artifacts/*.json"
