#!/usr/bin/env nextflow

// ============================================================
// Klebsiella pneumoniae Genomic Analysis Pipeline
// ============================================================
// Tools:
//   - Prokka       : Genome annotation
//   - MLST         : Sequence typing (ST)
//   - Kleborate    : Klebsiella-specific typing (ST, resistance, virulence, capsule)
//   - AMRFinder    : Antimicrobial resistance gene detection
//   - Snippy       : Variant calling (assembly mode --ctgs)
//   - Snippy-core  : Core SNP alignment
//   - IQ-TREE      : Phylogenetic inference
// ============================================================

nextflow.enable.dsl = 2

include { PROKKA                      } from '../modules/prokka'
include { MLST; MLST_SUMMARY          } from '../modules/mlst'
include { KLEBORATE; KLEBORATE_SUMMARY } from '../modules/kleborate'
include { AMRFINDER; AMRFINDER_SUMMARY } from '../modules/amrfinder'
include { SNIPPY; SNIPPY_CORE         } from '../modules/snippy'
include { IQTREE                      } from '../modules/iqtree'

// ============================================================
// Print pipeline info
// ============================================================

log.info """
╔══════════════════════════════════════════════════════╗
║     Klebsiella pneumoniae Analysis Pipeline v1.0     ║
╠══════════════════════════════════════════════════════╣
║ FASTA dir   : ${params.fasta_dir}
║ Reference   : ${params.reference}
║ Output dir  : ${params.outdir}
╚══════════════════════════════════════════════════════╝
""".stripIndent()

// ============================================================
// Helper: check required files exist
// ============================================================

def checkInputFiles(fasta_dir, reference) {
    def fasta_path = file(fasta_dir)
    def ref_path   = file(reference)
    if (!fasta_path.exists()) error "FASTA directory not found: ${fasta_dir}"
    if (!ref_path.exists())   error "Reference file not found: ${reference}"
}

// ============================================================
// Main workflow
// ============================================================

workflow {

    checkInputFiles(params.fasta_dir, params.reference)

    // Reference genome
    reference = file(params.reference)

    // Build input channel: [sample_id, fasta_file]
    // Exclude reference and any non-isolate files
    fasta_ch = Channel
        .fromPath("${params.fasta_dir}/*.fasta")
        .filter { it.name != file(params.reference).name && !it.name.startsWith("kp_ref") }
        .map { fasta -> [ fasta.baseName, fasta ] }

    // --------------------------------------------------------
    // 1. Genome Annotation - Prokka
    // --------------------------------------------------------
    PROKKA(fasta_ch)

    // --------------------------------------------------------
    // 2a. Sequence Typing - MLST (parallel, uses FASTA)
    // --------------------------------------------------------
    MLST(fasta_ch)
    MLST_SUMMARY(MLST.out.tsv.collect())

    // --------------------------------------------------------
    // 2b. Klebsiella-specific Typing - Kleborate (parallel, uses FASTA)
    //     (ST, KL/OL capsule type, resistance, virulence loci)
    // --------------------------------------------------------
    KLEBORATE(fasta_ch)
    KLEBORATE_SUMMARY(KLEBORATE.out.results.collect())

    // --------------------------------------------------------
    // 2c. Variant Calling - Snippy (parallel, uses FASTA)
    // --------------------------------------------------------
    SNIPPY(fasta_ch, reference)

    // --------------------------------------------------------
    // 3. Core SNP Alignment - Snippy-core
    // --------------------------------------------------------
    snippy_dirs_ch = SNIPPY.out.snippy_dir
        .map { sample_id, dir -> dir }
        .collect()

    SNIPPY_CORE(snippy_dirs_ch, reference)

    // --------------------------------------------------------
    // 4. Phylogenetic Tree - IQ-TREE (using core SNP alignment directly)
    // --------------------------------------------------------
    IQTREE(SNIPPY_CORE.out.core_full_aln)

    // --------------------------------------------------------
    // 5. Resistance Gene Detection - AMRFinder
    // --------------------------------------------------------
    AMRFINDER(PROKKA.out.faa)
    AMRFINDER_SUMMARY(AMRFINDER.out.tsv.collect())

}

// --------------------------------------------------------
// Done
// --------------------------------------------------------
workflow.onComplete {
    log.info """
    ╔══════════════════════════════════════════════════════╗
    ║              Pipeline Complete!                      ║
    ╠══════════════════════════════════════════════════════╣
    ║ Status     : ${workflow.success ? 'SUCCESS' : 'FAILED'}
    ║ Duration   : ${workflow.duration}
    ║ Results    : ${params.outdir}
    ╚══════════════════════════════════════════════════════╝
    """.stripIndent()
}
