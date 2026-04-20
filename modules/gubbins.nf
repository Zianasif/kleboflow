process GUBBINS {
    publishDir "${params.outdir}/gubbins", mode: 'copy'

    input:
    path(alignment)

    output:
    path("gubbins.filtered_polymorphic_sites.fasta"), emit: clean_aln
    path("gubbins.recombination_predictions.gff"),    emit: recomb_gff
    path("gubbins.per_branch_statistics.csv"),        emit: stats
    path("gubbins.summary_of_snp_distribution.vcf"),  emit: vcf
    path("gubbins.node_labelled.final_tree.tre"),     emit: tree

    script:
    """
    run_gubbins.py \\
        --prefix gubbins \\
        --tree-builder ${params.gubbins_tree_builder} \\
        --threads ${task.cpus} \\
        ${alignment}
    """
}
