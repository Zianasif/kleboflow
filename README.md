# KleboFlow

**A Nextflow DSL2 pipeline for whole-genome sequence analysis of *Klebsiella pneumoniae* clinical isolates.**

KleboFlow takes assembled FASTA genomes and runs genome annotation, multi-locus sequence typing, Klebsiella-specific molecular typing, antimicrobial resistance gene detection, core-SNP variant calling, and maximum-likelihood phylogenetic inference — all in a single automated workflow.

---

## Pipeline Overview

```
Input FASTA assemblies
        │
        ├──► PROKKA          Structural & functional genome annotation
        │
        ├──► MLST            Multi-locus sequence typing (klebsiella scheme)
        │      └──► MLST_SUMMARY        Combined ST table
        │
        ├──► KLEBORATE        Capsule type, resistance loci, virulence loci
        │      └──► KLEBORATE_SUMMARY   Merged results table
        │
        ├──► AMRFINDER        AMR gene detection from annotated proteins
        │      └──► AMRFINDER_SUMMARY   Combined AMR table with sample column
        │
        └──► SNIPPY           Per-sample SNP calling vs. reference (assembly mode)
                │
                └──► SNIPPY_CORE    Core-genome SNP alignment
                            │
                            └──► IQTREE    Maximum-likelihood phylogenetic tree
```

---

## Requirements

| Requirement | Version |
|-------------|---------|
| Nextflow | ≥ 23.0.0 |
| Conda / Mamba | Any recent version |

The pipeline uses separate conda environments for each tool (see [Configuration](#configuration)). Mamba is used by default for faster environment resolution (`conda.useMamba = true` in `nextflow.config`).

---

## Repository Structure

```
bioinformatics/
├── Nextflow pipeline/
│   ├── main.nf              # Main workflow
│   └── nextflow.config      # Parameters, resources, conda envs
├── modules/
│   ├── prokka.nf
│   ├── mlst.nf
│   ├── kleborate.nf
│   ├── amrfinder.nf
│   ├── snippy.nf            # Contains both SNIPPY and SNIPPY_CORE processes
│   └── iqtree.nf
├── .gitignore
├── LICENSE
└── README.md
```

---

## Input Data

**FASTA directory** — one assembled genome per file, with `.fasta` extension.

**Reference genome** — a single FASTA file in the same directory. The pipeline automatically excludes:
- Any file whose name matches the reference filename
- Any file whose name begins with `kp_ref`

The default paths in `nextflow.config` are:

```
fasta_dir  = <pipeline_dir>/../Fasta files
reference  = <pipeline_dir>/../Fasta files/kp_ref_uncompressed.fasta
```

Override these on the command line if needed:

```bash
nextflow run main.nf \
    --fasta_dir /path/to/fastas \
    --reference /path/to/reference.fasta
```

---

## Running the Pipeline

```bash
cd "Nextflow pipeline"

# Full run
nextflow run main.nf

# Resume after failure or interruption
nextflow run main.nf -resume

# Override output directory
nextflow run main.nf --outdir /path/to/results
```

---

## Output Files

All results are written to `Nextflow pipeline/results/` by default.

```
results/
├── prokka/
│   └── {sample_id}/
│       ├── {sample_id}.gff       # Annotation (GFF3)
│       ├── {sample_id}.gbk       # GenBank format
│       ├── {sample_id}.faa       # Protein sequences (FASTA)
│       ├── {sample_id}.ffn       # Nucleotide sequences (FASTA)
│       └── {sample_id}.txt       # Summary statistics
│
├── mlst/
│   ├── {sample_id}_mlst.tsv      # Per-sample MLST result
│   └── mlst_summary.tsv          # All samples combined
│
├── kleborate/
│   ├── {sample_id}_kleborate.txt # Per-sample Kleborate result
│   └── kleborate_summary.tsv     # All samples combined
│
├── amrfinder/
│   ├── {sample_id}/
│   │   └── {sample_id}_amrfinder.tsv   # Per-sample AMR genes
│   └── amrfinder_summary.tsv           # All samples combined (with Sample column)
│
├── snippy/
│   └── {sample_id}/
│       ├── {sample_id}/          # Full Snippy output directory
│       ├── {sample_id}.tab       # SNP table
│       └── {sample_id}.vcf       # VCF file
│
├── snippy_core/
│   ├── core.aln                  # Core-only SNP alignment (variable sites)
│   ├── core.full.aln             # Full alignment including invariant sites
│   ├── core.tab                  # Core SNP table
│   ├── core.txt                  # Summary statistics
│   └── core.vcf                  # Core VCF
│
├── iqtree/
│   ├── kp_phylogeny.treefile     # Maximum-likelihood tree (Newick)
│   ├── kp_phylogeny.contree      # Consensus tree with bootstrap support
│   ├── kp_phylogeny.iqtree       # Detailed IQ-TREE log and statistics
│   └── kp_phylogeny.log          # Run log
│
├── pipeline_report_*.html        # Nextflow execution report
├── timeline_*.html               # Process timeline
└── pipeline_dag_*.html           # Directed acyclic graph of workflow
```

---

## Configuration

All parameters and resource allocations are in `Nextflow pipeline/nextflow.config`.

### Key parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `prokka_genus` | `Klebsiella` | Genus passed to Prokka |
| `prokka_species` | `pneumoniae` | Species passed to Prokka |
| `mlst_scheme` | `klebsiella` | MLST scheme |
| `snippy_mincov` | `10` | Minimum read coverage for SNP calling |
| `amrfinder_organism` | `Klebsiella_pneumoniae` | AMRFinder organism flag |
| `iqtree_model` | `GTR+G` | Substitution model |
| `iqtree_bootstrap` | `1000` | Number of ultrafast bootstrap replicates |
| `outdir` | `<pipeline_dir>/results` | Output directory |
| `max_cpus` | `30` | Maximum CPUs across all processes |
| `max_memory` | `60.GB` | Maximum memory across all processes |

### Conda environments

Each tool runs in its own named conda environment. The pipeline expects the following environments to exist under `~/miniconda3/envs/` (or the path set in `CONDA_ENVS_PATH`):

| Environment | Used by |
|-------------|---------|
| `prokka_env` | PROKKA |
| `mlst_env` | MLST, MLST_SUMMARY |
| `kleborate_env` | KLEBORATE, KLEBORATE_SUMMARY |
| `amrfinder_env` | AMRFINDER, AMRFINDER_SUMMARY |
| `snippy_env` | SNIPPY, SNIPPY_CORE |
| `iqtree_env` | IQTREE |

You can override the environment root path:

```bash
nextflow run main.nf --conda_env_root /path/to/your/envs
```

### Resource allocation (per process)

| Process | CPUs | Memory |
|---------|------|--------|
| PROKKA | 20 | 28 GB |
| MLST | 6 | 2 GB |
| KLEBORATE | 4 | 4 GB |
| AMRFINDER | 8 | 10 GB |
| SNIPPY | 12 | 16 GB |
| SNIPPY_CORE | 8 | 16 GB |
| IQTREE | 16 | 28 GB |

These are tuned for an Intel Core i9-14900K with 64 GB RAM. Adjust in `nextflow.config` to match your system.

### Execution profiles

```bash
# Local execution (default)
nextflow run main.nf -profile standard

# SLURM cluster
nextflow run main.nf -profile slurm
```

---

## Tool Details

| Tool | Mode / Flags | Notes |
|------|-------------|-------|
| Prokka | `--kingdom Bacteria --force` | Annotates assemblies directly; outputs GFF, FAA, FFN, GBK |
| MLST | `--scheme klebsiella` | Tseemann/mlst; writes one TSV per sample |
| Kleborate | `--preset kpsc` | K. pneumoniae species complex preset; includes capsule, resistance, virulence |
| AMRFinder | `--protein ... --organism Klebsiella_pneumoniae --plus` | Runs on Prokka FAA output |
| Snippy | `--ctgs` (assembly mode) `--mincov 10` | SNP calling from assembled contigs vs. reference |
| Snippy-core | — | Symlinks Snippy output dirs to avoid path issues; produces `core.full.aln` |
| IQ-TREE | `-m GTR+G -B 1000 --redo` | Ultrafast bootstrap; tree prefix `kp_phylogeny` |

---

## Troubleshooting

**`command not found` for any tool**  
The conda environment for that process is missing or the tool is not installed in it. Check with:
```bash
conda activate snippy_env
snippy --version
```

**Memory errors**  
Reduce per-process memory in `nextflow.config` and lower `max_memory`:
```groovy
params.max_memory = "48.GB"
```

**Resuming a run after failure**  
```bash
nextflow run main.nf -resume
```
Nextflow caches completed process outputs and skips them on resume.

**Viewing logs**  
```bash
cat .nextflow.log
```

---

## Citation

If you use KleboFlow, please cite the underlying tools:

- **Prokka**: Seemann T. (2014). *Bioinformatics*, 30(15):2068–2069. https://doi.org/10.1093/bioinformatics/btu153
- **MLST**: Tseemann T. https://github.com/tseemann/mlst
- **Kleborate**: Lam MMC, et al. (2022). *Nature Communications*, 13:4183. https://doi.org/10.1038/s41467-022-31715-6
- **AMRFinder**: Feldgarden M, et al. (2021). *Scientific Reports*, 11:16931. https://doi.org/10.1038/s41598-021-95699-7
- **Snippy**: Seemann T. https://github.com/tseemann/snippy
- **IQ-TREE**: Nguyen LT, et al. (2015). *Molecular Biology and Evolution*, 32(1):268–274. https://doi.org/10.1093/molbev/msu300
- **Nextflow**: Di Tommaso P, et al. (2017). *Nature Biotechnology*, 35:316–319. https://doi.org/10.1038/nbt.3820

---

## License

MIT — see [LICENSE](LICENSE).
