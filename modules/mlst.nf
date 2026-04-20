process MLST {
    tag "${sample_id}"
    publishDir "${params.outdir}/mlst", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path("${sample_id}_mlst.tsv"), emit: tsv

    script:
    """
    mlst \\
        --scheme ${params.mlst_scheme} \\
        --threads ${task.cpus} \\
        ${fasta} > ${sample_id}_mlst.tsv
    """
}

process MLST_SUMMARY {
    publishDir "${params.outdir}/mlst", mode: 'copy'

    input:
    path(tsvs)

    output:
    path("mlst_summary.tsv"), emit: summary

    script:
    """
    # Combine all MLST results into one table
    echo -e "FILE\\tSCHEME\\tST\\tALLELES" > mlst_summary.tsv
    cat ${tsvs} >> mlst_summary.tsv
    """
}
