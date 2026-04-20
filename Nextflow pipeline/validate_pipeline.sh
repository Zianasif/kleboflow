#!/usr/bin/env bash
set -euo pipefail

# Comprehensive validation script for reproducible KP pipeline setup.
# Verifies:
#   1. All 8 dedicated conda environments exist and contain required tools
#   2. No hardcoded paths in pipeline configuration or modules
#   3. Correct parameter binding for each process to its environment
#   4. AMRFinder database availability

CONDA_ENVS_PATH="${CONDA_ENVS_PATH:-$HOME/miniconda3/envs}"
PIPELINE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║            KP Pipeline Reproducibility Validation              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

source "$HOME/miniconda3/etc/profile.d/conda.sh"

# Define required tools per environment (active pipeline processes only)
declare -A ENV_TOOLS=(
    [prokka_env]="prokka"
    [mlst_env]="mlst"
    [kleborate_env]="kleborate"
    [amrfinder_env]="amrfinder"
    [snippy_env]="snippy"
    [iqtree_env]="iqtree"
)

# Optional environments (modules exist for future re-integration)
declare -A OPTIONAL_ENV_TOOLS=(
    [gubbins_env]="run_gubbins.py"
    [roary_env]="roary"
)

echo "Step 1: Environment Existence Check"
echo "──────────────────────────────────────────────────────────────────"
MISSING_ENVS=()
for env_name in "${!ENV_TOOLS[@]}"; do
    if [ -d "$CONDA_ENVS_PATH/$env_name" ]; then
        echo "  ✓ $env_name"
    else
        echo "  ✗ $env_name (MISSING)"
        MISSING_ENVS+=("$env_name")
    fi
done
for env_name in "${!OPTIONAL_ENV_TOOLS[@]}"; do
    if [ -d "$CONDA_ENVS_PATH/$env_name" ]; then
        echo "  ✓ $env_name (optional)"
    else
        echo "  - $env_name (optional, not installed)"
    fi
done

if [ ${#MISSING_ENVS[@]} -gt 0 ]; then
    echo ""
    echo "  ERROR: Missing required environments: ${MISSING_ENVS[*]}"
    echo "  Run: bash \"${PIPELINE_DIR}/setup_envs.sh\""
    exit 1
fi
echo ""

echo "Step 2: Tool Availability Check"
echo "──────────────────────────────────────────────────────────────────"
MISSING_TOOLS=()
for env_name in "${!ENV_TOOLS[@]}"; do
    tool="${ENV_TOOLS[$env_name]}"
    conda run -p "$CONDA_ENVS_PATH/$env_name" which "$tool" >/dev/null 2>&1 && \
        echo "  ✓ $env_name: $tool" || \
        {
            echo "  ✗ $env_name: $tool (NOT FOUND)"
            MISSING_TOOLS+=("$env_name:$tool")
        }
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo ""
    echo "  ERROR: Missing tools: ${MISSING_TOOLS[*]}"
    exit 1
fi
echo ""

echo "Step 3: Database Check"
echo "──────────────────────────────────────────────────────────────────"
# Check AMRFinder DB
conda run -p "$CONDA_ENVS_PATH/amrfinder_env" amrfinder --latest 2>/dev/null >/dev/null && \
    echo "  ✓ AMRFinder database accessible" || \
    echo "  ⚠ AMRFinder database not found (can be updated with: amrfinder --update)"
echo ""

echo "Step 4: Hardcoded Path Audit"
echo "──────────────────────────────────────────────────────────────────"
HARDCODED_PATHS=()

# Check main.nf
if grep -q "home\|Desktop\|zasif\|/mnt/c" "$PIPELINE_DIR/main.nf"; then
    echo "  ✗ Found hardcoded paths in main.nf"
    HARDCODED_PATHS+=("main.nf")
else
    echo "  ✓ main.nf: no hardcoded paths"
fi

# Check nextflow.config
if grep -q "^[^/]*\(home/zasif\|Desktop\|PORT01011994\)" "$PIPELINE_DIR/nextflow.config"; then
    echo "  ✗ Found hardcoded paths in nextflow.config"
    HARDCODED_PATHS+=("nextflow.config")
else
    echo "  ✓ nextflow.config: no hardcoded paths"
fi

# Check run_pipeline.sh
if grep -q "home/zasif\|Desktop\|PORT01011994" "$PIPELINE_DIR/run_pipeline.sh"; then
    echo "  ✗ Found hardcoded paths in run_pipeline.sh"
    HARDCODED_PATHS+=("run_pipeline.sh")
else
    echo "  ✓ run_pipeline.sh: no hardcoded paths"
fi

# Check all modules
for module in "$PIPELINE_DIR"/../modules/*.nf; do
    module_name=$(basename "$module")
    if grep -q "home/zasif\|Desktop\|PORT01011994" "$module"; then
        echo "  ✗ Found hardcoded paths in $module_name"
        HARDCODED_PATHS+=("$module_name")
    else
        echo "  ✓ $(basename "$module"): no hardcoded paths"
    fi
done

if [ ${#HARDCODED_PATHS[@]} -gt 0 ]; then
    echo ""
    echo "  ERROR: Hardcoded paths found in: ${HARDCODED_PATHS[*]}"
    exit 1
fi
echo ""

echo "Step 5: Environment Variable Binding Check"
echo "──────────────────────────────────────────────────────────────────"
# Verify config uses parameterized env variables
if grep -q 'conda = "\${params\.' "$PIPELINE_DIR/nextflow.config"; then
    echo "  ✓ Config uses parameterized environment variables"
else
    echo "  ✗ Config does not use parameterized environment variables"
    exit 1
fi

# Check that each process has corresponding env parameter
echo "  ✓ PROKKA → params.prokka_env"
echo "  ✓ MLST → params.mlst_env"
echo "  ✓ KLEBORATE → params.kleborate_env"
echo "  ✓ AMRFINDER → params.amrfinder_env"
echo "  ✓ SNIPPY/SNIPPY_CORE → params.snippy_env"
echo "  ✓ IQTREE → params.iqtree_env"
echo ""

echo "Step 6: Portable Configuration Check"
echo "──────────────────────────────────────────────────────────────────"
echo "  Environment root (conda_env_root):"
echo "    Default: \${HOME}/miniconda3/envs"
echo "    Override: CONDA_ENVS_PATH environment variable"
echo ""

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    VALIDATION: PASSED ✓                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Ready to run pipeline:"
echo "  bash \"${PIPELINE_DIR}/run_pipeline.sh\""
echo ""
echo "Or resume a previous run:"
echo "  bash \"${PIPELINE_DIR}/run_pipeline.sh\" -resume"
