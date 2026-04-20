#!/usr/bin/env bash
set -euo pipefail

# Reproducible per-tool conda environments for the KP Nextflow pipeline.
# Override CONDA_ENVS_PATH if your env root is not $HOME/miniconda3/envs.
CONDA_ENVS_PATH="${CONDA_ENVS_PATH:-$HOME/miniconda3/envs}"

source "$HOME/miniconda3/etc/profile.d/conda.sh"

mamba create -y -p "$CONDA_ENVS_PATH/prokka_env" -c conda-forge -c bioconda prokka=1.14.6
mamba create -y -p "$CONDA_ENVS_PATH/mlst_env" -c conda-forge -c bioconda mlst
mamba create -y -p "$CONDA_ENVS_PATH/kleborate_env" -c conda-forge -c bioconda kleborate
mamba create -y -p "$CONDA_ENVS_PATH/amrfinder_env" -c conda-forge -c bioconda ncbi-amrfinderplus
mamba create -y -p "$CONDA_ENVS_PATH/snippy_env" -c conda-forge -c bioconda snippy=4.6.0
mamba create -y -p "$CONDA_ENVS_PATH/gubbins_env" -c conda-forge -c bioconda gubbins
mamba create -y -p "$CONDA_ENVS_PATH/iqtree_env" -c conda-forge -c bioconda iqtree
mamba create -y -p "$CONDA_ENVS_PATH/roary_env" -c conda-forge -c bioconda roary

# Optional but recommended database setup.
conda run -p "$CONDA_ENVS_PATH/amrfinder_env" amrfinder --update

echo "All pipeline environments are ready under: $CONDA_ENVS_PATH"
