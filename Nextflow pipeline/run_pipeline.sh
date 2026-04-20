#!/bin/bash
# ============================================================
# Run the Klebsiella pneumoniae Analysis Pipeline
# ============================================================
# Usage:
#   ./run_pipeline.sh              # fresh run
#   ./run_pipeline.sh -resume      # resume from checkpoint
# ============================================================

set -euo pipefail

PIPELINE_DIR="$(cd "$(dirname "$0")" && pwd)"
NEXTFLOW="${NEXTFLOW:-nextflow}"
WORK_DIR="${WORK_DIR:-${PIPELINE_DIR}/work}"

mkdir -p "${WORK_DIR}"

# Pass -resume flag if provided
RESUME_FLAG="${1:-}"

echo "Starting Klebsiella pipeline..."
echo "Pipeline dir : $PIPELINE_DIR"
echo "Nextflow cmd : $NEXTFLOW"
echo "Work dir     : $WORK_DIR"
echo ""

$NEXTFLOW run "${PIPELINE_DIR}/main.nf" \
    -c "${PIPELINE_DIR}/nextflow.config" \
    -w "${WORK_DIR}" \
    -with-trace \
    $RESUME_FLAG

echo "Pipeline finished."
